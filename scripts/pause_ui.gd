extends CanvasLayer
# Menu de pausa como el del juego original: titulo, ayuda de controles, volumen de
# musica y efectos, silenciar y tres botones. Los controles son los del mando elegido.

const NAVG = preload("res://scripts/navgrid.gd")
const SV = preload("res://scripts/save_data.gd")
const PAD = preload("res://scripts/pad.gd")
const PADI = preload("res://scripts/padicons.gd")
const IC = preload("res://scripts/icons.gd")
const L = preload("res://scripts/lang.gd")
const Aud = preload("res://scripts/audio.gd")
const PXF = preload("res://scripts/pxfont.gd")
const DSP = preload("res://scripts/display.gd")

signal resume
signal quit_run
signal open_settings
signal fov_changed(pct: int)
signal stick_fixed_changed(on: bool)

const GOLD := Color("#ffd23f")
var th := Theme.new()
var cont_btn: Button
var mute_btn: Button
var hint_row: HBoxContainer
var cc: CenterContainer
var pc: PanelContainer
var sc: ScrollContainer
var vbox: VBoxContainer


func _init() -> void:
	layer = 90
	visible = false


static func _sb(bg: Color, border: Color, bw: int, radius: int, shadow: int = 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(bw)
	s.set_corner_radius_all(radius)
	s.content_margin_left = 16
	s.content_margin_right = 16
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	if shadow > 0:
		s.shadow_color = Color("#0b1838")
		s.shadow_size = shadow
	return s


func _label(t: String, size: int, col: Color = Color.WHITE) -> Label:
	var l := Label.new()
	l.text = L.t(t)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _btn(text: String, gold: bool, cb: Callable) -> Button:
	var b := Button.new()
	b.text = L.t(text)
	b.custom_minimum_size = Vector2(210, 72)
	b.add_theme_font_size_override("font_size", 28)
	b.focus_mode = Control.FOCUS_ALL
	var bg: Color = Color("#f6b52b") if gold else Color("#2b4f9e")
	var bgh: Color = Color("#ffcf55") if gold else Color("#3a64bf")
	var fc: Color = Color("#3d2a00") if gold else Color.WHITE
	b.add_theme_stylebox_override("normal", _sb(bg, Color.WHITE, 3, 12, 3))
	b.add_theme_stylebox_override("hover", _sb(bgh, Color.WHITE, 3, 12, 3))
	b.add_theme_stylebox_override("pressed", _sb(bg.darkened(0.2), Color.WHITE, 3, 12, 3))
	b.add_theme_stylebox_override("focus", _sb(bgh, GOLD if not gold else Color("#fff2a0"), 5, 12, 3))
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(c, fc)
	b.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.0) if gold else Color("#0b1838"))
	b.pressed.connect(cb)
	return b


func _knob() -> Texture2D:
	var img := Image.create(26, 26, false, Image.FORMAT_RGBA8)
	img.fill(Color("#0b1838"))
	for y in range(3, 23):
		for x in range(3, 23):
			img.set_pixel(x, y, Color("#ffd23f") if y < 14 else Color("#f0a31e"))
	for y in range(3, 6):
		for x in range(3, 23):
			img.set_pixel(x, y, Color("#fff2a0"))
	return ImageTexture.create_from_image(img)


