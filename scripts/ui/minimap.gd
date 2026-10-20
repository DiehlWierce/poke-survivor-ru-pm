# Minimapa circular (exclusivo del port Android). Terreno detallado que se desplaza
# con el jugador y niebla de exploracion: lo que ya recorriste queda dibujado (mas
# apagado), lo que no, oculto. Iconos: cofres/altares/fuentes cercanos o ya vistos,
# trampas ocultas solo muy cerca, enemigos solo a corta distancia; grietas y jefes
# siempre, como flecha en el borde.
extends Node2D
const ARENA = preload("res://scripts/arena.gd")
const WTex = preload("res://scripts/game/wtex.gd")
const Actor = preload("res://scripts/main.gd").Actor

const N := 50          # tiles guardados en la imagen
const VIEW := 48       # tiles visibles (diametro)
const S := 4.0         # pixeles por tile
const BOX := 192.0     # VIEW * S
const CT := Vector2(100.0, 100.0)
const RAD := 96.0
const SIGHT := 14      # radio (tiles) que se descubre y se ve a pleno color
const RADAR := 20.0    # radio (tiles) en el que se detectan cofres, altares y fuentes
const TRAP_R := 9.0    # radio (tiles) en el que se revelan las trampas
const FOE_R := 12.0    # radio (tiles) en el que se ven enemigos
const CODE := "shader_type canvas_item;\nuniform vec2 ctr = vec2(100.0, 100.0);\nuniform float rad = 97.0;\nvarying vec2 lp;\nvoid vertex() { lp = VERTEX; }\nvoid fragment() { COLOR.a *= 1.0 - smoothstep(rad - 1.0, rad, distance(lp, ctr)); }\n"
var m
var img: Image
var tex: ImageTexture
var fog: Image
var fog_tex: ImageTexture
var explored := {}
var ti := Vector2i(99999, 99999)
var bio := -1
var sd := -1
var t := 0.0
var ring: Node2D

func _init() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	img = Image.create(N, N, false, Image.FORMAT_RGBA8)
	tex = ImageTexture.create_from_image(img)
	fog = Image.create(N, N, false, Image.FORMAT_RGBA8)
	fog_tex = ImageTexture.create_from_image(fog)
	var sh := Shader.new()
	sh.code = CODE
	var mat := ShaderMaterial.new()
	mat.shader = sh
	material = mat
	ring = MiniRing.new()
	add_child(ring)

class MiniRing extends Node2D:
	func _draw() -> void:
		var c := Vector2(100.0, 100.0)
		draw_arc(c, 97.5, 0.0, TAU, 96, Color(0.02, 0.04, 0.1, 0.9), 3.0, true)
		draw_arc(c, 96.0, 0.0, TAU, 96, Color("#f4f8ff"), 2.0, true)
		draw_string(ThemeDB.fallback_font, Vector2(c.x - 5.0, 20.0), "N", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, Color(1, 1, 1, 0.8))

func _tile_color(g, pal: Dictionary, tx: int, ty: int) -> Color:
	var h: float = ARENA.hsh(tx, ty, 31)
	var tt: int = g.terrain(tx, ty)
	var c: Color
	if tt == 1:
		var south: int = g.terrain(tx, ty + 1)
		var north: int = g.terrain(tx, ty - 1)
		if south != 1:
			c = pal["wallFace"][0]
		elif north != 1:
			c = pal["wallLight"]
		else:
			c = pal["wallTop"][int(h * 3.0) % 3]
	elif tt == 2:
		var inner: bool = g.terrain(tx - 1, ty) == 2 and g.terrain(tx + 1, ty) == 2 and g.terrain(tx, ty - 1) == 2 and g.terrain(tx, ty + 1) == 2
		c = pal["liqDeep"] if inner else pal["liq"]
		if h > 0.92:
			c = c.lerp(pal["foam"], 0.55)
	else:
		if g.is_dirt(tx, ty):
			c = pal["dirt"][int(h * 3.0) % 3]
		else:
			c = pal["floor"][int(h * 3.0) % 3]
			if h > 0.965:
				c = pal["flowers"][int(h * 1000.0) % 3]
			elif h < 0.07:
				c = c.lerp(pal["grass"][2], 0.5)
		if g.terrain(tx, ty + 1) == 1:
			c = c.darkened(0.25)
		elif g.terrain(tx + 1, ty) == 2 or g.terrain(tx - 1, ty) == 2 or g.terrain(tx, ty + 1) == 2 or g.terrain(tx, ty - 1) == 2:
			c = c.lerp(pal["shore"], 0.35)
	return c

