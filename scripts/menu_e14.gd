extends Control
# Menu principal: jugar, Pokemon, mejoras, gacha, misiones y ajustes.
# Funciona con toque, mando (cruceta + A / B) y teclado (flechas + Enter / Esc).

const SV = preload("res://scripts/save_data.gd")
const Aud = preload("res://scripts/audio.gd")
const L = preload("res://scripts/lang.gd")
const MD = preload("res://scripts/moves_data.gd")
const ST = preload("res://scripts/starters_data.gd")
const IC = preload("res://scripts/icons.gd")

const C_PANEL := Color("#27449a")
const C_PANEL_D := Color("#18296a")
const C_BTN := Color("#1c3a8c")
const C_BTN_H := Color("#2f58c9")
const C_GOLD := Color("#ffd33d")
const PER_PAGE := 24

var theme_main := Theme.new()
var screens := {}
var cur := ""
var coin_lbl: Label
var ticket_lbl: Label
var toast_lbl: Label
var toast_t := 0.0
var back_btn: Button
var focus_first: Control = null

# estado de pantallas
var dex_gen := 0
var dex_page := 0
var dex_only_owned := false
var dex_sel := 25
var dex_grid: GridContainer
var dex_page_lbl: Label
var dex_detail: VBoxContainer
var dex_prev: Preview
var gacha_region := 1
var gacha_box: VBoxContainer
var gacha_result: Control
var goals_tab := "m"
var goals_box: VBoxContainer
var up_box: VBoxContainer
var main_prev: Preview
var main_card: PanelContainer
var main_info: Label
var main_stats: Label
var test_box: VBoxContainer
var test_idx := 0
var test_scores := {}
var test_result_dex := 0
var reset_armed := false
var settings_box: VBoxContainer


# ---------------------------------------------------------------
# Vista previa animada de un Pokemon (hoja Idle, fila 0)
# ---------------------------------------------------------------
class Preview extends Control:
	var dex := 25
	var shiny := false
	var scale_k := 5.0
	var dark := false
	var t := 0.0
	var frame := 0
	var tr: TextureRect = null

	func setup(d: int, shn: bool = false, k: float = 5.0, drk: bool = false) -> void:
		dex = d
		shiny = shn
		scale_k = k
		dark = drk
		frame = 0
		t = 0.0
		queue_redraw()

	static func anim_of(d: int) -> Dictionary:
		var SVl = load("res://scripts/save_data.gd")
		var sm: Dictionary = SVl.smeta.get(str(d), {})
		if sm.is_empty():
			return {}
		var a: Dictionary = sm["a"]
		var nm := "Idle" if a.has("Idle") else "Walk"
		return {"name": nm, "info": a[nm], "sm": sm}

	static func tex_of(d: int, nm: String, shn: bool) -> Texture2D:
		if shn:
			var ps := "res://assets/pokemon/%d/s/%s.png" % [d, nm]
			if ResourceLoader.exists(ps):
				return load(ps)
		var p := "res://assets/pokemon/%d/%s.png" % [d, nm]
		if ResourceLoader.exists(p):
			return load(p)
		return null

	func _process(delta: float) -> void:
		var an: Dictionary = anim_of(dex)
		if an.is_empty():
			return
		var info: Dictionary = an["info"]
		t += delta * 60.0
		var guard := 0
		while t >= float(info["d"][frame]) and guard < 12:
			guard += 1
			t -= float(info["d"][frame])
			frame = (frame + 1) % int(info["n"])
		queue_redraw()

	func _draw() -> void:
		var an: Dictionary = anim_of(dex)
		if an.is_empty():
			return
		var info: Dictionary = an["info"]
		var tx: Texture2D = tex_of(dex, String(an["name"]), shiny)
		if tx == null:
			draw_rect(Rect2(size * 0.5 - Vector2(16, 16), Vector2(32, 32)), Color(1, 1, 1, 0.15))
			return
		var w: float = float(info["w"])
		var h: float = float(info["h"])
		var k: float = scale_k
		# ajusta para que no se salga del cuadro
		k = minf(k, minf(size.x / w, size.y / h) * 0.92)
		var pos := Vector2(size.x * 0.5 - float(info["ax"]) * k, size.y * 0.5 + h * k * 0.5 - (h - float(info["ay"])) * k * 0.0 - float(info["ay"]) * k + (float(info["ay"]) * k) * 0.0)
		pos = Vector2(size.x * 0.5 - float(info["ax"]) * k, size.y * 0.84 - float(info["ay"]) * k)
		draw_set_transform(Vector2(size.x * 0.5, size.y * 0.84), 0.0, Vector2(1.0, 0.35))
		draw_circle(Vector2.ZERO, w * k * 0.28, Color(0, 0, 0, 0.3))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		if tr == null:
			tr = TextureRect.new()
			tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
			tr.stretch_mode = TextureRect.STRETCH_SCALE
			tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			add_child(tr)
		var at := AtlasTexture.new()
		at.atlas = tx
		at.region = Rect2(float(frame) * w, 0.0, w, h)
		tr.texture = at
		tr.position = pos
		tr.size = Vector2(w * k, h * k)
		tr.modulate = Color(0, 0, 0, 0.9) if dark else Color.WHITE


# ---------------------------------------------------------------
# Construccion
# ---------------------------------------------------------------
func _sb(col: Color, border: Color = Color.TRANSPARENT, bw: int = 0, radius: int = 8) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = col
	s.border_color = border
	s.set_border_width_all(bw)
	s.set_corner_radius_all(radius)
	s.content_margin_left = 14
	s.content_margin_right = 14
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	return s


