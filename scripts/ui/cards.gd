# Cartas de subida de nivel (tactil, mando y teclado)
extends Node2D
const L = preload("res://scripts/lang.gd")
const IC = preload("res://scripts/icons.gd")
const DSP = preload("res://scripts/display.gd")
const PAD = preload("res://scripts/pad.gd")
const PADI = preload("res://scripts/padicons.gd")

signal chosen(idx: int)
var items: Array = []
var sel := 0
var open := false
var age := 0.0
var title := ""
var headline := L.t("¡Subes de nivel!")
var _axis_free := true
signal reroll_pressed
signal ban_picked(idx: int)
var rerolls := 0
var bans := 0
var ban_mode := false
var extras := true
# Disposicion en cache: bloque vertical (titulo, cartas, botones, pie) que cabe en la zona util.
# Se recalcula al abrir y en size_changed (ventana o % de vista), no en cada _draw.
var _vp := Vector2(1280.0, 720.0)
var _ins := Vector4.ZERO
var _cx := 640.0       # centro horizontal de la zona util
var _top := 100.0      # arriba del bloque (linea del titulo = _top + 34)
var _h := 294.0        # alto de las cartas (240..294)
var _btn_y := 0.0
var _bw := 230.0       # ancho de cada boton Cambiar / Vetar

func _ready() -> void:
	_relayout()
	get_viewport().size_changed.connect(_relayout)

func _relayout() -> void:
	_vp = get_viewport_rect().size
	_ins = DSP.insets(get_tree())
	_cx = (_ins.x + _vp.x - _ins.z) * 0.5
	var top_lim: float = _ins.y + 6.0
	var bot_lim: float = _vp.y - _ins.w - 48.0          # encima del pie (iconos de 28 px)
	var head := 78.0                                     # titulo y subtitulo antes de las cartas
	var tail: float = (12.0 + 50.0 + 30.0) if extras else 0.0   # botones y cartel de veto
	var avail: float = bot_lim - top_lim
	_h = clampf(avail - head - tail, 240.0, 294.0)
	_top = top_lim + maxf(0.0, (avail - (head + _h + tail)) * 0.6)
	_btn_y = _top + head + _h + 12.0
	_bw = clampf((_vp.x - _ins.x - _ins.z - 60.0) * 0.5, 120.0, 230.0)
	_fit_text()
	queue_redraw()

# Tamano de letra de cada carta (etiqueta, titulo, descripcion): se reduce lo justo para que el texto quepa en la
# carta (titulo en 2 lineas, descripcion en las que deje la altura) sin cortarse ni salirse. Se calcula al abrir y
# en size_changed, no en cada _draw. Cada elemento: {tag, tag_fs, title_fs, desc_fs, d_lines}.
var _fit: Array = []

func _lines_of(font: Font, txt: String, w: float, fs: int) -> Vector2:
	# se mide con 8 px de holgura: con el escalado de la vista la letra se rasteriza algo distinta y una linea al borde puede pasar a dos
	var sz: Vector2 = font.get_multiline_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, w - 8.0, fs, -1, TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND)
	return Vector2(roundf(sz.y / font.get_height(fs)), sz.x)   # x = lineas, y = ancho de la linea mas larga

func _fit_ml(font: Font, txt: String, w: float, fs0: int, fs_min: int, lines_for: Callable) -> int:
	var fs: int = fs0
	while fs > fs_min:
		var ln: Vector2 = _lines_of(font, txt, w, fs)
		if int(ln.x) <= int(lines_for.call(fs)) and ln.y <= w - 8.0 + 0.5:
			return fs
		fs -= 1
	return fs_min

func _fit_text() -> void:
	_fit = []
	var font := ThemeDB.fallback_font
	var rs: Array = _rects()
	var d_y: float = 196.0 - (294.0 - _h) * 0.5
	for i in range(items.size()):
		var it: Dictionary = items[i]
		var w: float = (rs[i] as Rect2).size.x
		var tag: String = L.t(String(it["tag"]))
		var tfs := 16
		while tfs > 10 and font.get_string_size(tag, HORIZONTAL_ALIGNMENT_LEFT, -1.0, tfs).x > w - 40.0:
			tfs -= 1
		while tag.length() > 2 and font.get_string_size(tag, HORIZONTAL_ALIGNMENT_LEFT, -1.0, tfs).x > w - 40.0:
			tag = tag.substr(0, tag.length() - 2).strip_edges() + "…"
		var ttl_fs: int = _fit_ml(font, L.t(String(it["title"])), w - 24.0, 24, 14, func(_f: int) -> int: return 2)
		var h_card: float = _h
		var dsc_fs: int = _fit_ml(font, L.t(String(it["desc"])), w - 32.0, 18, 11, func(f: int) -> int: return int((h_card - 6.0 - d_y - 0.25 * float(f)) / font.get_height(f)) + 1)
		var dl: int = maxi(2, int((h_card - 6.0 - d_y - 0.25 * float(dsc_fs)) / font.get_height(dsc_fs)) + 1)
		_fit.append({"tag": tag, "tag_fs": tfs, "title_fs": ttl_fs, "desc_fs": dsc_fs, "d_lines": dl})

