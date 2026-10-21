extends Node2D
# Mapa infinito por casillas (world.js + tiles.js del juego original).
# 16 px de arte por casilla, escalado x3. El terreno (suelo / pared / liquido) sale de
# ruido; cada trozo de 16x16 casillas se hornea juntando casillas ya pintadas.
# Hay 3 biomas y despues las paletas de las 18 arenas; cambian cada 4 minutos.

const MX = preload("res://scripts/util/mathx.gd")
const AS = preload("res://scripts/arena.gd")
const T := 16
const N := 16
const TS := 48.0
const CW := 768.0
const FLOOR := 0
const WALL := 1
const LIQUID := 2
const FADE := 2.6
const LAKE_CELL := 30.0
const LAKE_P := 0.6
const SHORE_WALL := 0.66

const NORMAL := [
	{"name": "Bosque Umbrío", "liquid": "water", "prop": "tree",
		"floor": ["#3e7a39", "#44813d", "#397134"], "dirt": ["#7d6742", "#735e3b", "#86704a"], "speck": "#2f5f2b", "light": "#5f9d50",
		"flowers": ["#f4d65c", "#f39ac0", "#eef2ff"], "wallTop": ["#5d6e49", "#677a50", "#566544"], "wallLight": "#88a06e", "wallEdge": "#26301f",
		"wallFace": ["#3e4934", "#363f2d"], "wallFaceDark": "#232a1d", "liq": "#3b7fc6", "liqDeep": "#2c64a6", "foam": "#b3defa", "shore": "#2b5b2a",
		"leaf": ["#235a2b", "#2f7535", "#45943f", "#64b252"], "trunk": ["#5b3b22", "#7a5130"], "rock": ["#5e6670", "#7f8893", "#a1aab4"], "grass": ["#2f6b2c", "#4c9a3f", "#7cc45a"]},
	{"name": "Cueva Cristal", "liquid": "water", "prop": "crystal",
		"floor": ["#4d5778", "#535e81", "#47506f"], "dirt": ["#3c4462", "#424a69", "#37405b"], "speck": "#3b4363", "light": "#6a78a4",
		"flowers": ["#8fe3ff", "#c9a6ff", "#7ef0d0"], "wallTop": ["#5f5089", "#695996", "#56497d"], "wallLight": "#a08ddc", "wallEdge": "#1f1934",
		"wallFace": ["#3f3463", "#382e59"], "wallFaceDark": "#221c3a", "liq": "#2a9cab", "liqDeep": "#1d7c8a", "foam": "#aaf4f7", "shore": "#33405e",
		"leaf": ["#5ad1e8", "#8fe7f5", "#c8f7ff", "#ffffff"], "trunk": ["#3a4a78", "#4e64a0"], "rock": ["#555d79", "#737c9c", "#959fc0"], "grass": ["#3d5c8a", "#5a86c0", "#8ab8ee"]},
	{"name": "Volcán Ceniza", "liquid": "lava", "prop": "dead",
		"floor": ["#5b4537", "#644c3c", "#533f32"], "dirt": ["#403530", "#473b34", "#392f2b"], "speck": "#47362b", "light": "#806452",
		"flowers": ["#ff8d3d", "#ffc45e", "#e06a4a"], "wallTop": ["#3c3634", "#443d3a", "#35302e"], "wallLight": "#625752", "wallEdge": "#141110",
		"wallFace": ["#2b2624", "#25201f"], "wallFaceDark": "#151211", "liq": "#e45a1f", "liqDeep": "#b9401a", "foam": "#ffd46a", "shore": "#3a2a22",
		"leaf": ["#4a3a30", "#5e4a3c", "#6f5a49", "#806a58"], "trunk": ["#3a2e27", "#52423a"], "rock": ["#4e4642", "#6a605b", "#877c76"], "grass": ["#6b4a2a", "#94693a", "#c4914e"]},
]

# cantidad de terreno (ajustable): liquido y paredes crecen con la distancia al inicio
var liq_base := 0.05
var liq_grow := 0.17
var wall_grow := 0.27

var seed_v := 1
var biome := 0
var prev_biome := 0
var center := Vector2.ZERO
var terr := {}
const SHORE_OFFS: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(2, 0), Vector2i(-2, 0), Vector2i(0, 2), Vector2i(0, -2), Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)]
var raw_c := {}   # terreno crudo ya calculado (la orilla lo pide ~13 veces por casilla)
var dirt := {}
var chunks := {}
var sets := {}
var pals := {}
var fade_t := 1.0
# Смена биома без «полукарты»: следующий биом заранее запекается в фоне (prepare_biome) в ch["nx"], а растворение
# держится на нуле (fade_hold), пока у всех видимых кусков нет новой текстуры; после HOLD_MAX видимые допекаются сразу.
var nx_biome := -1
var fade_hold := 0.0
const HOLD_MAX := 2.0
var queue: Array = []
var grass := {}
var gt := 0.0
var gl: Node2D
var theme_keys: Array = []
var cc := Vector2i(99999, 99999)


func _init() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if bake_thread:
		# necesario bakethread.txt junto al ejecutable: 0 = sin hilos (horneado sincrono con presupuesto), 1/2 = tareas a la vez
		var bf := FileAccess.open(OS.get_executable_path().get_base_dir().path_join("bakethread.txt"), FileAccess.READ)
		if bf != null:
			var txt: String = bf.get_as_text().strip_edges()
			if txt.is_valid_int():
				var nj: int = int(txt)
				if nj <= 0:
					bake_thread = false
				elif nj <= 2:
					bake_jobs = nj
		var ua := OS.get_cmdline_user_args()
		var ji := ua.find("--bakejobs")
		if ji >= 0 and ji + 1 < ua.size():
			bake_jobs = clampi(int(ua[ji + 1]), 1, 2)
		var di := ua.find("--bakeslow")   # prueba: cada tarea espera tantos ms (emula hilos lentos y comprueba la docruta)
		if di >= 0 and di + 1 < ua.size():
			bake_delay = int(ua[di + 1])
	for k in AS.THEMES.keys():
		if k != "judgment":
			theme_keys.append(k)


func _ready() -> void:
	gl = GrassLayer.new()
	gl.tw = self
	gl.z_index = 1
	add_child(gl)
	z_index = -3


func count() -> int:
	return 3 + theme_keys.size()


func setup(sd: int) -> void:
	_bake_cancel()   # las tareas del hilo calculan con la semilla vieja
	seed_v = sd


# ---------------- paletas y juegos de casillas ----------------

func pal(b: int) -> Dictionary:
	if pals.has(b):
		return pals[b]
	var p: Dictionary
	if b < 3:
		var d: Dictionary = NORMAL[b]
		p = {"name": d["name"], "liquid": d["liquid"], "prop": d["prop"]}
		for k in ["floor", "dirt", "wallTop", "wallFace", "flowers", "leaf", "trunk", "rock", "grass"]:
			var a: Array = []
			for h in d[k]:
				a.append(Color(String(h)))
			p[k] = a
		for k in ["speck", "light", "wallLight", "wallEdge", "wallFaceDark", "liq", "liqDeep", "foam", "shore"]:
			p[k] = Color(String(d[k]))
	else:
		var th: Dictionary = AS.THEMES[theme_keys[b - 3]]
		p = MX.make_palette(th)
		p["name"] = th["name"]
	pals[b] = p
	return p


func biome_name(b: int) -> String:
	return String(pal(b)["name"])