func _refresh(i0: Vector2i, full: bool) -> void:
	var g = m.ground
	var pal: Dictionary = g.pal(g.biome)
	var dx: int = i0.x - ti.x
	var dy: int = i0.y - ti.y
	var half: int = N / 2
	if full or absi(dx) >= N or absi(dy) >= N:
		for r in range(N):
			for c in range(N):
				img.set_pixel(c, r, _tile_color(g, pal, i0.x - half + c, i0.y - half + r))
	else:
		var old: Image = img.duplicate()
		img.fill(Color(0, 0, 0, 0))
		img.blit_rect(old, Rect2i(maxi(dx, 0), maxi(dy, 0), N - absi(dx), N - absi(dy)), Vector2i(maxi(-dx, 0), maxi(-dy, 0)))
		var cols: Array = []
		var rows: Array = []
		if dx > 0:
			for c in range(N - dx, N):
				cols.append(c)
		elif dx < 0:
			for c in range(0, -dx):
				cols.append(c)
		if dy > 0:
			for r in range(N - dy, N):
				rows.append(r)
		elif dy < 0:
			for r in range(0, -dy):
				rows.append(r)
		for c in cols:
			for r in range(N):
				img.set_pixel(c, r, _tile_color(g, pal, i0.x - half + c, i0.y - half + r))
		for r in rows:
			for c in range(N):
				img.set_pixel(c, r, _tile_color(g, pal, i0.x - half + c, i0.y - half + r))
	tex.update(img)
	ti = i0

# Descubre el area alrededor del jugador y repinta la niebla.
# La niebla se repinta por tandas de filas (unas pocas por fotograma): hacerlo entera de golpe,
# en cada tile que cruza el jugador, eran decenas de ms en una consola.
const FOG_ROWS := 10
var _fog_c := Vector2i.ZERO
var _fog_row := N   # N = nada pendiente

func _fog_begin(i0: Vector2i) -> void:
	for oy in range(-SIGHT, SIGHT + 1):
		for ox in range(-SIGHT, SIGHT + 1):
			if ox * ox + oy * oy <= SIGHT * SIGHT:
				explored[Vector2i(i0.x + ox, i0.y + oy)] = true
	_fog_c = i0
	_fog_row = 0

func _fog_step() -> void:
	if _fog_row >= N:
		return
	var i0: Vector2i = _fog_c
	var half: int = N / 2
	var r_end: int = mini(_fog_row + FOG_ROWS, N)
	var s2: int = SIGHT * SIGHT
	for r in range(_fog_row, r_end):
		var oy: int = r - half
		for c in range(N):
			var ox: int = c - half
			var a := 0.94
			if ox * ox + oy * oy <= s2:
				a = 0.0
			elif explored.has(Vector2i(i0.x + ox, i0.y + oy)):
				a = 0.5
			fog.set_pixel(c, r, Color(0.03, 0.05, 0.11, a))
	_fog_row = r_end
	if _fog_row >= N:
		fog_tex.update(fog)

var _acc := 0.0

func _on() -> bool:
	return m.arena == null and not m.jd.active() and not m.hud.dead

func _process(delta: float) -> void:
	t += delta
	visible = _on()
	if not visible:
		return
	var g = m.ground
	var i0 := Vector2i(floori(m.player.position.x / g.TS), floori(m.player.position.y / g.TS))
	if i0 != ti or bio != g.biome or sd != g.seed_v:
		var full: bool = bio != g.biome or sd != g.seed_v
		bio = g.biome
		sd = g.seed_v
		_refresh(i0, full)
		_fog_begin(i0)
		_acc = 1.0
	_fog_step()
	_acc += delta
	if _acc >= (0.1 if Actor.lite else 0.04):   # 25 veces por segundo bastan para el minimapa (10 en consola)
		_acc = 0.0
		queue_redraw()