func _btn_rects() -> Array:
	return [Rect2(_cx - 20.0 - _bw, _btn_y, _bw, 50.0), Rect2(_cx + 20.0, _btn_y, _bw, 50.0)]

func _do_reroll() -> void:
	if extras and rerolls > 0 and not ban_mode:
		reroll_pressed.emit()

func _toggle_ban() -> void:
	if extras and bans > 0:
		ban_mode = not ban_mode
		queue_redraw()

func show_cards(list: Array, heading: String, head: String = "¡Subes de nivel!", ex: bool = true) -> void:
	items = list
	title = heading
	headline = head
	extras = ex
	ban_mode = false
	sel = 0
	open = true
	age = 0.0
	_axis_free = false
	_relayout()   # sin botones el bloque es mas bajo
	queue_redraw()

func hide_cards() -> void:
	open = false
	queue_redraw()

func _rects() -> Array:
	var n: int = items.size()
	var gap := 20.0
	var w: float = minf(300.0, (_vp.x - _ins.x - _ins.z - 40.0 - gap * float(n - 1)) / float(maxi(n, 1)))
	var h: float = _h
	var total: float = w * float(n) + gap * float(n - 1)
	var x0: float = _cx - total * 0.5
	var y0: float = _top + 78.0
	var out: Array = []
	for i in range(n):
		out.append(Rect2(x0 + float(i) * (w + gap), y0, w, h))
	return out

func _process(delta: float) -> void:
	if open:
		age += delta
		queue_redraw()

func _move(step: int) -> void:
	if items.is_empty():
		return
	sel = posmod(sel + step, items.size())
	queue_redraw()

func _pick(i: int) -> void:
	if i >= 0 and i < items.size():
		sel = i
		if ban_mode:
			if String(items[i]["cat"]) == "new":
				ban_picked.emit(i)
			return
		chosen.emit(i)

func _input(event: InputEvent) -> void:
	if not open:
		return
	if event is InputEventJoypadMotion and event.axis == JOY_AXIS_LEFT_X:
		if absf(event.axis_value) < 0.3:
			_axis_free = true
		elif absf(event.axis_value) > 0.6 and _axis_free and age > 0.3:
			_axis_free = false
			_move(1 if event.axis_value > 0.0 else -1)
		return
	var pressed := false
	if event is InputEventScreenTouch:
		pressed = event.pressed
	elif event is InputEventJoypadButton:
		pressed = event.pressed
	elif event is InputEventKey:
		pressed = event.pressed and not event.echo
	if not pressed:
		return
	# Tragamos las pulsaciones (no las sueltas) mientras hay cartas.
	get_viewport().set_input_as_handled()
	if age < 0.4:
		return
	if event is InputEventScreenTouch:
		var brs: Array = _btn_rects()
		if brs[0].has_point(event.position):
			_do_reroll()
			return
		if brs[1].has_point(event.position):
			_toggle_ban()
			return
		var rs: Array = _rects()
		for i in range(rs.size()):
			if rs[i].has_point(event.position):
				_pick(i)
				return
	elif event is InputEventKey:
		match event.keycode:
			KEY_1:
				_pick(0)
			KEY_2:
				_pick(1)
			KEY_3:
				_pick(2)
			KEY_LEFT, KEY_A:
				_move(-1)
			KEY_RIGHT, KEY_D:
				_move(1)
			KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_E:
				_pick(sel)
			KEY_R:
				_do_reroll()
			KEY_B:
				_toggle_ban()
	elif event is InputEventJoypadButton:
		var bi: int = event.button_index
		if bi == JOY_BUTTON_DPAD_LEFT or bi == PAD.btn("prev"):
			_move(-1)
		elif bi == JOY_BUTTON_DPAD_RIGHT or bi == PAD.btn("next"):
			_move(1)
		elif bi == PAD.btn("confirm"):
			_pick(sel)
		elif bi == PAD.btn("reroll"):
			_do_reroll()
		elif bi == PAD.btn("ban"):
			_toggle_ban()

