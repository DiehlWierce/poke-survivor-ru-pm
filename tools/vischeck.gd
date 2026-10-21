extends SceneTree
# Проверка «каждый визуал способности и каждый дроп виден на экране» в худшем позднем случае.
# Окно (не headless), как приставка: потолок 30 к/с с настоящим delta, режим lite (--keys-only):
#   godot --path . --script res://tools/vischeck.gd -- --keys-only [--seed 7] [--shots DIR] [--fps 30]
#         [--mode normal|daily|rush|...] [--dex N (стартер)] [--frames 2700] [--zoff K] [--meta fresh|max]
# Сохранения: запускать с временным HOME (см. tools/vischeck_suite.sh) — реальный сейв не трогается.
# --frames короче 2700 сжимает все фазы пропорционально. Z-ходы всех 18 типов по кругу (каждые ~240 кадров,
# начиная с типа №zoff), в связке (фьюжн) первые 3 хода активной группы.
# Бот двигает игрока: прямой бег в новые куски, возврат назад, круги, блуждание; затем насыщение
# (босс, толпа до ENEMY_CAP, много орбов опыта и предметов, все способности сразу, Z-ход), смена биома, вход в разлом.
# Все 66 ходов (прокачаны и эволюционированы) стреляют группами по очереди; неактивные слоты тикаются вручную.
# Метрики (по фазам и итог):
#   pfx (через tools/vis_probe_pfx.gd): спрайты/кольца/удары/лучи способностей — запрошено, отброшено лимитом,
#     ни разу не нарисовано за жизнь (undrawn), доля кадров с отрисовкой; частицы — отброшено бюджетом;
#     ghost — кадры, когда эффектов нет, а старый рисунок не стёрт.
#   узлы: снаряды/поля/опасности видимы в дереве; Fx (лучи опасностей и пр.) не удалены лимитом раньше срока.
#   дропы: на каждое убийство в кадре — видимый орб в пределах R от места смерти через ≤3 кадра; каждый новый орб видим.
# Итог: строка VIS {...} (JSON) и VIS_OK / VIS_FAIL (визуалы способностей и дропы должны быть 100 %).
const MD = preload("res://scripts/moves_data.gd")
var MAIN = null   # load() во время работы: preload main.gd до регистрации автозагрузок (Prof) не парсится
var PROBE = null
const KILL_R := 40.0
const BOSS_R := 95.0

var m: Node
var n := 0
var n0 := 0
var started := false
var all_moves: Array = []
var group := -1
var phase := "load"
var dir := Vector2.RIGHT
var shots_dir := ""
var shot_frames := {}
var c := {}                 # phase -> счётчики узлов/дропов
var seen_b := {}            # id снаряда -> true
var seen_f := {}
var seen_h := {}
var seen_o := {}
var fx_age := {}            # id Fx -> [node, last_age, life, onscreen]
var kills: Array = []       # [pos, frames_left, radius, phase]
var dead_seen := {}
var rift_entered := false
var arena_frames := 0
var rng := RandomNumberGenerator.new()
var END := 2700
var K := 1.0                # END / 2700: масштаб фаз
var zoff := 0
var zi := 0
var z_seen := {}
const ZTYPES := ["normal", "fire", "water", "electric", "grass", "ice", "fighting", "poison", "ground", "flying", "psychic", "bug", "rock", "ghost", "dragon", "dark", "steel", "fairy"]


static func _arg(name: String, def: String) -> String:
	var a := OS.get_cmdline_user_args()
	var i := a.find(name)
	return String(a[i + 1]) if i >= 0 and i + 1 < a.size() else def