func liquid_kind() -> String:
	return String(pal(biome)["liquid"])


func _pk(c: Color) -> int:
	return AS.pk(c)


func _arr(a: Array) -> Array:
	var o: Array = []
	for c in a:
		o.append(_pk(c))
	return o


func tset(b: int) -> Dictionary:
	if sets.has(b):
		return sets[b]
	var B: Dictionary = pal(b)
	var C := {}
	for k in ["floor", "dirt", "wallTop", "wallFace", "flowers"]:
		C[k] = _arr(B[k])
	for k in ["speck", "light", "wallLight", "wallEdge", "wallFaceDark", "liq", "liqDeep", "foam", "shore"]:
		C[k] = _pk(B[k])
	C["liqLight"] = _pk((B["liq"] as Color).lerp(B["foam"], 0.28))
	var S := {"C": C, "floors": [], "wall": {}, "liq": {}, "dirt": {}, "spr": {}, "fimg": {}, "pal": B}
	var fl: Array = S["floors"]
	for v in range(12):
		fl.append(_floor_pix(C, 100 + v, 300 + v * 3, 0, 0))
	for v in range(4):
		fl.append(_floor_pix(C, 200 + v, 400 + v, 1, 0))
	for v in range(6):
		fl.append(_floor_pix(C, 210 + v, 410 + v, 2, v % 3))
	for v in range(3):
		fl.append(_floor_pix(C, 220 + v, 420 + v, 3, 0))
	var sh := AS.Pix.new(T, 2)
	for x in range(T):
		sh.set_px(x, 0, C["wallFaceDark"])
		if x % 2 == 1:
			sh.set_px(x, 1, C["speck"])
	S["shadow"] = sh.img()
	sets[b] = S
	return S


func _floor_pix(C: Dictionary, vx: int, vy: int, detail: int, ci: int):
	var P := AS.Pix.new(T, T)
	var fl: Array = C["floor"]
	for y in range(T):
		for x in range(T):
			var gx: int = vx * T + x
			var gy: int = vy * T + y
			var band: float = MX.hsh(gx >> 3, gy >> 3, 11) * 0.7 + MX.hsh(gx, gy, 12) * 0.5
			var col: int = fl[mini(2, int(band * 3.0 / 1.2))]
			var rr: float = MX.hsh(gx, gy, 13)
			if rr < 0.035:
				col = C["speck"]
			elif rr > 0.985:
				col = C["light"]
			P.set_px(x, y, col)
	var dx: int = 3 + int(MX.hsh(vx, vy, 15) * 10.0)
	var dy: int = 4 + int(MX.hsh(vx, vy, 16) * 9.0)
	var lt: int = C["light"]
	var sp: int = C["speck"]
	if detail == 1:
		P.set_px(dx, dy, lt)
		P.set_px(dx - 1, dy - 1, lt)
		P.set_px(dx + 1, dy - 1, lt)
		P.set_px(dx, dy - 2, lt)
		P.set_px(dx, dy + 1, sp)
	elif detail == 2:
		var fc: int = (C["flowers"] as Array)[ci]
		P.set_px(dx, dy - 1, fc)
		P.set_px(dx - 1, dy, fc)
		P.set_px(dx + 1, dy, fc)
		P.set_px(dx, dy + 1, fc)
		P.set_px(dx, dy, lt)
	elif detail == 3:
		P.set_px(dx, dy, lt)
		P.set_px(dx + 1, dy, lt)
		P.set_px(dx, dy + 1, sp)
		P.set_px(dx + 1, dy + 1, sp)
	return P


func _edge_d(x: int, y: int, n: bool, s: bool, w: bool, e: bool, nw: bool, ne: bool, sw: bool, se: bool) -> float:
	var BIG := 99.0
	var d: float = minf(minf(BIG if n else float(y), BIG if s else float(T - 1 - y)), minf(BIG if w else float(x), BIG if e else float(T - 1 - x)))
	if n and w and not nw:
		d = minf(d, Vector2(x, y).length() - 0.5)
	if n and e and not ne:
		d = minf(d, Vector2(T - 1 - x, y).length() - 0.5)
	if s and w and not sw:
		d = minf(d, Vector2(x, T - 1 - y).length() - 0.5)
	if s and e and not se:
		d = minf(d, Vector2(T - 1 - x, T - 1 - y).length() - 0.5)
	return d


func _wall_img(S: Dictionary, key: int, v: int) -> Image:
	var kk: int = key * 3 + v
	var cache: Dictionary = S["wall"]
	if cache.has(kk):
		return cache[kk]
	var C: Dictionary = S["C"]
	var P = (S["floors"][0] as AS.Pix).dup()
	var n: bool = key & 1 != 0
	var s: bool = key & 2 != 0
	var w: bool = key & 4 != 0
	var e: bool = key & 8 != 0
	var face: int = 0 if s else 6
	var tops: Array = C["wallTop"]
	var faces: Array = C["wallFace"]
	for y in range(T):
		for x in range(T):
			if not n and not w and x + y < 3:
				continue
			if not n and not e and (T - 1 - x) + y < 3:
				continue
			if not s and not w and x + (T - 1 - y) < 2:
				continue
			if not s and not e and (T - 1 - x) + (T - 1 - y) < 2:
				continue
			var gx: int = (500 + v) * T + x
			var gy: int = (600 + v * 2) * T + y
			var col: int
			if y >= T - face:
				var fy: int = y - (T - face)
				var vv: int = 0 if MX.hsh(gx, 0, 21) < 0.5 else 1
				col = faces[1 if (x + vv) % 3 == 0 else 0]
				if fy == 0:
					col = C["wallEdge"]
				elif y == T - 1:
					col = C["wallFaceDark"]
				elif MX.hsh(gx, gy, 22) < 0.08:
					col = C["wallFaceDark"]
			else:
				col = tops[int(MX.hsh(gx >> 1, gy >> 1, 23) * 2.2 + MX.hsh(gx, gy, 24) * 0.8) % tops.size()]
				if MX.hsh(gx, gy, 25) < 0.05:
					col = C["wallLight"]
				if not n and y == 0:
					col = C["wallEdge"]
				elif not n and y == 1:
					col = C["wallLight"]
				if not w and x == 0:
					col = C["wallEdge"]
				if not e and x == T - 1:
					col = C["wallEdge"]
			P.set_px(x, y, col)
	var im: Image = P.img()
	cache[kk] = im
	return im


