extends SceneTree
# Сценарии событий в ОКОННОМ запуске (не headless) с ботом, который ходит по карте (долгие прямые, развороты назад),
# и покадровыми проверками: время кадра, пустые/незапечённые куски под экраном, куски без объектов (main.chunks),
# «полусмена» биома (по состоянию кусков и, с --capture, по пикселям), чёрные области на снимке, зависания.
#   godot --path . --script res://tools/bench_events.gd -- --keys-only --scenario NAME [--out DIR] [--capture]
# NAME: walk | rift | rift_slow | biome | rift_biome_before | rift_biome_same | rift_biome_after | sat_rift | sat_biome |
#       boss_chain_biome | pause_biome | pause_rift | rush_chain
# --mode normal|daily|rush (SV.run_mode), --dex N (стартер, SV.run_dex).
# rift_slow: вместе с --arenaslow MS (поток арены нарочно медленный, как приставка) — проверка завесы «Загрузка…».
# --keys-only: как на приставке (запекание в потоках). Без него — путь Mac по умолчанию (синхронное по строкам).
# --capture: снимок вьюпорта каждый кадр (дорого: время кадров в таком прогоне не показательно), PNG в --out.
# --pick S: через сколько секунд после открытия «игрок» выбирает карту (0.45: окно глотает ввод первые 0.4 с).
# Итог: строка RESULT {...}; при --out ещё frames_NAME.csv (кадр, мс, метка).

const L = preload("res://scripts/lang.gd")

var m: Node
var SCEN := _arg_str("--scenario", "rift")
var OUT := _arg_str("--out", "")
var CAPTURE := "--capture" in OS.get_cmdline_user_args()
var PICK := float(_arg_str("--pick", "0.45"))
var rng := RandomNumberGenerator.new()

var n := 0
var last := 0
var t0 := 0
var label := ""
var frames: Array = []        # [кадр, мс, метка]
var res := {}
var marks := {}               # событие -> кадр
# бот
var walking := false
var wdir := Vector2.RIGHT
var wleft := 0.0
var autopick := true
var saturate := false
# проверки
var chk_frames := 0
var blank_frames := 0
var blank_chunks := 0
var noobj_frames := 0
var half_int := 0
var half_px := 0
var black_max := 0.0
var black_frames := 0
var shots := 0
# окна
var open_prev := false
var last_close_us := 0
var gap_max_frame := 0.0
var gaps: Array = []
var cards_seen: Array = []
var bond_close_us := 0


static func _arg_str(name: String, def: String) -> String:
	var a := OS.get_cmdline_user_args()
	var i := a.find(name)
	return String(a[i + 1]) if i >= 0 and i + 1 < a.size() else def


func _initialize() -> void:
	seed(12345)
	rng.seed = 777
	var SVl = load("res://scripts/save_data.gd")
	SVl.ensure()
	SVl.run_mode = _arg_str("--mode", "normal")
	SVl.run_dex = int(_arg_str("--dex", "25"))
	if "--maxup" in OS.get_cmdline_user_args():
		# сильно прокачанное сохранение (только в памяти; запускать с временным HOME): все улучшения на максимум
		var up := {}
		for u in SVl.UPGRADES:
			if String(u["id"]) != "tm" and String(u["id"]) != "ban":
				up[String(u["id"])] = int(u["max"])
		SVl.d["pup"][str(SVl.run_dex)] = up
	m = load("res://scenes/main.tscn").instantiate()
	root.add_child(m)
	last = Time.get_ticks_usec()
	t0 = last
	if OUT != "":
		DirAccess.make_dir_recursive_absolute(OUT)
	_main.call_deferred()


func _log(what: String) -> void:
	print("  [%8.1f мс, кадр %d] %s" % [(Time.get_ticks_usec() - t0) / 1000.0, n, what])


func _mark(ev: String) -> void:
	marks[ev] = n
	_log("событие " + ev)


