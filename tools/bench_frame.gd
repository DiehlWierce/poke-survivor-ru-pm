extends SceneTree
# Замер кадра с толпой на Mac (на приставке ~40× медленнее):
#   godot --headless --path . --fixed-fps 30 --script res://tools/bench_frame.gd -- --keys-only [--prof]
#   godot --headless --path . --fixed-fps 30 --script res://tools/bench_frame.gd -- --keys-only --scenario run
# Сценарий run: высокий уровень и прокачанные выстрелы, 3600 кадров (120 с) непрерывного бега в одну сторону,
# толпа добирается до ENEMY_CAP (в т.ч. впереди), каждые 300 кадров строка со счётчиками, в конце разбивка Prof и RESULT {...}.
# Загружает main.tscn, ставит поздний этап (run_time), добивает толпу до ENEMY_CAP, даёт игроку набор атак,
# ведёт его по кругу и печатает мс на кадр (всего / скрипты) и «рывки»; с --prof ещё раздел за разделом.
const FRAMES_DEFAULT := 900
const FRAMES_RUN := 3600
const WARM := 120
const MOVES := ["ember", "fire-spin", "heat-wave", "thunderbolt", "bug-buzz", "rock-slide", "tackle", "water-gun"]

var m: Node
var RUN := _arg_scenario() == "run"   # бег прямо в новые зоны с толпой и множеством снарядов
var STRESS := "--orbstress" in OS.get_cmdline_user_args()   # лишняя нагрузка орбами и цифрами урона
var FRAMES := FRAMES_RUN if _arg_scenario() == "run" else FRAMES_DEFAULT
var NOWARP := "--nobenchwarp" in OS.get_cmdline_user_args()   # выключить собственный перенос отставших бенчем (проверка переселения в main.gd)
var NORELOC := "--noreloc" in OS.get_cmdline_user_args()      # выключить переселение в main.gd (relocate_on=false), для сравнения «до»
var TANK := "--tank" in OS.get_cmdline_user_args()   # враги не умирают, бенч сам не спавнит: копятся отставшие (воспроизведение жалобы)
var SPEED := _arg_float("--speed", 165.0)   # скорость бега игрока, px/s (сценарий run)
var STALL := "--stall" in OS.get_cmdline_user_args()   # искусственные тормоза главного потока (проверка автооткатa запекания в потоках): 60 мс на кадр в кадрах 400..700
var blank_frames := 0   # кадров, где по независимой проверке бенча виден кусок без текстуры
var blank_chunks := 0
var vis_ok_frames := 0
var run_dir := Vector2(1.0, 0.25).normalized()
var prof_rows: Array = []   # на каждый замеренный кадр: копия Prof.last (секции предыдущего, уже закрытого кадра)
var n := 0
var last := 0
var samples: Array = []
var proc_sum := 0.0
var spawn_t := 0.0
var prev_pf := {}
var DIE := _arg_int("--die", -1)   # --die N: игрок умирает на кадре N, печать кадров за 200 кадров после смерти
var die_samples: Array = []
var die_rows: Array = []
var load_frames := 0     # кадров экрана загрузки (main.loading_done == false)
var load_worst := 0.0    # самый длинный кадр во время загрузки, мс
var load_total := 0.0    # вся загрузка, мс


static func _arg_float(name: String, def: float) -> float:
	var a := OS.get_cmdline_user_args()
	var i := a.find(name)
	return float(a[i + 1]) if i >= 0 and i + 1 < a.size() else def


static func _arg_scenario() -> String:
	var a := OS.get_cmdline_user_args()
	var i := a.find("--scenario")
	return String(a[i + 1]) if i >= 0 and i + 1 < a.size() else "default"


static func _arg_int(name: String, dflt: int) -> int:
	var a := OS.get_cmdline_user_args()
	var i := a.find(name)
	return int(a[i + 1]) if i >= 0 and i + 1 < a.size() else dflt


func _initialize() -> void:
	if STALL:
		Engine.max_fps = 30   # без --fixed-fps: настоящий delta, чтобы автооткат запекания его видел
	seed(12345)
	var SVl = load("res://scripts/save_data.gd")
	SVl.ensure()
	m = load("res://scenes/main.tscn").instantiate()
	root.add_child(m)
	last = Time.get_ticks_usec()


func _blank_check() -> void:
	# независимо от tileworld: куски под прямоугольником экрана вокруг игрока (позиция прошлого кадра) без текстуры и без старого биома
	var g = m.ground
	var half: Vector2 = m.get_viewport_rect().size * 0.5 / m.cam_zoom
	var p: Vector2 = m.player.position
	var x0 := floori((p.x - half.x) / g.CW)
	var x1 := floori((p.x + half.x) / g.CW)
	var y0 := floori((p.y - half.y) / g.CW)
	var y1 := floori((p.y + half.y) / g.CW)
	var bad := 0
	for ky in range(y0, y1 + 1):
		for kx in range(x0, x1 + 1):
			var ch = g.chunks.get(Vector2i(kx, ky))
			if ch == null or (ch["tex"] == null and (ch["old"] == null or g.fade_t >= 1.0)):
				bad += 1
	blank_chunks += bad
	if bad > 0:
		blank_frames += 1
	vis_ok_frames += 1