func _liq_img(S: Dictionary, key: int, v: int) -> Image:
	var kk: int = key * 2 + v
	var cache: Dictionary = S["liq"]
	if cache.has(kk):
		return cache[kk]
	var C: Dictionary = S["C"]
	var P = (S["floors"][0] as AS.Pix).dup()
	var n: bool = key & 1 != 0
	var s: bool = key & 2 != 0
	var w: bool = key & 4 != 0
	var e: bool = key & 8 != 0
	var nw: bool = key & 16 != 0
	var ne: bool = key & 32 != 0
	var sw: bool = key & 64 != 0
	var se: bool = key & 128 != 0
	for y in range(T):
		for x in range(T):
			if not n and not w and x + y < 3:
				continue
			if not n and not e and (T - 1 - x) + y < 3:
				continue
			if not s and not w and x + (T - 1 - y) < 3:
				continue
			if not s and not e and (T - 1 - x) + (T - 1 - y) < 3:
				continue
			var d: float = _edge_d(x, y, n, s, w, e, nw, ne, sw, se)
			var gx: int = (700 + v) * T + x
			var gy: int = (800 + v * 3) * T + y
			var rr: float = MX.hsh(gx, gy, 31)
			var col: int
			if d < 1.0:
				col = C["shore"]
			elif d < 2.0:
				col = C["foam"]
			elif d < 4.0:
				col = C["liqLight"]
			elif d < 6.0:
				col = C["liq"] if rr < 0.5 else C["liqLight"]
			else:
				col = C["liq"] if (d < 8.0 and rr < 0.5) else C["liqDeep"]
			if d >= 6.0 and d < 99.0 and rr < 0.08:
				col = C["liq"]
			if d >= 3.0 and MX.hsh(gx >> 2, gy, 33) < 0.045 and (gx & 3) != 3:
				col = C["liqLight"]
			if d >= 3.0 and MX.hsh(gx, gy, 34) < 0.004:
				col = C["foam"]
			P.set_px(x, y, col)
	var im: Image = P.img()
	cache[kk] = im
	return im


func _dirt_img(S: Dictionary, key: int, v: int) -> Image:
	var kk: int = key * 2 + v
	var cache: Dictionary = S["dirt"]
	if cache.has(kk):
		return cache[kk]
	var C: Dictionary = S["C"]
	var P = (S["floors"][v] as AS.Pix).dup()
	var n: bool = key & 1 != 0
	var s: bool = key & 2 != 0
	var w: bool = key & 4 != 0
	var e: bool = key & 8 != 0
	var nw: bool = key & 16 != 0
	var ne: bool = key & 32 != 0
	var sw: bool = key & 64 != 0
	var se: bool = key & 128 != 0
	var dt: Array = C["dirt"]
	for y in range(T):
		for x in range(T):
			if not n and not w and x + y < 3:
				continue
			if not n and not e and (T - 1 - x) + y < 3:
				continue
			if not s and not w and x + (T - 1 - y) < 3:
				continue
			if not s and not e and (T - 1 - x) + (T - 1 - y) < 3:
				continue
			var d: float = _edge_d(x, y, n, s, w, e, nw, ne, sw, se)
			var gx: int = (900 + v) * T + x
			var gy: int = (950 + v * 3) * T + y
			if d < 1.0 and MX.hsh(gx, gy, 35) < 0.45:
				continue
			if d >= 1.0 and d < 2.0 and MX.hsh(gx, gy, 36) < 0.18:
				continue
			var band: float = MX.hsh(gx >> 3, gy >> 3, 11) * 0.7 + MX.hsh(gx, gy, 12) * 0.5
			var col: int = dt[mini(2, int(band * 3.0 / 1.2))]
			var rr: float = MX.hsh(gx, gy, 13)
			if rr < 0.035:
				col = C["speck"]
			if d < 1.0 or (not n and y == 0):
				col = C["speck"]
			P.set_px(x, y, col)
	if MX.hsh(v, key, 14) < 0.35:
		var dx: int = 4 + int(MX.hsh(v, key, 15) * 8.0)
		var dy: int = 5 + int(MX.hsh(v, key, 16) * 7.0)
		P.set_px(dx, dy, C["light"])
		P.set_px(dx + 1, dy, C["light"])
		P.set_px(dx, dy + 1, C["speck"])
		P.set_px(dx + 1, dy + 1, C["speck"])
	var im: Image = P.img()
	cache[kk] = im
	return im


func prop_tex(name: String, b: int = -1) -> Texture2D:
	var S: Dictionary = tset(biome if b < 0 else b)
	var spr: Dictionary = S["spr"]
	if spr.is_empty():
		var a = AS.new()
		a.palette = S["pal"]
		a.th = {"prop": String(S["pal"]["prop"])}
		a._bake_props()
		for k in a.prop_imgs:
			spr[k] = ImageTexture.create_from_image(a.prop_imgs[k])
		a.free()
	return spr.get(name)


# ---------------- terreno ----------------

# Lagos grandes: cada celda de LAKE_CELL casillas puede tener un lago (elipse con orilla irregular),
# asi no salen charcos pequenos. Solo depende de las coordenadas.
# Lagos activos de las 9 celdas vecinas, guardados por celda: casi todas las casillas comparten celda y casi
# ninguna celda tiene lago, asi que se evita repetir ~20 hashes por casilla.
var _lk_key := Vector2i(1 << 30, 1 << 30)
var _lk_seed := -1
var _lk_list: Array = []


func _lake_cells(cx0: int, cy0: int) -> Array:
	if _lk_key != Vector2i(cx0, cy0) or _lk_seed != seed_v:
		_lk_key = Vector2i(cx0, cy0)
		_lk_seed = seed_v
		_lk_list = []
		for cy in range(cy0 - 1, cy0 + 2):
			for cx in range(cx0 - 1, cx0 + 2):
				if MX.hsh(cx, cy, seed_v + 500) > LAKE_P:
					continue
				var mx: float = (float(cx) + 0.15 + 0.7 * MX.hsh(cx, cy, seed_v + 501)) * LAKE_CELL
				var my: float = (float(cy) + 0.15 + 0.7 * MX.hsh(cx, cy, seed_v + 502)) * LAKE_CELL
				if Vector2(mx, my).length() < 15.0:
					continue
				var rx: float = 3.4 + 2.6 * MX.hsh(cx, cy, seed_v + 503)
				var ry: float = 3.0 + 2.2 * MX.hsh(cx, cy, seed_v + 504)
				_lk_list.append(Vector4(mx, my, rx, ry))
	return _lk_list


func _lake(tx: int, ty: int) -> bool:
	var lakes: Array = _lake_cells(floori(float(tx) / LAKE_CELL), floori(float(ty) / LAKE_CELL))
	if lakes.is_empty():
		return false
	var px: float = float(tx) + 0.5
	var py: float = float(ty) + 0.5
	for lk in lakes:
		var dx: float = (px - lk.x) / lk.z
		var dy: float = (py - lk.y) / lk.w
		var wob: float = (MX.fbm(px / 5.0, py / 5.0, seed_v + 111) - 0.5) * 1.5 + (MX.fbm(px / 2.2, py / 2.2, seed_v + 113) - 0.5) * 0.5
		if dx * dx + dy * dy < 1.0 + wob:
			return true
	return false


# Terreno "crudo": suelo, pared o liquido (sin cache; solo depende de las coordenadas).
func _raw(tx: int, ty: int) -> int:
	var rk := Vector2i(tx, ty)
	if raw_c.has(rk):
		return raw_c[rk]
	var rv: int = _raw_calc(tx, ty)
	raw_c[rk] = rv
	return rv


func _raw_calc(tx: int, ty: int) -> int:
	var d: float = Vector2(float(tx) + 0.5, float(ty) + 0.5).length()
	if d >= 9.0:
		var ramp: float = clampf((d - 9.0) / 8.0, 0.0, 1.0)
		if _lake(tx, ty):
			return LIQUID
		if MX.fbm(float(tx) / 8.0, float(ty) / 8.0, seed_v + 202) > 1.0 - wall_grow * ramp:
			return WALL
	return FLOOR


