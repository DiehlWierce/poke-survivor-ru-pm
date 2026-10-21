extends Node
# Режим приставки (PortMaster): кнопки приходят клавишами из gptokeyb, а нативный джойстик Godot
# дублирует их (d-pad одновременно кнопками и осью, раскладка SDL не совпадает) — поэтому события
# джойстика отбрасываются раньше остальных обработчиков. Заодно: потолок 30 к/с и лог рывков
# (perf_log.txt рядом с игрой). Вне приставки ничего не делает.

const SPIKE_MS := 45.0
const REPORT_S := 10.0          # сводка раз в REPORT_S секунд ЧАСОВ (а не накопленных delta: у Godot delta обрезана ~0,13 с)
const SPIKES_PER_REPORT := 24   # рывков в журнал за период; остальные только считаются
const LOG_MAX_BYTES := 1500000  # файл больше — ротация в perf_log.1.txt (старый .1 затирается), запись продолжается

const SV = preload("res://scripts/save_data.gd")

static var base_fps := 0   # потолок до выбора в настройках (0 = без ограничения)

var active := false
var _log: FileAccess
var _log_path := ""
var _acc := 0.0               # накопленные delta периода (для к/с); границу периода задают часы
var _period_t0 := 0           # Time.get_ticks_msec() начала периода
var _last_us := 0             # метка прошлого кадра: настоящее время кадра, не обрезанное delta
var _spikes_logged := 0
var _spikes_skipped := 0
var _long_frames := 0         # кадры >1 с в периоде
var _frames := 0
var _sum := 0.0
var _worst := 0.0
var _spikes := 0
var _proc := 0.0
var _phys := 0.0
var _rcpu := 0.0


func _ready() -> void:
	active = OS.has_feature("handheld") or "--keys-only" in OS.get_cmdline_user_args()
	set_process_input(active)
	Prof.on = active
	set_process(false)
	# потолок кадров по умолчанию: на приставке 30 (или maxfps.txt), на десктопе остаётся как есть; выбор в настройках главнее
	base_fps = Engine.max_fps
	if active:
		base_fps = 30
		# необязательный файл maxfps.txt рядом с игрой (например 60 для максимума): ровные 30 к/с часто приятнее, чем 40–55 с провалами
		var fpsf := FileAccess.open(OS.get_executable_path().get_base_dir().path_join("maxfps.txt"), FileAccess.READ)
		if fpsf != null:
			var want: int = int(fpsf.get_as_text().strip_edges())
			if want >= 20 and want <= 120:
				base_fps = want
	apply_fps()
	if not active:
		return
	process_mode = Node.PROCESS_MODE_ALWAYS
	RenderingServer.viewport_set_measure_render_time(get_tree().root.get_viewport_rid(), true)
	# _input вызывается с конца дерева: держим узел последним ребёнком корня, чтобы он шёл первым
	var root := get_tree().root
	root.child_entered_tree.connect(func(_n: Node): _to_last.call_deferred())
	var dir: String = OS.get_executable_path().get_base_dir()
	_log_path = dir.path_join("perf_log.txt")
	_open_log()
	if _log == null:
		_log_path = "user://perf_log.txt"   # si la carpeta del juego no es escribible
		_open_log()
	if _log != null:
		_period_t0 = Time.get_ticks_msec()
		_last_us = Time.get_ticks_usec()
		set_process(true)


func _open_log() -> void:
	_log = FileAccess.open(_log_path, FileAccess.WRITE)
	if _log != null:
		_log.store_line("# %s  версия %s  рывок = кадр > %d мс (настоящее время кадра, не обрезанное); сводка раз в %d с по часам; при >%d КБ файл уходит в perf_log.1.txt" % [Time.get_datetime_string_from_system(), str(ProjectSettings.get_setting("application/config/version", "?")), int(SPIKE_MS), int(REPORT_S), LOG_MAX_BYTES / 1000])


# Журнал не обрывается на лимите рывков (раньше 600 штук — и тишина, из-за чего зависание на 29-й минуте не попало в лог):
# при росте файла старый уходит в perf_log.1.txt, новый продолжает с шапки.
func _rotate_if_big() -> void:
	if _log == null or _log.get_position() < LOG_MAX_BYTES:
		return
	_log.close()
	var old := _log_path.get_base_dir().path_join("perf_log.1.txt")
	DirAccess.remove_absolute(old)
	DirAccess.rename_absolute(_log_path, old)
	_open_log()


# Что делает игра сейчас: пауза/окно, режим, номер босса, время забега, память процесса (VmRSS и MemAvailable с /proc —
# именно по ним видно, что приставка упёрлась в 1 ГБ), число ресурсов/объектов.
func _state_line() -> String:
	var sc: Node = get_tree().current_scene
	var s := "сцена=%s пауза=%s" % [sc.name if sc != null else "-", str(get_tree().paused)]
	if sc != null and "run_time" in sc:
		s += " режим=%s забег=%.0fс босс=%d/%d биом=%s окно_карточек=%s пауза_игры=%s лвл=%s" % [str(sc.get("mode")), float(sc.get("run_time")), int(sc.get("run_bosses")), int(sc.get("boss_idx")), str(sc.get("biome_idx")), str(sc.get("choosing")), str(sc.get("paused")), str(sc.get("player").get("level") if sc.get("player") != null else "-")]
	s += " | " + _mem_line()
	return s