# ---------------- каждый кадр ----------------
func _process(delta: float) -> bool:
	var now := Time.get_ticks_usec()
	var ms := (now - last) / 1000.0
	last = now
	if m == null or not m.loading_done:
		return false
	frames.append([n, snappedf(ms, 0.01), label])
	if ms > 100.0 and n > 60:
		_log("кадр %.0f мс (%s) Prof: %s | куски: %s" % [ms, label, Prof.line_cur(), Prof.line_chunks()])
	n += 1
	_god()
	if m.get("rift_wait") and not marks.has("завеса"):
		_mark("завеса")
	_checks()
	_bot(delta)
	_cards(ms, now)
	return false


func _god() -> void:
	m.player.hp = maxf(m.player.hp, 1e6)
	m.player.max_hp = maxf(m.player.max_hp, 1e6)
	m.player.invuln = 5.0


func _bot(delta: float) -> void:
	if saturate and m.arena == null and not m.choosing and not m.paused:
		if m.enemies.size() < m.ENEMY_CAP:
			m._spawn_one()
		if m.orbs.size() < 120 and n % 2 == 0:
			m._spawn_orb(m.player.position + Vector2(rng.randf_range(-700, 700), rng.randf_range(-450, 450)), "xp", 1.0)
	if not walking or m.choosing or m.paused or m.arena != null:
		return
	wleft -= delta
	if wleft <= 0.0:
		# длинные прямые по нескольку кусков и развороты назад (возврат в уже выгруженные места)
		if rng.randf() < 0.3:
			wdir = -wdir
		else:
			wdir = Vector2.from_angle(rng.randf() * TAU)
		wleft = rng.randf_range(2.0, 9.0)
	m.player.position += wdir * 165.0 * minf(delta, 0.1)


func _cards(ms: float, now: int) -> void:
	var op: bool = m.cards.open
	if op and not open_prev:
		var gap := (now - last_close_us) / 1000.0 if last_close_us > 0 else -1.0
		cards_seen.append(String(m.cards.headline))
		_log("окно открыто: %s%s" % [m.cards.headline, ("  (после прошлого %.0f мс, худший кадр %.1f)" % [gap, gap_max_frame]) if gap >= 0.0 else ""])
		if gap >= 0.0 and gap < 15000.0:
			gaps.append([snappedf(gap, 1.0), snappedf(gap_max_frame, 0.1)])
		gap_max_frame = 0.0
	if not op and last_close_us > 0:
		gap_max_frame = maxf(gap_max_frame, ms)
	if op and autopick and not m.paused and m.cards.age >= PICK:
		var heading: String = String(m.cards.headline)
		m._on_card_chosen(0)
		if not m.cards.open:
			last_close_us = Time.get_ticks_usec()
			if heading == L.t("¡Vínculo!"):
				bond_close_us = last_close_us
	open_prev = m.cards.open


# Куски под экраном (прямоугольник камеры прошлого кадра): без текстуры и без старого биома = пустота;
# нет записи в main.chunks = объекты (деревья, камни, трава) этого куска не созданы; новый биом в одном куске и только
# старый в другом = полусмена.
func _checks() -> void:
	var g = m.ground
	if not g.visible or n < 30:
		return
	chk_frames += 1
	var vp: Viewport = root
	var r: Rect2 = vp.get_canvas_transform().affine_inverse() * Rect2(Vector2.ZERO, vp.get_visible_rect().size)
	var k: float = g.fade_t * g.fade_t * (3.0 - 2.0 * g.fade_t)
	var bad := 0
	var noobj := 0
	var nn := 0
	var oo := 0
	for key in g._keys_in(r):
		var ch = g.chunks.get(key)
		if ch == null or (ch["tex"] == null and (ch["old"] == null or g.fade_t >= 1.0)):
			bad += 1
		if not m.chunks.has(key):
			noobj += 1
		if ch != null and g.fade_t < 1.0:
			var newv: bool = ch["tex"] != null and ch["tb"] == g.biome
			if newv and (k > 0.15 or ch["old"] == null):
				nn += 1
			elif not newv and ch["old"] != null:
				oo += 1
	if bad > 0:
		blank_frames += 1
		blank_chunks += bad
	if noobj > 0:
		noobj_frames += 1
	if nn > 0 and oo > 0:
		half_int += 1
		if half_int <= 5:
			_log("ПОЛУСМЕНА (куски): новых=%d старых=%d fade=%.2f" % [nn, oo, g.fade_t])
	if CAPTURE:
		_pixel_check(g)