func _initialize() -> void:
	var fps := int(_arg("--fps", "30"))
	Engine.max_fps = fps
	seed(12345)
	rng.seed = 777
	var bseed := int(_arg("--seed", "7"))
	MAIN = load("res://scripts/main.gd")
	PROBE = load("res://tools/vis_probe_pfx.gd")
	MAIN.bench_seed_override = bseed
	shots_dir = _arg("--shots", "")
	for f in [300, 750, 1050, 1350, 1560, 1620, 1800, 1915, 2000, 2300, 2500]:
		shot_frames[int(f * float(int(_arg("--frames", "2700"))) / 2700.0)] = true
	END = int(_arg("--frames", "2700"))
	K = float(END) / 2700.0
	zoff = int(_arg("--zoff", "0"))
	var SVl = load("res://scripts/save_data.gd")
	SVl.ensure()
	SVl.run_mode = _arg("--mode", "normal")
	if _arg("--dex", "") != "":
		SVl.run_dex = int(_arg("--dex", "25"))
	var meta := _arg("--meta", "fresh")   # fresh: сохранение без покупок; max: все улучшения выкуплены (только в памяти, HOME временный)
	if meta == "max":
		for dx in [SVl.run_dex, SVl.daily_dex(SVl.daily_seed())]:
			var pu := {}
			for u in SVl.UPGRADES:
				pu[String(u["id"])] = int(u["max"])
			SVl.d["pup"][str(dx)] = pu
	print("vischeck mode=%s dex=%d frames=%d meta=%s" % [SVl.run_mode, SVl.run_dex, END, meta])
	m = load("res://scenes/main.tscn").instantiate()
	root.add_child(m)


func _cnt(key: String, k: String, v: int = 1) -> void:
	if not c.has(phase):
		c[phase] = {}
	var d: Dictionary = c[phase]
	d[key + "." + k] = int(d.get(key + "." + k, 0)) + v


func _view() -> Rect2:
	var vp: Vector2 = m.get_viewport().get_visible_rect().size
	return m.get_viewport().get_canvas_transform().affine_inverse() * Rect2(Vector2.ZERO, vp)


func _vis(nd) -> bool:
	return is_instance_valid(nd) and nd.is_inside_tree() and nd.is_visible_in_tree() and nd.modulate.a > 0.05 and nd.self_modulate.a > 0.05


func _setup() -> void:
	var dens: float = m.pfx.dens
	m.pfx.set_script(PROBE)
	m.pfx.setup(dens)
	m.pfx.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	m.run_time = 900.0
	m.player.hp = 1e9
	m.player.max_hp = 1e9
	m.player.level = 40
	m.player.xp_next = 1e12
	m.stat_lv = {"atk": 6, "cd": 10, "spd": 5}
	for id in MD.ORDER:
		var mv: Dictionary = m._new_move(String(id), 4)
		for _i in range(30):
			m._level_up_move(mv)
		m._evolve(mv)
		all_moves.append(mv)
	m.preload_t = 1e9
	for k in range(m.ENEMY_CAP):
		var en = m._spawn_one()
		en.position = m.player.position + Vector2(rng.randf_range(-500, 500), rng.randf_range(-500, 500))


func _set_group(gi: int, size: int) -> void:
	if gi == group:
		return
	group = gi
	m._clear_orbit_orbs()
	var mv: Array = []
	for i in range(size):
		mv.append(all_moves[(gi * size + i) % all_moves.size()])
	m.player.moves = mv
	m.bond_ids = [String(mv[0]["id"]), String(mv[1]["id"]), String(mv[2]["id"])]   # связка (фьюжн) в активном слоте
	m.player.slot = 0


func _phase_for(f0: int) -> String:
	var f: int = int(float(f0) / K)
	if f < 600:
		return "run"
	if f < 900:
		return "back"
	if f < 1200:
		return "circle"
	if f < 1500:
		return "wander"
	if f < 1900:
		return "saturate"
	if f < 2100:
		return "biome"
	return "rift"


