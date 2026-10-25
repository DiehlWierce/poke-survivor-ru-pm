extends Node
# Режим приставки (PortMaster): кнопки приходят клавишами из gptokeyb, а нативный джойстик Godot
# дублирует их (d-pad одновременно кнопками и осью, раскладка SDL не совпадает) — поэтому события
# джойстика отбрасываются раньше остальных обработчиков. Заодно: потолок 30 к/с и лог рывков
# (perf_log.txt рядом с игрой). Вне приставки ничего не делает.

const SPIKE_MS := 45.0
const CENSUS_S := 30.0          # состав сцены (узлы по классам, враги/пули/орбы/Fx по видам) раз в CENSUS_S секунд во время забега
const CENSUS_LOW_S := 12.0      # ...и не чаще, чем раз в столько секунд при просадке
const LOW_FPS := 28             # к/с периода ниже — внеочередной снимок состава
const POLL_MS := 250            # опрос состояния игры для событий (уровень, босс, разлом, окно карточек, смерть...)
const WIN_CAP := 6000           # кадров в окне периода/метки для перцентилей
const RUN_WIN_CAP := 120000     # кадров за весь забег для итоговых перцентилей
const REPORT_S := 10.0          # сводка раз в REPORT_S секунд ЧАСОВ (а не накопленных delta: у Godot delta обрезана ~0,13 с)
const SPIKES_PER_REPORT := 24   # рывков в журнал за период; остальные только считаются
const LOG_MAX_BYTES := 4000000  # файл больше — ротация в perf_log.1.txt (старый .1 затирается), запись продолжается

const SV = preload("res://scripts/save_data.gd")
const PAD = preload("res://scripts/pad.gd")

static var listen_joy := false   # el menu espera un boton del mando para asignarlo: no tirar sus eventos

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
var _win := PackedFloat32Array()      # кадры текущего периода (мс) для перцентилей
var _mk := PackedFloat32Array()       # кадры с прошлой метки события
var _runw := PackedFloat32Array()     # кадры всего забега
var _hist := PackedInt32Array([0, 0, 0, 0, 0])   # периодная гистограмма: <20, <33, <50, <100, >=100 мс
var _run: FileAccess                  # run_log.txt: только события и итоги, не затирается между запусками
var _run_path := ""
var _cpu_t0 := 0                      # тики процессора процесса в начале периода
var _last_census := -999.0
var _poll_t0 := 0
var _scene_id := 0
var _scene_t0 := 0
var _scene_name := "?"
var _ps := {}                         # прошлые значения опроса
var _in_run := false
var _shut := false
var _run_t0_ms := 0
var _run_frames := 0
var _run_sum := 0.0
var _run_worst := 0.0
var _run_slow33 := 0.0                # мс в кадрах >33 мс (время «ниже 30 к/с»)
var _run_slow50 := 0.0                # мс в кадрах >50 мс (время «ниже 20 к/с»)
var _run_d := PackedInt64Array()      # _draw по классам за забег
var _run_pf := 0
var _run_sec := PackedInt64Array()    # круги Prof по системам за забег
var _node_names := {}                 # script -> имя внутреннего класса main.gd


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
	for ua in OS.get_cmdline_user_args():   # --perf-dir=путь: писать журналы в другую папку (отладка на десктопе)
		if String(ua).begins_with("--perf-dir="):
			dir = String(ua).substr(11)
	_log_path = dir.path_join("perf_log.txt")
	_run_path = dir.path_join("run_log.txt")
	_keep_prev(_log_path)
	_open_log()
	if _log == null:
		_log_path = "user://perf_log.txt"   # si la carpeta del juego no es escribible
		_run_path = "user://run_log.txt"
		_keep_prev(_log_path)
		_open_log()
	if _log != null:
		_open_run_log()
		_write_header()
		_period_t0 = Time.get_ticks_msec()
		_last_us = Time.get_ticks_usec()
		_cpu_t0 = _cpu_ticks()
		set_process(true)