func _build_theme() -> void:
	theme_main.default_font_size = 22
	theme_main.set_stylebox("normal", "Button", _sb(C_BTN, Color("#6f8be0"), 2))
	theme_main.set_stylebox("hover", "Button", _sb(C_BTN_H, Color("#9fb4f0"), 2))
	theme_main.set_stylebox("pressed", "Button", _sb(C_PANEL_D, C_GOLD, 2))
	theme_main.set_stylebox("focus", "Button", _sb(C_BTN_H, C_GOLD, 4))
	theme_main.set_stylebox("disabled", "Button", _sb(Color("#222c4a"), Color("#3a456a"), 2))
	theme_main.set_color("font_color", "Button", Color.WHITE)
	theme_main.set_color("font_disabled_color", "Button", Color("#7d86a6"))
	theme_main.set_stylebox("panel", "PanelContainer", _sb(C_PANEL, Color.WHITE, 3, 10))
	theme_main.set_stylebox("fill", "ProgressBar", _sb(Color("#5fe08a"), Color.TRANSPARENT, 0, 4))
	theme_main.set_stylebox("background", "ProgressBar", _sb(Color("#101a3e"), Color.TRANSPARENT, 0, 4))
	theme_main.set_constant("separation", "VBoxContainer", 10)
	theme_main.set_constant("separation", "HBoxContainer", 10)
	theme = theme_main


func _ready() -> void:
	SV.ensure()
	L.apply()
	Aud.setup(self)
	Aud.music("village")
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_theme()
	RenderingServer.set_default_clear_color(Color("#16233a"))
	# fondo: pasto en mosaico oscurecido
	var bg := TextureRect.new()
	var gt: Texture2D = load("res://assets/world/ground_grass.png") if ResourceLoader.exists("res://assets/world/ground_grass.png") else null
	if gt != null:
		bg.texture = gt
		bg.stretch_mode = TextureRect.STRETCH_TILE
		bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var shade := ColorRect.new()
	shade.color = Color(0, 0.05, 0.1, 0.45)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	# barra superior
	var top := HBoxContainer.new()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 16
	top.offset_right = -16
	top.offset_top = 10
	top.offset_bottom = 58
	add_child(top)
	back_btn = _btn("◀ Volver", func(): _show("main"), Vector2(150, 44))
	top.add_child(back_btn)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(sp)
	coin_lbl = _chip("coin")
	ticket_lbl = _chip("ticket")
	top.add_child(coin_lbl)
	top.add_child(ticket_lbl)
	toast_lbl = Label.new()
	toast_lbl.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	toast_lbl.offset_left = -300
	toast_lbl.offset_right = 300
	toast_lbl.offset_top = -80
	toast_lbl.offset_bottom = -30
	toast_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_lbl.add_theme_font_size_override("font_size", 24)
	toast_lbl.add_theme_color_override("font_color", C_GOLD)
	toast_lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	toast_lbl.add_theme_constant_override("outline_size", 6)
	toast_lbl.z_index = 50
	add_child(toast_lbl)
	_build_main()
	_build_test()
	_build_dex()
	_build_up()
	_build_gacha()
	_build_goals()
	_build_settings()
	if SV.reopen != "":
		var ro: String = SV.reopen
		SV.reopen = ""
		_show(ro)
	elif SV.owned_count() == 0:
		_show("test")
	else:
		_show("main")
		if not SV.last_run.is_empty():
			_show_run_summary()


func _chip(icon: String = "") -> Label:
	var l := Label.new()
	var sbx := _sb(Color(0, 0, 0, 0.55), Color.WHITE, 2, 22)
	sbx.content_margin_left = 46
	l.add_theme_stylebox_override("normal", sbx)
	l.add_theme_color_override("font_color", C_GOLD)
	l.custom_minimum_size = Vector2(150, 44)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if icon != "":
		var ic := IC.rect(icon, 24)
		ic.position = Vector2(12, 10)
		l.add_child(ic)
	return l


# Boton con iconos dentro: [icono] titulo + coste con su propio icono.
func _cost_btn(title: String, cost: String, icon: String, cost_icon: String, cb: Callable, min_size: Vector2, enabled: bool = true, vertical: bool = false) -> Button:
	var b := _btn("", cb, min_size)
	b.disabled = not enabled
	var hb := HBoxContainer.new()
	hb.set_anchors_preset(Control.PRESET_FULL_RECT)
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.add_theme_constant_override("separation", 10)
	if not enabled:
		hb.modulate = Color(1, 1, 1, 0.5)
	if icon != "":
		hb.add_child(IC.rect(icon, 32))
	var holder: BoxContainer = VBoxContainer.new() if vertical else HBoxContainer.new()
	holder.alignment = BoxContainer.ALIGNMENT_CENTER
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_theme_constant_override("separation", 8 if not vertical else 0)
	holder.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if title != "":
		var tl := _label(title, 22)
		tl.autowrap_mode = TextServer.AUTOWRAP_OFF
		tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.add_child(tl)
	var cr := HBoxContainer.new()
	cr.alignment = BoxContainer.ALIGNMENT_CENTER
	cr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cr.add_theme_constant_override("separation", 6)
	cr.add_child(IC.rect(cost_icon, 24))
	var cl := _label(cost, 22, C_GOLD)
	cl.autowrap_mode = TextServer.AUTOWRAP_OFF
	cl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cr.add_child(cl)
	holder.add_child(cr)
	hb.add_child(holder)
	b.add_child(hb)
	return b


# Fila [icono] texto
func _icon_label(icon: String, text: String, size: int = 22, col: Color = Color.WHITE, isz: float = 24.0) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	h.add_child(IC.rect(icon, isz))
	var l := _label(text, size, col)
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	h.add_child(l)
	return h


func _btn(text: String, cb: Callable, min_size: Vector2 = Vector2(0, 52)) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = min_size
	b.focus_mode = Control.FOCUS_ALL
	b.pressed.connect(cb)
	b.pressed.connect(func(): Aud.sfx("click"))
	b.focus_entered.connect(func(): Aud.sfx("hover"))
	return b


