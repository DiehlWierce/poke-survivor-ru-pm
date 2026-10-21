extends SceneTree
# Проверка меню (геймпад/вкладки/фон):
#  1) навигация вверх/вниз в Настройках: фокус ходит по пунктам страницы, скролл следует за фокусом,
#     на вкладки/верхнюю панель уходит только с самого верхнего пункта; слайдер не глотает вверх/вниз;
#  2) переключение вкладок Настроек: страница целиком готова в том же кадре (нет пустого/недостроенного кадра);
#  3) фон главного экрана — живой мир (MenuWorld), а не картинка.
# Запуск: godot --path . --script res://tools/menu_ux_check.gd [-- --shots <папка>]  (окно нужно для снимков)
# Ничего не сохраняет в сейв: работает на копии данных в памяти.

var failures := 0
var shots := ""
var m: Control


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var i := args.find("--shots")
	if i >= 0 and i + 1 < args.size():
		shots = args[i + 1]
		DirAccess.make_dir_recursive_absolute(shots)
	call_deferred("_run")


func _fail(msg: String) -> void:
	failures += 1
	print("FAIL: " + msg)


func _frames(n: int) -> void:
	for _k in range(n):
		await process_frame


func _shot(name: String) -> void:
	if shots == "" or DisplayServer.get_name() == "headless":
		return
	var img: Image = root.get_texture().get_image()
	img.save_png(shots.path_join(name + ".png"))


func _press(action: String) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	root.push_input(ev)
	var up := InputEventAction.new()
	up.action = action
	up.pressed = false
	root.push_input(up)


func _desc(c: Control) -> String:
	if c == null:
		return "<нет>"
	var t := ""
	if c is Button:
		t = (c as Button).text
	if t == "" and c.get_parent() != null:
		for s in c.get_parent().get_children():
			if s is Label:
				t = (s as Label).text
				break
	return "%s«%s»" % [c.get_class(), t.substr(0, 24)]


func _region(c: Control) -> String:
	if c == null:
		return "-"
	if m.set_tabs_row.is_ancestor_of(c):
		return "tabs"
	if m.settings_host.is_ancestor_of(c):
		return "page"
	if m.top_bar.is_ancestor_of(c):
		return "top"
	return "other"


func _run() -> void:
	var sv = load("res://scripts/save_data.gd")
	sv.ensure()
	sv.set("save_blocked", true)   # проверка не пишет сейв
	var ua := OS.get_cmdline_user_args()
	var li := ua.find("--lang")
	if li >= 0 and li + 1 < ua.size():   # язык интерфейса: ru, ja, fr, ...
		sv.d["settings"]["lang"] = ua[li + 1]
		load("res://scripts/lang.gd").apply()
	var t0 := Time.get_ticks_usec()
	m = (load("res://scenes/menu.tscn") as PackedScene).instantiate()
	root.add_child(m)
	print("MENU_READY_MS %.1f" % ((Time.get_ticks_usec() - t0) / 1000.0))
	await _frames(20)
	await _check_world()
	await _check_nav()
	await _check_tabs()
	await _check_chal()
	await _check_gachapon()
	await _check_medals()
	await _check_lex_tabs()
	await _check_dex()
	await _check_modes_walk()
	if failures == 0:
		print("MENU_UX_OK")
	else:
		print("MENU_UX_FAIL: %d" % failures)
	quit(1 if failures > 0 else 0)


# ---------- 3) живой фон ----------
func _check_world() -> void:
	var w: Node2D = null
	for c in m.get_children():
		if c.get_script() != null and String(c.get_script().resource_path).ends_with("menu.gd") == false and c is Node2D and c.get("tw") != null:
			w = c
	for c in m.get_children():
		if c is Node2D and c.has_method("_update_chunks"):
			w = c
	if w == null:
		_fail("на главном экране нет живого мира (MenuWorld)")
		return
	Engine.max_fps = 60
	var ts := Time.get_ticks_msec()
	while not bool(w.get("shown")) and Time.get_ticks_msec() - ts < 10000:
		await process_frame
	print("WORLD виден через %d мс после готовности меню (lite=%s)" % [Time.get_ticks_msec() - ts, str(w.get("lite"))])
	if not bool(w.get("shown")):
		_fail("фон так и не показался")
	await _frames(40)   # фейд-ин и появление покемонов
	var cam0: Vector2 = w.get("cam")
	_shot("world_0")
	var worst := 0.0
	var tt := Time.get_ticks_usec()
	for _k in range(120):
		var a := Time.get_ticks_usec()
		await process_frame
		worst = maxf(worst, (Time.get_ticks_usec() - a) / 1000.0)
	_shot("world_1")
	var cam1: Vector2 = w.get("cam")
	var mons: Array = w.get("mons")
	var chunks: Dictionary = (w.get("gen") as Object).get("chunks")
	print("WORLD cam %.0f,%.0f -> %.0f,%.0f  покемонов=%d  кусков=%d  120 кадров за %.0f мс, худший %.1f мс" % [cam0.x, cam0.y, cam1.x, cam1.y, mons.size(), chunks.size(), (Time.get_ticks_usec() - tt) / 1000.0, worst])
	if cam0.distance_to(cam1) < 1.0:
		_fail("камера фона не движется")
	if mons.is_empty():
		_fail("на фоне нет покемонов")
	Engine.max_fps = 0