func _process(_delta: float) -> bool:
	if STALL and n >= 400 and n < 700:
		OS.delay_msec(60)
	var now := Time.get_ticks_usec()
	# Пока main грузит мир по кускам (экран загрузки), игры ещё нет: ждём и мерим сами кадры загрузки отдельно
	if not m.loading_done:
		load_frames += 1
		load_worst = maxf(load_worst, (now - last) / 1000.0)
		load_total += (now - last) / 1000.0
		last = now
		if load_frames > 5000:
			print("загрузка не закончилась")
			return true
		return false
	if load_frames > 0 and n == 0:
		print("загрузка: кадров=%d  всего=%.0f мс  худший кадр=%.1f мс" % [load_frames, load_total, load_worst])
	if n == 3:
		if NORELOC:
			m.relocate_on = false
		m.run_time = 900.0
		m.player.hp = 1e9
		m.player.max_hp = 1e9
		m.player.level = 20
		for mid in MOVES:
			m.player.moves.append(m._new_move(mid, 4))
		if RUN:
			m.player.level = 40
			m.player.xp_next = 1e12   # без новых карточек уровня (иначе игра встаёт на выбор)
			m.stat_lv = {"atk": 10, "cd": 10, "spd": 5}   # урон, перезарядка, скорость
			for mv in m.player.moves:   # прокачка выстрелов до максимума по лестнице (count/size/speed/cd через _apply_mods)
				for _i in range(30):
					m._level_up_move(mv)
			for k in range(m.ENEMY_CAP):   # стартовая толпа позади и вокруг
				var en = m._spawn_one()
				en.position = m.player.position + Vector2(randf_range(-500, 500), randf_range(-500, 500))
		m.preload_t = 1e9
	if DIE >= 0 and n == DIE:
		m.player.hp = 10.0   # смертельный удар; дальше hp не восстанавливается
		m.player.invuln = 0.0
		m.revives = 0
		m._hurt_player(1e9, "", true)
	if DIE >= 0 and n > DIE:
		var dms: float = (now - last) / 1000.0
		die_samples.append(dms)
		die_rows.append(Prof.last.duplicate() if Prof.on else [])
		if n - DIE >= 200:
			report_die()
			return true
	if n > 3 and (DIE < 0 or n < DIE):
		m.player.hp = 1e9
		m.player.invuln = 5.0
		if n % 60 == 0 and not RUN:
			m.player.slot = (m.player.slot + 1) % m.player.moves.size()
		var a: float = n * 0.01
		if RUN:
			if m.choosing or m.pending_levels > 0:
				m.pending_levels = 0
				m.choosing = false
				m.cards.hide_cards()
			m.player.position += run_dir * (SPEED * _delta)
			var act: Array = m._active_group()
			for mv in m.player.moves:   # неактивные слоты тоже стреляют (в игре тикает только активная группа)
				if not act.has(mv):
					m._tick_move(mv, 1.0 / 30.0)
			if TANK and n % 30 == 0:
				for e in m.enemies:
					e.hp = 1e9
					e.spd = minf(e.spd, 60.0)   # медленнее игрока (165 px/s): толпа отстаёт, как у быстрого персонажа
					e.max_hp = 1e9
			if m.enemies.size() < m.ENEMY_CAP and n % 3 == 0 and not TANK:
				m._spawn_one(run_dir.angle() + randf_range(-1.0, 1.0))   # толпа подтягивается и впереди по ходу
			if n % 8 == 0 and not NOWARP:   # отставших далеко позади переносим вперёд: впереди всегда новая толпа
				var moved := 0
				for e in m.enemies:
					if moved >= 3:
						break
					if (e.position - m.player.position).dot(run_dir) < -700.0 and not e.boss:
						e.position = m.player.position + run_dir * randf_range(450.0, 750.0) + run_dir.orthogonal() * randf_range(-400.0, 400.0)
						moved += 1
			if STRESS:   # нагрузка: орбы опыта вокруг (и далеко) + цифры урона у врагов
				for k in range(3):
					m._spawn_orb(m.player.position + Vector2(randf_range(-1400, 1400), randf_range(-1000, 1000)), "xp" if k < 2 else "xpBig", 4.0 + float(k))
				for k in range(3):
					if not m.enemies.is_empty():
						var en2 = m.enemies[randi() % m.enemies.size()]
						if m.has_method("_dmg_text"):
							m._dmg_text(en2.position, 5 + randi() % 40, Color.WHITE, 18)
						else:
							m.add_text(en2.position, str(5 + randi() % 40), Color.WHITE, 18)
			if n % 300 == 0:
				_run_line()
		else:
			m.player.position += Vector2(cos(a), sin(a * 0.7)) * 5.0
			if m.enemies.size() < m.ENEMY_CAP and n % 4 == 0:
				m._spawn_one()
	if n % 200 == 0 and "--dbg" in OS.get_cmdline_user_args():
		print("DBG n=%d paused=%s choosing=%s dead=%s down=%s z=%s run_time=%.1f mode=%s arena=%s jdcine=%s" % [n, m.paused, m.choosing, m.player.dead, m.down, m.z_state, m.run_time, m.mode, m.arena, m.jd.cinematic()])
	if n > WARM:
		_blank_check()
		samples.append((now - last) / 1000.0)
		if (now - last) > 5000 and m.get("pf") != null:
			var top := ""
			var best := 0
			var sum := 0
			for k in m.pf:
				var d: int = int(m.pf[k]) - int(prev_pf.get(k, 0))
				sum += d
				if d > best:
					best = d
					top = k
			print("  выброс кадр %d: %.1f мс  (главный раздел %s %.1f мс; всего в _process main %.1f; узлов %d)" % [n, (now - last) / 1000.0, top, best / 1000.0, sum / 1000.0, int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))])
		if RUN and Prof.on:
			prof_rows.append(Prof.last.duplicate())
		proc_sum += Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
	last = now
	if m.get("pf") != null:
		prev_pf = m.pf.duplicate()
	n += 1
	if n >= FRAMES:
		report()
		return true
	return false