func build() -> void:
	PXF.apply(th)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.theme = th
	add_child(root)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.04, 0.12, 0.62)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)
	cc = CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(cc)
	pc = PanelContainer.new()
	pc.add_theme_stylebox_override("panel", _sb(Color("#27489a"), Color("#f4f8ff"), 3, 14, 6))
	cc.add_child(pc)
	# El contenido va en un ScrollContainer: si el panel no cabe en la vista visible (zoom 140 %,
	# pantalla 16:9, margenes seguros) se desplaza y el foco del mando lo trae a la vista.
	sc = ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	sc.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	sc.follow_focus = true
	pc.add_child(sc)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	v.custom_minimum_size = Vector2(700, 0)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(v)
	vbox = v
	var title := _label("Pausa", 52)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	hint_row = HBoxContainer.new()
	hint_row.alignment = BoxContainer.ALIGNMENT_CENTER
	hint_row.add_theme_constant_override("separation", 8)
	v.add_child(hint_row)
	v.add_child(_slider_row("Música", "music"))
	v.add_child(_slider_row("Efectos", "sfx"))
	v.add_child(_fov_row())
	v.add_child(_stick_row())
	v.add_child(_aim_row())
	var mrow := HBoxContainer.new()
	mrow.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(mrow)
	mute_btn = _btn("Silenciar", true, _toggle_mute)
	mute_btn.custom_minimum_size = Vector2(190, 58)
	mute_btn.add_theme_font_size_override("font_size", 24)
	mrow.add_child(mute_btn)
	txt_btn = _btn("Texto: Normal", false, _cycle_text)
	txt_btn.custom_minimum_size = Vector2(250, 58)
	txt_btn.add_theme_font_size_override("font_size", 24)
	mrow.add_child(txt_btn)
	var brow := HBoxContainer.new()
	brow.alignment = BoxContainer.ALIGNMENT_CENTER
	brow.add_theme_constant_override("separation", 18)
	v.add_child(brow)
	cont_btn = _btn("Continuar", true, func(): resume.emit())
	brow.add_child(cont_btn)
	brow.add_child(_btn("Resumen", false, func(): summary_requested.emit()))
	brow.add_child(_btn("Ajustes", false, func(): open_settings.emit()))
	brow.add_child(_btn("Abandonar partida", false, func(): quit_run.emit()))
	_build_summary(root)
	get_viewport().size_changed.connect(_fit)
	v.minimum_size_changed.connect(_fit_later)
	_fit()


func _fit_later() -> void:
	_fit.call_deferred()


# Recoloca el panel dentro de la zona visible (rect visible - margenes seguros) y limita su tamano.
func _fit() -> void:
	if cc == null or not is_inside_tree():
		return
	DSP.fit_to_safe(get_tree(), cc)
	var sb: StyleBox = pc.get_theme_stylebox("panel")
	DSP.fit_scroll(get_tree(), sc, vbox, sb.get_minimum_size() + Vector2(6, 6), 6.0)