func _panel(parent: Node) -> VBoxContainer:
	var pc := PanelContainer.new()
	parent.add_child(pc)
	var v := VBoxContainer.new()
	pc.add_child(v)
	return v


func _label(text: String, size: int = 22, col: Color = Color.WHITE) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


func _screen(name: String) -> Control:
	var c := MarginContainer.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.add_theme_constant_override("margin_left", 24)
	c.add_theme_constant_override("margin_right", 24)
	c.add_theme_constant_override("margin_top", 72)
	c.add_theme_constant_override("margin_bottom", 18)
	c.visible = false
	add_child(c)
	screens[name] = c
	return c


func _show(name: String) -> void:
	cur = name
	for k in screens:
		screens[k].visible = k == name
	back_btn.visible = name != "main" and name != "test"
	coin_lbl.visible = name != "test"
	ticket_lbl.visible = name != "test"
	_update_top()
	focus_first = null
	call("_refresh_" + name)
	if focus_first != null and is_instance_valid(focus_first):
		_gf(focus_first)


func _gf(c: Control) -> void:
	call_deferred("_do_focus", c)


func _do_focus(c: Control) -> void:
	if is_instance_valid(c) and c.is_inside_tree() and c.is_visible_in_tree():
		c.grab_focus()


func _update_top() -> void:
	coin_lbl.text = "%d" % int(SV.d["coins"])
	ticket_lbl.text = "%d" % int(SV.d["tickets"])


func toast(msg: String) -> void:
	toast_lbl.text = msg
	toast_t = 2.6


func _process(delta: float) -> void:
	if toast_t > 0.0:
		toast_t -= delta
		if toast_t <= 0.0:
			toast_lbl.text = ""


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if gacha_result != null and gacha_result.visible:
			gacha_result.visible = false
			get_viewport().set_input_as_handled()
			return
		if cur != "main" and cur != "test":
			_show("main")
			get_viewport().set_input_as_handled()


func _clear(box: Node) -> void:
	for c in box.get_children():
		box.remove_child(c)
		c.queue_free()


func _name_of(dex: int) -> String:
	return String(SV.dex_by[dex]["name"])


func _type_text(dex: int) -> String:
	var out: Array = []
	for t in SV.dex_by[dex]["types"]:
		out.append(L.t(String(MD.TYPE_NAME[String(t)])))
	return " / ".join(out)


# ---------------------------------------------------------------
# Pantalla principal
# ---------------------------------------------------------------
func _build_main() -> void:
	var s: Control = _screen("main")
	var row := HBoxContainer.new()
	s.add_child(row)
	# columna izquierda: titulo + Pokemon
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(left)
	var title := _label("Pokémon Survivors", 56, C_GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_outline_color", Color("#7a3d00"))
	title.add_theme_constant_override("outline_size", 12)
	left.add_child(title)
	var sub := _label("MYSTERY DUNGEON", 22, Color.WHITE)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	left.add_child(sub)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _sb(Color("#0f1a34"), Color("#ff9a4d"), 4, 10))
	card.custom_minimum_size = Vector2(360, 260)
	card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	left.add_child(card)
	main_card = card
	main_info = _label("", 26)
	main_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	left.add_child(main_info)
	# columna derecha: menu
	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(380, 0)
	row.add_child(right)
	var p := PanelContainer.new()
	right.add_child(p)
	var mv := VBoxContainer.new()
	p.add_child(mv)
	var entries := [["Jugar", "play", "flag"], ["Pokémon", "dex", "ball"], ["Mejoras", "up", "up"], ["Gacha", "gacha", "ballLux"], ["Misiones y logros", "goals", "trophy"], ["Ajustes", "settings", "gear"]]
	var first := true
	for e in entries:
		var key: String = String(e[1])
		var b := _btn(String(e[0]), func(): _menu_pick(key), Vector2(0, 58))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.icon = IC.btn_tex(String(e[2]), 36)
		b.add_theme_constant_override("icon_max_width", 40)
		b.add_theme_constant_override("h_separation", 14)
		b.add_theme_font_size_override("font_size", 26)
		mv.add_child(b)
		if first:
			first = false
			main_play_btn = b
	main_stats = _label("", 18, Color("#c8d6ee"))
	var sp2 := PanelContainer.new()
	right.add_child(sp2)
	sp2.add_child(main_stats)
var main_play_btn: Button


func _menu_pick(key: String) -> void:
	if key == "play":
		SV.run_dex = int(SV.d["selected"])
		SV.save()
		get_tree().change_scene_to_file("res://scenes/main.tscn")
	else:
		_show(key)


func _refresh_main() -> void:
	var dex: int = int(SV.d["selected"])
	if not SV.owns(dex) and SV.owned_count() > 0:
		dex = int(SV.d["owned"].keys()[0])
		SV.d["selected"] = dex
	var shn: bool = bool(SV.d["shiny_on"]) and SV.owns(dex) and bool(SV.d["owned"][str(dex)]["shiny"])
	if is_instance_valid(main_prev):
		main_prev.queue_free()
	main_prev = Preview.new()
	main_prev.custom_minimum_size = Vector2(340, 240)
	main_card.add_child(main_prev)
	main_prev.setup(dex, shn, 6.0)
	main_info.text = "%s · %s" % [_name_of(dex), _type_text(dex)]
	var st: Dictionary = SV.d["stats"]
	main_stats.text = L.t("Partidas %d · Mejor tiempo %d:%02d\nMejor nivel %d · Derrotados %d\nPokémon %d / %d") % [int(st["runs"]), int(st["best_time"]) / 60, int(st["best_time"]) % 60, int(st["best_level"]), int(st["kills"]), SV.owned_count(), SV.dex_list.size()]
	focus_first = main_play_btn