func terrain(tx: int, ty: int) -> int:
	var k := Vector2i(tx, ty)
	if terr.has(k):
		return terr[k]
	var res: int = _raw(tx, ty)
	# Orilla: junto al agua aparecen tramos de pared de tierra (como barrancos)
	if res == FLOOR and Vector2(float(tx) + 0.5, float(ty) + 0.5).length() >= 12.0:
		var near_liq := false
		for o in SHORE_OFFS:   # los 13 vecinos con |ox|+|oy| <= 2; al primer agua se corta
			if _raw(tx + o.x, ty + o.y) == LIQUID:
				near_liq = true
				break
		# barrancos: tramos de pared de tierra pegados a la orilla (se rompen con ruido para dejar pasos)
		if near_liq and MX.fbm(float(tx) / 3.5, float(ty) / 3.5, seed_v + 910) > SHORE_WALL:
			res = WALL
	terr[k] = res
	return res


func is_dirt(tx: int, ty: int) -> bool:
	var k := Vector2i(tx, ty)
	if dirt.has(k):
		return dirt[k]
	var r: bool = terrain(tx, ty) == FLOOR and MX.fbm(float(tx) / 6.0, float(ty) / 6.0, seed_v + 303) > 0.66
	dirt[k] = r
	return r


func tile_of(pos: Vector2) -> Vector2i:
	return Vector2i(floori(pos.x / TS), floori(pos.y / TS))


func liquid_at(pos: Vector2) -> String:
	var t: Vector2i = tile_of(pos)
	if terrain(t.x, t.y) == LIQUID:
		return liquid_kind()
	return ""


func open_at(tx: int, ty: int) -> bool:
	for b in range(-1, 2):
		for a in range(-1, 2):
			if terrain(tx + a, ty + b) != FLOOR:
				return false
	return true


# Los arboles son altos: necesitan casillas libres tambien alrededor y hacia arriba (para que la copa no se meta en una pared).
func tree_clear(tx: int, ty: int) -> bool:
	for b in range(-2, 2):
		for a in range(-1, 2):
			if terrain(tx + a, ty + b) != FLOOR:
				return false
	return true


func collide(pos: Vector2, rad: float) -> Vector2:
	var t: Vector2i = tile_of(pos)
	var rng: int = 1 + int(rad / TS)
	for dy in range(-rng, rng + 1):
		for dx in range(-rng, rng + 1):
			if terrain(t.x + dx, t.y + dy) == WALL:
				pos = AS.push_rect(pos, rad, Rect2(float(t.x + dx) * TS, float(t.y + dy) * TS, TS, TS))
	return pos


# ---------------- trozos ----------------

func chunk_of(pos: Vector2) -> Vector2i:
	return Vector2i(floori(pos.x / CW), floori(pos.y / CW))


func set_center(c: Vector2i) -> void:
	cc = c
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			var key := Vector2i(c.x + dx, c.y + dy)
			if not chunks.has(key):
				chunks[key] = {"tex": null, "old": null, "tb": -1, "liq": []}
				queue.append(key)
	if not view_ok:   # con vista (en juego) los descarta _view_chunks por el rectangulo; sin ella, por distancia
		for key in chunks.keys():
			if absi(key.x - c.x) > 2 or absi(key.y - c.y) > 2:
				chunks.erase(key)
				queue.erase(key)
	for key in grass.keys():
		if absi(key.x - c.x) > 3 or absi(key.y - c.y) > 3:
			grass.erase(key)
			for j in range(N):
				for i in range(N):
					var k := Vector2i(key.x * N + i, key.y * N + j)
					terr.erase(k)
					dirt.erase(k)
					raw_c.erase(k)
	_queue_sort()


# Hornea ya los trozos pendientes (al empezar: el suelo aparece completo desde el primer fotograma)
func flush_bake() -> void:
	_bake_drain()
	if bk_key != Vector2i(99999, 99999):
		if chunks.has(bk_key) and bk_biome == biome:
			_bake_rows(bk_key, bk_img, bk_liq, bk_row, N)
			_bake_finish(bk_key, bk_img, bk_liq)
		bk_key = Vector2i(99999, 99999)
	while not queue.is_empty():
		var key: Vector2i = queue.pop_front()
		if chunks.has(key):
			bake_chunk(key)
	queue_redraw()


func set_biome(b: int, instant: bool = false) -> void:
	b = posmod(b, count())
	if b == biome:
		return
	prev_biome = biome
	biome = b
	fade_t = 1.0 if instant else 0.0
	fade_hold = 0.0
	for key in chunks:
		var ch: Dictionary = chunks[key]
		var pre = ch.get("nx") if int(ch.get("nxb", -1)) == b else null
		if ch["tex"] != null:
			ch["old"] = null if instant else ch["tex"]
			ch["tex"] = null
			if pre == null and not queue.has(key):
				queue.append(key)
		if pre != null:
			ch["tex"] = pre   # запечён заранее: готов в тот же кадр
			ch["tb"] = b
			ch["liq"] = ch["nxl"]
			ch.erase("liqd")
			queue.erase(key)
		ch.erase("nx")
		ch.erase("nxb")
		ch.erase("nxl")
	nx_biome = -1
	_queue_sort()
	if is_inside_tree():
		get_tree().call_group("fade_props", "set_process", true)   # árboles y rocas duermen salvo durante el cambio de bioma


# Следующий биом (абсолютный индекс как в set_biome): его куски вокруг вида запекаются в фоне, когда текущих дел нет.
func prepare_biome(b: int) -> void:
	b = posmod(b, count())
	if b == biome or b == nx_biome:
		return
	nx_biome = b
	for key in chunks:
		chunks[key].erase("nx")
		chunks[key].erase("nxb")
		chunks[key].erase("nxl")


func _nx_has(key: Vector2i) -> bool:
	var ch: Dictionary = chunks[key]
	return ch.has("nx") and int(ch["nxb"]) == nx_biome


func _nx_store(key: Vector2i, img: Image, liq: Array) -> void:
	var ch: Dictionary = chunks[key]
	ch["nx"] = ImageTexture.create_from_image(img)
	ch["nxb"] = nx_biome
	ch["nxl"] = liq


# Следующий кусок для заранее запекаемого биома: из pre_r (вид + запас), по приоритету; без вида — ближайшие к центру.
func _nx_pick() -> Vector2i:
	if nx_biome < 0 or nx_biome == biome:
		return NO_KEY
	var best := NO_KEY
	var bp := 1e9
	for key in chunks:
		if _nx_has(key) or _nx_busy(key):
			continue
		if view_ok and not Rect2(float(key.x) * CW, float(key.y) * CW, CW, CW).intersects(pre_r):
			continue
		var pv: float = _prio(key)
		if pv < bp:
			bp = pv
			best = key
	return best


func _nx_busy(key: Vector2i) -> bool:
	for j in jobs:
		if j.key == key and j.biome == nx_biome:
			return true
	for j in done_jobs:
		if j.key == key and j.biome == nx_biome:
			return true
	return nk_key == key and nk_biome == nx_biome


const NO_KEY := Vector2i(99999, 99999)


# Все куски под видом (с FORCE_PAD), где сейчас виден старый биом, уже имеют новую текстуру.
func _vis_ready() -> bool:
	if not view_ok:
		return true
	for key in _keys_in(vis_r.grow(FORCE_PAD)):
		var ch: Dictionary = chunks.get(key, {})
		if not ch.is_empty() and ch["old"] != null and not _ready_tex(ch):
			return false
	return true


func bake_chunk(key: Vector2i) -> void:
	var img := Image.create(N * T, N * T, false, Image.FORMAT_RGBA8)
	var liq: Array = []
	_bake_rows(key, img, liq, 0, N)
	_bake_finish(key, img, liq)