func _slider_row(label: String, key: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	var sic := IC.rect("sound", 30)
	sic.custom_minimum_size.x = 44
	row.add_child(sic)
	var l := _label(label, 24)
	l.custom_minimum_size = Vector2(120, 0)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(l)
	var sl := HSlider.new()
	sl.min_value = 0
	sl.max_value = 100
	sl.step = 5
	sl.value = float(SV.d["settings"][key])
	sl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sl.custom_minimum_size = Vector2(360, 40)
	sl.focus_mode = Control.FOCUS_ALL
	var track := _sb(Color("#14285a"), Color.TRANSPARENT, 0, 7)
	track.content_margin_top = 7
	track.content_margin_bottom = 7
	sl.add_theme_stylebox_override("slider", track)
	sl.add_theme_stylebox_override("grabber_area", track)
	sl.add_theme_stylebox_override("grabber_area_highlight", track)
	var kn: Texture2D = _knob()
	sl.add_theme_icon_override("grabber", kn)
	sl.add_theme_icon_override("grabber_highlight", kn)
	sl.add_theme_icon_override("grabber_disabled", kn)
	sl.value_changed.connect(func(val: float):
		SV.d["settings"][key] = int(val)
		SV.save()
		if Aud.inst != null:
			Aud.inst.apply()
		if key == "sfx":
			Aud.sfx("coin"))
	row.add_child(sl)
	return row


# Campo de vision: acerca/aleja la camara (100-200 %). Se guarda y se aplica al instante.
func _fov_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	var gap := Control.new()
	gap.custom_minimum_size.x = 44
	row.add_child(gap)
	var l := _label("Visión", 24)
	l.custom_minimum_size = Vector2(120, 0)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(l)
	var sl := HSlider.new()
	sl.min_value = 100
	sl.max_value = 200
	sl.step = 5
	sl.value = float(clampi(int(SV.d["settings"].get("fov", 165)), 100, 200))
	sl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sl.custom_minimum_size = Vector2(300, 40)
	sl.focus_mode = Control.FOCUS_ALL
	var track := _sb(Color("#14285a"), Color.TRANSPARENT, 0, 7)
	track.content_margin_top = 7
	track.content_margin_bottom = 7
	sl.add_theme_stylebox_override("slider", track)
	sl.add_theme_stylebox_override("grabber_area", track)
	sl.add_theme_stylebox_override("grabber_area_highlight", track)
	var kn: Texture2D = _knob()
	sl.add_theme_icon_override("grabber", kn)
	sl.add_theme_icon_override("grabber_highlight", kn)
	sl.add_theme_icon_override("grabber_disabled", kn)
	row.add_child(sl)
	var pl := _label("%d%%" % int(sl.value), 22, GOLD)
	pl.custom_minimum_size = Vector2(64, 0)
	row.add_child(pl)
	sl.value_changed.connect(func(val: float):
		SV.d["settings"]["fov"] = int(val)
		SV.save()
		pl.text = "%d%%" % int(val)
		fov_changed.emit(int(val)))
	return row


# Joystick fijo: lo deja siempre abajo a la izquierda (o flotante donde toques).
func _stick_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	var gap := Control.new()
	gap.custom_minimum_size.x = 44
	row.add_child(gap)
	var l := _label("Joystick fijo", 24)
	l.custom_minimum_size = Vector2(190, 0)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(l)
	var on: bool = bool(SV.d["settings"].get("stick_fixed", false))
	var b := _btn("Sí" if on else "No", on, func(): pass)
	b.custom_minimum_size = Vector2(120, 48)
	b.add_theme_font_size_override("font_size", 22)
	b.pressed.connect(func():
		var nv: bool = not bool(SV.d["settings"].get("stick_fixed", false))
		SV.d["settings"]["stick_fixed"] = nv
		SV.save()
		b.text = L.t("Sí") if nv else L.t("No")
		_style_toggle(b, nv)
		stick_fixed_changed.emit(nv))
	row.add_child(b)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(sp)
	return row


func _style_toggle(b: Button, on: bool) -> void:
	var bg: Color = Color("#f6b52b") if on else Color("#2b4f9e")
	var bgh: Color = Color("#ffcf55") if on else Color("#3a64bf")
	var fc: Color = Color("#3d2a00") if on else Color.WHITE
	b.add_theme_stylebox_override("normal", _sb(bg, Color.WHITE, 3, 12, 3))
	b.add_theme_stylebox_override("hover", _sb(bgh, Color.WHITE, 3, 12, 3))
	b.add_theme_stylebox_override("pressed", _sb(bg.darkened(0.2), Color.WHITE, 3, 12, 3))
	b.add_theme_stylebox_override("focus", _sb(bgh, GOLD if not on else Color("#fff2a0"), 5, 12, 3))
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(c, fc)


func _toggle_mute() -> void:
	SV.d["settings"]["mute"] = not bool(SV.d["settings"].get("mute", false))
	SV.save()
	if Aud.inst != null:
		Aud.inst.apply()
	_refresh_mute()


func _refresh_mute() -> void:
	mute_btn.text = L.t("Activar sonido") if bool(SV.d["settings"].get("mute", false)) else L.t("Silenciar")


func _badge(t: String) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _sb(Color(0, 0, 0, 0.12), Color(0.96, 0.97, 1.0, 0.35), 2, 7))
	var sb: StyleBoxFlat = p.get_theme_stylebox("panel")
	sb.content_margin_top = 2
	sb.content_margin_bottom = 2
	sb.content_margin_left = 9
	sb.content_margin_right = 9
	p.add_child(_label(t, 19, Color("#e8f0ff")))
	return p