# ---------- 1) навигация ----------
func _check_nav() -> void:
	# главный экран: колонка кнопок, вверх с первой — на верхнюю панель
	m._show("main")
	await _frames(3)
	m.main_play_btn.grab_focus()
	var seq: Array = []
	for d in ["ui_down", "ui_down", "ui_down", "ui_down", "ui_down", "ui_down", "ui_down", "ui_up", "ui_up", "ui_up", "ui_up", "ui_up", "ui_up", "ui_up", "ui_up"]:
		_press(d)
		await _frames(2)
		var f: Control = m.get_viewport().gui_get_focus_owner()
		seq.append("%s:%s" % [d.substr(3), _desc(f)])
	print("MAIN: " + " ".join(PackedStringArray(seq)))
	m._show("settings")
	await _frames(3)
	for tab in [1, 2, 0]:
		m._settings_pick(tab)
		await _frames(3)
		var sc: ScrollContainer = m.settings_host.get_parent()
		var items: Array = m.NAVG.focusables(m.settings_box)
		var first: Control = items[0]
		print("TAB %d: пунктов=%d первый=%s фокус=%s" % [tab, items.size(), _desc(first), _desc(m.get_viewport().gui_get_focus_owner())])
		var left_page_at := -1
		var max_scroll := 0
		var slider_seen := false
		for k in range(items.size() + 6):
			var before: Control = m.get_viewport().gui_get_focus_owner()
			var val: float = (before as Range).value if before is Range else 0.0
			_press("ui_down")
			await _frames(2)
			var f: Control = m.get_viewport().gui_get_focus_owner()
			if before is Slider:
				slider_seen = true
				if f == before and k < items.size() - 1:
					_fail("tab %d: слайдер %s проглотил «вниз»" % [tab, _desc(before)])
				if (before as Range).value != val:
					_fail("tab %d: «вниз» изменил значение слайдера" % tab)
			max_scroll = maxi(max_scroll, sc.scroll_vertical)
			if _region(f) != "page":
				_fail("tab %d: «вниз» увёл фокус из страницы в %s (%s)" % [tab, _region(f), _desc(f)])
				break
			if not sc.get_global_rect().grow(2.0).encloses(f.get_global_rect()):
				print("  (вниз %d) фокус %s вне видимой области: скролл=%d" % [k, _desc(f), sc.scroll_vertical])
		var bottom_scroll: int = sc.scroll_vertical
		var log_up: Array = []
		for k in range(items.size() + 6):
			var before: Control = m.get_viewport().gui_get_focus_owner()
			var sv0: int = sc.scroll_vertical
			_press("ui_up")
			await _frames(2)
			var f: Control = m.get_viewport().gui_get_focus_owner()
			if before is Slider and f == before and sc.scroll_vertical == sv0:
				_fail("tab %d: слайдер проглотил «вверх»" % tab)
			log_up.append("%s/%d" % [_region(f), sc.scroll_vertical])
			if _region(f) != "page":
				left_page_at = k
				if before != first:
					_fail("tab %d: «вверх» ушёл в %s не с первого пункта, а с %s (скролл %d)" % [tab, _region(f), _desc(before), sv0])
				if sv0 != 0:
					_fail("tab %d: ушёл со страницы при скролле %d" % [tab, sv0])
				break
			if not sc.get_global_rect().grow(2.0).encloses(f.get_global_rect()):
				_fail("tab %d: фокус %s вне видимой области после «вверх»" % [tab, _desc(f)])
		print("TAB %d: вниз до скролла %d (макс %d), вверх: %s; со страницы вышел на шаге %d, слайдер был=%s" % [tab, bottom_scroll, max_scroll, " ".join(PackedStringArray(log_up)), left_page_at, slider_seen])
		if tab == 1 and max_scroll == 0:
			_fail("tab 1: скролл не следовал за фокусом")