# Hornea un trozo por franjas de filas (una franja por fotograma en juego) para no hacer tirones.
var bk_key := Vector2i(99999, 99999)
var bk_img: Image
var bk_liq: Array = []
var bk_row := 0
var bk_biome := -1
const BK_ROWS := 1


func _bake_step() -> bool:
	if bk_key == Vector2i(99999, 99999):
		if not jobs.is_empty() or not done_jobs.is_empty():
			_bake_drain()   # carga: el que llama espera al final, aqui se esperan las tareas del hilo
			return true
		while not queue.is_empty():
			var k: Vector2i = queue.pop_front()
			if chunks.has(k):
				bk_key = k
				bk_img = Image.create(N * T, N * T, false, Image.FORMAT_RGBA8)
				bk_liq = []
				bk_row = 0
				bk_biome = biome
				break
		if bk_key == Vector2i(99999, 99999):
			return _nx_step()
	if not chunks.has(bk_key) or bk_biome != biome:
		# el trozo se descarto o cambio el bioma a medias: set_biome ya lo vuelve a encolar
		if chunks.has(bk_key) and not queue.has(bk_key):
			queue.push_front(bk_key)
		bk_key = Vector2i(99999, 99999)
		return true
	_bake_rows(bk_key, bk_img, bk_liq, bk_row, mini(N, bk_row + BK_ROWS))
	bk_row += BK_ROWS
	if bk_row >= N:
		_bake_finish(bk_key, bk_img, bk_liq)
		bk_key = Vector2i(99999, 99999)
	return true


# Без потоков: следующий биом по строкам, только когда текущих кусков в очереди нет.
var nk_key := NO_KEY
var nk_img: Image
var nk_liq: Array = []
var nk_row := 0
var nk_biome := -1


func _nx_step() -> bool:
	if nk_key != NO_KEY and (not chunks.has(nk_key) or nk_biome != nx_biome):
		nk_key = NO_KEY
	if nk_key == NO_KEY:
		var k: Vector2i = _nx_pick()
		if k == NO_KEY:
			return false
		nk_key = k
		nk_img = Image.create(N * T, N * T, false, Image.FORMAT_RGBA8)
		nk_liq = []
		nk_row = 0
		nk_biome = nx_biome
	_bake_rows(nk_key, nk_img, nk_liq, nk_row, mini(N, nk_row + BK_ROWS), nk_biome)
	nk_row += BK_ROWS
	if nk_row >= N:
		_nx_store(nk_key, nk_img, nk_liq)
		nk_key = NO_KEY
	return false   # на экране ничего не меняется


func _bake_finish(key: Vector2i, img: Image, liq: Array) -> void:
	var ch: Dictionary = chunks[key]
	ch["tex"] = ImageTexture.create_from_image(img)
	ch["tb"] = biome
	ch["liq"] = liq
	ch.erase("liqd")


func _bake_rows(key: Vector2i, img: Image, liq: Array, j0: int, j1: int, b: int = -1) -> void:
	var S: Dictionary = tset(biome if b < 0 else b)
	var bx: int = key.x * N
	var by: int = key.y * N
	for j in range(j0, j1):
		for i in range(N):
			var tx: int = bx + i
			var ty: int = by + j
			var k: int = terrain(tx, ty)
			var tile: Image
			if k == WALL:
				var key4: int = int(terrain(tx, ty - 1) == WALL) | (int(terrain(tx, ty + 1) == WALL) << 1) | (int(terrain(tx - 1, ty) == WALL) << 2) | (int(terrain(tx + 1, ty) == WALL) << 3)
				tile = _wall_img(S, key4, int(MX.hsh(tx, ty, 21) * 3.0) % 3)
			elif k == LIQUID:
				var m := 0
				var nb: Array = [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, 1)]
				for q in range(8):
					if terrain(tx + nb[q].x, ty + nb[q].y) == LIQUID:
						m |= 1 << q
				tile = _liq_img(S, m, int(MX.hsh(tx, ty, 32) * 2.0) % 2)
				liq.append(Vector2i(tx, ty))
			elif is_dirt(tx, ty):
				var m2 := 0
				var nb2: Array = [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, 1)]
				for q in range(8):
					if is_dirt(tx + nb2[q].x, ty + nb2[q].y):
						m2 |= 1 << q
				tile = _dirt_img(S, m2, int(MX.hsh(tx, ty, 37) * 2.0) % 2)
			else:
				var d: float = MX.hsh(tx, ty, 14)
				var idx: int
				if d < 0.14:
					idx = 12 + int(MX.hsh(tx, ty, 15) * 4.0) % 4
				elif d < 0.20:
					idx = 16 + int(MX.hsh(tx, ty, 17) * 6.0) % 6
				elif d < 0.25:
					idx = 22 + int(MX.hsh(tx, ty, 18) * 3.0) % 3
				else:
					idx = int(MX.hsh(tx, ty, 16) * 12.0) % 12
				tile = _floor_img(S, idx)
			img.blit_rect(tile, Rect2i(0, 0, T, T), Vector2i(i * T, j * T))
			if k == FLOOR and terrain(tx, ty - 1) == WALL:
				img.blend_rect(S["shadow"], Rect2i(0, 0, T, 2), Vector2i(i * T, j * T))


# ---------------- horneado en hilo (consola) ----------------
# El trabajo (terreno + casillas + blit) corre en WorkerThreadPool sobre un clon privado de este nodo (sin arbol,
# con sus propias cachés terr/dirt/raw_c/sets): el hilo no toca nada del principal. Solo se queda en el principal
# crear la textura (un trozo por fotograma), el resultado de pixeles es el mismo que el del horneado sincrono.
class BakeJob extends RefCounted:
	var key := Vector2i.ZERO
	var biome := 0
	var slot := 0
	var tid := -1
	var img: Image
	var liq: Array = []
	var dur := 0   # microsegundos que tardo la tarea (lo escribe el hilo, se lee tras esperarla)

const SLOW_MS := 45.0       # umbral para bajar temporalmente la carga del trabajador
const SLOW_N := 5           # fotogramas lentos consecutivos antes de pausar nuevos trabajos
const BAKE_PAUSE_SEC := 1.5 # da tiempo al hilo principal a recuperar fluidez
const FORCE_PAD := 128.0    # margen (px de mundo) del rectangulo visible dentro del cual un trozo sin textura se hornea YA
const LOOK_T := 1.5         # segundos de anticipo segun la velocidad
const MAX_KEEP := 64        # tope de trozos vivos (256x256x4 = 256 KB de textura cada uno)
const BAKE_BUDGET := 3000   # microsegundos por fotograma para terminar trozos (create_from_image)
const CLONE_CACHE := 9000   # casillas en la caché del clon antes de vaciarla
var bake_thread: bool = (OS.has_feature("handheld") or "--keys-only" in OS.get_cmdline_user_args() or "--bakethread" in OS.get_cmdline_user_args()) and not "--nobakethread" in OS.get_cmdline_user_args()
# tareas a la vez: en la consola 1 (4 nucleos A53: al principal le quedan el sonido y gptokeyb), en Mac 2; bakethread.txt / --bakejobs lo cambian
var bake_jobs: int = 1 if OS.has_feature("handheld") else 2
var bake_delay := 0         # solo pruebas (--bakeslow)
var slow_n := 0
var bake_pause_t := 0.0
var view_ok := false        # ya hay rectangulo visible de la camara
var vis_r := Rect2()        # lo que ve la camara
var pre_r := Rect2()        # vis_r + 1 trozo en todo el borde + anticipo hacia delante: aqui los trozos tienen que estar listos
var keep_r := Rect2()       # pre_r + medio trozo: fuera de aqui se descartan
var vel := Vector2.ZERO     # velocidad de la camara, px/s (suavizada)
var vdir := Vector2.ZERO
var prev_vc := Vector2.ZERO
var prev_ok := false
var sort_t := 0
var jobs: Array = []        # tareas en el pool
var done_jobs: Array = []       # tareas terminadas a la espera de crear la textura
var _clones: Array = []