var _pal_cache := {}


func _pal_cols(g, b: int) -> Array:
	if _pal_cache.has(b):
		return _pal_cache[b]
	var p: Dictionary = g.pal(b)
	var out: Array = []
	for key in ["floor", "dirt", "wallTop", "wallFace"]:
		for c in p[key]:
			out.append(c)
	for key in ["speck", "light", "wallLight", "shore"]:   # без жидкостей: вода разных биомов похожа
		out.append(p[key])
	_pal_cache[b] = out
	return out


static func _near(c: Color, cols: Array) -> float:
	var best := 9.0
	for q in cols:
		best = minf(best, absf(c.r - q.r) + absf(c.g - q.g) + absf(c.b - q.b))
	return best


# Сетка 64x36 точек, 4x3 области. Точка относится к старой или новой палитре земли, если близка к одной из них.
# Полусмена: в одной области >=75 % нового, в другой >=75 % старого. Чёрное: доля точек почти (0,0,0).
func _pixel_check(g) -> void:
	var img: Image = root.get_texture().get_image()
	if img == null:
		return
	var fading: bool = g.fade_t < 1.0 and g.prev_biome != g.biome
	var oldc: Array = _pal_cols(g, g.prev_biome)
	var newc: Array = _pal_cols(g, g.biome)
	var W := img.get_width()
	var H := img.get_height()
	var rn := []
	var ro := []
	rn.resize(12)
	ro.resize(12)
	rn.fill(0)
	ro.fill(0)
	var blk := []
	blk.resize(12)
	blk.fill(0)
	for j in range(36):
		for i in range(64):
			var c := img.get_pixel(int((i + 0.5) * W / 64.0), int((j + 0.5) * H / 36.0))
			if c.r + c.g + c.b < 0.02:
				blk[(j * 3 / 36) * 4 + (i * 4 / 64)] += 1
			if not fading:
				continue
			var dn := _near(c, newc)
			var dold := _near(c, oldc)
			if minf(dn, dold) > 0.03 or absf(dn - dold) < 0.03:
				continue
			var ri: int = (j * 3 / 36) * 4 + (i * 4 / 64)
			if dn < dold:
				rn[ri] += 1
			else:
				ro[ri] += 1
	# «чёрная дыра»: область 1/12 экрана, где больше половины точек почти чёрные (контуры спрайтов так не набирают)
	var bf := 0.0
	for ri in range(12):
		bf = maxf(bf, float(blk[ri]) / (16.0 * 12.0))
	if bf <= 0.5:
		bf = 0.0
	black_max = maxf(black_max, bf)
	if bf > 0.5:
		black_frames += 1
	var half := false
	if fading:
		var mx := -1.0
		var mn := 2.0
		for ri in range(12):
			var t: int = rn[ri] + ro[ri]
			if t < 30:
				continue
			var f: float = float(rn[ri]) / float(t)
			mx = maxf(mx, f)
			mn = minf(mn, f)
		half = mx >= 0.75 and mn <= 0.25
		if half:
			half_px += 1
	if OUT != "" and shots < 60 and (half or bf > 0.5 or (fading and n % 10 == 0)):
		img.save_png(OUT.path_join("%s_%05d%s.png" % [SCEN, n, "_HALF" if half else ("_BLACK" if bf > 0.5 else "")]))
		shots += 1


# ---------------- ожидание ----------------
func _frames(k: int) -> void:
	for i in range(k):
		await process_frame