# ---------- 2) вкладки ----------
func _check_tabs() -> void:
	m._show("main")
	await _frames(5)
	var a := Time.get_ticks_usec()
	m._show("settings")
	var open_ms: float = (Time.get_ticks_usec() - a) / 1000.0
	var worst := 0.0
	for _k in range(90):   # фоновая достройка остальных вкладок
		var b := Time.get_ticks_usec()
		await process_frame
		worst = maxf(worst, (Time.get_ticks_usec() - b) / 1000.0)
	var pending := 0
	for e in m.fq:
		if e[0] in m.settings_pages.values():
			pending += 1
	print("SETTINGS открытие %.1f мс; 90 кадров достройки: худший кадр %.1f мс; осталось шагов=%d; страниц=%d" % [open_ms, worst, pending, m.settings_pages.size()])
	for step in range(5):
		var c := Time.get_ticks_usec()
		m._tab_step(1, true)
		var sw_ms: float = (Time.get_ticks_usec() - c) / 1000.0
		var page: Control = m.settings_box
		var n0: int = page.find_children("*", "", true, false).size()
		var pend := 0
		for e in m.fq:
			if e[0] == page:
				pend += 1
		var counts: Array = []
		var ftimes: Array = []
		for fr in range(4):
			var d := Time.get_ticks_usec()
			await process_frame
			ftimes.append("%.1f" % ((Time.get_ticks_usec() - d) / 1000.0))
			counts.append(page.find_children("*", "", true, false).size())
			_shot("tab%d_f%d" % [m.set_tab, fr])
		var vis := 0
		for pg in m.settings_pages.values():
			if (pg as Control).visible:
				vis += 1
		print("SWITCH -> вкладка %d: вызов %.2f мс, узлов %d, по кадрам %s, кадры(мс) %s, шагов в очереди %d, видимых страниц %d" % [m.set_tab, sw_ms, n0, str(counts), " ".join(PackedStringArray(ftimes)), pend, vis])
		if pend > 0:
			_fail("вкладка %d показана недостроенной (%d шагов в очереди)" % [m.set_tab, pend])
		for cn in counts:
			if int(cn) != n0:
				_fail("вкладка %d достраивалась после показа (%d -> %s)" % [m.set_tab, n0, str(counts)])
				break
		if vis != 1:
			_fail("видимых страниц %d" % vis)
		if n0 < 3:
			_fail("вкладка %d пустая" % m.set_tab)


# ---------- 4) Испытания: все вкладки строятся, карточек столько, сколько испытаний, Играть достижим ----------
func _check_chal() -> void:
	var ch = load("res://scripts/challenges.gd")
	for cat in ["p", "d", "w"]:
		m.chal_cat = cat
		m._show("chal")
		for _i in 400:
			await _frames(1)
			if m.fq.is_empty():
				break
		var n: int = m.chal_box.get_child_count()
		var want: int = 100 if cat == "p" else (3 if cat == "d" else 5)
		var cards := 0
		for c in m.chal_box.get_children():
			if c is PanelContainer:
				cards += 1
		if cards != want:
			_fail("chal %s: карточек %d, ожидалось %d (детей %d)" % [cat, cards, want, n])
		_shot("chal_" + cat)
	m._leave()
	await _frames(2)
	if m.cur != "modes":
		_fail("B из Испытаний ведёт в '%s', а не в modes" % m.cur)
	m._show("main")
	await _frames(3)


# ---------- 5b) Новые вкладки Лексикона (Fusion Dex, Kecleon, Novedades): строятся, карточки появляются ----------
func _check_lex_tabs() -> void:
	for k in ["f", "k", "n"]:
		m.lex_tab = k
		m._show("lexicon")
		await _frames(40)
		var page = m.lex_pages.get(k)
		var cards: int = page.find_children("*", "PanelContainer", true, false).size() if page != null else 0
		if cards < 3:
			_fail("лексикон %s: карточек %d, ожидалось ≥3" % [k, cards])
	m.lex_tab = "m"
	m._show("main")
	await _frames(5)