func _open_log() -> void:
	_log = FileAccess.open(_log_path, FileAccess.WRITE)
	if _log != null:
		_log.store_line("# %s  версия %s  рывок = кадр > %d мс (настоящее время кадра, не обрезанное); сводка раз в %d с по часам; при >%d КБ файл уходит в perf_log.1.txt" % [Time.get_datetime_string_from_system(), str(ProjectSettings.get_setting("application/config/version", "?")), int(SPIKE_MS), int(REPORT_S), LOG_MAX_BYTES / 1000])


# Прошлый запуск не теряется: perf_log.txt -> perf_log.prev.txt (раньше каждый запуск затирал журнал предыдущей катки).
func _keep_prev(path: String) -> void:
	if FileAccess.file_exists(path):
		var prev: String = path.get_base_dir().path_join("perf_log.prev.txt")
		DirAccess.remove_absolute(prev)
		DirAccess.rename_absolute(path, prev)


func _open_run_log() -> void:
	if FileAccess.file_exists(_run_path):
		_run = FileAccess.open(_run_path, FileAccess.READ_WRITE)
		if _run != null:
			_run.seek_end()
	else:
		_run = FileAccess.open(_run_path, FileAccess.WRITE)
	if _run != null and _run.get_position() > 1500000:
		_run.close()
		var old: String = _run_path.get_base_dir().path_join("run_log.1.txt")
		DirAccess.remove_absolute(old)
		DirAccess.rename_absolute(_run_path, old)
		_run = FileAccess.open(_run_path, FileAccess.WRITE)


# Строка только в perf_log
func _w(line: String) -> void:
	if _log != null:
		_log.store_line(line)


# Событие: в оба журнала (perf_log — для контекста между сводками, run_log — длинная история катки)
func _ev(line: String) -> void:
	var l := "[%s t=%.1f] %s" % [Time.get_datetime_string_from_system().substr(11), Time.get_ticks_msec() / 1000.0, line]
	_w(l)
	if _log != null:
		_log.flush()
	if _run != null:
		_run.store_line(l)
		_run.flush()


func _read1(path: String) -> String:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return ""
	return f.get_as_text().strip_edges()


# Тики процессора процесса (utime+stime, 1/100 с): по ним видно, упёрся ли главный поток в ядро.
func _cpu_ticks() -> int:
	var t: String = _read1("/proc/self/stat")
	var r: int = t.rfind(")")
	if r < 0:
		return 0
	var a: PackedStringArray = t.substr(r + 2).split(" ")
	if a.size() < 13:
		return 0
	return int(a[11]) + int(a[12])


# Частота/температура: на приставках троттлинг по нагреву — частая причина «ехало, потом просело».
func _sys_line() -> String:
	var s := ""
	var fr: String = _read1("/sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq")
	if fr != "":
		s += "ЦП=%d МГц(%s) " % [int(fr) / 1000, _read1("/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor")]
	var tz: String = _read1("/sys/class/thermal/thermal_zone0/temp")
	if tz != "":
		s += "темп=%.0f°C " % (float(tz) / 1000.0)
	var da: DirAccess = DirAccess.open("/sys/class/devfreq")
	if da != null:
		for dn in da.get_directories():
			var gf: String = _read1("/sys/class/devfreq/%s/cur_freq" % dn)
			if gf != "":
				s += "%s=%d МГц " % [dn, int(gf) / 1000000]
	s += "нагрузка=" + _read1("/proc/loadavg").get_slice(" ", 0)
	return s