func _show_run_summary() -> void:
	var r: Dictionary = SV.last_run
	SV.last_run = {}
	var ov := ColorRect.new()
	ov.color = Color(0, 0, 0, 0.6)
	ov.set_anchors_preset(Control.PRESET_FULL_RECT)
	ov.z_index = 40
	add_child(ov)
	var c := CenterContainer.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	ov.add_child(c)
	var pc := PanelContainer.new()
	c.add_child(pc)
	var v := VBoxContainer.new()
	pc.add_child(v)
	v.add_child(_label("Resumen de la partida", 32, C_GOLD))
	var t: int = int(r["time"])
	v.add_child(_label(L.t("Aguantaste %d:%02d y derrotaste %d\nNivel %d · Jefes derrotados %d") % [t / 60, t % 60, int(r["kills"]), int(r["level"]), int(r["bosses"])], 24))
	var gr := HBoxContainer.new()
	gr.add_theme_constant_override("separation", 10)
	gr.add_child(IC.rect("coin", 36))
	var gl := _label(L.t("+%d monedas") % int(r["coins"]), 30, Color("#ffd23f"))
	gl.autowrap_mode = TextServer.AUTOWRAP_OFF
	gr.add_child(gl)
	if int(r["tickets"]) > 0:
		var gsp := Control.new()
		gsp.custom_minimum_size = Vector2(16, 0)
		gr.add_child(gsp)
		gr.add_child(IC.rect("ticket", 36))
		var gt := _label(L.t("  +%d tickets") % int(r["tickets"]), 30, Color("#ff8ad8"))
		gt.autowrap_mode = TextServer.AUTOWRAP_OFF
		gr.add_child(gt)
	v.add_child(gr)
	var ok := _btn("Continuar", func(): ov.queue_free(); _update_top(); focus_first = main_play_btn; main_play_btn.grab_focus(), Vector2(260, 56))
	v.add_child(ok)
	_gf(ok)
	_update_top()


# ---------------------------------------------------------------
# Test de personalidad
# ---------------------------------------------------------------
func _build_test() -> void:
	var s: Control = _screen("test")
	var c := CenterContainer.new()
	s.add_child(c)
	var pc := PanelContainer.new()
	pc.custom_minimum_size = Vector2(820, 0)
	c.add_child(pc)
	test_box = VBoxContainer.new()
	pc.add_child(test_box)


func _refresh_test() -> void:
	test_idx = -1
	test_scores = {}
	_clear(test_box)
	test_box.add_child(_label("¡Bienvenido a Pokémon Survivors!", 36, C_GOLD))
	test_box.add_child(_label("Como en Mundo Misterioso, unas preguntas decidirán tu personalidad y tu compañero.\nPuedes aceptar el resultado o elegir otro Pokémon inicial.", 24))
	var b := _btn("Empezar el test", func(): _test_next(), Vector2(0, 60))
	test_box.add_child(b)
	focus_first = b


func _test_next() -> void:
	test_idx += 1
	_clear(test_box)
	if test_idx >= ST.TEST.size():
		_test_finish()
		return
	var q: Dictionary = ST.TEST[test_idx]
	test_box.add_child(_label(L.t("Pregunta %d / %d") % [test_idx + 1, ST.TEST.size()], 20, Color("#9fb4f0")))
	test_box.add_child(_label(String(q["q"]), 30, Color.WHITE))
	var first: Button = null
	for a in q["a"]:
		var ans: Dictionary = a
		var b := _btn(String(ans["t"]), func(): _test_answer(ans), Vector2(0, 56))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		test_box.add_child(b)
		if first == null:
			first = b
	_gf(first)


func _test_answer(ans: Dictionary) -> void:
	for k in ans["p"]:
		test_scores[k] = int(test_scores.get(k, 0)) + int(ans["p"][k])
	_test_next()


func _test_finish() -> void:
	var trt := ""
	var best := -1
	for k in test_scores:
		if int(test_scores[k]) > best:
			best = int(test_scores[k])
			trt = String(k)
	var cands: Array = []
	var best_s := -1
	for s in ST.STARTERS:
		var v: int = int(test_scores.get(String(s["traits"][0]), 0)) * 2 + int(test_scores.get(String(s["traits"][1]), 0))
		if v > best_s:
			best_s = v
			cands = [s]
		elif v == best_s:
			cands.append(s)
	test_result_dex = int(cands[randi() % cands.size()]["dex"])
	_test_show_result(trt)


func _test_show_result(trt: String) -> void:
	_clear(test_box)
	test_box.add_child(_label(L.t("Tu personalidad: %s") % L.t(trt.capitalize()), 34, C_GOLD))
	test_box.add_child(_label(String(ST.TRAIT_TEXT.get(trt, "")), 22, Color("#c8d6ee")))
	var pv := Preview.new()
	pv.custom_minimum_size = Vector2(0, 220)
	test_box.add_child(pv)
	pv.setup(test_result_dex, false, 5.0)
	var nm := _label(L.t("Tu compañero: %s (%s)") % [_name_of(test_result_dex), _type_text(test_result_dex)], 28)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	test_box.add_child(nm)
	var row := HBoxContainer.new()
	test_box.add_child(row)
	var ok := _btn("¡Aceptar!", func(): _accept_starter(test_result_dex), Vector2(0, 58))
	ok.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(ok)
	var other := _btn("Elegir otro", func(): _test_pick_other(), Vector2(0, 58))
	other.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(other)
	_gf(ok)