# ---------- 5a) Вкладка «Медали»: 18 типов + список по категориям, без ошибок, кнопки категорий фокусируются ----------
func _check_medals() -> void:
	m.goals_tab = "h"
	m._show("goals")
	await _frames(30)
	var chips := 0
	for b in m.goals_box.find_children("*", "Button", true, false):
		chips += 1
	if chips < 4:
		_fail("medals: кнопок категорий %d, ожидалось ≥4" % chips)
	if m.focus_first == null:
		_fail("medals: нет первой точки фокуса")
	_shot("medals_0")
	m.med_cat = "mastery"
	m._refresh_goals()
	await _frames(30)
	m.goals_tab = "m"
	m._show("main")
	await _frames(5)


# ---------- 5) TM Gachapon: монета тратится, ручка крутится, капсула даёт приём ----------
func _check_gachapon() -> void:
	var sv = load("res://scripts/save_data.gd")
	var gp = load("res://scripts/gachapon.gd")
	sv.d["gcoins"] = 2
	var n0: int = gp.unlocked().size()
	m._show("gachapon")
	await _frames(3)
	if m.gp_btn1.disabled:
		_fail("gachapon: кнопка монеты заблокирована при gcoins=2")
		return
	_shot("gachapon_0")
	m._gp_insert(false)
	for _i in 900:
		await _frames(1)
		if m.gacha_result.visible:
			break
	if not m.gacha_result.visible:
		_fail("gachapon: результат не появился за 900 кадров")
	elif gp.unlocked().size() != n0 + 1:
		_fail("gachapon: движений %d -> %d, ожидался +1" % [n0, gp.unlocked().size()])
	if int(sv.d["gcoins"]) != 1:
		_fail("gachapon: gcoins=%d, ожидалась 1" % int(sv.d["gcoins"]))
	_shot("gachapon_1")
	m.gacha_result.visible = false
	m._show("main")
	await _frames(3)


# ---------- 6) Коллекция: сортировка и избранное ----------
func _check_dex() -> void:
	var sv = load("res://scripts/save_data.gd")
	for dx in [1, 4, 7, 25]:
		if not sv.owns(dx):
			sv.add_owned(dx)
	m.dex_gen = 0
	m.dex_only_owned = true
	m.dex_page = 0
	m.dex_sort = 0
	m._show("dex")
	await _frames(3)
	var asc: Array = m._dex_filtered()
	if asc.size() < 2:
		_fail("dex: мало Pokémon для проверки сортировки (%d)" % asc.size())
		return
	m.dex_sort = 1
	var desc: Array = m._dex_filtered()
	if int(desc[0]["dex"]) != int(asc[asc.size() - 1]["dex"]):
		_fail("dex: сортировка по убыванию не работает")
	var pick: int = int(asc[asc.size() - 1]["dex"])
	if m._is_fav(pick):
		_fail("dex: избранное не должно быть задано заранее")
	m._fav_toggle(pick)
	if not m._is_fav(pick):
		_fail("dex: _fav_toggle не включил избранное")
	m.dex_sort = 4
	var fv: Array = m._dex_filtered()
	if int(fv[0]["dex"]) != pick:
		_fail("dex: «Избранные первыми» не ставит избранное в начало")
	await _frames(3)
	_shot("dex_fav")
	m._fav_toggle(pick)
	if m._is_fav(pick):
		_fail("dex: _fav_toggle не выключил избранное")
	sv.d.erase("dex_fav")
	m.dex_sort = 0
	m.dex_only_owned = false
	m._show("main")
	await _frames(3)


# ---------- 7) Геймпадом по списку режимов: фокус идёт по всем карточкам, A запускает режим ----------
func _check_modes_walk() -> void:
	m._show("modes")
	for _i in 400:
		await _frames(1)
		if m.fq.is_empty():
			break
	await _frames(5)
	var titles := {}
	for _k in 40:
		var f: Control = root.gui_get_focus_owner()
		if f is Button and (f as Button).text.contains("\n"):
			titles[(f as Button).text.get_slice("\n", 0)] = true
		_press("ui_down")
		await _frames(4)
	_shot("modes_walk")
	if titles.size() < 8:
		_fail("режимы: геймпадом достижимо только %d карточек из ≥8" % titles.size())
	var sv = load("res://scripts/save_data.gd")
	for _k in 40:
		_press("ui_up")
		await _frames(2)
	_press("ui_accept")
	await _frames(2)
	if String(sv.run_mode) != "normal":
		_fail("режимы: A на первой карточке дал run_mode='%s', ожидался normal" % String(sv.run_mode))