func _write_header() -> void:
	var st: Dictionary = SV.d["settings"] if SV.d.has("settings") else {}
	var meminfo: String = _read1("/proc/meminfo").get_slice("\n", 0)
	_w("# --- СИСТЕМА ---")
	_w("# Godot %s | ОС=%s | модель=%s | ЦП=%s x%d | %s" % [Engine.get_version_info().get("string", "?"), OS.get_name(), OS.get_model_name(), OS.get_processor_name(), OS.get_processor_count(), meminfo])
	_w("# рендер=%s | видеокарта=%s (%s) | окно=%s | vsync=%d | потолок к/с=%d (база %d) | handheld=%s | аргументы=%s" % [RenderingServer.get_current_rendering_method(), RenderingServer.get_video_adapter_name(), RenderingServer.get_video_adapter_vendor(), str(DisplayServer.window_get_size()), DisplayServer.window_get_vsync_mode(), Engine.max_fps, base_fps, str(OS.has_feature("handheld")), str(OS.get_cmdline_user_args())])
	_w("# настройки: качество=%s обзор=%s fov=%s max_fps=%s адаптивность=%s тряска=%s числа_урона=%s эффекты_непрозр=%s" % [str(st.get("quality")), str(st.get("view")), str(st.get("fov")), str(st.get("max_fps")), str(st.get("adaptive")), str(st.get("shake")), str(st.get("dmg_numbers")), str(st.get("fx_op"))])
	_w("# железо сейчас: " + _sys_line())
	_w("# журналы: perf_log.txt (подробно, этот запуск), perf_log.prev.txt (прошлый запуск), run_log.txt (события и итоги всех катк, дописывается)")
	_ev("ЗАПУСК игры, версия %s" % str(ProjectSettings.get_setting("application/config/version", "?")))


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
		# Excepcion (D4): botones asignados a "Elegir movimiento N" (por defecto sin asignar en consola) y la
		# asignacion en Ajustes > Controles pasan; el resto sigue llegando como teclas desde gptokeyb.
		if event is InputEventJoypadButton and (listen_joy or PAD.slot_of(event.button_index) >= 0):
			return
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
	_record_frame(ms)
	if ms > SPIKE_MS:
		_spikes += 1
		if ms > 1000.0:
			_long_frames += 1
		if _spikes_logged < SPIKES_PER_REPORT or ms > 1000.0:   # долгие зависания пишем всегда
			_spikes_logged += 1
			var scene: Node = get_tree().current_scene
			_log.store_line("рывок %.0f мс (delta %.0f)  t=%.1f  сцена=%s  узлов=%d  процесс=%.1f мс" % [ms, delta * 1000.0, Time.get_ticks_msec() / 1000.0, scene.name if scene != null else "-", int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)), Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0])
			_log.store_line("  разбивка(мс): " + Prof.line_cur())
			var dc: String = Prof.line_draw_cur()
			if dc != "":
				_log.store_line("  рисование_gd(мс): " + dc)
			if ms > 1000.0:
				_log.store_line("  состояние: " + _state_line())
			if ms > 250.0:
				_census("рывок %.0f мс" % ms, false)
			_log.flush()
		else:
			_spikes_skipped += 1
	var now_ms := Time.get_ticks_msec()
	if now_ms - _poll_t0 >= POLL_MS:
		_poll_t0 = now_ms
		_poll()
	# сводка по часам: во время долгих кадров она всё равно выходит сразу после такого кадра, а не «когда накопится 10 с delta»
	if now_ms - _period_t0 >= int(REPORT_S * 1000.0):
		_report(now_ms)


func _record_frame(ms: float) -> void:
	if _win.size() < WIN_CAP:
		_win.append(ms)
	if _mk.size() < WIN_CAP * 4:
		_mk.append(ms)
	if ms < 20.0:
		_hist[0] += 1
	elif ms < 33.4:
		_hist[1] += 1
	elif ms < 50.0:
		_hist[2] += 1
	elif ms < 100.0:
		_hist[3] += 1
	else:
		_hist[4] += 1
	Prof.peak_enemies = maxi(Prof.peak_enemies, Prof.n_enemies)
	Prof.peak_bullets = maxi(Prof.peak_bullets, Prof.n_bullets)
	Prof.peak_orbs = maxi(Prof.peak_orbs, Prof.n_orbs)
	Prof.peak_fx = maxi(Prof.peak_fx, Prof.n_fx)
	if _in_run:
		_run_frames += 1
		_run_sum += ms
		_run_worst = maxf(_run_worst, ms)
		if ms > 33.4:
			_run_slow33 += ms
		if ms > 50.0:
			_run_slow50 += ms
		if _runw.size() < RUN_WIN_CAP:
			_runw.append(ms)


static func _pct(a: PackedFloat32Array, q: float) -> float:
	if a.is_empty():
		return 0.0
	var b: PackedFloat32Array = a.duplicate()
	b.sort()
	return b[clampi(int(q * float(b.size() - 1)), 0, b.size() - 1)]