func _test_pick_other() -> void:
	_clear(test_box)
	test_box.add_child(_label("Elige a tu compañero", 32, C_GOLD))
	var grid := GridContainer.new()
	grid.columns = 6
	test_box.add_child(grid)
	var first: Button = null
	for s in ST.STARTERS:
		var dx: int = int(s["dex"])
		var b := _btn("", func(): _accept_starter(dx), Vector2(120, 100))
		var tx: Texture2D = _icon_tex(dx, false)
		if tx != null:
			b.icon = tx
			b.expand_icon = true
			b.add_theme_constant_override("icon_max_width", 56)
		b.text = _name_of(dx)
		b.add_theme_font_size_override("font_size", 14)
		b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		grid.add_child(b)
		if first == null:
			first = b
	_gf(first)


func _accept_starter(dex: int) -> void:
	SV.add_owned(dex)
	SV.d["selected"] = dex
	SV.save()
	toast(L.t("¡%s se une a tu equipo!") % _name_of(dex))
	_show("main")


# ---------------------------------------------------------------
# Iconos
# ---------------------------------------------------------------
func _icon_tex(dex: int, shiny: bool) -> Texture2D:
	var an: Dictionary = Preview.anim_of(dex)
	if an.is_empty():
		return null
	var tx: Texture2D = Preview.tex_of(dex, String(an["name"]), shiny)
	if tx == null:
		return null
	var info: Dictionary = an["info"]
	var at := AtlasTexture.new()
	at.atlas = tx
	at.region = Rect2(0.0, 0.0, float(info["w"]), float(info["h"]))
	return at


# ---------------------------------------------------------------
# Coleccion de Pokemon
# ---------------------------------------------------------------
func _build_dex() -> void:
	var s: Control = _screen("dex")
	var row := HBoxContainer.new()
	s.add_child(row)
	var dp := PanelContainer.new()
	dp.custom_minimum_size = Vector2(360, 0)
	row.add_child(dp)
	dex_detail = VBoxContainer.new()
	dp.add_child(dex_detail)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(right)
	var filters := HFlowContainer.new()
	filters.add_theme_constant_override("h_separation", 6)
	right.add_child(filters)
	var names := ["Todas"]
	for i in range(9):
		names.append("%d · %s" % [i + 1, L.t(SV.REGIONS[i])])
	for i in range(names.size()):
		var gi: int = i
		var b := _btn(String(names[i]), func(): dex_gen = gi; dex_page = 0; _refresh_dex(), Vector2(0, 40))
		b.add_theme_font_size_override("font_size", 16)
		filters.add_child(b)
	var own := CheckButton.new()
	own.text = "Solo los míos"
	own.add_theme_font_size_override("font_size", 18)
	own.toggled.connect(func(on: bool): dex_only_owned = on; dex_page = 0; _refresh_dex())
	filters.add_child(own)
	dex_grid = GridContainer.new()
	dex_grid.columns = 6
	dex_grid.add_theme_constant_override("h_separation", 6)
	dex_grid.add_theme_constant_override("v_separation", 6)
	right.add_child(dex_grid)
	var nav := HBoxContainer.new()
	nav.alignment = BoxContainer.ALIGNMENT_CENTER
	right.add_child(nav)
	nav.add_child(_btn("◀", func(): dex_page = maxi(0, dex_page - 1); _refresh_dex(), Vector2(80, 44)))
	dex_page_lbl = _label("", 22)
	dex_page_lbl.custom_minimum_size = Vector2(220, 0)
	dex_page_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nav.add_child(dex_page_lbl)
	nav.add_child(_btn("▶", func(): dex_page += 1; _refresh_dex(), Vector2(80, 44)))


func _dex_filtered() -> Array:
	var out: Array = []
	for p in SV.dex_list:
		if dex_gen != 0 and int(p["gen"]) != dex_gen:
			continue
		if dex_only_owned and not SV.owns(int(p["dex"])):
			continue
		if not SV.smeta.has(str(int(p["dex"]))):
			continue
		out.append(p)
	return out


func _refresh_dex() -> void:
	var list: Array = _dex_filtered()
	var pages: int = maxi(1, ceili(float(list.size()) / float(PER_PAGE)))
	dex_page = clampi(dex_page, 0, pages - 1)
	_clear(dex_grid)
	var first: Button = null
	for i in range(dex_page * PER_PAGE, mini(list.size(), (dex_page + 1) * PER_PAGE)):
		var p: Dictionary = list[i]
		var dx: int = int(p["dex"])
		var owned: bool = SV.owns(dx)
		var b := Button.new()
		b.custom_minimum_size = Vector2(118, 96)
		b.focus_mode = Control.FOCUS_ALL
		var shn: bool = owned and bool(SV.d["owned"][str(dx)]["shiny"]) and bool(SV.d["shiny_on"])
		var tx: Texture2D = _icon_tex(dx, shn)
		if tx != null:
			b.icon = tx
			b.expand_icon = true
			b.add_theme_constant_override("icon_max_width", 48)
		b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		b.text = ("#%d %s" % [dx, String(p["name"])]) if owned else "#%d ???" % dx
		b.add_theme_font_size_override("font_size", 13)
		if not owned:
			for k in ["icon_normal_color", "icon_hover_color", "icon_pressed_color", "icon_focus_color"]:
				b.add_theme_color_override(k, Color(0, 0, 0, 0.85))
		if dx == int(SV.d["selected"]):
			b.add_theme_stylebox_override("normal", _sb(Color("#3a6a2e"), C_GOLD, 3))
		b.pressed.connect(func(): dex_sel = dx; _dex_detail())
		dex_grid.add_child(b)
		if first == null:
			first = b
	dex_page_lbl.text = L.t("Página %d / %d  (%d)") % [dex_page + 1, pages, list.size()]
	if not SV.dex_by.has(dex_sel) or not SV.owns(dex_sel):
		dex_sel = int(SV.d["selected"])
	_dex_detail()
	focus_first = first


