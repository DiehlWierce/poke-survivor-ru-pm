extends RefCounted
# Iconos pixel art (portados de ui/icons.js): se dibujan al vuelo desde mapas de
# caracteres, asi que no hacen falta imagenes. Nombres: "heart", "coin", "move:<id>", "type:<tipo>"...

const MD = preload("res://scripts/moves_data.gd")
const K := Color("#1b1528")

# Movimientos con el mismo tipo y clase: usan el dibujo de otro tipo para distinguirse.
const GLYPH_OVERRIDE := {"swords-dance": "steel", "agility": "flying", "harden": "rock", "body-slam": "fighting", "poison-sting": "bug"}

static var data: Dictionary = {}
static var cache := {}
static var loaded := false


static func _load() -> void:
	if loaded:
		return
	loaded = true
	var f := FileAccess.open("res://data/icons.json", FileAccess.READ)
	if f != null:
		var d = JSON.parse_string(f.get_as_text())
		if d is Dictionary:
			data = d


static func _shade(c: Color, k: float) -> Color:
	return Color(clampf(c.r * k, 0.0, 1.0), clampf(c.g * k, 0.0, 1.0), clampf(c.b * k, 0.0, 1.0), c.a)


static func _from_rows(def: Dictionary) -> Image:
	var rows: Array = def["rows"]
	var h: int = rows.size()
	var w := 0
	for r in rows:
		w = maxi(w, String(r).length())
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var pal: Dictionary = def.get("pal", {})
	for y in range(h):
		var row: String = String(rows[y])
		for x in range(row.length()):
			var ch: String = row.substr(x, 1)
			if ch == "." or ch == " ":
				continue
			if ch == "k":
				img.set_pixel(x, y, K)
			elif pal.has(ch):
				img.set_pixel(x, y, Color.html(String(pal[ch])))
	return img


static func _emblem(type: String, kind: String, evo: bool = false, glyph: String = "") -> Image:
	var S := 16
	var img := Image.create(S, S, false, Image.FORMAT_RGBA8)
	var col := Color.html(String(MD.TYPE_COLOR.get(type, "#b0a99f")))
	var dark: Color = _shade(col, 0.55)
	var lite: Color = _shade(col, 1.3)
	var edge: Color = Color("#ffd23f") if evo else K
	for y in range(S):
		for x in range(S):
			var d: float = Vector2(float(x) - 7.5, float(y) - 7.5).length()
			if d > 7.6:
				continue
			var f: Color = col
			if d > 6.6:
				f = edge
			elif (float(x) - 7.5) + (float(y) - 7.5) > 6.0:
				f = dark
			elif (float(x) - 7.5) + (float(y) - 7.5) < -6.5:
				f = lite
			img.set_pixel(x, y, f)
	var g: Array = data["type"].get(glyph if glyph != "" else type, data["type"]["normal"])
	for y in range(g.size()):
		var row: String = String(g[y])
		for x in range(row.length()):
			if row.substr(x, 1) == "#":
				img.set_pixel(x + 5, y + 5, dark)
	for y in range(g.size()):
		var row2: String = String(g[y])
		for x in range(row2.length()):
			if row2.substr(x, 1) == "#":
				img.set_pixel(x + 4, y + 4, Color.WHITE)
	if kind != "" and data["kind"].has(kind):
		for y in range(9, 16):
			for x in range(9, 16):
				img.set_pixel(x, y, K)
		for y in range(10, 15):
			for x in range(10, 15):
				img.set_pixel(x, y, Color("#2b3454"))
		var kg: Array = data["kind"][kind]
		for y in range(kg.size()):
			var kr: String = String(kg[y])
			for x in range(kr.length()):
				if kr.substr(x, 1) == "#":
					img.set_pixel(x + 10, y + 10, Color("#ffd23f"))
	return img


static func image(name: String) -> Image:
	_load()
	if name.begins_with("move:") or name.begins_with("evo:"):
		var evo: bool = name.begins_with("evo:")
		var id: String = name.substr(4 if evo else 5)
		if MD.MOVES.has(id):
			return _emblem(String(MD.MOVES[id]["type"]), String(MD.MOVES[id]["kind"]), evo, String(GLYPH_OVERRIDE.get(id, "")))
		return _emblem("normal", "")
	if name.begins_with("type:"):
		return _emblem(name.substr(5), "")
	var ui: Dictionary = data["ui"]
	return _from_rows(ui.get(name, ui["star"]))


# Textura ampliada por un factor entero (sin suavizar).
static func tex(name: String, scale: int = 1) -> Texture2D:
	var key := "%s@%d" % [name, scale]
	if cache.has(key):
		return cache[key]
	var img: Image = image(name)
	if scale > 1:
		img.resize(img.get_width() * scale, img.get_height() * scale, Image.INTERPOLATE_NEAREST)
	var t := ImageTexture.create_from_image(img)
	cache[key] = t
	return t


# Escala entera que mas se acerca a un tamano objetivo en pantalla.
static func scale_for(name: String, size: float) -> int:
	_load()
	var w: int = 16
	if not (name.begins_with("move:") or name.begins_with("type:") or name.begins_with("evo:")):
		var ui: Dictionary = data["ui"]
		var rows: Array = ui.get(name, ui["star"])["rows"]
		w = String(rows[0]).length()
	return maxi(1, roundi(size / float(w)))


# Dibuja el icono centrado en un rectangulo (para _draw de un CanvasItem).
static func draw_in(ci: CanvasItem, name: String, center: Vector2, size: float, mod: Color = Color.WHITE) -> void:
	var sc: int = scale_for(name, size)
	var t: Texture2D = tex(name, 1)
	var sz := Vector2(t.get_width(), t.get_height()) * float(sc)
	ci.draw_texture_rect(t, Rect2((center - sz * 0.5).round(), sz), false, mod)


# TextureRect listo para meter en un menu.
static func rect(name: String, size: float) -> TextureRect:
	var sc: int = scale_for(name, size)
	var t: Texture2D = tex(name, sc)
	var tr := TextureRect.new()
	tr.texture = t
	tr.stretch_mode = TextureRect.STRETCH_KEEP
	tr.custom_minimum_size = Vector2(t.get_width(), t.get_height())
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tr.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return tr


# Icono para el campo "icon" de un Button (ya ampliado).
static func btn_tex(name: String, size: float) -> Texture2D:
	return tex(name, scale_for(name, size))