func _txt(t: String) -> Label:
	var l := _label(t, 19, Color("#b9cbf0"))
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return l


# Ayuda de controles segun el mando elegido (Xbox, PlayStation o Nintendo).
func _refresh_hints() -> void:
	for c in hint_row.get_children():
		c.queue_free()
	hint_row.add_child(PADI.rect(7, 30.0))
	hint_row.add_child(_txt("mover"))
	hint_row.add_child(_txt("·"))
	hint_row.add_child(PADI.rect(PAD.btn("prev"), 30.0))
	hint_row.add_child(_txt("/"))
	hint_row.add_child(PADI.rect(PAD.btn("next"), 30.0))
	hint_row.add_child(_txt("cambiar"))
	hint_row.add_child(_txt("·"))
	hint_row.add_child(PADI.rect(PAD.btn("pause"), 30.0))
	hint_row.add_child(_txt("pausa"))


# Mismo manejo del mando que el menu principal: filas, ciclo izquierda/derecha y columna recordada.
func _input(event: InputEvent) -> void:
	if not visible:
		return
	if sum_root != null and sum_root.visible and (event.is_action_pressed("ui_cancel") or (event is InputEventJoypadButton and event.pressed and event.button_index == PAD.btn("cancel"))):
		hide_summary()
		get_viewport().set_input_as_handled()
		return
	if sum_root != null and sum_root.visible:
		if PAD.stick_event(event):
			get_viewport().set_input_as_handled()
			return
		if event.is_action_pressed("ui_down", true) or event.is_action_pressed("ui_up", true):
			sum_sc.scroll_vertical += 150 if event.is_action_pressed("ui_down", true) else -150
			get_viewport().set_input_as_handled()
		return
	if PAD.stick_event(event):
		get_viewport().set_input_as_handled()
		return
	if NAVG.move(get_viewport(), event, NAVG.focusables(self)):
		get_viewport().set_input_as_handled()
		return
	# Primer / ultimo control pero aun queda contenido por ese lado: se desplaza (el foco se queda)
	var down: bool = event.is_action_pressed("ui_down", true)
	if down or event.is_action_pressed("ui_up", true):
		var f: Control = get_viewport().gui_get_focus_owner()
		if f != null and sc.is_ancestor_of(f):
			var v: int = sc.scroll_vertical
			sc.scroll_vertical = v + int(maxf(60.0, sc.size.y / 3.0)) * (1 if down else -1)
			if sc.scroll_vertical != v:
				get_viewport().set_input_as_handled()


func open() -> void:
	_refresh_text_btn()
	TXS.scale_tree(self)
	if aim_btn != null:
		var on: bool = bool(SV.d["settings"].get("manual_aim", false))
		aim_btn.text = L.t("Sí") if on else L.t("No")
		_style_toggle(aim_btn, on)
	_refresh_hints()
	sc.scroll_vertical = 0
	_fit()
	_refresh_mute()
	visible = true
	cont_btn.call_deferred("grab_focus")


func close() -> void:
	visible = false

const TXS = preload("res://scripts/textscale.gd")

signal summary_requested

var txt_btn: Button

var sum_root: Control

var sum_box: VBoxContainer

var sum_back: Button

var sum_sc: ScrollContainer

func _build_summary(root: Control) -> void :
	sum_root = Control.new()
	sum_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	sum_root.visible = false
	root.add_child(sum_root)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.04, 0.12, 0.88)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	sum_root.add_child(dim)
	var m := MarginContainer.new()
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	for k in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + k, 40)
	sum_root.add_child(m)
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", _sb(Color("#27489a"), Color("#f4f8ff"), 3, 14, 6))
	m.add_child(pc)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	pc.add_child(v)
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sum_sc = sc
	v.add_child(sc)
	sum_box = VBoxContainer.new()
	sum_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sum_box.add_theme_constant_override("separation", 6)
	sc.add_child(sum_box)
	sum_back = _btn("Volver", true, func(): hide_summary())
	sum_back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(sum_back)