func _run_line() -> void:
	var front := 0
	var back := 0
	var sum := 0.0
	var behind_far := 0   # позади дальше 900 px
	for e in m.enemies:
		var d: Vector2 = e.position - m.player.position
		sum += d.length()
		if d.dot(run_dir) >= 0.0:
			front += 1
		else:
			back += 1
			if d.length() > 900.0 and not e.boss and not e.is_minion:   # отставшие обычные (боссы и их миньоны не переселяются)
				behind_far += 1
				if "--dbgfar" in OS.get_cmdline_user_args():
					print("    далеко: %s dist=%.0f boss=%s legend=%s judge=%s minion=%s life=%.1f jump=%s dead=%s" % [e.enemy_name, d.length(), e.boss, e.legend, e.judge, e.is_minion, e.life, e.jump != null, e.dead])
	print("  кадр %4d: врагов впереди=%d позади=%d (обычных дальше 900: %d) ср.дистанция=%.0f  снарядов=%d  вражьих=%d  орбов=%d  эффектов=%d" % [
		n, front, back, behind_far, sum / maxf(1.0, float(m.enemies.size())), m.bullets.size(), m.ebullets.size(), m.orbs.size(), m.fx.get_child_count()])


func _sec_line(a) -> String:
	var s := ""
	for i in range(Prof.NAMES.size()):
		s += "%s=%.1f " % [Prof.NAMES[i], float(a[i]) / 1000.0]
	return s.strip_edges()