# Prioridad de un trozo (menor = antes): 0 los que toca la vista (con margen), 1 los de por delante segun el movimiento, 2 el resto;
# dentro de la clase, por cercania al centro de la vista menos un premio a lo que queda por delante.
func _prio(key: Vector2i) -> float:
	if not view_ok:
		var d: Vector2i = key - cc
		return float(absi(d.x) + absi(d.y))
	var cell := Rect2(float(key.x) * CW, float(key.y) * CW, CW, CW)
	var dv: Vector2 = (cell.get_center() - vis_r.get_center()) / CW
	var fwd: float = dv.dot(vdir)
	var cls := 2
	if cell.intersects(vis_r.grow(FORCE_PAD)):
		cls = 0
	elif vel.length_squared() > 400.0 and fwd > 0.0:
		cls = 1
	return float(cls) * 100.0 + dv.length() - 0.6 * fwd


func _queue_sort() -> void:
	queue.sort_custom(func(a, b2): return _prio(a) < _prio(b2))


func _keys_in(r: Rect2) -> Array:
	var out: Array = []
	var x0: int = floori(r.position.x / CW)
	var y0: int = floori(r.position.y / CW)
	var x1: int = floori((r.end.x - 0.01) / CW)
	var y1: int = floori((r.end.y - 0.01) / CW)
	for ky in range(y0, y1 + 1):
		for kx in range(x0, x1 + 1):
			out.append(Vector2i(kx, ky))
	return out


# Rectangulo visible de la camara (mundo), velocidad y los rectangulos de anticipo/retencion.
func _view_update(delta: float) -> void:
	var vp := get_viewport()
	if vp == null:
		return
	# transformacion propia hasta la pantalla (camara + padres): en el fondo del menu el mundo se mueve con el nodo padre, sin
	# camara, y con la del viewport la "vista" quedaba en el origen: horneaba trozos que no se ven y no los de la camara.
	var r: Rect2 = get_global_transform_with_canvas().affine_inverse() * Rect2(Vector2.ZERO, vp.get_visible_rect().size)
	if not (r.size.x > 1.0 and r.size.y > 1.0 and r.size.x < 20000.0 and is_finite(r.position.x) and is_finite(r.position.y)):
		return
	vis_r = r
	var vc := r.get_center()
	if prev_ok and delta > 0.0:
		var v := (vc - prev_vc) / delta
		if v.length() > 3000.0:
			v = Vector2.ZERO   # salto (teletransporte): no es velocidad
		vel = vel.lerp(v, 0.25)
	prev_vc = vc
	prev_ok = true
	vdir = vel.normalized() if vel.length_squared() > 400.0 else Vector2.ZERO
	var look: Vector2 = (vel * LOOK_T).limit_length(2.0 * CW)
	var base := r.grow(CW)
	pre_r = base.merge(Rect2(base.position + look, base.size))
	keep_r = pre_r.grow(CW * 0.5)
	view_ok = true


# Crea (y encola) los trozos de pre_r y descarta los que quedan fuera de keep_r (y de los 5x5 del centro).
func _view_chunks() -> bool:
	var changed := false
	for key in _keys_in(pre_r):
		if not chunks.has(key):
			chunks[key] = {"tex": null, "old": null, "tb": -1, "liq": []}
			queue.append(key)
			changed = true
	for key in chunks.keys():
		var cell := Rect2(float(key.x) * CW, float(key.y) * CW, CW, CW)
		if not cell.intersects(keep_r) and (absi(key.x - cc.x) > 2 or absi(key.y - cc.y) > 2):
			chunks.erase(key)
			queue.erase(key)
	if chunks.size() > MAX_KEEP:   # tope de memoria: fuera los de menor prioridad (nunca los visibles)
		var ks: Array = chunks.keys()
		ks.sort_custom(func(a, b2): return _prio(a) > _prio(b2))
		for key in ks:
			if chunks.size() <= MAX_KEEP or _prio(key) < 100.0:
				break
			chunks.erase(key)
			queue.erase(key)
	return changed


func _job_run(job: BakeJob) -> void:
	var cl = _clones[job.slot]
	var t0 := Time.get_ticks_usec()
	if bake_delay > 0:
		OS.delay_msec(bake_delay)
	cl._bake_rows(job.key, job.img, job.liq, 0, N)
	job.dur = Time.get_ticks_usec() - t0


func _job_covers(key: Vector2i) -> bool:
	for j in jobs:
		if j.key == key and j.biome == biome:
			return true
	for j in done_jobs:
		if j.key == key and j.biome == biome:
			return true
	return false


func _job_start(key: Vector2i, b: int = -1) -> void:
	if b < 0:
		b = biome
	var slot := 0
	while true:
		var used := false
		for j in jobs:
			if j.slot == slot:
				used = true
		if not used:
			break
		slot += 1
	while _clones.size() < bake_jobs:
		_clones.append(get_script().new())
	var cl = _clones[slot]
	if cl.seed_v != seed_v or cl.terr.size() > CLONE_CACHE:
		cl.terr.clear()
		cl.dirt.clear()
		cl.raw_c.clear()
	if cl.biome != b and cl.sets.size() > 1:
		cl.sets.clear()   # в клоне держим наборы двух биомов (текущий и следующий), не больше
	cl.seed_v = seed_v
	cl.biome = b
	cl.liq_base = liq_base
	cl.liq_grow = liq_grow
	cl.wall_grow = wall_grow
	var job := BakeJob.new()
	job.key = key
	job.biome = b
	job.slot = slot
	job.img = Image.create(N * T, N * T, false, Image.FORMAT_RGBA8)
	job.tid = WorkerThreadPool.add_task(_job_run.bind(job), false, "bake_chunk")
	jobs.append(job)


# Termina un trozo horneado en el hilo; false si ya no hace falta (se descartó o cambió el bioma): entonces se vuelve a encolar.
func _job_take(j: BakeJob) -> bool:
	Prof.bk_task_n += 1
	Prof.bk_task_us += j.dur
	if not chunks.has(j.key):
		return false
	var ch: Dictionary = chunks[j.key]
	if j.biome != biome:
		if ch["tex"] == null and not queue.has(j.key) and not _job_covers(j.key):
			queue.append(j.key)
			_queue_sort()
		return false
	if ch["tex"] != null and ch["tb"] == biome:
		return false
	_bake_finish(j.key, j.img, j.liq)
	return true