func _move_bot(dt: float) -> void:
	var p: Vector2 = m.player.position
	var spd := 230.0
	match phase:
		"run":
			dir = Vector2(1.0, 0.2).normalized()
		"back":
			dir = Vector2(-1.0, -0.15).normalized()
		"circle":
			var a: float = float(n) * 0.03
			dir = Vector2(-sin(a), cos(a))
			spd = 260.0 * 0.03 * 30.0 / 3.0
		"wander", "saturate", "biome":
			if n % 45 == 0:
				dir = Vector2.from_angle(rng.randf() * TAU)
			spd = 200.0 if phase != "saturate" else 120.0
		"rift":
			if m.rift != null and is_instance_valid(m.rift) and m.arena == null:
				dir = (m.rift.position - p).normalized()
				if p.distance_to(m.rift.position) < 30.0:
					spd = 0.0
			elif n % 45 == 0:
				dir = Vector2.from_angle(rng.randf() * TAU)
			spd = 200.0 if spd > 0.0 else 0.0
	m.player.position = p + dir * spd * dt
	m.player.aim = dir.angle() if dir != Vector2.ZERO else m.player.aim


func _events() -> void:
	var f: int = int(float(n) / K)
	var f1: int = int(float(n - 1) / K)
	if f >= 1500 and f1 < 1500 and m.boss_run.size() > 0:
		m._spawn_boss(m.boss_run[0])
	if n % 240 == 120 and m.z_state == "" and m.arena == null:
		m.z_type = ZTYPES[(zoff + zi) % ZTYPES.size()]
		z_seen[m.z_type] = true
		zi += 1
		m.z_used = false
		m._z_start()
	if f >= 1905 and f1 < 1905:
		m.run_time = float(m.biome_idx - m.biome_off + 1) * (150.0 if m.mode == "rush" else 240.0) - 0.1
	if f >= 2110 and f1 < 2110:
		m._open_rift(-1, false)
	if phase == "saturate" and n % 2 == 0:
		var p: Vector2 = m.player.position
		for k in range(3):
			m._spawn_orb(p + Vector2(rng.randf_range(-1200, 1200), rng.randf_range(-900, 900)), "xp" if k < 2 else "xpBig", 4.0 + float(k))
		if n % 20 == 0:
			var kinds := ["heal", "item", "coin", "ticket", "bomb"]
			m._spawn_orb(p + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(120.0, 260.0), String(kinds[(n / 20) % kinds.size()]), 1.0)


func _check_nodes(view: Rect2) -> void:
	for b in m.bullets:
		var id: int = b.get_instance_id()
		if seen_b.has(id):
			continue
		seen_b[id] = true
		if not view.has_point(b.position):
			continue
		_cnt("bullet", "n")
		if not _vis(b):
			_cnt("bullet", "hidden")
	for f in m.fields:
		var id2: int = f.get_instance_id()
		if seen_f.has(id2):
			continue
		seen_f[id2] = true
		if not view.has_point(f.position):
			continue
		_cnt("field", "n")
		if not _vis(f):
			_cnt("field", "hidden")
	for h in m.hazards:
		var id3: int = h.get_instance_id()
		if seen_h.has(id3):
			continue
		seen_h[id3] = true
		if not view.has_point(h.position):
			continue
		_cnt("hazard", "n")
		if not _vis(h):
			_cnt("hazard", "hidden")
	var FxC = MAIN.Fx
	# Fx: лучи опасностей, вспышки травы и т.п. — не должны исчезать раньше срока
	for ch in m.fx.get_children():
		if ch.get_script() == FxC and not ch.is_queued_for_deletion():
			var fid: int = ch.get_instance_id()
			if not fx_age.has(fid):
				fx_age[fid] = [ch, ch.age, ch.life, view.has_point(ch.position), ch.kind, phase]
			else:
				fx_age[fid][1] = ch.age
	for fid in fx_age.keys():
		var r: Array = fx_age[fid]
		var nd = r[0]
		if not is_instance_valid(nd) or nd.is_queued_for_deletion():
			if bool(r[3]):
				var key := "fx_" + String(r[4])
				var ph := phase
				phase = String(r[5])
				_cnt(key, "n")
				if float(r[1]) < float(r[2]) - 0.1:
					_cnt(key, "trimmed")
				phase = ph
			fx_age.erase(fid)
	# орбы: каждый новый в списке виден
	var cur := {}
	for o in m.orbs:
		var oid: int = o.get_instance_id()
		cur[oid] = true
		if seen_o.has(oid):
			continue
		if view.has_point(o.position):
			_cnt("orb_new", "n")
			if not _vis(o) or o.sc <= 0.01:
				_cnt("orb_new", "hidden")
	seen_o = cur
	# убийства на экране: рядом с местом смерти должен быть видимый орб (дроп)
	for e in m.enemies:
		var eid: int = e.get_instance_id()
		if e.dead and not dead_seen.has(eid):
			dead_seen[eid] = true
			if e.legend or e.behavior == "thief" or not e.visible or not view.grow(-24.0).has_point(e.position):
				continue
			kills.append([e.position, 3, BOSS_R if e.boss else KILL_R, phase])
	for i in range(kills.size() - 1, -1, -1):
		var k: Array = kills[i]
		var ok := false
		var r2: float = float(k[2]) * float(k[2])
		for o in m.orbs:
			if _vis(o) and o.position.distance_squared_to(k[0]) <= r2:
				ok = true
				break
		if ok or int(k[1]) <= 0:
			var ph2 := phase
			phase = String(k[3])
			_cnt("drop", "n")
			if not ok:
				_cnt("drop", "missing")
			phase = ph2
			kills.remove_at(i)
		else:
			k[1] = int(k[1]) - 1