func _report(now_ms: int) -> void:
	var wall: float = (now_ms - _period_t0) / 1000.0
	var fps_now: int = int(_frames / maxf(0.001, wall))
	var calls: int = int(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME))
	Prof.peak_draw = maxi(Prof.peak_draw, calls)
	Prof.peak_nodes = maxi(Prof.peak_nodes, int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)))
	_log.store_line("t=%.0f  период=%.1fс  кадров=%d  средн=%.1f  худший=%.0f  к/с=%d  рывков=%d(пропущено %d, >1с: %d)  узлов=%d  отрисовка=%d  скрипты=%.1f  физика=%.1f  рендер_цпу=%.1f мс" % [now_ms / 1000.0, wall, _frames, _sum / maxf(1.0, _frames), _worst, fps_now, _spikes, _spikes_skipped, _long_frames, int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)), calls, _proc / maxf(1.0, _frames), _phys / maxf(1.0, _frames), _rcpu / maxf(1.0, _frames)])
	_log.store_line("  кадр(мс): p50=%.1f p95=%.1f p99=%.1f | <20:%d <33:%d <50:%d <100:%d >=100:%d" % [_pct(_win, 0.5), _pct(_win, 0.95), _pct(_win, 0.99), _hist[0], _hist[1], _hist[2], _hist[3], _hist[4]])
	var ticks: int = _cpu_ticks()
	_log.store_line("  рендер: вызовов=%d объектов=%d примитивов=%d | видеопамять=%.0f МБ текстуры=%.0f МБ буферы=%.0f МБ | ЦП процесса=%d%% | %s" % [calls, int(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME)), int(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)), float(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_VIDEO_MEM_USED)) / 1048576.0, float(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TEXTURE_MEM_USED)) / 1048576.0, float(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_BUFFER_MEM_USED)) / 1048576.0, int(float(ticks - _cpu_t0) / maxf(0.001, wall)), _sys_line()])
	_cpu_t0 = ticks
	_log.store_line("  средн(мс): " + Prof.line_avg())
	_log.store_line("  макс(мс): " + Prof.line_max())
	_log.store_line("  " + Prof.line_draw())
	_log.store_line("  " + Prof.line_counts())
	_log.store_line("  состояние: " + _state_line())
	if _in_run:
		_run_accumulate()
		var due: bool = Time.get_ticks_msec() / 1000.0 - _last_census >= CENSUS_S
		var low: bool = fps_now < LOW_FPS and Time.get_ticks_msec() / 1000.0 - _last_census >= CENSUS_LOW_S
		if low:
			_census("просадка: %d к/с" % fps_now, false)
		elif due:
			_census("плановый", false)
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
	_win.clear()
	for k in range(_hist.size()):
		_hist[k] = 0


# Копим за забег _draw по классам и круги Prof (до сброса периода) — для итога.
func _run_accumulate() -> void:
	if _run_d.size() != Prof.D_NAMES.size():
		_run_d.resize(Prof.D_NAMES.size())
	if _run_sec.size() != Prof.NAMES.size():
		_run_sec.resize(Prof.NAMES.size())
	for i in range(Prof.D_NAMES.size()):
		_run_d[i] += Prof.d_sum[i] if Prof.d_sum.size() == Prof.D_NAMES.size() else 0
	for j in range(Prof.NAMES.size()):
		_run_sec[j] += Prof.sum[j] if Prof.sum.size() == Prof.NAMES.size() else 0
	_run_pf += Prof.frames