func _bake_tick() -> bool:
	if not bake_thread:
		return _bake_step()
	var t0 := Time.get_ticks_usec()
	var did := false
	var i := 0
	while i < jobs.size():
		var j: BakeJob = jobs[i]
		if WorkerThreadPool.is_task_completed(j.tid):
			WorkerThreadPool.wait_for_task_completion(j.tid)
			jobs.remove_at(i)
			done_jobs.append(j)
		else:
			i += 1
	# un trozo por fotograma (el mas cercano/adelantado), los inservibles se tiran todos
	var best := -1
	var bk := 1e9
	var nxi := -1
	i = 0
	while i < done_jobs.size():
		var j: BakeJob = done_jobs[i]
		if chunks.has(j.key) and j.biome == nx_biome and j.biome != biome:
			if nxi < 0:
				nxi = i
			i += 1
			continue
		if not chunks.has(j.key) or j.biome != biome:
			done_jobs.remove_at(i)
			_job_take(j)
			continue
		var kv: float = _prio(j.key)
		if kv < bk:
			bk = kv
			best = i
		i += 1
	if best >= 0 and Time.get_ticks_usec() - t0 < BAKE_BUDGET:
		var jb: BakeJob = done_jobs[best]
		done_jobs.remove_at(best)
		did = _job_take(jb)
	elif best < 0 and nxi >= 0 and Time.get_ticks_usec() - t0 < BAKE_BUDGET:
		# заранее запечённый кусок следующего биома: текстура создаётся только в кадр без текущих кусков
		var jn: BakeJob = done_jobs[nxi]
		done_jobs.remove_at(nxi)
		_nx_store(jn.key, jn.img, jn.liq)
	while bake_pause_t <= 0.0 and jobs.size() < bake_jobs and done_jobs.size() < 2 and not queue.is_empty():
		var k: Vector2i = queue.pop_front()
		if chunks.has(k) and not _job_covers(k) and not (chunks[k]["tex"] != null and chunks[k]["tb"] == biome):
			_job_start(k)
	if bake_pause_t <= 0.0 and jobs.size() < bake_jobs and done_jobs.is_empty() and queue.is_empty():
		var nk: Vector2i = _nx_pick()
		if nk != NO_KEY:
			_job_start(nk, nx_biome)
	return did


# Espera todas las tareas y termina sus trozos (flush_bake, carga, cambio de bioma instantaneo).
func _bake_drain() -> void:
	for j in jobs:
		WorkerThreadPool.wait_for_task_completion(j.tid)
		done_jobs.append(j)
	jobs.clear()
	for j in done_jobs:
		_job_take(j)
	done_jobs.clear()


# Espera y descarta todo (cambio de semilla, salir del arbol); los trozos sin textura vuelven a la cola.
func _bake_cancel() -> void:
	for j in jobs:
		WorkerThreadPool.wait_for_task_completion(j.tid)
	var lost: Array = jobs + done_jobs
	jobs.clear()
	done_jobs.clear()
	for j in lost:
		if chunks.has(j.key) and chunks[j.key]["tex"] == null and not queue.has(j.key):
			queue.append(j.key)


func _exit_tree() -> void:
	_bake_cancel()
	for cl in _clones:
		if is_instance_valid(cl):
			cl.free()
	_clones.clear()


func _floor_img(S: Dictionary, idx: int) -> Image:
	var cache: Dictionary = S["fimg"]
	var key: String = "fi" + str(idx)
	if not cache.has(key):
		cache[key] = (S["floors"][idx] as AS.Pix).img()
	return cache[key]


# Todo lo de los trozos en un fotograma: vista, anticipo, cola, horneado y la GARANTIA: lo que toca el rectangulo visible
# (con FORCE_PAD) y aun no tiene textura se hornea ahora mismo en el hilo principal (antes de dibujar).
func _chunk_frame(delta: float) -> bool:
	var dirty := false
	_view_update(delta)
	if bake_pause_t > 0.0:
		bake_pause_t = maxf(0.0, bake_pause_t - delta)
		slow_n = 0
	elif bake_thread and delta * 1000.0 > SLOW_MS and delta < 2.0 and (not jobs.is_empty() or not done_jobs.is_empty()):
		slow_n += 1
		if slow_n >= SLOW_N:
			bake_pause_t = BAKE_PAUSE_SEC
			slow_n = 0
			Prof.bk_pauses += 1
	else:
		slow_n = 0
	Prof.bk_workers = jobs.size()
	sort_t += 1
	if view_ok:
		if _view_chunks() or (sort_t & 3) == 0:
			_queue_sort()
	if _bake_tick():
		dirty = true
	if view_ok:
		if _bake_force():
			dirty = true
	return dirty


func _ready_tex(ch: Dictionary) -> bool:
	return ch["tex"] != null and ch["tb"] == biome


# Hornea el trozo ya, en el hilo principal. Devuelve true si hizo falta esperar/hornear (docruta sincrona).
func _bake_now(key: Vector2i) -> bool:
	for i in range(jobs.size()):
		var j: BakeJob = jobs[i]
		if j.key == key and j.biome == biome:
			WorkerThreadPool.wait_for_task_completion(j.tid)
			jobs.remove_at(i)
			_job_take(j)
			queue.erase(key)
			return true
	for i in range(done_jobs.size()):
		var j: BakeJob = done_jobs[i]
		if j.key == key and j.biome == biome:
			done_jobs.remove_at(i)
			_job_take(j)
			queue.erase(key)
			return false   # ya estaba horneado: solo faltaba crear la textura (barato)
	if bk_key == key and bk_biome == biome:
		_bake_rows(bk_key, bk_img, bk_liq, bk_row, N)
		_bake_finish(bk_key, bk_img, bk_liq)
		bk_key = Vector2i(99999, 99999)
	else:
		bake_chunk(key)
	queue.erase(key)
	return true


func _force_visible() -> void:
	for key in _keys_in(vis_r.grow(FORCE_PAD)):
		var ch: Dictionary = chunks.get(key, {})
		if not ch.is_empty() and not _ready_tex(ch):
			_bake_now(key)


# Nunca se dibuja vacio: la cola prioriza la vista, y si aun asi un trozo visible no esta listo, se termina aqui.
func _bake_force() -> bool:
	var did := false
	var t0 := Time.get_ticks_usec()
	for key in _keys_in(vis_r.grow(FORCE_PAD)):
		var ch: Dictionary = chunks.get(key, {})
		if ch.is_empty() or _ready_tex(ch):
			continue
		if ch["old"] != null and fade_t <= 0.0:
			continue   # смена биома ещё держится на старом (fade_hold): видимые куски готовит очередь/заранее запечённое
		# во время растворения кусок без нового биома выделялся бы на фоне соседей (полусмена): допекаем сразу.
		# После удержания такое бывает редко: кусок только что въехал в вид или растворение шло до входа в арену.
		did = true
		var t1 := Time.get_ticks_usec()
		if _bake_now(key):
			var dt := Time.get_ticks_usec() - t1
			Prof.ch_sync_n += 1
			Prof.ch_sync_us += dt
			Prof.ch_sync_max = maxi(Prof.ch_sync_max, dt)
	Prof.ch_sync_last = Time.get_ticks_usec() - t0 if did else 0
	_bake_visible_status()
	return did


# Cuenta de control: trozos visibles que seguirian sin dibujar nada (tiene que ser 0).
func _bake_visible_status() -> void:
	var nv := 0
	var missing := 0
	for key in _keys_in(vis_r):
		nv += 1
		var ch2: Dictionary = chunks.get(key, {})
		if ch2.is_empty() or (ch2["tex"] == null and (ch2["old"] == null or fade_t >= 1.0)):
			missing += 1
	Prof.ch_vis_missing = missing
	Prof.ch_vis_total += missing
	Prof.ch_vis_n = nv
	Prof.ch_n = chunks.size()
	Prof.ch_n_max = maxi(Prof.ch_n_max, chunks.size())


