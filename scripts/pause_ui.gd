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
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(cc)
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", _sb(Color("#27489a"), Color("#f4f8ff"), 3, 14, 6))
	cc.add_child(pc)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	v.custom_minimum_size = Vector2(700, 0)
	pc.add_child(v)
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
	var mrow := HBoxContainer.new()
	mrow.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(mrow)
	mute_btn = _btn("Silenciar", true, _toggle_mute)
	mute_btn.custom_minimum_size = Vector2(190, 58)
	mute_btn.add_theme_font_size_override("font_size", 24)
	mrow.add_child(mute_btn)
	var brow := HBoxContainer.new()
	brow.alignment = BoxContainer.ALIGNMENT_CENTER
	brow.add_theme_constant_override("separation", 18)
	v.add_child(brow)
	cont_btn = _btn("Continuar", true, func(): resume.emit())
	brow.add_child(cont_btn)
	brow.add_child(_btn("Ajustes", false, func(): open_settings.emit()))
	brow.add_child(_btn("Abandonar partida", false, func(): quit_run.emit()))


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
	if NAVG.move(get_viewport(), event, NAVG.focusables(self)):
		get_viewport().set_input_as_handled()


func open() -> void:
	_refresh_hints()
	_refresh_mute()
	visible = true
	cont_btn.call_deferred("grab_focus")


func close() -> void:
	visible = false