func _mem_line() -> String:
	var rss := 0
	var avail := 0
	var f := FileAccess.open("/proc/self/status", FileAccess.READ)
	if f != null:
		for ln in f.get_as_text().split("\n"):
			if ln.begins_with("VmRSS:"):
				rss = int(ln.get_slice(":", 1).strip_edges().get_slice(" ", 0)) / 1024
				break
	var mf := FileAccess.open("/proc/meminfo", FileAccess.READ)
	if mf != null:
		for ln in mf.get_as_text().split("\n"):
			if ln.begins_with("MemAvailable:"):
				avail = int(ln.get_slice(":", 1).strip_edges().get_slice(" ", 0)) / 1024
				break
	return "RSS=%d МБ свободно=%d МБ стат.память=%d МБ ресурсов=%d объектов=%d" % [rss, avail, OS.get_static_memory_usage() / 1048576, int(Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT)), int(Performance.get_monitor(Performance.OBJECT_COUNT))]


# Потолок кадров: значение из настроек ("max_fps": 30 / 40 / 60 / 0 = без ограничения), пока оно не выбрано (-1) — base_fps.
static func apply_fps() -> void:
	SV.ensure()
	var v: int = int(SV.d["settings"].get("max_fps", -1))
	Engine.max_fps = v if v >= 0 else base_fps


func _to_last() -> void:
	var root := get_tree().root
	if get_parent() == root and root.get_child(root.get_child_count() - 1) != self:
		root.move_child(self, root.get_child_count() - 1)


func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if Prof.on:
		Prof.end_frame()   # último en el orden de proceso: ya cuenta main y los trozos de suelo de este fotograma
	var now_us := Time.get_ticks_usec()
	var real_ms: float = (now_us - _last_us) / 1000.0   # настоящее время кадра: delta у движка обрезана и прятала кадры по 7–25 с
	_last_us = now_us
	var ms := maxf(delta * 1000.0, real_ms)
	_frames += 1
	_sum += ms
	_acc += delta
	_worst = maxf(_worst, ms)
	_proc += Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
	_phys += Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
	_rcpu += RenderingServer.viewport_get_measured_render_time_cpu(get_tree().root.get_viewport_rid())
	if ms > SPIKE_MS:
		_spikes += 1
		if ms > 1000.0:
			_long_frames += 1
		if _spikes_logged < SPIKES_PER_REPORT or ms > 1000.0:   # долгие зависания пишем всегда
			_spikes_logged += 1
			var scene: Node = get_tree().current_scene
			_log.store_line("рывок %.0f мс (delta %.0f)  t=%.1f  сцена=%s  узлов=%d  процесс=%.1f мс" % [ms, delta * 1000.0, Time.get_ticks_msec() / 1000.0, scene.name if scene != null else "-", int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)), Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0])
			_log.store_line("  разбивка(мс): " + Prof.line_cur())
			if ms > 1000.0:
				_log.store_line("  состояние: " + _state_line())
			_log.flush()
		else:
			_spikes_skipped += 1
	# сводка по часам: во время долгих кадров она всё равно выходит сразу после такого кадра, а не «когда накопится 10 с delta»
	var now_ms := Time.get_ticks_msec()
	if now_ms - _period_t0 >= int(REPORT_S * 1000.0):
		var wall: float = (now_ms - _period_t0) / 1000.0
		_log.store_line("t=%.0f  период=%.1fс  кадров=%d  средн=%.1f  худший=%.0f  к/с=%d  рывков=%d(пропущено %d, >1с: %d)  узлов=%d  отрисовка=%d  скрипты=%.1f  физика=%.1f  рендер_цпу=%.1f мс" % [now_ms / 1000.0, wall, _frames, _sum / maxf(1.0, _frames), _worst, int(_frames / maxf(0.001, wall)), _spikes, _spikes_skipped, _long_frames, int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)), int(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)), _proc / maxf(1.0, _frames), _phys / maxf(1.0, _frames), _rcpu / maxf(1.0, _frames)])
		_log.store_line("  средн(мс): " + Prof.line_avg())
		_log.store_line("  макс(мс): " + Prof.line_max())
		_log.store_line("  " + Prof.line_counts())
		_log.store_line("  состояние: " + _state_line())
		_log.flush()
		_rotate_if_big()
		Prof.reset_period()
		_period_t0 = now_ms
		_acc = 0.0
		_frames = 0
		_sum = 0.0
		_worst = 0.0
		_proc = 0.0
		_phys = 0.0
		_rcpu = 0.0
		_spikes_logged = 0
		_spikes_skipped = 0
		_long_frames = 0