func _secs(s: float) -> void:
	var until := Time.get_ticks_msec() + int(s * 1000.0)
	while Time.get_ticks_msec() < until:
		await process_frame


func _until(cond: Callable, timeout_s: float, what: String) -> bool:
	var until := Time.get_ticks_msec() + int(timeout_s * 1000.0)
	while not cond.call():
		if Time.get_ticks_msec() > until:
			_log("ТАЙМАУТ: " + what)
			res["timeout"] = what
			return false
		await process_frame
	return true


func _boundary() -> float:
	var step: float = 150.0 if m.mode == "rush" else 240.0
	return float(m.biome_idx - m.biome_off + 1) * step


func _saturate() -> void:
	saturate = true
	m.player.level = 30
	m.player.xp_next = 1e12
	for mid in ["ember", "fire-spin", "heat-wave", "thunderbolt", "bug-buzz", "rock-slide", "tackle", "water-gun"]:
		if m.player.moves.size() < 8:
			var mv: Dictionary = m._new_move(mid, 4)
			m.player.moves.append(mv)
			for _i in range(10):
				m._level_up_move(mv)
	m.item = "leftovers"
	for k in range(m.ENEMY_CAP):
		m._spawn_one()
	for k in range(60):
		m._spawn_orb(m.player.position + Vector2(rng.randf_range(-600, 600), rng.randf_range(-400, 400)), "xpBig" if k % 3 == 0 else "xp", 2.0)
	for k in range(4):
		m._spawn_orb(m.player.position + Vector2(rng.randf_range(-500, 500), rng.randf_range(-300, 300)), "heal", 0.0)
	if not m.boss_run.is_empty():
		m._spawn_boss(m.boss_run[0])
	_log("насыщение: врагов=%d орбов=%d босс=%s" % [m.enemies.size(), m.orbs.size(), m._boss_alive()])


# ---------------- сценарии ----------------
func _main() -> void:
	await _until(func() -> bool: return m.loading_done, 60.0, "загрузка")
	await _frames(60)
	m.run_time = 150.0   # подальше от смены биома, если сценарий её не задаёт
	label = "прогулка"
	walking = true
	match SCEN:
		"walk":
			await _secs(60.0)
		"rift", "rift_slow":
			await _rift_flow(false, "")
		"rush_chain":
			await _rush_chain()
		"sat_rift":
			await _rift_flow(true, "")
		"rift_biome_before", "rift_biome_same", "rift_biome_after":
			await _rift_flow(false, SCEN.trim_prefix("rift_biome_"))
		"pause_rift":
			await _rift_flow(false, "", true)
		"biome":
			await _biome_flow(false, false, false)
		"sat_biome":
			await _biome_flow(true, false, false)
		"pause_biome":
			await _biome_flow(false, true, false)
		"boss_chain_biome":
			await _biome_flow(false, false, true)
		_:
			_log("неизвестный сценарий " + SCEN)
	_report()
	quit()


func _ev_stats(ev: String, span: int) -> Dictionary:
	if not marks.has(ev):
		return {}
	var f0: int = marks[ev]
	var w := 0.0
	var o50 := 0
	var o100 := 0
	for f in frames:
		if f[0] > f0 and f[0] <= f0 + span:
			w = maxf(w, f[1])
			if f[1] > 50.0:
				o50 += 1
			if f[1] > 100.0:
				o100 += 1
	return {"worst_ms": snappedf(w, 0.1), "over50": o50, "over100": o100}