# Состав сцены: сколько узлов какого класса + кто именно на экране (враги/пули/орбы/Fx по видам).
func _census(reason: String, _force: bool) -> void:
	_last_census = Time.get_ticks_msec() / 1000.0
	if _node_names.is_empty():
		var ms: Script = load("res://scripts/main.gd")
		if ms != null:
			var cm: Dictionary = ms.get_script_constant_map()
			for k in cm:
				if cm[k] is Script:
					_node_names[cm[k]] = str(k)
	var counts := {}
	var visible_n := 0
	var stack: Array = [get_tree().root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		var key: String = n.get_class()
		var sc: Script = n.get_script()
		if sc != null:
			key = _node_names.get(sc, sc.resource_path.get_file().get_basename() if sc.resource_path != "" else key)
		counts[key] = int(counts.get(key, 0)) + 1
		if n is CanvasItem and (n as CanvasItem).is_visible_in_tree():
			visible_n += 1
		for ch in n.get_children():
			stack.append(ch)
	var keys: Array = counts.keys()
	keys.sort_custom(func(a, b): return int(counts[a]) > int(counts[b]))
	var s := ""
	for i in range(mini(keys.size(), 22)):
		s += "%s=%d " % [keys[i], int(counts[keys[i]])]
	_log.store_line("  СНИМОК(%s): узлов по классам: %s| видимых CanvasItem=%d" % [reason, s.strip_edges(), visible_n])
	var sc2: Node = get_tree().current_scene
	if sc2 != null and sc2.has_method("perf_census"):
		_log.store_line("  СНИМОК: " + str(sc2.call("perf_census")))


# Опрос игры раз в POLL_MS: переходы состояний -> строки событий. Ничего не трогает в игре, только читает.
func _poll() -> void:
	var sc: Node = get_tree().current_scene
	var sid: int = sc.get_instance_id() if sc != null else 0
	if sid != _scene_id:
		var nm: String = sc.name if sc != null else "-"
		if _in_run:
			_end_run("сцена сменилась на %s (выход из забега или перезапуск)" % nm)
		_ev("СЦЕНА %s -> %s (прошло %.1f с)  узлов=%d  %s" % [_scene_name, nm, (Time.get_ticks_msec() - _scene_t0) / 1000.0, int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)), _mem_line()])
		_scene_id = sid
		_scene_name = nm
		_scene_t0 = Time.get_ticks_msec()
		_ps.clear()
	if sc == null or not ("run_time" in sc):
		return
	var ld: bool = bool(sc.get("loading_done"))
	if _chg("ld", ld):
		if ld:
			_ev("ЗАГРУЗКА завершена за %.1f с  %s" % [(Time.get_ticks_msec() - _scene_t0) / 1000.0, _mem_line()])
		else:
			_ev("ЗАГРУЗКА началась")
	if not ld:
		return
	var rt: float = float(sc.get("run_time"))
	var pl = sc.get("player")
	if not _in_run and rt > 0.2 and not bool(sc.get("run_saved")):
		_start_run(sc, pl)
	if not _in_run:
		return
	if pl != null and _chg("lvl", int(pl.get("level"))):
		_mark(sc, "УРОВЕНЬ %d" % int(pl.get("level")))
	if _chg("boss", int(sc.get("run_bosses"))):
		_mark(sc, "БОСС убит/пройден: run_bosses=%d idx=%d" % [int(sc.get("run_bosses")), int(sc.get("boss_idx"))])
	if _chg("bidx", int(sc.get("boss_idx"))):
		_mark(sc, "БОСС заспавнен: idx=%d" % int(sc.get("boss_idx")))
	if _chg("biome", int(sc.get("biome_idx"))):
		_mark(sc, "БИОМ %d" % int(sc.get("biome_idx")))
	var ar = sc.get("arena")
	var ai: Dictionary = sc.get("ainfo") if sc.get("ainfo") is Dictionary else {}
	if _chg("arena", ar != null):
		if ar != null:
			_mark(sc, "ВХОД в разлом/пещеру: тип=%s dex=%s cave=%s den=%s" % [str(ai.get("type", "?")), str(ai.get("dex", "?")), str(ai.get("cave", false)), str(ai.get("den", false))])
		else:
			_mark(sc, "ВЫХОД из разлома/пещеры")
	if ar != null and _chg("phase", str(ai.get("phase", ""))):
		_mark(sc, "РАЗЛОМ фаза=%s" % str(ai.get("phase", "")))
	if _chg("choosing", bool(sc.get("choosing"))):
		if bool(sc.get("choosing")):
			_ps["choose_t"] = Time.get_ticks_msec()
			_ev("ОКНО карточек открыто: лвл=%d ожидает=%d связь_ожидает=%d предметы=%d" % [int(pl.get("level")) if pl != null else 0, int(sc.get("pending_levels")), int(sc.get("bonds")), int(sc.get("items_waiting"))])
		else:
			_ev("ОКНО карточек закрыто через %.1f с" % ((Time.get_ticks_msec() - int(_ps.get("choose_t", Time.get_ticks_msec()))) / 1000.0))
	if _chg("paused", bool(sc.get("paused"))):
		_ev("ПАУЗА %s" % ("вкл" if bool(sc.get("paused")) else "выкл"))
	var bnd: String = ",".join(sc.get("bond_ids")) if sc.get("bond_ids") is Array else ""
	if _chg("bond", "%s|%d" % [bnd, int(sc.get("bonds"))]):
		_ev("СВЯЗЬ: пара=[%s] накоплено=%d слитые_приёмы=%s" % [bnd, int(sc.get("bonds")), str(sc.get("fused_away"))])
	if _chg("fused", str(sc.get("fused_away"))):
		_mark(sc, "СЛИЯНИЕ: слито=%s" % str(sc.get("fused_away")))
	if _chg("qauto", snappedf(float(sc.get("q_auto")), 0.01)):
		_ev("АВТО-качество: q_auto=%.2f" % float(sc.get("q_auto")))
	if _chg("wx", str(sc.get("wx_kind"))):
		_ev("ПОГОДА: %s" % str(sc.get("wx_kind")))
	if _chg("legend", sc.get("legend") != null):
		_ev("ЛЕГЕНДА %s" % ("появилась" if sc.get("legend") != null else "ушла"))
	var alp = sc.get("alpha")
	if alp != null and _chg("allies", int(alp.get("allies_made"))):
		_mark(sc, "СОЮЗНИК пойман: %s (всего %d)" % [str(sc.get("join_name")), int(alp.get("allies_made"))])
	if pl != null and _chg("dead", bool(pl.get("dead"))) and bool(pl.get("dead")):
		_mark(sc, "СМЕРТЬ игрока")
	if bool(sc.get("run_saved")):
		_end_run("забег завершён и сохранён")