func _process(dt: float) -> bool:
	if m == null or n0 > 6000:
		print("VIS_FAIL: игра не загрузилась")
		return true
	if not m.loading_done:
		n0 += 1
		return false
	n += 1
	if n == 3:
		_setup()
		started = true
	if not started:
		return false
	var np := _phase_for(n)
	if np != phase:
		phase = np
		print("phase %s at frame %d  enemies=%d orbs=%d bullets=%d fps=%.0f" % [phase, n, m.enemies.size(), m.orbs.size(), m.bullets.size(), Engine.get_frames_per_second()])
	m.pfx.phase_tag = phase
	m.player.hp = 1e9
	m.player.invuln = 5.0
	m.pending_levels = 0
	if m.choosing:
		m.choosing = false
		m.cards.hide_cards()
	var gsize := 24 if phase == "saturate" else 12
	_set_group(int(n / 120) if phase != "saturate" else 100 + int(n / 120), gsize)
	_events()
	_move_bot(dt)
	if m.rift != null and is_instance_valid(m.rift) and m.arena == null and m.rift.t > 1.0:
		m.player.position = m.rift.position
	if m.arena != null:
		arena_frames += 1
	if not m.paused and not m.choosing and m.z_state != "cine":
		var act: Array = m._active_group()
		for mv in m.player.moves:
			if not act.has(mv):
				m._tick_move(mv, dt)
	if m.enemies.size() < m.ENEMY_CAP and n % 3 == 0 and m.arena == null:
		m._spawn_one(dir.angle() + rng.randf_range(-1.2, 1.2))
	var view := _view()
	m.pfx.view = view
	_check_nodes(view)
	if shots_dir != "" and shot_frames.has(n):
		var img: Image = m.get_viewport().get_texture().get_image()
		if img != null:
			img.save_png(shots_dir.path_join("vis_%04d_%s.png" % [n, phase]))
	if n >= END:
		_report()
		return true
	return false