func _rift_flow(sat: bool, bmode: String, pause: bool = false) -> void:
	if sat:
		_saturate()
	else:
		m.player.level = 6
		m.player.xp = 0.0
		m.player.xp_next = m._xp_need(6)
		for mid in ["ember", "water-gun", "thunderbolt"]:
			if m.player.moves.size() < 4:
				m.player.moves.append(m._new_move(mid, 1))
	await _secs(12.0)
	walking = false
	label = "к_грете"
	m.rift_check = 1e9
	m._open_rift(-1, false)
	_mark("грета_открыта")
	if m.rift == null:
		res["error"] = "грета не открылась"
		return
	# идём к ней как игрок (~165 px/s), но не ближе 60 px
	await _until(func() -> bool:
		if m.rift == null:
			return true
		var to: Vector2 = m.rift.position - m.player.position
		if to.length() > 60.0:
			m.player.position += to.normalized() * minf(to.length() - 59.0, 165.0 / 30.0)
		return to.length() <= 90.0 and m.rift.t > 1.0, 20.0, "подход к грете")
	if m.rift == null:
		res["error"] = "грета исчезла"
		return
	var ar = m.rift_info.get("arena")
	res["arena_thread_done_at_entry"] = ar != null and (ar._thread == null or not ar._thread.is_alive())
	var e_before := 0
	for e in m.enemies:
		if is_instance_valid(e) and not e.dead:
			e_before += 1
	res["world_enemies_before"] = e_before
	res["world_orbs_before"] = m.orbs.size()
	res["biome_before"] = m.biome_idx
	var bnd := _boundary()
	label = "вход"
	if bmode == "before":
		m.run_time = bnd - 0.0001   # смена в следующем кадре, вход через 0.5 с
		await _until(func() -> bool: return m.biome_idx != res["biome_before"], 3.0, "смена до входа")
		_mark("смена_биома")
		await _secs(0.5)
	elif bmode == "same":
		m.run_time = bnd - 0.0001   # в одном кадре main: _update_biome (смена), затем _update_rift (вход)
	elif bmode == "after":
		m.run_time = bnd - 0.5      # смена наступит через 0.5 с уже внутри арены
	m.player.position = m.rift.position
	_mark("вход")
	await _until(func() -> bool: return m.arena != null, 10.0, "арена")
	_mark("арена")
	if pause:
		await _frames(2)
		m.paused = true
		_mark("пауза")
		await _secs(1.5)
		m.paused = false
	await _secs(2.0)
	label = "бой"
	var b = m.ainfo.get("boss")
	if b != null and is_instance_valid(b):
		b.position = m.player.position + Vector2(0.0, -150.0)
		m._kill_enemy(b)
	_mark("победа")
	label = "окна"
	var ok: bool = await _until(func() -> bool: return m.arena == null, 40.0, "возврат в мир")
	if not ok:
		return
	_mark("мир")
	res["bond_to_world_ms"] = snappedf((Time.get_ticks_usec() - bond_close_us) / 1000.0, 1.0) if bond_close_us > 0 else -1.0
	var e_after := 0
	for e in m.enemies:
		if is_instance_valid(e) and not e.dead:
			e_after += 1
	res["world_enemies_after"] = e_after
	res["world_orbs_after"] = m.orbs.size()
	res["world_hidden_after"] = _hidden_count()
	label = "после"
	walking = true
	await _secs(15.0)
	res["biome_after"] = m.biome_idx


# Режим «только боссы»: 5 боссов подряд, каждый убивается, окна уровней выбираются; ничего не должно залипнуть.
func _rush_chain() -> void:
	m.player.level = 6
	m.player.xp = 0.0
	m.player.xp_next = m._xp_need(6)
	for i in range(5):
		label = "босс%d" % (i + 1)
		if m.mode == "rush":
			m.rush_rest = minf(m.rush_rest, 1.0)
		elif not m.boss_run.is_empty():
			m._spawn_boss(m.boss_run[mini(i, m.boss_run.size() - 1)])
		var ok: bool = await _until(func() -> bool: return m._boss_alive(), 20.0, "босс %d не появился" % (i + 1))
		if not ok:
			return
		await _secs(1.0)
		for e in m.enemies.duplicate():
			if is_instance_valid(e) and e.boss and not e.dead:
				e.position = m.player.position + Vector2(140.0, 0.0)
				m._kill_enemy(e)
		_mark("босс%d_убит" % (i + 1))
		ok = await _until(func() -> bool: return not m._boss_alive() and not m.choosing and m.pending_levels == 0, 30.0, "окна после босса %d" % (i + 1))
		if not ok:
			return
	res["bosses_killed"] = 5
	await _secs(3.0)


