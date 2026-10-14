extends RefCounted
# Iconos de botones de mando (Xbox, PlayStation, Nintendo) dibujados en pixel art.
# tex(boton, tipo_de_mando) devuelve una textura cuadrada lista para mostrar.

const PAD = preload("res://scripts/pad.gd")
const G := 24          # rejilla de pixeles
const S := 3           # pixeles reales por celda
const OUT := Color("#0b0f1e")
const DARK := Color("#20263c")
const MID := Color("#3b4466")
const LIGHT := Color("#e6e8f0")
# Xbox original: botones macizos verde / rojo / azul / amarillo con letra negra
const XB := [Color("#3fb83a"), Color("#e0382c"), Color("#2f6fe0"), Color("#f2c21e")]   # A B X Y
# New Nintendo 3DS: A rojo, B amarillo, X azul, Y verde (orden Godot: abajo, derecha, izquierda, arriba = B, A, Y, X)
const N3: Array = [Color("#f2c21e"), Color("#e0382c"), Color("#3fae4a"), Color("#2f6fe0")]
const PS := [Color("#6fb0ff"), Color("#ff6f7d"), Color("#ff93d6"), Color("#5fe8a0")]   # Cruz Circulo Cuadrado Triangulo

const FONT := {
	"A": [".###.", "#...#", "#...#", "#####", "#...#", "#...#", "#...#"],
	"B": ["####.", "#...#", "#...#", "####.", "#...#", "#...#", "####."],
	"X": ["#...#", "#...#", ".#.#.", "..#..", ".#.#.", "#...#", "#...#"],
	"Y": ["#...#", "#...#", ".#.#.", "..#..", "..#..", "..#..", "..#.."],
	"L": ["#....", "#....", "#....", "#....", "#....", "#....", "#####"],
	"R": ["####.", "#...#", "#...#", "####.", "#.#..", "#..#.", "#...#"],
	"1": ["..#..", ".##..", "..#..", "..#..", "..#..", "..#..", ".###."],
}

static var _cache := {}