func _pt(wp: Vector2) -> Vector2:
	var d: Vector2 = (wp - m.player.position) / m.ground.TS
	return Vector2((d.x + float(VIEW) * 0.5) * S + 4.0, (d.y + float(VIEW) * 0.5) * S + 4.0)

func _inside(q: Vector2, pad: float = 0.0) -> bool:
	return q.distance_to(CT) <= RAD - pad

func _edge(q: Vector2) -> Vector2:
	var c := CT
	var d: Vector2 = q - c
	var lim: float = RAD - 12.0
	if d.length() > lim:
		return c + d.normalized() * lim
	return q

# Sprites del mundo reducidos una sola vez (suavizados) para el minimapa.
static var icons := {}

static func _icon(n: String, w: int) -> Texture2D:
	var k: String = "%s_%d" % [n, w]
	if not icons.has(k):
		var tx: Texture2D = WTex.get_t(n)
		if tx == null:
			icons[k] = null
		else:
			var im: Image = tx.get_image()
			var h: int = maxi(1, int(round(float(im.get_height()) * float(w) / float(im.get_width()))))
			im.resize(w, h, Image.INTERPOLATE_LANCZOS)
			icons[k] = ImageTexture.create_from_image(im)
	return icons[k]

func _spr_at(n: String, w: int, q: Vector2) -> bool:
	var tx: Texture2D = _icon(n, w)
	if tx == null:
		return false
	var sz := Vector2(tx.get_width(), tx.get_height())
	draw_texture(tx, (q - sz * 0.5).round())
	return true

# Sprite de un Pokemon (fotograma actual) a tamano maximo mx px.
func _pk_at(a, mx: float, q: Vector2) -> bool:
	if a == null or not is_instance_valid(a) or a.sprite.texture == null:
		return false
	var rr: Rect2 = a.sprite.region_rect
	var k: float = mx / maxf(rr.size.x, rr.size.y)
	var sz: Vector2 = rr.size * k
	var anc: Vector2 = Vector2(-a.sprite.offset.x, -a.sprite.offset.y) * k
	draw_texture_rect_region(a.sprite.texture, Rect2((q - anc + Vector2(0, sz.y * 0.25)).round(), sz), rr)
	return true

func _tile_of(wp: Vector2) -> Vector2i:
	return Vector2i(floori(wp.x / m.ground.TS), floori(wp.y / m.ground.TS))