func _report() -> void:
	var probe = m.pfx
	var by_phase := {}
	var tot := {}
	for key in probe.stats:
		var parts: PackedStringArray = String(key).split("|")
		var ph: String = parts[0]
		var k: String = parts[1]
		var s: Dictionary = probe.stats[key]
		for dst in [tot, by_phase.get_or_add(ph, {})]:
			if not dst.has(k):
				dst[k] = {"req": 0, "drop": 0, "undrawn": 0, "offscreen": 0, "draws": 0, "frames": 0}
			for f in s:
				dst[k][f] += int(s[f])
	print("=== pfx по источнику (итог) ===")
	var keys: Array = tot.keys()
	keys.sort()
	var essential_bad := 0
	var essential_n := 0
	for k in keys:
		var s: Dictionary = tot[k]
		var drawn_frac: float = float(s["draws"]) / maxf(1.0, float(s["frames"]))
		print("  %-22s req=%6d drop=%5d undrawn=%4d offscreen=%5d draw_frac=%.2f" % [k, s["req"], s["drop"], s["undrawn"], s["offscreen"], drawn_frac])
		var src: String = String(k).split(":")[1]
		var kind: String = String(k).split(":")[0]
		if kind != "px" and (src == "ability" or src == "zmove" or src == "dynamax"):
			essential_n += int(s["req"]) - int(s["offscreen"])
			essential_bad += int(s["drop"]) + int(s["undrawn"])
	print("  ghost frames (stale drawing after all effects ended): %d" % probe.ghost_frames)
	var node_tot := {}
	print("=== узлы и дропы по фазам ===")
	for ph in c:
		var line := "  %-9s" % ph
		var ks: Array = c[ph].keys()
		ks.sort()
		for k in ks:
			line += " %s=%d" % [k, c[ph][k]]
			node_tot[k] = int(node_tot.get(k, 0)) + int(c[ph][k])
		print(line)
	print("=== pfx способностей по фазам (req/drop/undrawn) ===")
	for ph in by_phase:
		var line2 := "  %-9s" % ph
		var rq := 0
		var bad := 0
		for k in by_phase[ph]:
			var src2: String = String(k).split(":")[1]
			if String(k).split(":")[0] != "px" and (src2 == "ability" or src2 == "zmove" or src2 == "dynamax"):
				rq += int(by_phase[ph][k]["req"]) - int(by_phase[ph][k]["offscreen"])
				bad += int(by_phase[ph][k]["drop"]) + int(by_phase[ph][k]["undrawn"])
		print(line2 + " onscreen_req=%d lost=%d rate=%.2f%%" % [rq, bad, 100.0 * float(rq - bad) / maxf(1.0, float(rq))])
	var drops_n: int = int(node_tot.get("drop.n", 0))
	var drops_miss: int = int(node_tot.get("drop.missing", 0))
	var hidden: int = int(node_tot.get("bullet.hidden", 0)) + int(node_tot.get("field.hidden", 0)) + int(node_tot.get("hazard.hidden", 0)) + int(node_tot.get("orb_new.hidden", 0))
	var fx_trim := 0      # обрезанные лимитом Fx, кроме косметических вспышек травы (burst) — должно быть 0
	var fx_cosm := 0
	for k in node_tot:
		if String(k).ends_with(".trimmed"):
			if String(k).begins_with("fx_burst"):
				fx_cosm += int(node_tot[k])
			else:
				fx_trim += int(node_tot[k])
	var res := {"ability_vis_n": essential_n, "ability_vis_lost": essential_bad,
		"ability_vis_rate": snappedf(100.0 * float(essential_n - essential_bad) / maxf(1.0, float(essential_n)), 0.01),
		"drops_n": drops_n, "drops_missing": drops_miss, "drop_rate": snappedf(100.0 * float(drops_n - drops_miss) / maxf(1.0, float(drops_n)), 0.01),
		"nodes_hidden": hidden, "fx_trimmed": fx_trim, "fx_cosmetic_trimmed": fx_cosm, "ghost_frames": probe.ghost_frames, "arena_frames": arena_frames,
		"lite": MAIN.Actor.lite, "frames": n, "mode": m.mode, "dex": m._pdex(), "z_types": z_seen.keys()}
	print("VIS " + JSON.stringify(res))
	print("VIS_OK" if essential_bad == 0 and drops_miss == 0 and hidden == 0 and fx_trim == 0 else "VIS_FAIL")