func _dex_detail() -> void:
	_clear(dex_detail)
	var dx: int = dex_sel
	var p: Dictionary = SV.dex_by[dx]
	var owned: bool = SV.owns(dx)
	var pv := Preview.new()
	pv.custom_minimum_size = Vector2(0, 200)
	dex_detail.add_child(pv)
	var shiny_owned: bool = owned and bool(SV.d["owned"][str(dx)]["shiny"])
	pv.setup(dx, shiny_owned and bool(SV.d["shiny_on"]), 5.0, not owned)
	if not owned:
		dex_detail.add_child(_label("#%d  ???" % dx, 28))
		dex_detail.add_child(_label(L.t("Aún no lo tienes. Consíguelo en el Gacha (región %d · %s).") % [int(p["gen"]), L.t(SV.REGIONS[int(p["gen"]) - 1])], 20, Color("#c8d6ee")))
		return
	dex_detail.add_child(_label("#%d  %s" % [dx, String(p["name"])], 30, C_GOLD))
	var trow := HBoxContainer.new()
	trow.add_theme_constant_override("separation", 6)
	for t in SV.dex_by[dx]["types"]:
		trow.add_child(IC.rect("type:" + String(t), 32))
	var tlb := _label(_type_text(dx), 22)
	tlb.autowrap_mode = TextServer.AUTOWRAP_OFF
	trow.add_child(tlb)
	dex_detail.add_child(trow)
	dex_detail.add_child(_label(L.t("PS %d · Velocidad %d · Ataque x%.2f") % [int(p["hp"]), int(p["spd"]), float(p["atk"])], 18, Color("#c8d6ee")))
	var mv: String = SV.start_move_of(dx)
	dex_detail.add_child(_icon_label("move:" + mv, L.t("Movimiento inicial: %s") % L.t(String(MD.MOVES[mv]["name"])), 18, Color("#c8d6ee"), 32.0))
	dex_detail.add_child(_label(L.t("Rareza: %s · Tenido x%d") % [L.t(SV.RARITY_NAME[clampi(int(p["rarity"]) - 1, 0, 4)]), int(SV.d["owned"][str(dx)]["n"])], 16, Color("#9fb4f0")))
	if shiny_owned:
		var cb := CheckButton.new()
		cb.text = "Usar versión shiny ✨"
		cb.button_pressed = bool(SV.d["shiny_on"])
		cb.toggled.connect(func(on: bool): SV.d["shiny_on"] = on; SV.save(); _refresh_dex())
		dex_detail.add_child(cb)
	var sel_b: Button
	if dx == int(SV.d["selected"]):
		sel_b = _btn("✔ Es tu compañero", func(): pass, Vector2(0, 54))
		sel_b.disabled = true
	else:
		sel_b = _btn("Elegir", func(): SV.d["selected"] = dx; SV.save(); toast(L.t("Compañero: %s") % _name_of(dx)); _refresh_dex(), Vector2(0, 54))
	dex_detail.add_child(sel_b)


# ---------------------------------------------------------------
# Mejoras permanentes
# ---------------------------------------------------------------
func _build_up() -> void:
	var s: Control = _screen("up")
	var pc := PanelContainer.new()
	s.add_child(pc)
	var v := VBoxContainer.new()
	pc.add_child(v)
	v.add_child(_label("Mejoras permanentes", 32, C_GOLD))
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(sc)
	up_box = VBoxContainer.new()
	up_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(up_box)


const UP_ICON := {"hp": "heart", "atk": "fist", "spd": "boot", "cd": "clock", "def": "shield", "regen": "sprout", "magnet": "magnet", "xp": "book", "coins": "coin", "moves": "cards", "crit": "star", "reroll": "bond", "ban": "ban"}


func _refresh_up() -> void:
	_clear(up_box)
	var first: Button = null
	for u in SV.UPGRADES:
		var id: String = String(u["id"])
		var lv: int = SV.up_level(id)
		var mx: int = int(u["max"])
		var row := HBoxContainer.new()
		up_box.add_child(row)
		var uic := IC.rect(String(UP_ICON.get(id, "star")), 36)
		uic.custom_minimum_size.x = 48
		row.add_child(uic)
		var nm := _label(String(u["name"]), 24)
		nm.custom_minimum_size = Vector2(200, 0)
		row.add_child(nm)
		var ds := _label(String(u["unit"]), 18, Color("#c8d6ee"))
		ds.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(ds)
		var lb := _label(L.t("Nv. %d/%d") % [lv, mx], 22, C_GOLD)
		lb.custom_minimum_size = Vector2(110, 0)
		row.add_child(lb)
		var b: Button
		if lv >= mx:
			b = _btn("Máximo", func(): pass, Vector2(170, 46))
			b.disabled = true
		else:
			var cost: int = SV.up_cost(id, lv)
			b = _cost_btn(L.t("Comprar"), str(cost), "", "coin", func(): _buy(id), Vector2(170, 46), int(SV.d["coins"]) >= cost)
		row.add_child(b)
		if first == null and not b.disabled:
			first = b
	focus_first = first


func _buy(id: String) -> void:
	if SV.buy_upgrade(id):
		Aud.sfx("buy")
		toast("¡Mejora comprada!")
	else:
		Aud.sfx("error")
	_update_top()
	_refresh_up()


# ---------------------------------------------------------------
# Gacha
# ---------------------------------------------------------------
func _build_gacha() -> void:
	var s: Control = _screen("gacha")
	var pc := PanelContainer.new()
	s.add_child(pc)
	gacha_box = VBoxContainer.new()
	pc.add_child(gacha_box)
	gacha_result = ColorRect.new()
	gacha_result.color = Color(0, 0, 0, 0.7)
	gacha_result.set_anchors_preset(Control.PRESET_FULL_RECT)
	gacha_result.z_index = 30
	gacha_result.visible = false
	add_child(gacha_result)