var _redraw_acc := 0.0
var _view_skip := 0
var lite: bool = OS.has_feature("handheld") or "--keys-only" in OS.get_cmdline_user_args()


func _process(delta: float) -> void:
	gt += delta
	if not visible:
		# слой земли спрятан (арена греты / Суда, камера далеко): под камерой арены куски не заводим и синхронно
		# не печём — раньше в кадр входа допекались 4–6 ненужных кусков и потоки грузились десятками кусков вокруг
		# арены. Очередь мира (вид прошлого кадра в мире) допекается в фоне: к возврату всё готово.
		bake_pause_t = maxf(0.0, bake_pause_t - delta)
		_bake_tick()
		_view_skip = 2
		return
	if _view_skip > 0:
		# первый кадр после возврата: трансформ холста ещё от камеры арены — по нему вид оказался бы у арены
		# и там синхронно допеклись бы 4 куска (было 130–290 мс в кадр выхода из греты)
		_view_skip -= 1
		_bake_tick()
		queue_redraw()
		return
	var dirty := false
	if fade_t <= 0.0 and fade_hold < HOLD_MAX and not _vis_ready():
		fade_hold += delta   # старый биом целиком, пока под видом не готов новый (обычно уже запечён заранее)
		if fade_hold >= HOLD_MAX:
			_force_visible()   # запасной путь: допечь видимое сразу, чтобы не ждать дольше
	elif fade_t < 1.0:
		fade_t = minf(1.0, fade_t + delta / FADE)
		dirty = true
		if fade_t >= 1.0:
			for key in chunks:
				if chunks[key]["tex"] != null:
					chunks[key]["old"] = null
	var pt := Time.get_ticks_usec()
	if _chunk_frame(delta):
		dirty = true
	if Prof.on:
		Prof.lap(Prof.S_CHUNK, pt)
	# Las texturas del suelo no cambian: solo se redibuja para animar el liquido (20 veces por s).
	_redraw_acc += delta
	if dirty or _redraw_acc >= (0.1 if lite else 0.05):   # consola: el agua se anima a 10 Hz
		_redraw_acc = 0.0
		queue_redraw()


func _draw() -> void:
	var k: float = fade_t * fade_t * (3.0 - 2.0 * fade_t)
	var kind: String = liquid_kind()
	var lava: bool = kind == "lava" or kind == "poison" or kind == "spark"
	var foam: Color = pal(biome)["foam"]
	var spd: float = 2.2 if lava else 1.6
	var cwid: float = 6.0 if lava else 9.0
	for key in chunks:
		var ch: Dictionary = chunks[key]
		var tx = ch["tex"]
		var org := Vector2(float(key.x) * CW, float(key.y) * CW)
		var rc := Rect2(org, Vector2(CW, CW))
		var old = ch["old"]
		if old != null and fade_t < 1.0:
			draw_texture_rect(old, rc, false)
			if tx != null:
				draw_texture_rect(tx, rc, false, Color(1, 1, 1, k))
		elif tx != null:
			draw_texture_rect(tx, rc, false)
		else:
			continue
		var liq: Array = ch["liq"]
		if liq.is_empty():
			continue
		# solo anima el liquido de los chunks cercanos a la camara
		if absf(org.x + CW * 0.5 - center.x) > 760.0 + CW * 0.5 or absf(org.y + CW * 0.5 - center.y) > 460.0 + CW * 0.5:
			continue
		var ld = ch.get("liqd")
		if ld == null:
			ld = []
			for tl in liq:
				ld.append(Vector4(float(tl.x) * TS, float(tl.y) * TS, MX.hsh(tl.x, tl.y, 77) * TAU,
					floorf(MX.hsh(tl.x, tl.y, 78) * 12.0 + 2.0) * 3.0))
				ld.append(floorf(MX.hsh(tl.x, tl.y, 79) * 12.0 + 2.0) * 3.0)
			ch["liqd"] = ld
		var i := 0
		while i < ld.size():
			var v: Vector4 = ld[i]
			var oy: float = ld[i + 1]
			i += 2
			if absf(v.x - center.x) > 760.0 or absf(v.y - center.y) > 460.0:
				continue
			var kk: float = (sin(gt * spd + v.z) + 1.0) * 0.5
			var c := foam
			c.a = (0.35 + kk * 0.5) if lava else kk * 0.7
			var sx: float = v.x + v.w
			var sy: float = v.y + oy
			draw_rect(Rect2(sx + roundf(kk * 2.0) * 3.0, sy, cwid, 3.0), c)
			if lava and kk > 0.8:
				draw_rect(Rect2(sx, sy - 6.0, 3.0, 3.0), c)


# ---------------- pasto cortable ----------------

func add_grass(key: Vector2i, items: Array) -> void:
	grass[key] = items


func cut_grass(pos: Vector2, r: float) -> Array:
	var out: Array = []
	if grass.is_empty():
		return out
	# solo los trozos que toca el circulo (casi siempre 1), sin crear un Vector2 por mata
	var c0: Vector2i = chunk_of(pos - Vector2(r, r))
	var c1: Vector2i = chunk_of(pos + Vector2(r, r))
	var r2: float = r * r
	for cx in range(c0.x, c1.x + 1):
		for cy in range(c0.y, c1.y + 1):
			var arr = grass.get(Vector2i(cx, cy))
			if arr == null:
				continue
			for i in range(arr.size() - 1, -1, -1):
				var g: Vector3 = arr[i]
				var dx: float = g.x - pos.x
				var dy: float = g.y - pos.y
				if dx * dx + dy * dy <= r2:
					out.append(Vector2(g.x, g.y))
					arr.remove_at(i)
	return out


class GrassLayer extends Node2D:
	var tw: Node2D
	var tick := -1

	func _ready() -> void:
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	func _process(_d: float) -> void:
		var t: int = int(tw.gt * (3.0 if tw.lite else 4.0))
		if t != tick:
			tick = t
			queue_redraw()

	func _draw() -> void:
		var t0: Texture2D = tw.prop_tex("grass0")
		var t1: Texture2D = tw.prop_tex("grass1")
		if t0 == null:
			return
		var sz := Vector2(t0.get_width(), t0.get_height()) * 3.0
		var cen: Vector2 = tw.center
		for key in tw.grass:
			if absi(key.x - tw.cc.x) > 1 or absi(key.y - tw.cc.y) > 1:
				continue
			# el trozo entero fuera de la vista: se salta sin mirar cada mata
			var ox: float = float(key.x) * tw.CW
			var oy: float = float(key.y) * tw.CW
			if ox > cen.x + 700.0 or ox + tw.CW < cen.x - 700.0 or oy > cen.y + 420.0 or oy + tw.CW < cen.y - 420.0:
				continue
			for g in tw.grass[key]:
				if absf(g.x - cen.x) > 700.0 or absf(g.y - cen.y) > 420.0:
					continue
				var tx: Texture2D = t1 if sin(tw.gt * 2.4 + g.z) > 0.55 else t0
				draw_texture_rect(tx, Rect2(Vector2(g.x - sz.x * 0.5, g.y - sz.y + 12.0), sz), false)