func hide_summary() -> void :
	sum_root.visible = false
	cont_btn.grab_focus()

func _tile(label: String, value: String, accent: Color) -> PanelContainer:
	var pc := PanelContainer.new()
	var sb := _sb(Color("#1b3274"), accent, 0, 10)
	sb.border_width_left = 5
	sb.border_color = accent
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	pc.add_theme_stylebox_override("panel", sb)
	pc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	pc.add_child(v)
	var a := _label(label, 15, Color("#9fb4dc"))
	a.text = label
	v.add_child(a)
	var b := _label(value, 25, Color.WHITE)
	b.text = value
	v.add_child(b)
	return pc

func _pill(txt: String, col: Color, icon: Control = null) -> PanelContainer:
	var pc := PanelContainer.new()
	var sb := _sb(col.darkened(0.55), col, 2, 14)
	sb.content_margin_top = 3
	sb.content_margin_bottom = 3
	sb.content_margin_left = 10
	sb.content_margin_right = 12
	pc.add_theme_stylebox_override("panel", sb)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	pc.add_child(h)
	if icon != null:
		h.add_child(icon)
	var l := _label(txt, 18)
	l.text = txt
	h.add_child(l)
	return pc

func _sec_title(txt: String) -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	var l := _label(txt, 26, GOLD)
	h.add_child(l)
	var line := ColorRect.new()
	line.color = Color(1, 0.82, 0.25, 0.45)
	line.custom_minimum_size = Vector2(0, 3)
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(line)
	return h