# true, если значение изменилось с прошлого опроса (первый опрос только запоминает)
func _chg(key: String, v) -> bool:
	if not _ps.has("v_" + key):
		_ps["v_" + key] = v
		return false
	if _ps["v_" + key] == v:
		return false
	_ps["v_" + key] = v
	return true


# Метка события: окно «с прошлой метки» в цифрах — чтобы по каждому уровню/боссу/разлому было видно, где просело.
func _mark(sc: Node, label: String) -> void:
	var tot := 0.0
	for v in _mk:
		tot += v
	var n: int = _mk.size()
	var kills: int = int(sc.get("kills"))
	var coins: int = int(sc.get("coins"))
	_ev("▶ %s | забег=%.0fс убийств=%d монет=%d | с прошлой метки %.0fс: кадров=%d к/с≈%.0f p50=%.0f p95=%.0f худший=%.0f мс | %s" % [label, float(sc.get("run_time")), kills, coins, tot / 1000.0, n, float(n) / maxf(0.001, tot / 1000.0), _pct(_mk, 0.5), _pct(_mk, 0.95), _pct(_mk, 1.0), Prof.line_counts().get_slice("|", 0).strip_edges()])
	_mk.clear()


func _start_run(sc: Node, pl) -> void:
	_in_run = true
	Prof.run_active = true
	_run_t0_ms = Time.get_ticks_msec()
	_run_frames = 0
	_run_sum = 0.0
	_run_worst = 0.0
	_run_slow33 = 0.0
	_run_slow50 = 0.0
	_runw.clear()
	_mk.clear()
	_run_d = PackedInt64Array()
	_run_sec = PackedInt64Array()
	_run_pf = 0
	Prof.peak_enemies = 0
	Prof.peak_bullets = 0
	Prof.peak_orbs = 0
	Prof.peak_fx = 0
	Prof.peak_draw = 0
	Prof.peak_nodes = 0
	var mv := ""
	if pl != null and pl.get("moves") is Array:
		for m in pl.get("moves"):
			mv += "%s(ур%d%s) " % [str(m.get("id")), int(m.get("lvl", 1)), "*" if bool(m.get("evolved", false)) else ""]
	var st: Dictionary = SV.d["settings"]
	_ev("=== СТАРТ ЗАБЕГА === режим=%s покемон=%s ур=%d приёмы: %s| модификаторов=%d | качество=%s обзор=%s max_fps=%s потолок_врагов=%s" % [str(sc.get("mode")), str(pl.get("dex")) if pl != null else "?", int(pl.get("level")) if pl != null else 0, mv, (sc.get("mods") as Array).size() if sc.get("mods") is Array else 0, str(st.get("quality")), str(st.get("view")), str(st.get("max_fps")), str(sc.get("ENEMY_CAP"))])
	_w("  железо: " + _sys_line())
	_last_census = -999.0
	_census("старт забега", true)