func _region_counts(region: int) -> Vector2i:
	var pool: Array = SV.region_pool(region)
	var n := 0
	for p in pool:
		if SV.owns(int(p["dex"])):
			n += 1
	return Vector2i(n, pool.size())


func _refresh_gacha() -> void:
	_clear(gacha_box)
	gacha_box.add_child(_label("Gacha · 9 regiones", 32, C_GOLD))
	var grid := GridContainer.new()
	grid.columns = 3
	gacha_box.add_child(grid)
	var first: Button = null
	for i in range(1, 10):
		var r: int = i
		var cnt: Vector2i = _region_counts(r)
		var b := _btn("%d · %s   %d/%d" % [r, L.t(SV.REGIONS[r - 1]), cnt.x, cnt.y], func(): gacha_region = r; _refresh_gacha(), Vector2(0, 50))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if r == gacha_region:
			b.add_theme_stylebox_override("normal", _sb(Color("#3a6a2e"), C_GOLD, 3))
		grid.add_child(b)
		if r == gacha_region:
			first = b
	gacha_box.add_child(_label(L.t("Región elegida: %s. Los Pokémon repetidos te devuelven monedas; un shiny sale 1 de cada 32 tiradas.\nProbabilidades: Común 40%% · Poco común 30%% · Raro 18%% · Muy raro 9%% · Legendario 3%%.") % L.t(SV.REGIONS[gacha_region - 1]), 18, Color("#c8d6ee")))
	var row := HBoxContainer.new()
	gacha_box.add_child(row)
	var b1 := _cost_btn(L.t("Tirada ×1"), str(SV.PULL_COST), "ball", "coin", func(): _do_pull(1, "coins"), Vector2(0, 80), int(SV.d["coins"]) >= SV.PULL_COST, true)
	var b10 := _cost_btn(L.t("Tirada ×10"), str(SV.PULL10_COST), "ballLux", "coin", func(): _do_pull(10, "coins"), Vector2(0, 80), int(SV.d["coins"]) >= SV.PULL10_COST, true)
	var bt := _cost_btn(L.t("Con ticket"), "1", "ticket10", "ticket", func(): _do_pull(1, "ticket"), Vector2(0, 80), int(SV.d["tickets"]) >= 1, true)
	for b in [b1, b10, bt]:
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(b)
	focus_first = first


func _do_pull(n: int, pay: String) -> void:
	if pay == "ticket":
		if int(SV.d["tickets"]) < 1:
			return
		SV.d["tickets"] = int(SV.d["tickets"]) - 1
	else:
		var cost: int = SV.PULL_COST if n == 1 else SV.PULL10_COST
		if int(SV.d["coins"]) < cost:
			return
		SV.d["coins"] = int(SV.d["coins"]) - cost
	var results: Array = []
	for i in range(n):
		results.append(SV.pull(gacha_region))
	SV.save()
	_update_top()
	var best := 1
	var anyshiny := false
	for r in results:
		best = maxi(best, clampi(int(r.get("rarity", 1)), 1, 5))
		anyshiny = anyshiny or bool(r["shiny"])
	Aud.sfx("burst%d" % best)
	if anyshiny:
		Aud.sfx("shinyGet")
	_show_pulls(results)


func _show_pulls(results: Array) -> void:
	_clear(gacha_result)
	var c := CenterContainer.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	gacha_result.add_child(c)
	var pc := PanelContainer.new()
	c.add_child(pc)
	var v := VBoxContainer.new()
	pc.add_child(v)
	v.add_child(_label("¡Resultado!", 32, C_GOLD))
	var grid := GridContainer.new()
	grid.columns = 5 if results.size() > 1 else 1
	v.add_child(grid)
	for r in results:
		var cell := VBoxContainer.new()
		cell.custom_minimum_size = Vector2(150, 0)
		grid.add_child(cell)
		var pv := Preview.new()
		pv.custom_minimum_size = Vector2(150, 110)
		cell.add_child(pv)
		pv.setup(int(r["dex"]), bool(r["shiny"]), 3.0)
		var nm := _label(String(r["name"]) + (" ✨" if bool(r["shiny"]) else ""), 18)
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cell.add_child(nm)
		if bool(r["new"]) or int(r["refund"]) <= 0:
			var tag := "¡NUEVO!" if bool(r["new"]) else "Shiny"
			var tl := _label(tag, 16, Color("#5fe08a") if bool(r["new"]) else Color("#ffd23f"))
			tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			cell.add_child(tl)
		else:
			var rf := _icon_label("coin", "+%d" % int(r["refund"]), 16, Color("#ffd23f"), 24.0)
			rf.alignment = BoxContainer.ALIGNMENT_CENTER
			cell.add_child(rf)
		var rar: int = clampi(int(r["rarity"]), 1, 5)
		var rl := _icon_label(String(["ball", "ball2", "ball3", "ball4", "ballLux"][rar - 1]), SV.RARITY_NAME[rar - 1], 14, Color("#9fb4f0"), 24.0)
		rl.alignment = BoxContainer.ALIGNMENT_CENTER
		cell.add_child(rl)
	var ok := _btn("Aceptar", func(): gacha_result.visible = false; _refresh_gacha(), Vector2(0, 54))
	v.add_child(ok)
	gacha_result.visible = true
	_gf(ok)


# ---------------------------------------------------------------
# Misiones y logros
# ---------------------------------------------------------------
func _build_goals() -> void:
	var s: Control = _screen("goals")
	var pc := PanelContainer.new()
	s.add_child(pc)
	var v := VBoxContainer.new()
	pc.add_child(v)
	var tabs := HBoxContainer.new()
	v.add_child(tabs)
	tabs.add_child(_btn("Misiones", func(): goals_tab = "m"; _refresh_goals(), Vector2(200, 46)))
	tabs.add_child(_btn("Logros", func(): goals_tab = "a"; _refresh_goals(), Vector2(200, 46)))
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(sc)
	goals_box = VBoxContainer.new()
	goals_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(goals_box)