func show_summary(d: Dictionary) -> void :
	call_deferred("_scale_sum")
	for c in sum_box.get_children():
		sum_box.remove_child(c)
		c.queue_free()
	var t: int = int(d["time"])

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	sum_box.add_child(head)
	var tl := _label("Resumen de la partida", 38, GOLD)
	tl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(tl)
	head.add_child(_pill(String(d["pname"]), Color("#ff9a4d")))
	head.add_child(_pill("%s %d" % [L.t("Nivel"), int(d["level"])], Color("#5fe08a")))
	head.add_child(_pill("%02d:%02d" % [t / 60, t % 60], Color("#6ab7ff")))
	head.add_child(_pill("%s %d" % [L.t("Derrotas"), int(d["kills"])], Color("#ff6a7a")))
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 22)
	cols.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sum_box.add_child(cols)

	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_stretch_ratio = 1.0
	left.add_theme_constant_override("separation", 8)
	cols.add_child(left)
	left.add_child(_sec_title("Estadísticas"))
	var gs := GridContainer.new()
	gs.columns = 3
	gs.add_theme_constant_override("h_separation", 8)
	gs.add_theme_constant_override("v_separation", 8)
	left.add_child(gs)
	var accents := [Color("#ff6a7a"), Color("#ff9a4d"), Color("#6ab7ff"), Color("#ffd23f"), Color("#8fa3ff"), Color("#5fe08a"), Color("#c47bff")]
	var ai := 0
	for st in d["all"]:
		gs.add_child(_tile(String(st[0]), String(st[1]), accents[ai % accents.size()]))
		ai += 1

	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 8)
	cols.add_child(right)
	right.add_child(_sec_title("Movimientos"))
	var maxd := 1.0
	for mv in d["moves"]:
		maxd = maxf(maxd, float(mv["dps"]))
	for mv in d["moves"]:
		var col := Color(String(mv["col"]))
		var card := PanelContainer.new()
		var sb := _sb(Color("#1b3274"), col, 0, 10)
		sb.border_width_left = 6
		sb.border_color = col
		sb.content_margin_top = 6
		sb.content_margin_bottom = 8
		card.add_theme_stylebox_override("panel", sb)
		right.add_child(card)
		var cv := VBoxContainer.new()
		cv.add_theme_constant_override("separation", 3)
		card.add_child(cv)
		var top := HBoxContainer.new()
		top.add_theme_constant_override("separation", 8)
		cv.add_child(top)
		var nl := _label(String(mv["name"]), 22, Color.WHITE)
		nl.text = String(mv["name"])
		nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		top.add_child(nl)
		top.add_child(_pill("%s · %s %d" % [String(mv["type"]), L.t("Nv."), int(mv["lvl"])], col))
		var bar_bg := ColorRect.new()
		bar_bg.color = Color("#0f1e4d")
		bar_bg.custom_minimum_size = Vector2(0, 12)
		cv.add_child(bar_bg)
		var fill := ColorRect.new()
		fill.color = col
		fill.anchor_bottom = 1.0
		fill.anchor_right = clampf(float(mv["dps"]) / maxd, 0.0, 1.0)
		bar_bg.add_child(fill)
		var info := _label("DPS (%ds): %s   ·   %s: %d   ·   %s: %d" % [int(d["window"]), ("%.1f" % float(mv["dps"])) if int(mv["dmg"]) > 0 else "—", L.t("Daño total"), int(mv["dmg"]), L.t("Derrotas"), int(mv["kills"])], 17, Color("#c8d6ee"))
		info.text = "DPS (%ds): %s   ·   %s: %d   ·   %s: %d" % [int(d["window"]), ("%.1f" % float(mv["dps"])) if int(mv["dmg"]) > 0 else "—", L.t("Daño total"), int(mv["dmg"]), L.t("Derrotas"), int(mv["kills"])]
		cv.add_child(info)
	if not (d["stats"] as Array).is_empty():
		right.add_child(_sec_title("Mejoras"))
		var fl := HFlowContainer.new()
		fl.add_theme_constant_override("h_separation", 6)
		fl.add_theme_constant_override("v_separation", 6)
		right.add_child(fl)
		for st in d["stats"]:
			fl.add_child(_pill("%s %d" % [String(st["name"]), int(st["lv"])], Color("#ffd23f"), IC.rect(String(st["icon"]), 22)))
	if not (d["items"] as Array).is_empty():
		right.add_child(_sec_title("Objetos"))
		var fi := HFlowContainer.new()
		fi.add_theme_constant_override("h_separation", 6)
		right.add_child(fi)
		for it in d["items"]:
			fi.add_child(_pill(String(it["name"]), Color("#ff8ad8"), IC.rect(String(it["id"]), 22)))
	sum_root.visible = true
	sum_back.grab_focus()

var aim_btn: Button = null

func _aim_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	var gap := Control.new()
	gap.custom_minimum_size.x = 44
	row.add_child(gap)
	var l := _label("Apuntado manual", 24)
	l.custom_minimum_size = Vector2(190, 0)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(l)
	var on: bool = bool(SV.d["settings"].get("manual_aim", false))
	var b := _btn("Sí" if on else "No", on, func(): pass)
	b.custom_minimum_size = Vector2(120, 48)
	b.add_theme_font_size_override("font_size", 22)
	b.pressed.connect( func():
		var nv: bool = not bool(SV.d["settings"].get("manual_aim", false))
		SV.d["settings"]["manual_aim"] = nv
		SV.save()
		b.text = L.t("Sí") if nv else L.t("No")
		_style_toggle(b, nv))
	aim_btn = b
	row.add_child(b)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(sp)
	return row

func _process(_d: float) -> void :
	if visible:
		PAD.stick_tick()
	else:
		PAD.stick_reset()

func _cycle_text() -> void :
	TXS.set_idx((TXS.idx() + 1) % 3)
	_refresh_text_btn()
	TXS.scale_tree(self)

func _refresh_text_btn() -> void :
	if txt_btn != null:
		txt_btn.text = L.t("Texto") + ": " + L.t(String(TXS.NAMES[TXS.idx()]))

func _scale_sum() -> void :
	if sum_root != null:
		TXS.scale_tree(sum_root)