func report_run(s: Array, tot: float, spikes: int) -> void:
	var cnt := samples.size()
	var avg := tot / cnt
	var p95: float = s[int(cnt * 0.95)]
	var p99: float = s[int(cnt * 0.99)]
	print("БЕГ: кадров=%d  средн=%.2f мс  p95=%.2f  p99=%.2f  макс=%.1f  >45мс: %d" % [cnt, avg, p95, p99, s[-1], spikes])
	var pa := PackedFloat64Array()
	var pm := PackedFloat64Array()
	pa.resize(Prof.NAMES.size())
	pm.resize(Prof.NAMES.size())
	for row in prof_rows:
		for i in range(Prof.NAMES.size()):
			pa[i] += float(row[i])
			pm[i] = maxf(pm[i], float(row[i]))
	var ra := PackedInt64Array()
	var rm := PackedInt64Array()
	for i in range(Prof.NAMES.size()):
		ra.append(int(pa[i] / maxf(1.0, prof_rows.size())))
		rm.append(int(pm[i]))
	print("Prof средн (мс) за все кадры: " + _sec_line(ra))
	print("Prof макс  (мс) за все кадры: " + _sec_line(rm))
	print("Prof.line_avg() (последний период): " + Prof.line_avg())
	print("Prof.line_max() (последний период): " + Prof.line_max())
	var idx: Array = range(cnt)
	idx.sort_custom(func(x, y): return samples[x] > samples[y])
	print("Худшие 5 кадров (секции Prof, мс):")
	for k in range(mini(5, cnt)):
		var j: int = idx[k]
		print("  #%d кадр %d: %.1f мс | %s" % [k + 1, WARM + 1 + j, samples[j], _sec_line(prof_rows[j]) if j < prof_rows.size() else "-"])
	var sec := {}
	var secmax := {}
	for i in range(Prof.NAMES.size()):
		sec[Prof.NAMES[i]] = snappedf(float(ra[i]) / 1000.0, 0.01)
		secmax[Prof.NAMES[i]] = snappedf(float(rm[i]) / 1000.0, 0.1)
	var res := {"frames": cnt, "avg_ms": snappedf(avg, 0.01), "p95_ms": snappedf(p95, 0.01), "p99_ms": snappedf(p99, 0.01),
		"max_ms": snappedf(s[-1], 0.1), "over45": spikes, "enemies": m.enemies.size(), "bullets": m.bullets.size(), "kills": m.kills, "orbs": m.orbs.size(), "level": m.player.level,
		"sec_avg_ms": sec, "sec_max_ms": secmax}
	res["chunks"] = {"speed": SPEED, "bench_blank_frames": blank_frames, "bench_blank_chunks": blank_chunks, "vis_missing": Prof.ch_vis_missing,
		"sync_n": Prof.ch_sync_n, "sync_ms": snappedf(float(Prof.ch_sync_us) / 1000.0, 0.01), "sync_max_ms": snappedf(float(Prof.ch_sync_max) / 1000.0, 0.01),
		"chunks_now": Prof.ch_n, "chunks_max": Prof.ch_n_max, "workers": Prof.bk_workers, "task_avg_ms": snappedf(float(Prof.bk_task_us) / 1000.0 / maxf(1.0, float(Prof.bk_task_n)), 0.01), "rollbacks": Prof.bk_rollbacks}
	print("КУСКИ: скорость=%.0f px/s  кадров проверено=%d  кадров с пустотой (независимая проверка бенча)=%d  пустых кусков=%d" % [SPEED, vis_ok_frames, blank_frames, blank_chunks])
	print("КУСКИ (Prof): " + Prof.line_chunks() + "  | память текстур макс ~%.1f МБ" % (Prof.ch_n_max * 0.25))
	print("RESULT " + JSON.stringify(res))
	var gnd := 0.0
	for o in m.orbs:
		if o.kind == "xp" or o.kind == "xpBig":
			gnd += o.value
	if m.get("xp_orb_in") != null:
		print("XP целостность: вошло в орбы=%.1f  собрано=%.1f  на земле=%.1f  разница=%.3f  (орбов=%d, пул=%d)" % [m.xp_orb_in, m.xp_orb_out, gnd, m.xp_orb_in - m.xp_orb_out - gnd, m.orbs.size(), m.orb_pool.size()])


func report_die() -> void:
	var sum := 0.0
	var mxv := 0.0
	var over := 0
	for x in die_samples:
		sum += x
		mxv = maxf(mxv, x)
		if x > 10.0:
			over += 1
	var idx: Array = range(die_samples.size())
	idx.sort_custom(func(x, y): return die_samples[x] > die_samples[y])
	print("СМЕРТЬ: кадров=%d  сумма=%.1f мс  макс=%.1f мс  >10мс: %d  dead=%s  time_scale=%.2f" % [die_samples.size(), sum, mxv, over, m.player.dead, Engine.time_scale])
	for k in range(mini(6, idx.size())):
		var j: int = idx[k]
		print("  #%d после-смерти кадр %d: %.1f мс | %s" % [k + 1, j + 1, die_samples[j], _sec_line(die_rows[j]) if die_rows[j].size() > 0 else "-"])


func report() -> void:
	var s := samples.duplicate()
	s.sort()
	var tot := 0.0
	var spikes := 0
	for x in samples:
		tot += x
		if x > 45.0:
			spikes += 1
	print("кадров=%d  средн=%.2f мс  p50=%.2f  p95=%.2f  p99=%.2f  худший=%.1f  >45мс: %d  TIME_PROCESS=%.2f  врагов=%d  пуль=%d  fx=%d  узлов=%d" % [
		samples.size(), tot / samples.size(), s[s.size() / 2], s[int(s.size() * 0.95)], s[int(s.size() * 0.99)], s[-1], spikes,
		proc_sum / samples.size(), m.enemies.size(), m.bullets.size(), m.fx.get_child_count(), int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))])
	if RUN:
		report_run(s, tot, spikes)
	if m.get("pf") != null and not m.pf.is_empty() and "--prof" in OS.get_cmdline_user_args():
		var ks: Array = m.pf.keys()
		ks.sort_custom(func(a, b): return m.pf[a] > m.pf[b])
		for k in ks:
			print("  %-14s %.3f мс/кадр" % [k, float(m.pf[k]) / 1000.0 / samples.size()])