func _hidden_count() -> int:
	var c := 0
	for e in m.enemies:
		if is_instance_valid(e) and not e.visible:
			c += 1
	for o in m.orbs:
		if is_instance_valid(o) and not o.visible:
			c += 1
	return c


func _biome_flow(sat: bool, pause: bool, boss_chain: bool) -> void:
	if sat:
		_saturate()
	await _secs(5.0)
	var b0: int = m.biome_idx
	var bnd := _boundary()
	m.run_time = bnd - (1.5 if boss_chain else 25.0)
	label = "до_смены"
	if boss_chain:
		m.player.level = 6
		m.player.xp = 0.0
		m.player.xp_next = m._xp_need(6)
		if m.mode == "rush" or not m.boss_run.is_empty():
			var bs = m._spawn_boss(m._rush_def(0) if m.mode == "rush" else m.boss_run[0])
			bs.position = m.player.position + Vector2(120.0, 0.0)
			m._kill_enemy(bs)
		for k in range(14):
			var o = m._spawn_orb(m.player.position + Vector2.from_angle(k * 0.45) * 160.0, "xpBig", 60.0)
			if o != null:
				o.pulled = true
		_mark("босс_убит")
	await _until(func() -> bool: return m.biome_idx != b0, 60.0, "смена биома")
	_mark("смена_биома")
	label = "смена"
	if pause:
		await _secs(0.6)
		m.paused = true
		_mark("пауза")
		await _secs(1.5)
		m.paused = false
	await _until(func() -> bool: return m.ground.fade_t >= 1.0, 20.0, "конец растворения")
	_mark("растворение_готово")
	res["switch_frames"] = n - int(marks["смена_биома"])
	label = "после"
	await _secs(10.0)


func _report() -> void:
	res["scenario"] = SCEN
	res["mode"] = m.mode
	res["dex"] = int(_arg_str("--dex", "25"))
	res["maxup"] = "--maxup" in OS.get_cmdline_user_args()
	res["keys_only"] = "--keys-only" in OS.get_cmdline_user_args()
	var evs := {}
	for ev in marks:
		evs[ev] = _ev_stats(ev, 90)
	res["events"] = evs
	res["gaps_ms_worstframe"] = gaps
	res["cards"] = cards_seen
	var s: Array = []
	var o100 := 0
	var tot := 0.0
	for f in frames:
		if f[0] < 60:
			continue   # первые кадры после загрузки (разовые 1 с на старте, есть и до правок) — не про события
		s.append(f[1])
		tot += f[1]
		if f[1] > 100.0:
			o100 += 1
	s.sort()
	res["frames"] = s.size()
	res["avg_ms"] = snappedf(tot / maxf(1.0, s.size()), 0.01)
	res["worst_ms"] = s[-1] if not s.is_empty() else 0.0
	res["over100"] = o100
	res["checked_frames"] = chk_frames
	res["blank_frames"] = blank_frames
	res["blank_chunks"] = blank_chunks
	res["noobj_frames"] = noobj_frames
	res["half_frames_internal"] = half_int
	if CAPTURE:
		res["half_frames_pixels"] = half_px
		res["black_frames"] = black_frames
		res["black_max_frac"] = snappedf(black_max, 0.001)
	res["end_state"] = {"arena": m.arena != null, "choosing": m.choosing, "paused": m.paused, "cards_open": m.cards.open, "fade_t": m.ground.fade_t, "ground_visible": m.ground.visible}
	if OUT != "":
		var fa := FileAccess.open(OUT.path_join("frames_%s.csv" % SCEN), FileAccess.WRITE)
		fa.store_line("frame,ms,label")
		for f in frames:
			fa.store_line("%d,%.2f,%s" % [f[0], f[1], f[2]])
		fa.close()
	print("RESULT " + JSON.stringify(res))