func _refresh_goals() -> void:
	_clear(goals_box)
	var first: Button = null
	for g in SV.GOALS:
		if String(g["kind"]) != goals_tab:
			continue
		var gd: Dictionary = g
		var row := HBoxContainer.new()
		goals_box.add_child(row)
		var gic := IC.rect("flag" if goals_tab == "m" else "trophy", 36)
		gic.custom_minimum_size.x = 48
		row.add_child(gic)
		var col := VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(col)
		col.add_child(_label(String(g["text"]), 22))
		var pb := ProgressBar.new()
		pb.max_value = float(g["target"])
		pb.value = minf(float(SV.stat_value(String(g["stat"]))), float(g["target"]))
		pb.custom_minimum_size = Vector2(0, 16)
		pb.show_percentage = false
		col.add_child(pb)
		var rw := HBoxContainer.new()
		rw.custom_minimum_size = Vector2(150, 0)
		rw.add_theme_constant_override("separation", 6)
		rw.add_child(IC.rect("coin", 24))
		var rwl := _label("%d" % int(g["coins"]), 20, C_GOLD)
		rwl.autowrap_mode = TextServer.AUTOWRAP_OFF
		rw.add_child(rwl)
		if int(g["tickets"]) > 0:
			rw.add_child(IC.rect("ticket", 24))
			var rtl := _label("%d" % int(g["tickets"]), 20, Color("#ff8ad8"))
			rtl.autowrap_mode = TextServer.AUTOWRAP_OFF
			rw.add_child(rtl)
		row.add_child(rw)
		var b: Button
		if SV.goal_claimed(g):
			b = _btn("Reclamado", func(): pass, Vector2(160, 46))
			b.disabled = true
		elif SV.goal_done(g):
			b = _btn("¡Reclamar!", func(): _claim(gd), Vector2(160, 46))
			if first == null:
				first = b
		else:
			b = _btn("%d / %d" % [mini(SV.stat_value(String(g["stat"])), int(g["target"])), int(g["target"])], func(): pass, Vector2(160, 46))
			b.disabled = true
		row.add_child(b)
	focus_first = first


func _claim(g: Dictionary) -> void:
	if SV.claim_goal(g):
		Aud.sfx("buy")
		toast("¡Recompensa reclamada!")
	_update_top()
	_refresh_goals()


# ---------------------------------------------------------------
# Ajustes
# ---------------------------------------------------------------
func _build_settings() -> void:
	var s: Control = _screen("settings")
	var pc := PanelContainer.new()
	s.add_child(pc)
	settings_box = VBoxContainer.new()
	pc.add_child(settings_box)


func _slider_row(label: String, key: String) -> void:
	var row := HBoxContainer.new()
	settings_box.add_child(row)
	var sic := IC.rect("sound", 28)
	sic.custom_minimum_size.x = 40
	row.add_child(sic)
	var l := _label(label, 22)
	l.custom_minimum_size = Vector2(240, 0)
	row.add_child(l)
	var sl := HSlider.new()
	sl.min_value = 0
	sl.max_value = 100
	sl.step = 5
	sl.value = float(SV.d["settings"][key])
	sl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sl.custom_minimum_size = Vector2(0, 40)
	sl.focus_mode = Control.FOCUS_ALL
	sl.value_changed.connect(func(v: float):
		SV.d["settings"][key] = int(v)
		SV.save()
		if Aud.inst != null:
			Aud.inst.apply()
		if key == "sfx":
			Aud.sfx("coin"))
	row.add_child(sl)


func _check_row(label: String, key: String) -> void:
	var cb := CheckButton.new()
	cb.text = label
	cb.button_pressed = bool(SV.d["settings"][key])
	cb.add_theme_font_size_override("font_size", 22)
	cb.toggled.connect(func(on: bool): SV.d["settings"][key] = on; SV.save())
	settings_box.add_child(cb)


func _refresh_settings() -> void:
	reset_armed = false
	_clear(settings_box)
	settings_box.add_child(_label("Ajustes", 32, C_GOLD))
	_slider_row("Volumen general", "master")
	_slider_row("Música", "music")
	_slider_row("Efectos", "sfx")
	_check_row("Mostrar números de daño", "dmg_numbers")
	_check_row("Vibración", "vibration")
	_check_row("Sacudida de pantalla", "shake")
	var sizes := ["Pequeño", "Mediano", "Grande"]
	var sb := _btn(L.t("Tamaño del joystick táctil: %s") % L.t(sizes[clampi(int(SV.d["settings"]["stick"]), 0, 2)]), func(): pass, Vector2(0, 50))
	sb.pressed.connect(func(): SV.d["settings"]["stick"] = (int(SV.d["settings"]["stick"]) + 1) % 3; SV.save(); _refresh_settings())
	settings_box.add_child(sb)
	var lb := _btn(L.t("Idioma: %s") % ("English" if L.is_en() else "Español"), func(): pass, Vector2(0, 50))
	lb.pressed.connect(func():
		SV.d["settings"]["lang"] = "es" if L.is_en() else "en"
		SV.save()
		L.apply()
		SV.reopen = "settings"
		get_tree().reload_current_scene())
	settings_box.add_child(lb)
	var rb := _btn("Borrar todo el progreso", func(): pass, Vector2(0, 50))
	rb.pressed.connect(func():
		if not reset_armed:
			reset_armed = true
			rb.text = "¿Seguro? Pulsa otra vez para borrar TODO"
		else:
			SV.reset_all()
			_show("test"))
	settings_box.add_child(rb)
	focus_first = sb