func _draw() -> void:
	var sz: float = BOX
	var c := CT
	draw_circle(c, 97.0, Color(0.03, 0.05, 0.11, 1.0))
	var ppos: Vector2 = m.player.position
	var px: float = ppos.x / m.ground.TS
	var py: float = ppos.y / m.ground.TS
	var fx: float = px - floorf(px)
	var fy: float = py - floorf(py)
	var half: float = float(N) * 0.5
	var src := Rect2(half + fx - float(VIEW) * 0.5, half + fy - float(VIEW) * 0.5, float(VIEW), float(VIEW))
	var dst := Rect2(4.0, 4.0, sz, sz)
	draw_texture_rect_region(tex, dst, src)
	draw_texture_rect_region(fog_tex, dst, src)
	var pul: float = 0.6 + 0.4 * sin(t * 6.0)
	var radar: float = RADAR * m.ground.TS
	var trap_r: float = TRAP_R * m.ground.TS
	var foe_r: float = FOE_R * m.ground.TS
	# eventos especiales y trampas ocultas
	for key in m.chunks:
		for p in m.chunks[key]["specials"]:
			if not is_instance_valid(p) or p.used:
				continue
			var k: String = p.kind
			var d: float = p.position.distance_to(ppos)
			var q: Vector2 = _pt(p.position)
			if not _inside(q, 6.0):
				continue
			if k == "trap":
				if d > trap_r or p.cd > 900.0:
					continue
				var tc := Color("#ff8a2b")
				match String(p.sub):
					"poison":
						tc = Color("#a35cff")
					"ice":
						tc = Color("#5fd8ff")
					"freeze":
						tc = Color("#2f8fe0")
					"shock":
						tc = Color("#ffe14d")
					"sleep":
						tc = Color("#b9b6ff")
					"confuse":
						tc = Color("#ff7ad9")
				draw_circle(q, 10.5, Color(tc.r, tc.g, tc.b, 0.35))
				if not _spr_at("trap_" + String(p.sub), 18, q):
					draw_circle(q, 4.0, tc)
				continue
			if d > radar and not explored.has(_tile_of(p.position)):
				continue
			var near: bool = d <= radar
			if k == "chest":
				if near:
					draw_arc(q, 11.0 + 2.0 * pul, 0.0, TAU, 20, Color(1.0, 0.85, 0.2, 0.75 * pul), 1.5)
				if not _spr_at("chest_closed", 20, q):
					draw_rect(Rect2(q - Vector2(5, 4), Vector2(10, 8)), Color("#ffd23f"))
			elif k == "altar":
				if near:
					draw_arc(q, 13.0 + 2.0 * pul, 0.0, TAU, 20, Color(p.color.r, p.color.g, p.color.b, 0.8 * pul), 1.5)
				if not _spr_at("altar_" + String(p.power), 16, q):
					draw_circle(q, 5.0, p.color)
			elif k == "spring":
				if not _spr_at("spring_on", 22, q):
					draw_circle(q, 5.0, Color("#2fc6e8"))
	# enemigos (solo a corta distancia)
	for e in m.enemies:
		if e.dead or e.boss:
			continue
		if e.position.distance_to(ppos) > foe_r:
			continue
		var q: Vector2 = _pt(e.position)
		if _inside(q, 2.0):
			draw_rect(Rect2(q - Vector2(1, 1), Vector2(2.5, 2.5)), Color(1.0, 0.25, 0.3, 0.95))
	# jefes (siempre, en el borde si estan lejos)
	for e in m.enemies:
		if e.dead or not e.boss:
			continue
		var q: Vector2 = _edge(_pt(e.position))
		draw_circle(q, 11.0, Color(0.88, 0.14, 0.23, 0.45 + 0.2 * pul))
		draw_arc(q, 11.0, 0.0, TAU, 20, Color.WHITE, 1.5)
		if not _pk_at(e, 22.0, q):
			draw_circle(q, 5.0, Color("#e0243a"))
	# grieta (siempre)
	if m.rift != null and is_instance_valid(m.rift):
		var q: Vector2 = _edge(_pt(m.rift.position))
		draw_circle(q, 7.5 + 1.5 * pul, Color(0.7, 0.4, 1.0, 0.35))
		draw_circle(q, 6.0, Color.WHITE)
		draw_circle(q, 4.8, Color("#9b4dff"))
		draw_arc(q, 3.0, 0.0, TAU * 0.75, 12, Color.WHITE, 1.4)
		# brujula: si queda fuera del radio, una puntita apunta hacia ella
		var rq: Vector2 = _pt(m.rift.position)
		if rq.distance_to(CT) > RAD - 12.0:
			var ad: Vector2 = (rq - CT).normalized()
			var base: Vector2 = CT + ad * (RAD - 2.0)
			var perp := Vector2(-ad.y, ad.x)
			draw_colored_polygon(PackedVector2Array([base + ad * 7.0, base - ad * 2.0 + perp * 6.0, base - ad * 2.0 - perp * 6.0]), Color(0.9, 0.82, 1.0, 0.8 + 0.2 * pul))
	# jugador
	draw_circle(c, 9.0, Color(1, 1, 1, 0.35))
	draw_arc(c, 9.0, 0.0, TAU, 20, Color("#ffd23f"), 1.5)
	if not _pk_at(m.player, 20.0, c):
		draw_circle(c, 3.0, Color("#ffd23f"))