func _end_run(reason: String) -> void:
	if not _in_run:
		return
	_in_run = false
	Prof.run_active = false
	_run_accumulate()
	Prof.peak_nodes = maxi(Prof.peak_nodes, int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)))
	var sc: Node = get_tree().current_scene if is_inside_tree() else null
	var wall: float = (Time.get_ticks_msec() - _run_t0_ms) / 1000.0
	var fr: float = float(maxi(1, _run_frames))
	_ev("=== ИТОГ ЗАБЕГА === причина: %s" % reason)
	if sc != null and "run_time" in sc and is_instance_valid(sc):
		var pl = sc.get("player")
		_ev("  результат: время=%.0fс уровень=%d убийств=%d монет=%d боссов=%d разломов=%d" % [float(sc.get("run_time")), int(pl.get("level")) if pl != null else 0, int(sc.get("kills")), int(sc.get("coins")), int(sc.get("run_bosses")), int(sc.get("run_rifts"))])
	_ev("  производительность: реальных %.0fс, кадров=%d, средний к/с=%.1f, p50=%.1f p95=%.1f p99=%.1f p99.9=%.1f худший=%.0f мс" % [wall, _run_frames, fr / maxf(0.001, _run_sum / 1000.0), _pct(_runw, 0.5), _pct(_runw, 0.95), _pct(_runw, 0.99), _pct(_runw, 0.999), _run_worst])
	_ev("  время в просадках: <30 к/с=%.0f%% времени (%.0fс), <20 к/с=%.0f%% (%.0fс)" % [100.0 * _run_slow33 / maxf(1.0, _run_sum), _run_slow33 / 1000.0, 100.0 * _run_slow50 / maxf(1.0, _run_sum), _run_slow50 / 1000.0])
	_ev("  пики: врагов=%d пуль=%d орбов=%d fx=%d вызовов_отрисовки=%d узлов=%d" % [Prof.peak_enemies, Prof.peak_bullets, Prof.peak_orbs, Prof.peak_fx, Prof.peak_draw, Prof.peak_nodes])
	if _run_pf > 0 and _run_d.size() == Prof.D_NAMES.size():
		var ds := ""
		var dt := 0.0
		for i in range(Prof.D_NAMES.size()):
			if _run_d[i] > 0:
				ds += "%s=%.1f " % [Prof.D_NAMES[i], float(_run_d[i]) / float(_run_pf) / 1000.0]
				dt += float(_run_d[i]) / float(_run_pf) / 1000.0
		_ev("  _draw в среднем за кадр (мс): %s| сумма=%.1f" % [ds.strip_edges(), dt])
		var ss := ""
		for j in range(Prof.NAMES.size()):
			if _run_sec[j] > 0:
				ss += "%s=%.1f " % [Prof.NAMES[j], float(_run_sec[j]) / float(_run_pf) / 1000.0]
		_ev("  логика в среднем за кадр (мс): %s" % ss.strip_edges())
	if is_inside_tree():
		_census("итог забега", true)
		_ev("  состояние: " + _state_line())


func _exit_tree() -> void:
	_shutdown()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_shutdown()


func _shutdown() -> void:
	if not active or _log == null or _shut:
		return
	_shut = true
	if _in_run:
		_end_run("выход из игры")
	_ev("ВЫХОД из игры")