func _draw() -> void:
	if not open:
		return
	var font := ThemeDB.fallback_font
	var vp: Vector2 = _vp
	draw_rect(Rect2(Vector2.ZERO, vp), Color(0, 0, 0, 0.6))
	draw_string(font, Vector2(0.0, _top + 34.0), L.t(headline), HORIZONTAL_ALIGNMENT_CENTER, vp.x, 40, Color("#ffd33d"))
	draw_string(font, Vector2(0.0, _top + 66.0), L.t(title), HORIZONTAL_ALIGNMENT_CENTER, vp.x, 20, Color.WHITE)
	var rs: Array = _rects()
	# Con cartas mas bajas (vista pequena) el icono, el titulo y la descripcion suben un poco.
	var sh: float = 294.0 - _h
	var t_y: float = 134.0 - sh * 0.25
	var d_y: float = 196.0 - sh * 0.5
	if _fit.size() != items.size():
		_fit_text()
	for i in range(rs.size()):
		var r: Rect2 = rs[i]
		var it: Dictionary = items[i]
		var ft: Dictionary = _fit[i]
		var tag_col: Color = it["color"]
		var chosen_now: bool = i == sel
		var border: Color = tag_col
		if chosen_now:
			border = Color("#ffd33d")
		var paper: bool = bool(it.get("paper", false))
		draw_rect(r.grow(4.0 if chosen_now else 1.5), border)
		draw_rect(r, Color("#1b2a44"))
		var legend: bool = bool(it.get("legend", false))
		if legend:
			_draw_legend_bg(r)
		if paper:
			draw_rect(r, Color("#ecd9a6"))
			draw_rect(r.grow(-6.0), Color("#8a6a3a"), false, 2.0)
			draw_line(Vector2(r.position.x + 24.0, r.end.y - 22.0), Vector2(r.position.x + r.size.x * 0.55, r.end.y - 22.0), Color("#6b4a2b"), 2.0)
			draw_circle(Vector2(r.end.x - 40.0, r.end.y - 34.0), 15.0, Color("#a8281c"))
			draw_circle(Vector2(r.end.x - 40.0, r.end.y - 34.0), 9.0, Color("#c0392b"))
		draw_rect(Rect2(r.position, Vector2(r.size.x, 32.0)), Color(tag_col.r, tag_col.g, tag_col.b, 0.35))
		draw_string(font, r.position + Vector2(10.0, 22.0), String(ft["tag"]), HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 40.0, int(ft["tag_fs"]), Color("#2b1a00") if legend else Color.WHITE)
		draw_string(font, r.position + Vector2(r.size.x - 24.0, 22.0), str(i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18, Color("#8fa8cc"))
		var ic_c: Vector2 = r.position + Vector2(r.size.x * 0.5, 72.0 - sh * 0.1)
		var ic_bg := Rect2(ic_c - Vector2(34.0, 34.0), Vector2(68.0, 68.0))
		draw_rect(ic_bg, Color(0.1, 0.06, 0.0, 0.82) if legend else Color(tag_col.r, tag_col.g, tag_col.b, 0.22))
		draw_rect(ic_bg, Color(tag_col.r, tag_col.g, tag_col.b, 0.7), false, 2.0)
		IC.draw_in(self, String(it.get("icon", "star")), ic_c, 52.0)
		draw_multiline_string(font, r.position + Vector2(12.0, t_y), L.t(String(it["title"])), HORIZONTAL_ALIGNMENT_CENTER, r.size.x - 24.0, int(ft["title_fs"]), 2, Color("#4a2f12") if paper else (Color("#2b1a00") if legend else Color.WHITE))
		draw_multiline_string(font, r.position + Vector2(16.0, d_y), L.t(String(it["desc"])), HORIZONTAL_ALIGNMENT_CENTER, r.size.x - 32.0, int(ft["desc_fs"]), int(ft["d_lines"]), Color("#5a3d1c") if paper else (Color("#3a2600") if legend else Color("#c8d6ee")))
	if extras:
		var brs: Array = _btn_rects()
		if rerolls > 0:
			draw_rect(brs[0], Color("#1b2a44"))
			draw_rect(brs[0], Color("#7fe0ff"), false, 2.0)
			_draw_key_label(brs[0], L.t("Cambiar (%d)  [R]") % rerolls, "reroll")
		if bans > 0:
			draw_rect(brs[1], Color("#5a1f2a") if ban_mode else Color("#1b2a44"))
			draw_rect(brs[1], Color("#ff6b7a"), false, 2.0)
			_draw_key_label(brs[1], L.t("Vetar (%d)  [B]") % bans, "ban")
		if ban_mode:
			draw_string(font, Vector2(0.0, _btn_y + 50.0 + 24.0), L.t("Elige un movimiento nuevo para vetarlo"), HORIZONTAL_ALIGNMENT_CENTER, vp.x, 22, Color("#ff9aa5"))
	_draw_footer(vp)


# Carta legendaria: fondo de oro con brillo diagonal que recorre la carta y destellos.
func _draw_legend_bg(r: Rect2) -> void:
	var beat: float = 0.5 + 0.5 * sin(age * 4.0)
	draw_rect(r.grow(5.0), Color(1.0, 0.82, 0.25, 0.25 + 0.2 * beat))
	draw_rect(r.grow(2.5), Color("#ffd23f"))
	draw_rect(r, Color("#a87a12"))
	draw_rect(Rect2(r.position + Vector2(0.0, 32.0), Vector2(r.size.x, r.size.y - 32.0)), Color("#c9951c"))
	draw_rect(Rect2(r.position + Vector2(0.0, r.size.y * 0.55), Vector2(r.size.x, r.size.y * 0.45)), Color("#e3b52e"))
	draw_rect(r.grow(-6.0), Color("#ffe27a"), false, 2.0)
	var sx: float = fposmod(age * 120.0, r.size.x + 160.0) - 80.0
	var sheen := PackedVector2Array([r.position + Vector2(sx, 0.0), r.position + Vector2(sx + 40.0, 0.0), r.position + Vector2(sx + 10.0, r.size.y), r.position + Vector2(sx - 30.0, r.size.y)])
	var clipped := Geometry2D.intersect_polygons(sheen, PackedVector2Array([r.position, r.position + Vector2(r.size.x, 0.0), r.end, r.position + Vector2(0.0, r.size.y)]))
	for poly in clipped:
		draw_colored_polygon(poly, Color(1.0, 0.97, 0.7, 0.22))
	for i in range(7):
		var ph: float = age * 1.3 + float(i) * 0.9
		var sp := Vector2(r.position.x + fposmod(float(i) * 47.0 + 20.0, r.size.x - 20.0) + 10.0, r.position.y + 40.0 + fposmod(float(i) * 83.0 + ph * 18.0, r.size.y - 60.0))
		var sz: float = 2.0 + 2.5 * (0.5 + 0.5 * sin(age * 6.0 + float(i) * 2.1))
		draw_colored_polygon(PackedVector2Array([sp + Vector2(0, -sz * 1.6), sp + Vector2(sz * 0.5, 0), sp + Vector2(0, sz * 1.6), sp + Vector2(-sz * 0.5, 0)]), Color(1.0, 0.98, 0.8, 0.9))
		draw_colored_polygon(PackedVector2Array([sp + Vector2(-sz * 1.6, 0), sp + Vector2(0, sz * 0.5), sp + Vector2(sz * 1.6, 0), sp + Vector2(0, -sz * 0.5)]), Color(1.0, 0.98, 0.8, 0.9))

# Texto de un boton de la pantalla; con mando conectado cambia "[R]" por el icono del boton asignado.
func _draw_key_label(r: Rect2, txt: String, action: String) -> void:
	var font := ThemeDB.fallback_font
	var pad: bool = Input.get_connected_joypads().size() > 0
	if not pad:
		draw_string(font, r.position + Vector2(0.0, 32.0), txt, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 20, Color.WHITE)
		return
	var rx := RegEx.new()
	rx.compile("\\s*\\[[^\\]]*\\]")
	var clean: String = rx.sub(txt, "", true)
	var tw: float = font.get_string_size(clean, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 20).x
	var isz := 30.0
	var x0: float = r.position.x + (r.size.x - (tw + 8.0 + isz)) * 0.5
	draw_string(font, Vector2(x0, r.position.y + 32.0), clean, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 20, Color.WHITE)
	draw_texture_rect(PADI.tex(PAD.btn(action)), Rect2(Vector2(x0 + tw + 8.0, r.position.y + (r.size.y - isz) * 0.5), Vector2(isz, isz)), false)


# Pie: "Toca una carta | Mando: [cruceta] [aceptar] | Teclado: 1 2 3" con los iconos del mando elegido.
func _draw_footer(vp: Vector2) -> void:
	var font := ThemeDB.fallback_font
	var col := Color("#8fa8cc")
	var parts: Array = [{"t": L.t("Toca una carta") + "  |  "}]
	if Input.get_connected_joypads().size() > 0:
		parts.append({"t": L.t("Mando") + ": "})
		parts.append({"i": PADI.named("dpad_lr")})
		parts.append({"t": " + "})
		parts.append({"i": PADI.tex(PAD.btn("confirm"))})
		parts.append({"t": "  |  "})
	parts.append({"t": L.t("Teclado: 1 2 3")})
	var isz := 28.0
	var total := 0.0
	for p in parts:
		total += isz if p.has("i") else font.get_string_size(String(p["t"]), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18).x
	var x: float = _cx - total * 0.5
	var y: float = vp.y - 24.0 - _ins.w
	for p in parts:
		if p.has("i"):
			draw_texture_rect(p["i"], Rect2(Vector2(x, y - 21.0), Vector2(isz, isz)), false)
			x += isz
		else:
			draw_string(font, Vector2(x, y), String(p["t"]), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18, col)
			x += font.get_string_size(String(p["t"]), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18).x