static func tex(b: int, lay: int = -1, key: String = "") -> ImageTexture:
	if lay < 0:
		lay = PAD.layout()
	var k := "%d_%d_%s" % [b, lay, key]
	if _cache.has(k):
		return _cache[k]
	var img := Image.create(G * S, G * S, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	_draw(img, b, lay, key)
	var t := ImageTexture.create_from_image(img)
	_cache[k] = t
	return t


# Icono con nombre propio ("dpad_lr": cruceta con izquierda y derecha marcadas).
static func named(key: String, lay: int = -1) -> ImageTexture:
	return tex(-1, lay, key)


static func rect(b: int, size: float = 32.0, lay: int = -1, key: String = "") -> TextureRect:
	var r := TextureRect.new()
	r.texture = tex(b, lay, key)
	r.custom_minimum_size = Vector2(size, size)
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


# ---------------------------------------------------------------
static func _px(img: Image, x: int, y: int, c: Color) -> void:
	if x < 0 or y < 0 or x >= G or y >= G:
		return
	for j in range(S):
		for i in range(S):
			img.set_pixel(x * S + i, y * S + j, c)


static func _disc(img: Image, cx: float, cy: float, r: float, c: Color) -> void:
	for y in range(G):
		for x in range(G):
			var dx: float = float(x) + 0.5 - cx
			var dy: float = float(y) + 0.5 - cy
			if dx * dx + dy * dy <= r * r:
				_px(img, x, y, c)


static func _ring(img: Image, cx: float, cy: float, r0: float, r1: float, c: Color) -> void:
	for y in range(G):
		for x in range(G):
			var dx: float = float(x) + 0.5 - cx
			var dy: float = float(y) + 0.5 - cy
			var d2: float = dx * dx + dy * dy
			if d2 <= r1 * r1 and d2 >= r0 * r0:
				_px(img, x, y, c)


static func _rect(img: Image, x0: int, y0: int, x1: int, y1: int, c: Color, round_corners: bool = false) -> void:
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			if round_corners and (x == x0 or x == x1) and (y == y0 or y == y1):
				continue
			_px(img, x, y, c)


static func _frame(img: Image, x0: int, y0: int, x1: int, y1: int, t: int, c: Color) -> void:
	_rect(img, x0, y0, x1, y0 + t - 1, c)
	_rect(img, x0, y1 - t + 1, x1, y1, c)
	_rect(img, x0, y0, x0 + t - 1, y1, c)
	_rect(img, x1 - t + 1, y0, x1, y1, c)


static func _letter(img: Image, ch: String, x: int, y: int, c: Color) -> void:
	if not FONT.has(ch):
		return
	var rows: Array = FONT[ch]
	for j in range(rows.size()):
		var row: String = rows[j]
		for i in range(row.length()):
			if row[i] == "#":
				_px(img, x + i, y + j, c)


static func _text(img: Image, s: String, cx: int, cy: int, c: Color) -> void:
	var w: int = s.length() * 6 - 1
	var x: int = cx - int(w / 2.0)
	for ch in s:
		_letter(img, ch, x, cy - 3, c)
		x += 6


static func _line(img: Image, x0: int, y0: int, x1: int, y1: int, th: int, c: Color) -> void:
	var n: int = maxi(absi(x1 - x0), absi(y1 - y0))
	for i in range(n + 1):
		var t: float = float(i) / float(maxi(n, 1))
		var x: int = roundi(lerpf(float(x0), float(x1), t))
		var y: int = roundi(lerpf(float(y0), float(y1), t))
		for a in range(th):
			for b2 in range(th):
				_px(img, x + a, y + b2, c)


static func _in_tri(px: float, py: float, ax: float, ay: float, bx: float, by: float, cx: float, cy: float) -> bool:
	var d1: float = (px - bx) * (ay - by) - (ax - bx) * (py - by)
	var d2: float = (px - cx) * (by - cy) - (bx - cx) * (py - cy)
	var d3: float = (px - ax) * (cy - ay) - (cx - ax) * (py - ay)
	var neg: bool = d1 < 0.0 or d2 < 0.0 or d3 < 0.0
	var pos: bool = d1 > 0.0 or d2 > 0.0 or d3 > 0.0
	return not (neg and pos)


static func _base_disc(img: Image, fill: Color, ring: Color) -> void:
	_disc(img, 12.0, 12.0, 11.6, OUT)
	_disc(img, 12.0, 12.0, 10.4, ring)
	_disc(img, 12.0, 12.0, 9.2, fill)


static func _draw(img: Image, b: int, lay: int, key: String) -> void:
	if key == "dpad_lr" or key == "dpad_ud":
		_dpad(img, [13, 14] if key == "dpad_lr" else [11, 12])
		return
	match b:
		0, 1, 2, 3:
			_face(img, b, lay)
		9, 10:
			_shoulder(img, b == 9, lay)
		6:
			_start(img, lay)
		4:
			_back(img, lay)
		7, 8:
			_stick(img, b == 7)
		11, 12, 13, 14:
			_dpad(img, [b])
		_:
			_base_disc(img, DARK, MID)
			_disc(img, 12.0, 12.0, 2.6, LIGHT)


static func _face(img: Image, b: int, lay: int) -> void:
	if lay == 1:
		# PlayStation: simbolos de colores sobre fondo oscuro
		var col: Color = PS[b]
		_base_disc(img, DARK, MID)
		match b:
			0:
				_line(img, 7, 7, 15, 15, 2, col)
				_line(img, 15, 7, 7, 15, 2, col)
			1:
				_ring(img, 12.0, 12.0, 3.6, 5.8, col)
			2:
				_frame(img, 7, 7, 16, 16, 2, col)
			3:
				for y in range(G):
					for x in range(G):
						var fx: float = float(x) + 0.5
						var fy: float = float(y) + 0.5
						if _in_tri(fx, fy, 12.0, 5.2, 5.4, 17.2, 18.6, 17.2) and not _in_tri(fx, fy, 12.0, 9.6, 8.8, 15.0, 15.2, 15.0):
							_px(img, x, y, col)
		return
	if lay == 2:
		var l2 := ["B", "A", "Y", "X"]
		var nc: Color = N3[b]
		_disc(img, 12.0, 12.0, 11.6, OUT)
		_disc(img, 12.0, 12.0, 10.4, nc.darkened(0.25))
		_disc(img, 12.0, 11.4, 9.6, nc)
		_letter(img, l2[b], 9, 8, Color("#fdfdff"))
		return
	# Xbox original: boton negro con el color del boton y un poco de brillo
	var letters := ["A", "B", "X", "Y"]
	var xc: Color = XB[b]
	_glow(img, 12.0, 12.0, 9.6, 11.9, xc)
	_disc(img, 12.0, 12.0, 9.9, xc.darkened(0.2))
	_disc(img, 12.0, 12.0, 8.4, Color("#07080c"))
	_letter(img, letters[b], 9, 8, xc.lightened(0.15))


# Halo suave: el color se desvanece desde r0 hasta r1.
static func _glow(img: Image, cx: float, cy: float, r0: float, r1: float, c: Color) -> void:
	for y in range(G):
		for x in range(G):
			var dx: float = float(x) + 0.5 - cx
			var dy: float = float(y) + 0.5 - cy
			var d: float = sqrt(dx * dx + dy * dy)
			if d > r0 and d <= r1:
				var a: float = 0.7 * (1.0 - (d - r0) / (r1 - r0))
				for j in range(S):
					for i in range(S):
						img.set_pixel(x * S + i, y * S + j, Color(c.r, c.g, c.b, a * a + 0.05))


static func _shoulder(img: Image, left: bool, lay: int) -> void:
	_rect(img, 1, 5, 22, 18, OUT, true)
	_rect(img, 2, 6, 21, 17, Color("#aab2cc"), true)
	_rect(img, 3, 7, 20, 16, MID, true)
	var s: String = ("L" if left else "R")
	if lay == 0:
		s += "B"
	elif lay == 1:
		s += "1"
	_text(img, s, 12, 11, Color.WHITE)


static func _start(img: Image, lay: int) -> void:
	_base_disc(img, DARK, MID)
	if lay == 2:
		_rect(img, 10, 6, 13, 17, LIGHT)
		_rect(img, 6, 10, 17, 13, LIGHT)
	elif lay == 1:
		# PS2: Start = triangulo "play"
		for y in range(G):
			for x in range(G):
				if _in_tri(float(x) + 0.5, float(y) + 0.5, 8.0, 6.0, 8.0, 17.6, 17.4, 11.8):
					_px(img, x, y, LIGHT)
	else:
		_rect(img, 7, 7, 16, 8, LIGHT)
		_rect(img, 7, 11, 16, 12, LIGHT)
		_rect(img, 7, 15, 16, 16, LIGHT)


static func _back(img: Image, lay: int) -> void:
	_base_disc(img, DARK, MID)
	if lay == 2:
		_rect(img, 6, 10, 17, 13, LIGHT)
	elif lay == 1:
		# PS2: Select = pastilla alargada
		_rect(img, 5, 9, 18, 14, LIGHT, true)
		_rect(img, 6, 10, 17, 13, MID, true)
		_rect(img, 8, 11, 15, 12, LIGHT)
	else:
		_frame(img, 6, 6, 14, 14, 1, LIGHT)
		_frame(img, 9, 9, 17, 17, 1, LIGHT)


static func _stick(img: Image, left: bool) -> void:
	_base_disc(img, DARK, Color("#aab2cc"))
	_disc(img, 12.0, 12.0, 6.6, MID)
	_letter(img, "L" if left else "R", 9, 8, Color.WHITE)


# Cruceta con los brazos indicados resaltados (11 arriba, 12 abajo, 13 izquierda, 14 derecha).
static func _dpad(img: Image, active: Array) -> void:
	var base := Color("#5b648a")
	var hi := Color.WHITE
	var arms := {11: [9, 2, 14, 9], 12: [9, 14, 14, 21], 13: [2, 9, 9, 14], 14: [14, 9, 21, 14]}
	_rect(img, 8, 1, 15, 22, OUT)
	_rect(img, 1, 8, 22, 15, OUT)
	for a in arms.keys():
		var r: Array = arms[a]
		_rect(img, int(r[0]) - 1, int(r[1]) - 1, int(r[2]) + 1, int(r[3]) + 1, OUT)
	for a in arms.keys():
		var r2: Array = arms[a]
		_rect(img, int(r2[0]), int(r2[1]), int(r2[2]), int(r2[3]), hi if active.has(a) else base)
	_rect(img, 9, 9, 14, 14, hi if active.size() > 0 and false else base)
