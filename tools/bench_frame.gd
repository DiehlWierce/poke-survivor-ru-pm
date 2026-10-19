extends SceneTree
# Замер кадра с толпой на Mac (на приставке ~40× медленнее):
#   godot --headless --path . --fixed-fps 30 --script res://tools/bench_frame.gd -- --keys-only [--prof]
# Загружает main.tscn, ставит поздний этап (run_time), добивает толпу до ENEMY_CAP, даёт игроку набор атак,
# ведёт его по кругу и печатает мс на кадр (всего / скрипты) и «рывки»; с --prof ещё раздел за разделом.
const FRAMES := 900
const WARM := 120
const MOVES := ["ember", "fire-spin", "heat-wave", "thunderbolt", "bug-buzz", "rock-slide", "tackle", "water-gun"]

var m: Node
var n := 0
var last := 0
var samples: Array = []
var proc_sum := 0.0
var spawn_t := 0.0
var prev_pf := {}
var load_frames := 0     # кадров экрана загрузки (main.loading_done == false)
var load_worst := 0.0    # самый длинный кадр во время загрузки, мс
var load_total := 0.0    # вся загрузка, мс


func _initialize() -> void:
	seed(12345)
	var SVl = load("res://scripts/save_data.gd")
	SVl.ensure()
	m = load("res://scenes/main.tscn").instantiate()
	root.add_child(m)
	last = Time.get_ticks_usec()


func _process(_delta: float) -> bool:
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
		m.run_time = 900.0
		m.player.hp = 1e9
		m.player.max_hp = 1e9
		m.player.level = 20
		for mid in MOVES:
			m.player.moves.append(m._new_move(mid, 4))
		m.preload_t = 1e9
	if n > 3:
		m.player.hp = 1e9
		m.player.invuln = 5.0
		if n % 60 == 0:
			m.player.slot = (m.player.slot + 1) % m.player.moves.size()
		var a: float = n * 0.01
		m.player.position += Vector2(cos(a), sin(a * 0.7)) * 5.0
		if m.enemies.size() < m.ENEMY_CAP and n % 4 == 0:
			m._spawn_one()
	if n > WARM:
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
		proc_sum += Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
	last = now
	if m.get("pf") != null:
		prev_pf = m.pf.duplicate()
	n += 1
	if n >= FRAMES:
		report()
		return true
	return false


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
	if m.get("pf") != null and not m.pf.is_empty() and "--prof" in OS.get_cmdline_user_args():
		var ks: Array = m.pf.keys()
		ks.sort_custom(func(a, b): return m.pf[a] > m.pf[b])
		for k in ks:
			print("  %-14s %.3f мс/кадр" % [k, float(m.pf[k]) / 1000.0 / samples.size()])
