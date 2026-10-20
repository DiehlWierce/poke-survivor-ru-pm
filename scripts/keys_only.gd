extends Node
# Режим приставки (PortMaster): кнопки приходят клавишами из gptokeyb, а нативный джойстик Godot
# дублирует их (d-pad одновременно кнопками и осью, раскладка SDL не совпадает) — поэтому события
# джойстика отбрасываются раньше остальных обработчиков. Заодно: потолок 30 к/с и лог рывков
# (perf_log.txt рядом с игрой). Вне приставки ничего не делает.

const SPIKE_MS := 45.0
const REPORT_S := 10.0

var active := false
var _log: FileAccess
var _acc := 0.0
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
	if not active:
		return
	process_mode = Node.PROCESS_MODE_ALWAYS
	Engine.max_fps = 30
	# необязательный файл maxfps.txt рядом с игрой (например 60 для максимума): ровные 30 к/с часто приятнее, чем 40–55 с провалами
	var fpsf := FileAccess.open(OS.get_executable_path().get_base_dir().path_join("maxfps.txt"), FileAccess.READ)
	if fpsf != null:
		var want: int = int(fpsf.get_as_text().strip_edges())
		if want >= 20 and want <= 120:
			Engine.max_fps = want
	RenderingServer.viewport_set_measure_render_time(get_tree().root.get_viewport_rid(), true)
	# _input вызывается с конца дерева: держим узел последним ребёнком корня, чтобы он шёл первым
	var root := get_tree().root
	root.child_entered_tree.connect(func(_n: Node): _to_last.call_deferred())
	var dir: String = OS.get_executable_path().get_base_dir()
	_log = FileAccess.open(dir.path_join("perf_log.txt"), FileAccess.WRITE)
	if _log == null:
		_log = FileAccess.open("user://perf_log.txt", FileAccess.WRITE)   # si la carpeta del juego no es escribible
	if _log != null:
		_log.store_line("# %s  кадр > %d мс = рывок; раз в %d с: средний/худший кадр (мс), к/с, узлов, вызовов отрисовки" % [Time.get_datetime_string_from_system(), int(SPIKE_MS), int(REPORT_S)])
		set_process(true)


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
	var ms := delta * 1000.0
	_frames += 1
	_sum += ms
	_acc += delta
	_worst = maxf(_worst, ms)
	_proc += Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
	_phys += Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
	_rcpu += RenderingServer.viewport_get_measured_render_time_cpu(get_tree().root.get_viewport_rid())
	if ms > SPIKE_MS:
		_spikes += 1
		if _spikes <= 600:
			var scene: Node = get_tree().current_scene
			_log.store_line("рывок %.0f мс  t=%.1f  сцена=%s  узлов=%d  процесс=%.1f мс" % [ms, Time.get_ticks_msec() / 1000.0, scene.name if scene != null else "-", int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)), Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0])
			_log.store_line("  разбивка(мс): " + Prof.line_cur())
			_log.flush()
	if _acc >= REPORT_S:
		_log.store_line("t=%.0f  средн=%.1f  худший=%.0f  к/с=%d  рывков=%d  узлов=%d  отрисовка=%d  скрипты=%.1f  физика=%.1f  рендер_цпу=%.1f мс" % [Time.get_ticks_msec() / 1000.0, _sum / maxf(1.0, _frames), _worst, int(_frames / _acc), _spikes, int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)), int(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)), _proc / maxf(1.0, _frames), _phys / maxf(1.0, _frames), _rcpu / maxf(1.0, _frames)])
		_log.store_line("  средн(мс): " + Prof.line_avg())
		_log.store_line("  макс(мс): " + Prof.line_max())
		_log.store_line("  " + Prof.line_counts())
		_log.flush()
		Prof.reset_period()
		_acc = 0.0
		_frames = 0
		_sum = 0.0
		_worst = 0.0
		_proc = 0.0
		_phys = 0.0
		_rcpu = 0.0
