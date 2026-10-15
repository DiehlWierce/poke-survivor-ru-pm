extends Control
# Menu principal: jugar, Pokemon, mejoras, gacha, misiones y ajustes.
# Funciona con toque, mando (cruceta + A / B) y teclado (flechas + Enter / Esc).

const NAVG = preload("res://scripts/navgrid.gd")
const SV = preload("res://scripts/save_data.gd")
const Aud = preload("res://scripts/audio.gd")
const PG = preload("res://scripts/progress.gd")
const L = preload("res://scripts/lang.gd")
const MD = preload("res://scripts/moves_data.gd")
const TD = preload("res://scripts/types_data.gd")
const AB = preload("res://scripts/abilities.gd")
const ZM = preload("res://scripts/zmove.gd")
const DYN = preload("res://scripts/dynamax.gd")
const ST = preload("res://scripts/starters_data.gd")
const IC = preload("res://scripts/icons.gd")
const PXF = preload("res://scripts/pxfont.gd")
const DSP = preload("res://scripts/display.gd")
const SLOTS = preload("res://scripts/slots.gd")
const PAD = preload("res://scripts/pad.gd")
const PADI = preload("res://scripts/padicons.gd")
const UPD = preload("res://scripts/updater.gd")
const PN = preload("res://scripts/patchnotes.gd")

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
var coin_pill: PanelContainer
var tix_pill: PanelContainer
var name_pill: Button
var name_lbl: Button
var tab_sel: Button
var tab_row: Control
var mute_top: Button
var set_top: Button
var ticket_lbl: Label
var ticket10_lbl: Label
var toast_lbl: Label
var is_overlay := false
signal closed
var ach_pop: PanelContainer
var ach_box: HBoxContainer
var ach_t := 0.0
var toast_t := 0.0
var back_btn: Button
var credit_lbl: Label
var pad_hint: HBoxContainer
var pad_hint_key := ""
var shade: ColorRect
var focus_first: Control = null
var news_top: Button
var news_box: VBoxContainer
var news_scroll: ScrollContainer

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
var up_picker: Control = null
var pk_gen := 0
var pk_type := ""
var pk_q := ""
var pk_focus := ""
var slots_ui: Control = null
var slots_busy := false
var goals_tab := "m"
var goals_box: VBoxContainer
var up_box: VBoxContainer
var up_dex := 25
var ban_open := false
var tm_open := false
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
# Pokemon animado que anda y ataca (como en Mundo Misterioso).
# Hojas: columnas = fotogramas, filas = 8 direcciones (0 abajo, 1 abajo-der, 2 der, 3 arriba-der, 4 arriba, 5 arriba-izq, 6 izq, 7 abajo-izq)
# ---------------------------------------------------------------
class Mon extends Node2D:
	var dex := 25
	var shiny := false
	var k := 3.0
	var bounds := Rect2(0.0, 0.0, 200.0, 40.0)
	var wander := true
	var state := "idle"
	var anim := "Idle"
	var frame := 0
	var t := 0.0
	var dir := 0
	var wait := 0.6
	var target := Vector2.ZERO
	var meta: Dictionary = {}
	var sprite: Sprite2D
	var shadow_w := 24.0
	var fx0 := 0.0
	var fx1 := 1.0
	var ysort := false
	var fixed := false      # quieto en su sitio, de frente, y embiste cada cierto tiempo (como en Mundo Misterioso)
	var home := Vector2.ZERO
	var lunge := 22.0
	var fdir := 0
	var walk_ok: Callable = Callable()   # (desde, hasta) -> bool: el camino esta libre de paredes y agua

	func setup(d: int, kk: float, shn: bool, b: Rect2, wd: bool = true) -> void:
		dex = d
		k = kk
		shiny = shn
		bounds = b
		wander = wd
		var SVl = load("res://scripts/save_data.gd")
		var sm: Dictionary = SVl.smeta.get(str(d), {})
		meta = sm.get("a", {})
		sprite = Sprite2D.new()
		sprite.centered = false
		sprite.region_enabled = true
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		add_child(sprite)
		position = Vector2(randf_range(b.position.x, b.end.x), randf_range(b.position.y, b.end.y))
		wait = randf_range(0.2, 1.2)
		if meta.has("Idle"):
			shadow_w = float(meta["Idle"]["w"]) * k * 0.22
		_set_anim("Idle")

	func _set_anim(a: String) -> void:
		if meta.is_empty():
			return
		if not meta.has(a):
			a = "Idle" if meta.has("Idle") else "Walk"
		anim = a
		frame = 0
		t = 0.0
		_apply()

	func _lunge_vec() -> Vector2:
		var a: float = float(fdir) * PI / 4.0
		return Vector2(sin(a), cos(a))

	func _face(v: Vector2) -> void:
		var a: float = v.angle()
		dir = posmod(int(floor((PI / 2.0 - a) / (PI / 4.0) + 0.5)), 8)

	func _apply() -> void:
		if meta.is_empty() or not meta.has(anim):
			return
		var am: Dictionary = meta[anim]
		var tx: Texture2D = Preview.tex_of(dex, anim, shiny)
		if tx == null:
			sprite.visible = false
			return
		sprite.visible = true
		sprite.texture = tx
		sprite.offset = Vector2(-float(am["ax"]), -float(am["ay"]))
		sprite.scale = Vector2(k, k)
		var rows: int = int(am.get("r", 8))
		var w: float = float(am["w"])
		var h: float = float(am["h"])
		sprite.region_rect = Rect2(float(frame) * w, float(mini(dir, rows - 1)) * h, w, h)

	func _next() -> void:
		if randf() < 0.55:
			var tg := position
			var found := false
			for tr in range(10):
				tg = Vector2(randf_range(bounds.position.x, bounds.end.x), randf_range(bounds.position.y, bounds.end.y))
				if tg.distance_to(position) < 24.0:
					continue
				if walk_ok.is_valid() and not bool(walk_ok.call(position, tg)):
					continue
				found = true
				break
			if not found:
				wait = 0.3
				return
			target = tg
			state = "walk"
			_face(tg - position)
			_set_anim("Walk")
		else:
			var a := "Attack"
			if randf() < 0.4:
				var opts: Array = []
				for n in ["Shoot", "Charge"]:
					if meta.has(n):
						opts.append(n)
				if not opts.is_empty():
					a = String(opts[randi() % opts.size()])
			if not meta.has(a):
				wait = 1.0
				return
			state = "attack"
			dir = randi() % 8
			_set_anim(a)

	func _process(delta: float) -> void:
		if meta.is_empty() or not meta.has(anim):
			return
		var am: Dictionary = meta[anim]
		t += delta * 60.0
		var guard := 0
		while t >= float(am["d"][frame]) and guard < 16:
			guard += 1
			t -= float(am["d"][frame])
			frame += 1
			if frame >= int(am["n"]):
				frame = 0
				if state == "attack":
					state = "idle"
					wait = randf_range(1.4, 2.6) if fixed else randf_range(0.5, 1.4)
					_set_anim("Idle")
					am = meta[anim]
		if fixed:
			dir = fdir
			if state == "idle":
				wait -= delta
				position = home
				if wait <= 0.0:
					if meta.has("Attack"):
						state = "attack"
						_set_anim("Attack")
					else:
						wait = 1.5
			elif state == "attack":
				var ai: Dictionary = meta[anim]
				var prog: float = clampf((float(frame) + t / maxf(1.0, float(ai["d"][frame]))) / float(maxi(1, int(ai["n"]))), 0.0, 1.0)
				position = home + _lunge_vec() * sin(prog * PI) * lunge
		elif state == "idle":
			wait -= delta
			if wait <= 0.0 and wander:
				_next()
		elif state == "walk":
			var v: Vector2 = target - position
			var step: float = 46.0 * delta * (k / 3.0)
			if v.length() <= step:
				position = target
				state = "idle"
				wait = randf_range(0.4, 1.2)
				_set_anim("Idle")
			else:
				position += v.normalized() * step
		if not ysort and not fixed:
			z_index = int(position.y)
		_apply()
		queue_redraw()

	func _draw() -> void:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.35))
		draw_circle(Vector2.ZERO, shadow_w, Color(0, 0, 0, 0.32))


# Fondo del menu: un trozo del mapa del juego que se desplaza solo, con Pokemon caminando.
class MenuWorld extends Node2D:
	const TW = preload("res://scripts/tileworld.gd")
	const MAINS = preload("res://scripts/main.gd")
	const PERIOD := 30.0   # segundos por ambiente, como en el menu del juego original (bosque -> cueva -> volcan)
	const CAST := [1, 4, 7, 25, 133, 52, 39, 35, 16, 43, 60, 69, 74, 92, 129, 147, 113, 143, 54, 79]
	var cam := Vector2.ZERO
	var t := 0.0
	var tw: Node2D            # el mismo terreno que una partida (lagos, paredes, tierra)
	var gen: Node2D           # instancia de main.gd sin escena: solo genera arboles, rocas, hierba y objetos igual que la partida
	var props: Node2D
	var mons: Array = []
	var vs := Vector2(1280, 720)
	var drift := Vector2(1, 0.3)
	var pool: Array = []
	var amb: Ambient = null
	var cur_chunk := Vector2i(99999, 99999)
	var gen_q: Array = []
	var biome_i := 0

	# Particulas de ambiente en pantalla: luciernagas, motas de cueva y ascuas de volcan.
	class Ambient extends Node2D:
		var t := 0.0
		var vs := Vector2(1280, 720)
		var w := [1.0, 0.0, 0.0]

		static func _h(n: float, k: float) -> float:
			var v: float = sin(n * 12.9898 + k * 78.233) * 43758.5453
			return v - floorf(v)

		func _draw() -> void:
			for k in range(3):
				var wk: float = float(w[k])
				if wk <= 0.01:
					continue
				for n in range(44):
					var fn := float(n)
					var r1: float = _h(fn, 1.0 + float(k))
					var r2: float = _h(fn, 7.0 + float(k))
					var r3: float = _h(fn, 13.0 + float(k))
					var pos: Vector2
					var col: Color
					var sz: float = 3.0
					if k == 0:
						pos = Vector2(r1 * vs.x + sin(t * 0.4 + r2 * 6.0) * 40.0, r3 * vs.y * 0.9 + cos(t * 0.3 + r1 * 6.0) * 30.0)
						col = Color(1.0, 0.95, 0.5, (0.5 + 0.5 * sin(t * 1.5 + r2 * 10.0)) * 0.8 * wk)
					elif k == 1:
						pos = Vector2(r1 * vs.x + sin(t * 0.5 + r3 * 9.0) * 20.0, fmod(r3 * vs.y + t * (10.0 + 20.0 * r2), vs.y))
						col = Color(0.7, 0.88, 1.0, 0.55 * wk)
						sz = 2.0 + floorf(r2 * 2.0)
					else:
						var yy: float = fmod(r3 * vs.y + t * (30.0 + 60.0 * r2), vs.y)
						pos = Vector2(r1 * vs.x + sin(t * 1.2 + r2 * 9.0) * 25.0, vs.y - yy)
						col = Color(1.0, 0.55 + 0.3 * r2, 0.15, 0.9 * (1.0 - yy / vs.y) * wk)
					draw_rect(Rect2(pos.round(), Vector2(sz, sz)), col)

	func _init() -> void:
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	func start() -> void:
		var SVl = load("res://scripts/save_data.gd")
		SVl.ensure()
		# Los mismos 20 Pokemon que pasean por el menu del juego original
		for d in CAST:
			for p in SVl.dex_list:
				if int(p["dex"]) == d and SVl.smeta.has(str(d)):
					pool.append(p)
					break
		cam = Vector2(randf_range(-3000.0, 3000.0), randf_range(-3000.0, 3000.0))
		var sd: int = randi() % 100000
		tw = TW.new()
		add_child(tw)
		tw.setup(sd)
		props = Node2D.new()
		props.y_sort_enabled = true
		add_child(props)
		gen = MAINS.new()
		gen.ground = tw
		gen.world = props
		gen.world_seed = sd
		gen.menu_mode = true
		MAINS.Prop.tw = tw
		vs = get_viewport_rect().size
		_update_chunks(true)
		tw.flush_bake()
		for i in range(pool.size()):
			_spawn_mon(true)
		amb = Ambient.new()
		get_parent().add_child(amb)
		get_parent().move_child(amb, get_index() + 1)
		tree_exiting.connect(func():
			if is_instance_valid(gen):
				gen.free())

	func _update_chunks(first: bool = false) -> void:
		var c: Vector2i = tw.chunk_of(cam)
		tw.center = cam
		if c != cur_chunk:
			cur_chunk = c
			tw.set_center(c)
			for dx in range(-2, 3):
				for dy in range(-2, 3):
					var key := Vector2i(c.x + dx, c.y + dy)
					if not gen.chunks.has(key) and not gen_q.has(key):
						gen_q.append(key)
			gen_q.sort_custom(func(a, b): return absi(a.x - c.x) + absi(a.y - c.y) < absi(b.x - c.x) + absi(b.y - c.y))
			for key in gen.chunks.keys():
				if absi(key.x - c.x) > 3 or absi(key.y - c.y) > 3:
					gen._free_chunk(key)
		# los trozos nuevos se crean de uno en uno (sin tirones); al empezar, todos de golpe
		var made := 0
		while not gen_q.is_empty():
			var nk: Vector2i = gen_q.pop_front()
			if not gen.chunks.has(nk):
				gen.chunks[nk] = gen._gen_chunk(nk.x, nk.y)
				made += 1
			# al empezar solo los 9 de alrededor; el resto llega de uno en uno
			if not first or made >= 9:
				break

	# Sitio libre: sin pared, agua ni lava alrededor.
	func _free_spot(pos: Vector2) -> bool:
		if tw.liquid_at(pos) != "":
			return false
		for o in [Vector2.ZERO, Vector2(18, 0), Vector2(-18, 0), Vector2(0, 18), Vector2(0, -18)]:
			if tw.collide(pos + o, 14.0) != pos + o:
				return false
		return true

	func _can_stand(m: Node2D, pos: Vector2) -> bool:
		if tw.collide(pos, 14.0) != pos:
			return false
		var liq: String = tw.liquid_at(pos)
		if liq == "":
			return true
		var ty: Array = m.get_meta("types", [])
		return ty.has("flying") or (liq == "water" and ty.has("water")) or (liq == "lava" and ty.has("fire")) or (liq == "swamp" and (ty.has("water") or ty.has("poison")))

	func _path_ok(m: Node2D, a: Vector2, b: Vector2) -> bool:
		for i in range(1, 7):
			if not _can_stand(m, a.lerp(b, float(i) / 6.0)):
				return false
		return true

	func _spawn_mon(anywhere: bool) -> void:
		if pool.is_empty():
			return
		# Uno de los 20 del menu original que ahora no este en pantalla
		var used := {}
		for mm in mons:
			used[mm.dex] = true
		var free: Array = []
		for pp in pool:
			if not used.has(int(pp["dex"])):
				free.append(pp)
		if free.is_empty():
			free = pool
		var p: Dictionary = free[randi() % free.size()]
		var pos: Vector2 = Vector2.ZERO
		var good := false
		for tries in range(40):
			if anywhere:
				pos = cam + Vector2(randf_range(-vs.x * 0.5, vs.x * 0.5), randf_range(-vs.y * 0.5, vs.y * 0.5))
			else:
				var side: Vector2 = drift.normalized()
				var perp := Vector2(-side.y, side.x)
				pos = cam + side * (vs.x * 0.5 + 120.0) + perp * randf_range(-vs.y * 0.5, vs.y * 0.5)
			if _free_spot(pos):
				good = true
				break
		if not good:
			return   # sin sitio razonable: no aparece (mejor que dentro de una pared)
		var m := Mon.new()
		m.ysort = true
		m.setup(int(p["dex"]), 2.4, randf() < 0.03, Rect2(pos - Vector2(170.0, 90.0), Vector2(340.0, 180.0)), true)
		m.position = pos
		m.set_meta("types", p.get("types", []))
		m.walk_ok = func(a: Vector2, b: Vector2) -> bool: return _path_ok(m, a, b)
		m.set_meta("lp", pos)
		props.add_child(m)
		mons.append(m)

	func _process(delta: float) -> void:
		t += delta
		vs = get_viewport_rect().size
		var ang: float = 0.3 + sin(t * 0.05) * 0.9
		drift = Vector2.from_angle(ang)
		cam += drift * 26.0 * delta
		position = vs * 0.5 - cam
		_update_chunks()
		for m in mons.duplicate():
			var pushed: Vector2 = tw.collide(m.position, 12.0)   # no atraviesan paredes (como en el juego original)
			if pushed.distance_to(m.position) > 0.5:
				m.position = pushed
				if m.state == "walk":   # chocó con una pared: se para y elige otro destino
					m.state = "idle"
					m.wait = 0.15
					m._set_anim("Idle")
			# agua: solo tipo agua o volador; lava: solo fuego o volador; el resto da la vuelta
			var liq: String = tw.liquid_at(m.position)
			if liq != "":
				var ty: Array = m.get_meta("types")
				var ok: bool = ty.has("flying") or (liq == "water" and ty.has("water")) or (liq == "lava" and ty.has("fire")) or (liq == "swamp" and (ty.has("water") or ty.has("poison")))
				if not ok:
					m.position = m.get_meta("lp")
					m.target = m.position
					m.wait = 0.5
			m.set_meta("lp", m.position)
			if absf(m.position.x - cam.x) > vs.x * 0.5 + 520.0 or absf(m.position.y - cam.y) > vs.y * 0.5 + 420.0:
				mons.erase(m)
				m.queue_free()
				_spawn_mon(false)
		# ambiente: bosque -> cueva de cristal -> volcan, como el original: el mismo mapa con los recursos de cada bioma
		var bi: int = int(floor(t / PERIOD)) % 3
		if bi != biome_i:
			biome_i = bi
			tw.set_biome(bi)
		if amb != null:
			var pv := [0.0, 0.0, 0.0]
			var kf: float = tw.fade_t * tw.fade_t * (3.0 - 2.0 * tw.fade_t)
			pv[tw.prev_biome % 3] += 1.0 - kf
			pv[biome_i] += kf
			amb.t = t
			amb.vs = vs
			amb.w = pv
			amb.queue_redraw()



# Escenario del Gacha: degradado de la region + Pokemon que se mueven.
class Banner extends Control:
	var c1 := Color("#5b2f8f")
	var c2 := Color("#1f6f7a")
	var mons: Array = []

	func _init() -> void:
		clip_contents = true

	func add_mon(d: int, kk: float, f0: float, f1: float) -> void:
		var m := Mon.new()
		m.fx0 = f0
		m.fx1 = f1
		add_child(m)
		m.setup(d, kk, false, Rect2(f0 * 700.0, 250.0, (f1 - f0) * 700.0, 60.0), false)
		m.fixed = true
		m.fdir = 1   # diagonal abajo-derecha
		m.dir = 1
		m.wait = 0.5 + 0.9 * float(mons.size())
		mons.append(m)
		_layout()

	func _notification(what: int) -> void:
		if what == NOTIFICATION_RESIZED:
			_layout()

	func _layout() -> void:
		for m in mons:
			# fila fija: centrada en su tercio, todos a la misma altura
			m.home = Vector2((m.fx0 + m.fx1) * 0.5 * size.x, size.y * 0.80)
			m.position = m.home

	func _draw() -> void:
		var w: float = size.x
		var h: float = size.y
		var pts := PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, h), Vector2(0, h)])
		var cols := PackedColorArray([c1, c1.lerp(c2, 0.5), c2, c1.lerp(c2, 0.5)])
		draw_polygon(pts, cols)
		draw_circle(Vector2(w * 0.55, h * 0.4), h * 0.6, Color(1, 1, 1, 0.05))
		draw_rect(Rect2(0, h * 0.64, w, h * 0.36), Color(0, 0, 0, 0.12))
		draw_rect(Rect2(1.5, 1.5, w - 3.0, h - 3.0), Color(0.7, 0.78, 1.0, 0.75), false, 3.0)


# Retrato del Pokemon (pantalla de mejoras)
class Portrait extends Control:
	var edge := Color("#ff7b3d")
	var mon: Mon = null

	func _init() -> void:
		clip_contents = true

	func setup(d: int, col: Color) -> void:
		edge = col
		if mon != null:
			mon.queue_free()
		mon = Mon.new()
		add_child(mon)
		mon.setup(d, 3.0, false, Rect2(60.0, 120.0, 80.0, 24.0), false)
		mon.dir = 0
		mon.ysort = true   # sin z_index propio: nunca queda por encima de menus y resultados
		_layout()

	func _notification(what: int) -> void:
		if what == NOTIFICATION_RESIZED:
			_layout()

	func _layout() -> void:
		if mon != null:
			# Quieto, centrado y mirando al frente; solo se anima en el sitio.
			mon.position = Vector2(size.x * 0.5, size.y * 0.82)

	func _draw() -> void:
		var w: float = size.x
		var h: float = size.y
		draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, h), Vector2(0, h)]), PackedColorArray([Color("#142a5c"), Color("#142a5c"), Color("#0a1230"), Color("#0a1230")]))
		draw_rect(Rect2(2, 2, w - 4.0, h - 4.0), edge, false, 4.0)


# Barras de nivel (pips)
class Pips extends Control:
	var lv := 0
	var mx := 5

	func setup(l: int, m: int) -> void:
		lv = l
		mx = m
		custom_minimum_size = Vector2(float(m) * 18.0, 10.0)
		queue_redraw()

	func _draw() -> void:
		for i in range(mx):
			draw_rect(Rect2(float(i) * 18.0, 1.0, 14.0, 8.0), Color("#ffd23f") if i < lv else Color("#0e1a40"))


# ---------------------------------------------------------------
# Construccion
# ---------------------------------------------------------------
# Foco de mando: borde negro con halo blanco (se ve sobre dorado, gris y azul).
const TOWER_FLOORS_M := 30

func _sb_focus(col: Color) -> StyleBoxFlat:
	var s := _sb(col, Color.BLACK, 4, 12)
	s.shadow_color = Color.WHITE
	s.shadow_size = 4
	s.shadow_offset = Vector2.ZERO
	return s


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
	PXF.apply(theme_main)
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
	is_overlay = bool(Engine.get_meta("menu_overlay", false))
	Engine.set_meta("menu_overlay", false)
	L.apply()
	DSP.apply(get_tree())
	PAD.apply()
	if not is_overlay:
		Aud.setup(self)
		Aud.music("village")
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_theme()
	RenderingServer.set_default_clear_color(Color("#16233a"))
	# fondo: un trozo del mapa que se desplaza solo, con Pokemon caminando
	if not is_overlay:
		var world := MenuWorld.new()
		world.z_index = -4000   # el fondo siempre queda detras de toda la interfaz
		add_child(world)
		world.start()
		var upd := UPD.new()
		add_child(upd)
		upd.found.connect(func(info: Dictionary):
			var pop := UPD.UpdatePopup.new()
			add_child(pop)
			pop.build(info))
		upd.start()
	shade = ColorRect.new()
	shade.color = Color(0, 0.05, 0.1, 0.30)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	# barra superior
	var top := HBoxContainer.new()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	var ins: Vector4 = DSP.insets(get_tree())
	top.offset_left = 16 + ins.x
	top.offset_right = -16 - ins.z
	top.offset_top = 10 + ins.y
	top.offset_bottom = 58
	add_child(top)
	back_btn = _btn("◀ Volver", func(): _leave(), Vector2(150, 44))
	top.add_child(back_btn)
	credit_lbl = Label.new()
	credit_lbl.text = L.t("Un port hecho por JayElDragon")
	credit_lbl.add_theme_font_size_override("font_size", 20)
	credit_lbl.add_theme_color_override("font_color", Color("#ffe9a8"))
	credit_lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	credit_lbl.add_theme_constant_override("outline_size", 6)
	credit_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	credit_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(credit_lbl)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(sp)
	# Barra superior como la del original: monedas, tickets, nombre, sonido y ajustes.
	coin_pill = _pill()
	coin_lbl = _pill_item(coin_pill, "coin", C_GOLD)
	tix_pill = _pill()
	ticket_lbl = _pill_item(tix_pill, "ticket", C_GOLD)
	ticket10_lbl = _pill_item(tix_pill, "ticket10", Color("#c47bff"))
	name_pill = _icon_btn("crown", func(): goals_tab = "p"; _show("goals"))
	name_pill.custom_minimum_size = Vector2(0, 44)
	name_pill.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	name_pill.add_theme_font_size_override("font_size", 22)
	name_pill.add_theme_constant_override("h_separation", 10)
	name_lbl = name_pill
	top.add_child(coin_pill)
	top.add_child(_gap(8))
	top.add_child(tix_pill)
	top.add_child(_gap(8))
	top.add_child(name_pill)
	top.add_child(_gap(8))
	news_top = _icon_btn("news", func(): if cur != "news": _show("news"))
	news_top.text = L.t("Novedades")
	news_top.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	news_top.add_theme_font_size_override("font_size", 20)
	news_top.add_theme_constant_override("h_separation", 8)
	news_top.custom_minimum_size = Vector2(0, 44)
	top.add_child(news_top)
	top.add_child(_gap(8))
	mute_top = _icon_btn("sound", func(): _toggle_mute_top())
	top.add_child(mute_top)
	top.add_child(_gap(8))
	set_top = _icon_btn("gear", func(): if cur != "settings": _show("settings"))
	top.add_child(set_top)
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
	ach_pop = PanelContainer.new()
	ach_pop.set_anchors_preset(Control.PRESET_CENTER_TOP)
	ach_pop.grow_horizontal = Control.GROW_DIRECTION_BOTH
	ach_pop.offset_top = 64
	ach_pop.z_index = 60
	ach_pop.visible = false
	ach_pop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var apsb := _sb(Color("#25479a"), Color("#ffd23f"), 3, 12)
	apsb.set_expand_margin_all(3)
	apsb.shadow_color = Color("#0b1838")
	apsb.shadow_size = 3
	apsb.content_margin_left = 18
	apsb.content_margin_right = 22
	apsb.content_margin_top = 10
	apsb.content_margin_bottom = 10
	ach_pop.add_theme_stylebox_override("panel", apsb)
	ach_box = HBoxContainer.new()
	ach_box.add_theme_constant_override("separation", 12)
	ach_pop.add_child(ach_box)
	add_child(ach_pop)
	pad_hint = HBoxContainer.new()
	pad_hint.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	pad_hint.offset_left = 24
	pad_hint.offset_top = -46
	pad_hint.offset_bottom = -6
	pad_hint.grow_vertical = Control.GROW_DIRECTION_BEGIN
	pad_hint.add_theme_constant_override("separation", 8)
	pad_hint.z_index = 49
	pad_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(pad_hint)
	_build_main()
	_build_test()
	_build_dex()
	_build_modes()
	_build_up()
	_build_gacha()
	_build_goals()
	_build_lexicon()
	_build_settings()
	_build_news()
	if is_overlay:
		_show("settings")
		return
	if SV.reopen != "":
		var ro: String = SV.reopen
		SV.reopen = ""
		_show(ro)
	elif SV.owned_count() == 0:
		_show("test")
	else:
		_show("main")
		if PN.should_show():
			_show("news")
		elif not SV.last_run.is_empty():
			_show_run_summary()


func _gap(w: float) -> Control:
	var g := Control.new()
	g.custom_minimum_size = Vector2(w, 0)
	return g


# Capsula oscura con borde claro (pildora de la barra superior del original).
func _pill() -> PanelContainer:
	var pc := PanelContainer.new()
	var sbx := _sb(Color("#0d1b3d"), Color("#f4f8ff"), 2, 24)
	sbx.content_margin_left = 16
	sbx.content_margin_right = 16
	sbx.content_margin_top = 6
	sbx.content_margin_bottom = 6
	pc.add_theme_stylebox_override("panel", sbx)
	pc.custom_minimum_size = Vector2(0, 44)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	pc.add_child(h)
	return pc


func _pill_item(pc: PanelContainer, icon: String, col: Color) -> Label:
	var h: HBoxContainer = pc.get_child(0)
	if h.get_child_count() > 0:
		h.add_child(_gap(6))
	var ic := IC.rect(icon, 26)
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(ic)
	var l := Label.new()
	l.add_theme_color_override("font_color", Color.WHITE if icon == "coin" else col)
	l.add_theme_font_size_override("font_size", 22)
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	h.add_child(l)
	return l


func _icon_btn(icon: String, cb: Callable) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(52, 44)
	b.focus_mode = Control.FOCUS_ALL
	b.icon = IC.tex(icon, IC.scale_for(icon, 26))
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.expand_icon = false
	b.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	b.add_theme_stylebox_override("normal", _sb(Color(0.05, 0.1, 0.22, 0.55), Color(1, 1, 1, 0.45), 2, 12))
	b.add_theme_stylebox_override("hover", _sb(Color(0.12, 0.2, 0.4, 0.8), Color.WHITE, 2, 12))
	b.add_theme_stylebox_override("pressed", _sb(Color(0.02, 0.05, 0.12, 0.9), Color.WHITE, 2, 12))
	b.add_theme_stylebox_override("focus", _sb(Color(0.12, 0.2, 0.4, 0.8), C_GOLD, 3, 12))
	b.pressed.connect(func():
		Aud.sfx("click")
		cb.call())
	return b


func _toggle_mute_top() -> void:
	SV.d["settings"]["mute"] = not bool(SV.d["settings"].get("mute", false))
	SV.save()
	if Aud.inst != null:
		Aud.inst.apply()
	_update_top()


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
func _cost_btn(title: String, cost: String, icon: String, cost_icon: String, cb: Callable, min_size: Vector2, enabled: bool = true, vertical: bool = false, gold: bool = false) -> Button:
	var b := _btn("", cb, min_size)
	b.disabled = not enabled
	var tcol: Color = Color.WHITE
	if gold:
		_gold_btn(b, enabled)
		tcol = Color.WHITE if enabled else Color.BLACK
		if not enabled:
			for st0 in ["normal", "hover", "pressed", "disabled"]:
				b.add_theme_stylebox_override(st0, _sb(Color("#a89c82"), Color("#6b6250"), 3, 12))
			b.add_theme_stylebox_override("focus", _sb_focus(Color("#b8ad94")))
	var hb := HBoxContainer.new()
	hb.set_anchors_preset(Control.PRESET_FULL_RECT)
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.add_theme_constant_override("separation", 10)
	if not enabled and not gold:
		hb.modulate = Color(1, 1, 1, 0.5)
	if icon != "":
		hb.add_child(IC.rect(icon, 32))
	var holder: BoxContainer = VBoxContainer.new() if vertical else HBoxContainer.new()
	holder.alignment = BoxContainer.ALIGNMENT_CENTER
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_theme_constant_override("separation", 8 if not vertical else 0)
	holder.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if title != "":
		var tl := _label(title, 22, tcol)
		tl.autowrap_mode = TextServer.AUTOWRAP_OFF
		tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if gold:
			tl.add_theme_constant_override("outline_size", 5 if enabled else 0)
			tl.add_theme_color_override("font_outline_color", Color("#3a2606"))
		holder.add_child(tl)
	var cr := HBoxContainer.new()
	cr.alignment = BoxContainer.ALIGNMENT_CENTER
	cr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cr.add_theme_constant_override("separation", 6)
	cr.add_child(IC.rect(cost_icon, 24))
	var cl := _label(cost, 22, tcol if gold else C_GOLD)
	cl.autowrap_mode = TextServer.AUTOWRAP_OFF
	cl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if gold:
		cl.add_theme_constant_override("outline_size", 5 if enabled else 0)
		cl.add_theme_color_override("font_outline_color", Color("#3a2606"))
	cr.add_child(cl)
	holder.add_child(cr)
	hb.add_child(holder)
	b.add_child(hb)
	return b


# Boton dorado (se puede pagar) o marron apagado (no alcanza).
func _gold_btn(b: Button, on: bool) -> void:
	var c := Color("#f7b733") if on else Color("#8c7f66")
	var edge := Color("#fff4d0") if on else Color("#5b5240")
	for st in ["normal", "hover", "pressed", "disabled"]:
		b.add_theme_stylebox_override(st, _sb(c, edge, 3, 12))
	b.add_theme_stylebox_override("focus", _sb_focus(c.lightened(0.15)))


func _card_sb() -> StyleBoxFlat:
	var sb := _sb(Color(0.08, 0.14, 0.36, 0.8), Color("#33498f"), 2, 14)
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	return sb


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


# Con mando: el ScrollContainer sigue al control enfocado.
# Si no hay nada enfocable mas abajo (o arriba) pero el menu sigue, el D-pad desplaza la lista.
func _scroll_fallback(down: bool) -> bool:
	var f: Control = get_viewport().gui_get_focus_owner()
	if f == null or not screens.has(cur):
		return false
	var p: Node = f.get_parent()
	while p != null and not (p is ScrollContainer):
		p = p.get_parent()
	if p == null:
		return false
	var sc := p as ScrollContainer
	var nb: Control = f.find_valid_focus_neighbor(SIDE_BOTTOM if down else SIDE_TOP)
	if nb != null and sc.is_ancestor_of(nb):
		return false
	var mx: float = maxf(0.0, (sc.get_v_scroll_bar().max_value - sc.size.y))
	var cur_v: float = float(sc.scroll_vertical)
	if down and cur_v >= mx - 1.0:
		return false
	if not down and cur_v <= 0.0:
		return false
	sc.scroll_vertical = int(cur_v + (140.0 if down else -140.0))
	return true


func _follow_focus() -> void:
	var f: Control = get_viewport().gui_get_focus_owner()
	if f != null and is_visible_in_tree():
		_follow(f)


func _follow(c: Control) -> void:
	var p: Node = c.get_parent()
	while p != null and not (p is ScrollContainer):
		p = p.get_parent()
	if p != null:
		(p as ScrollContainer).call_deferred("ensure_control_visible", c)


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
	var ins: Vector4 = DSP.insets(get_tree())
	c.add_theme_constant_override("margin_left", 24 + int(ins.x))
	c.add_theme_constant_override("margin_right", 24 + int(ins.z))
	c.add_theme_constant_override("margin_top", 72 + int(ins.y))
	c.add_theme_constant_override("margin_bottom", 18 + int(ins.w))
	c.visible = false
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(c)
	screens[name] = c
	return c


func _leave() -> void:
	if is_overlay:
		closed.emit()
		queue_free()
	else:
		_show("main")


func _show(name: String) -> void:
	if name == "up" and cur != "up":
		up_dex = int(SV.d["selected"])
	_close_up_picker()
	cur = name
	if name != "dex":
		dex_pick_party = false
		dex_pick_team = false
		dex_pick_coop = false
	for k in screens:
		screens[k].visible = k == name
	back_btn.visible = name != "main" and name != "test"
	credit_lbl.visible = name == "main"
	shade.color.a = 0.30 if name == "main" else 0.62
	for pn in [coin_pill, tix_pill, name_pill, news_top, mute_top, set_top]:
		pn.visible = name != "test"
	if is_overlay:
		for pn2 in [coin_pill, tix_pill, name_pill, news_top, mute_top, set_top]:
			pn2.visible = false
		shade.color.a = 0.8
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
	ticket10_lbl.text = "%d" % int(SV.d.get("tickets10", 0))
	var tt: String = String(SV.d.get("title", ""))
	name_lbl.text = _nick()
	var muted: bool = bool(SV.d["settings"].get("mute", false))
	var mn: String = "mute" if muted else "sound"
	mute_top.icon = IC.tex(mn, IC.scale_for(mn, 26))


func toast(msg: String) -> void:
	toast_lbl.text = msg
	toast_t = 2.6


# Ayuda de mando abajo a la izquierda: icono del boton + accion (sin texto del boton).
func _build_pad_hint() -> void:
	for c in pad_hint.get_children():
		pad_hint.remove_child(c)
		c.queue_free()
	for pair in [[PAD.confirm_btn(), "Aceptar"], [PAD.cancel_btn(), "Atrás"]]:
		pad_hint.add_child(PADI.rect(int(pair[0]), 36.0))
		var l := _label(L.t(String(pair[1])), 20, Color("#c8d6ee"))
		l.add_theme_color_override("font_outline_color", Color.BLACK)
		l.add_theme_constant_override("outline_size", 4)
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.autowrap_mode = TextServer.AUTOWRAP_OFF
		pad_hint.add_child(l)
		pad_hint.add_child(_gap(10))


func _process(delta: float) -> void:
	if pad_hint != null:
		var has_pad := Input.get_connected_joypads().size() > 0
		pad_hint.visible = has_pad and cur != "test"
		if has_pad:
			var hk := "%d_%d_%d_%s" % [PAD.layout(), PAD.confirm_btn(), PAD.cancel_btn(), L.t("Aceptar")]
			if hk != pad_hint_key:
				pad_hint_key = hk
				_build_pad_hint()
	if toast_t > 0.0:
		toast_t -= delta
		if toast_t <= 0.0:
			toast_lbl.text = ""
	if ach_t > 0.0:
		ach_t -= delta
		ach_pop.modulate.a = clampf(minf(ach_t, 2.8 - ach_t + 0.001) * 4.0, 0.0, 1.0)
		ach_pop.position.x = (get_viewport_rect().size.x - ach_pop.size.x) * 0.5
		if ach_t <= 0.0:
			ach_pop.visible = false
	elif not PG.toasts.is_empty() and not is_overlay:
		var tt: Dictionary = PG.toasts.pop_front()
		var msg: String = L.t(String(tt["title"])) % L.t(String(tt["arg"]))
		var sub := ""
		if String(tt["sub"]) != "":
			sub = L.t(String(tt["sub"])) % String(tt["subarg"]) if String(tt["subarg"]) != "" else L.t(String(tt["sub"]))
		_ach_toast(msg, sub, int(tt["tier"]))
		Aud.sfx("legend")
		_update_top()


# Aviso de logro: caja azul con borde dorado y la medalla, como en el juego original.
func _ach_toast(msg: String, sub: String, tier: int) -> void:
	for c in ach_box.get_children():
		c.queue_free()
	var mi := IC.rect("medal%d" % clampi(tier, 1, 3), 36)
	mi.custom_minimum_size.x = 40
	ach_box.add_child(mi)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 0)
	ach_box.add_child(col)
	var l := _label(msg, 24, Color("#ffd23f"))
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	col.add_child(l)
	if sub != "":
		var l2 := _label(sub, 16, Color("#b9cbf0"))
		l2.autowrap_mode = TextServer.AUTOWRAP_OFF
		col.add_child(l2)
	ach_pop.reset_size()
	ach_pop.visible = true
	ach_pop.modulate.a = 0.0
	ach_t = 2.8


var back_t := 0.0


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_go_back()


# Atras: cierra el cuadro abierto, sube al menu principal o (en el principal) pide pulsar otra vez para salir.
func _go_back() -> void:
	if listening != "":
		listening = ""
		_refresh_listen()
		return
	if slots_busy:
		slots_ui.fast = true
		return
	if gacha_result != null and gacha_result.visible:
		gacha_result.visible = false
		return
	if up_picker != null and is_instance_valid(up_picker):
		_close_up_picker()
		return
	if cur != "main" and cur != "test":
		_leave()
		return
	if cur == "main":
		if Time.get_ticks_msec() / 1000.0 - back_t < 2.0:
			get_tree().quit()
		else:
			back_t = Time.get_ticks_msec() / 1000.0
			toast(L.t("Pulsa atrás otra vez para salir"))


func _popup_open() -> bool:
	for n in find_children("*", "OptionButton", true, false):
		if (n as OptionButton).get_popup().visible:
			return true
	return false


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if listening != "":
		if event is InputEventJoypadButton and event.pressed:
			PAD.set_btn(listening, event.button_index)
			listening = ""
			_refresh_listen()
			get_viewport().set_input_as_handled()
			return
		if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
			listening = ""
			_refresh_listen()
			get_viewport().set_input_as_handled()
			return
	if event is InputEventJoypadButton and event.pressed and cur == "gacha" and not (gacha_result != null and gacha_result.visible):
		if event.button_index == PAD.btn("prev") or event.button_index == PAD.btn("next"):
			var d := -1 if event.button_index == PAD.btn("prev") else 1
			gacha_region = posmod(gacha_region - 1 + d, SV.REGIONS.size()) + 1
			_refresh_gacha()
			get_viewport().set_input_as_handled()
			return
	if event.is_action_pressed("ui_left") and cur in ["settings", "goals", "gacha", "lexicon"] and tab_sel != null and is_instance_valid(tab_sel) and tab_row != null:
		var f0: Control = get_viewport().gui_get_focus_owner()
		if f0 != null and not tab_row.is_ancestor_of(f0) and screens.has(cur) and screens[cur].is_ancestor_of(f0):
			var nb: Control = f0.find_valid_focus_neighbor(SIDE_LEFT)
			if nb == null or not screens[cur].is_ancestor_of(nb):
				tab_sel.grab_focus()
				get_viewport().set_input_as_handled()
				return
	if cur == "news" and news_scroll != null and (event.is_action_pressed("ui_down", true) or event.is_action_pressed("ui_up", true)):
		news_scroll.scroll_vertical += 130 if event.is_action_pressed("ui_down", true) else -130
		get_viewport().set_input_as_handled()
		return
	if _grid_nav(event):
		get_viewport().set_input_as_handled()
		call_deferred("_follow_focus")
		return
	if (event.is_action_pressed("ui_down") or event.is_action_pressed("ui_up")) and _scroll_fallback(event.is_action_pressed("ui_down")):
		get_viewport().set_input_as_handled()
		return
	if _nav_event(event):
		call_deferred("_follow_focus")
	if _nav_event(event) and get_viewport().gui_get_focus_owner() == null:
		# Al reconstruir una pantalla se pierde el foco: con mando/teclado lo recuperamos.
		var fc: Control = _first_focusable()
		if fc != null:
			fc.grab_focus()
			get_viewport().set_input_as_handled()
			return
	if PAD.is_cancel(event) or event.is_action_pressed("ui_cancel"):
		if _popup_open():
			return
		_go_back()
		get_viewport().set_input_as_handled()


# Navegacion con mando igual de comoda en todas las pantallas (navgrid.gd), como en Mejoras.
func _grid_items() -> Array:
	var root: Node = self
	if gacha_result != null and gacha_result.visible:
		root = gacha_result
	if up_picker != null and is_instance_valid(up_picker):
		root = up_picker
	var out: Array = []
	for c in NAVG.focusables(root):
		# con una pantalla abierta solo cuentan ella y la barra superior (no las ocultas)
		if root == self and screens.has(cur):
			if not (screens[cur].is_ancestor_of(c) or not _in_any_screen(c)):
				continue
		out.append(c)
	return out


func _in_any_screen(c: Control) -> bool:
	for k in screens:
		if screens[k].is_ancestor_of(c):
			return true
	return false


func _grid_nav(event: InputEvent) -> bool:
	if _popup_open() or listening != "":
		return false
	return NAVG.move(get_viewport(), event, _grid_items())


func _nav_event(event: InputEvent) -> bool:
	if event is InputEventJoypadButton and event.pressed:
		return true
	if event is InputEventJoypadMotion:
		return (event.axis == JOY_AXIS_LEFT_X or event.axis == JOY_AXIS_LEFT_Y) and absf(event.axis_value) > 0.6
	if event is InputEventKey and event.pressed and not event.echo:
		return event.keycode in [KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT, KEY_TAB, KEY_ENTER, KEY_SPACE]
	return false


# Primer control con foco visible: dentro del resultado del gacha si esta abierto, si no en la pantalla actual.
func _first_focusable() -> Control:
	var root: Node = self
	if gacha_result != null and gacha_result.visible:
		root = gacha_result
	elif screens.has(cur):
		root = screens[cur]
	for n in root.find_children("*", "Control", true, false):
		var c := n as Control
		if c.focus_mode == Control.FOCUS_ALL and c.is_visible_in_tree() and not (c is Slider) and not (c is LineEdit):
			if c is BaseButton and (c as BaseButton).disabled:
				continue
			return c
	return null


func _clear(box: Node) -> void:
	for c in box.get_children():
		box.remove_child(c)
		c.queue_free()


func _name_of(dex: int) -> String:
	return L.t(String(SV.dex_by[dex]["name"]))


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
	var entries := [["Jugar", "play", "flag"], ["Pokémon", "dex", "ball"], ["Mejoras", "up", "up"], ["Gacha", "gacha", "ballLux"], ["Misiones y logros", "goals", "trophy"], ["Léxico", "lexicon", "book"], ["Ajustes", "settings", "gear"]]
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
		if key == "goals":
			goals_btn = b
	main_stats = _label("", 18, Color("#c8d6ee"))
	var sp2 := PanelContainer.new()
	right.add_child(sp2)
	sp2.add_child(main_stats)
var main_play_btn: Button


func _menu_pick(key: String) -> void:
	if key == "play":
		_show("modes")
	else:
		_show(key)


# ---------------------------------------------------------------
# Modos de juego
# ---------------------------------------------------------------
var modes_box: VBoxContainer
var dex_pick_party := false
var dex_pick_team := false
var dex_pick_coop := false
const TYPE_IDS := ["normal", "fire", "water", "grass", "electric", "ice", "fighting", "poison", "ground", "flying", "psychic", "bug", "rock", "ghost", "dragon", "dark", "steel", "fairy"]
const MOD_ICON := {"fast": "boot", "horde": "m_horde", "tank": "shield", "hard": "fist", "frail": "heart", "nohealing": "berry"}
const MOD_INFO := {
	"fast": ["Veloces", "Los enemigos corren un 40% más rápido."],
	"horde": ["Horda", "Casi el doble de enemigos."],
	"tank": ["Resistentes", "Los enemigos tienen un 60% más de vida."],
	"hard": ["Golpes duros", "Los enemigos hacen un 50% más de daño."],
	"frail": ["Frágil", "Tu vida máxima se reduce a la mitad."],
	"nohealing": ["Sin curación", "No recuperas vida (solo la que te da subir de Vida)."],
}


func _start_mode(mode: String) -> void:
	SV.run_mode = mode
	SV.run_dex = int(SV.d["selected"])
	SV.run_type = String(SV.d.get("mode_type", "fire"))
	SV.save()
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _build_modes() -> void:
	var s: Control = _screen("modes")
	var pc := PanelContainer.new()
	s.add_child(pc)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	pc.add_child(v)
	v.add_child(_label("Elige un modo", 34, C_GOLD))
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(sc)
	modes_box = VBoxContainer.new()
	modes_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	modes_box.add_theme_constant_override("separation", 12)
	sc.add_child(modes_box)


func _mode_card(title: String, desc: String, cb: Callable, icon: String = "") -> Button:
	var b := Button.new()
	if icon != "":
		b.icon = IC.btn_tex(icon, 64)
		b.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_constant_override("h_separation", 16)
		b.add_theme_constant_override("icon_max_width", 64)
	b.text = title + "\n" + desc
	b.custom_minimum_size = Vector2(0, 92)
	b.focus_mode = Control.FOCUS_ALL
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.add_theme_font_size_override("font_size", 20)
	b.pressed.connect(cb)
	b.pressed.connect(func(): Aud.sfx("click"))
	b.focus_entered.connect(func(): Aud.sfx("hover"))
	modes_box.add_child(b)
	return b


func _refresh_modes() -> void:
	_clear(modes_box)
	SV.run_mods = Array(SV.d.get("mods", []))
	var first: Button = _mode_card(L.t("Partida normal"), L.t("La experiencia de siempre, igual que el juego original."), func(): _start_mode("normal"), "flag")
	var ds: int = SV.daily_seed()
	var dd: Dictionary = SV.d.get("daily", {})
	var best: int = int(dd.get("best", 0)) if int(dd.get("date", 0)) == ds else 0
	var dm: String = SV.daily_mod(ds)
	var dtxt: String = L.t("Hoy: %s con la regla «%s» (misma para todos). +25%% de monedas.") % [_name_of(SV.daily_dex(ds)), L.t(String(MOD_INFO[dm][0]))]
	dtxt += "  " + (L.t("Tu mejor tiempo de hoy: %s") % ("%d:%02d" % [best / 60, best % 60]) if best > 0 else L.t("Aún no lo has jugado hoy."))
	_mode_card(L.t("Desafío diario"), dtxt, func(): _start_mode("daily"), "m_daily")
	var rb: int = int(SV.d.get("rush_best", 0))
	_mode_card(L.t("Rush de Jefes"), L.t("Solo jefes y legendarios, uno tras otro, cada vez más fuertes. Récord: %d jefes.") % rb, func(): _start_mode("rush"), "m_rush")
	var pd: int = SV.party_dex
	_mode_card(L.t("Modo Fiesta"), L.t("Cualquier Pokémon, no puedes morir y no se guarda progreso. Pokémon: %s") % _name_of(pd), func(): _start_mode("party"), "m_party")
	var pb := Button.new()
	pb.text = L.t("Elegir Pokémon de la fiesta")
	pb.custom_minimum_size = Vector2(0, 52)
	pb.focus_mode = Control.FOCUS_ALL
	pb.pressed.connect(func():
		dex_pick_party = true
		toast(L.t("Toca un Pokémon para la fiesta"))
		_show("dex"))
	modes_box.add_child(pb)
	var cdx: int = int(SV.d.get("coop_dex", 0))
	if cdx <= 0 or not SV.dex_by.has(cdx):
		cdx = 133
		for x in SV.team_list():
			if int(x) != int(SV.d["selected"]):
				cdx = int(x)
				break
	_mode_card(L.t("Modo Cooperativo"), L.t("Un segundo Pokémon te acompaña y ataca solo. Si conectas un segundo mando, el jugador 2 lo mueve con su stick izquierdo. Comparte tus mejoras. -20%% de monedas. Compañero: %s") % _name_of(cdx), func(): _start_mode("coop"), "m_coop")
	var cb2 := Button.new()
	cb2.text = L.t("Elegir compañero")
	cb2.custom_minimum_size = Vector2(0, 52)
	cb2.focus_mode = Control.FOCUS_ALL
	cb2.pressed.connect(func():
		dex_pick_coop = true
		toast(L.t("Toca el Pokémon que será tu compañero"))
		_show("dex"))
	modes_box.add_child(cb2)
	var tw: Dictionary = SV.d.get("tower", {})
	var tbest: int = int(tw.get("best", 0))
	var rel: int = SV.tower_relics()
	_mode_card(L.t("Torre de pisos"), L.t("30 pisos, cada uno con un jefe fijo. Cada piso da un premio la primera vez y cada 5 pisos ganas una reliquia permanente (+6 de vida y +2% de ataque dentro de la Torre). Entre pisos eliges descanso y pactos de riesgo. Mejor piso: %d · Reliquias: %d / 6.") % [tbest, rel], func(): _start_mode("tower"), "m_tower")
	var tstarts: Array = [1]
	var tcl: Dictionary = tw.get("claimed", {})
	for k in range(5, TOWER_FLOORS_M, 5):
		if tcl.has(str(k)):
			tstarts.append(k + 1)
	var tcur: int = int(SV.d.get("tower_start", 1))
	if not tstarts.has(tcur):
		tcur = 1
		SV.d["tower_start"] = 1
	if tstarts.size() > 1:
		var tsb := Button.new()
		tsb.text = L.t("Piso inicial: %d") % tcur
		tsb.custom_minimum_size = Vector2(0, 52)
		tsb.focus_mode = Control.FOCUS_ALL
		tsb.pressed.connect(func():
			var i: int = tstarts.find(int(SV.d.get("tower_start", 1)))
			SV.d["tower_start"] = int(tstarts[(i + 1) % tstarts.size()])
			SV.save()
			_refresh_modes())
		modes_box.add_child(tsb)
	var rbest: int = int(SV.d.get("rifts_best", 0))
	_mode_card(L.t("Contrarreloj de grietas"), L.t("8 minutos: las grietas se abren sin parar. Gana todas las peleas que puedas. +25%% de monedas. Récord: %d grietas.") % rbest, func(): _start_mode("rifts"), "m_clock")
	var ty: String = String(SV.d.get("mode_type", "fire"))
	if not TYPE_IDS.has(ty):
		ty = "fire"
	_mode_card(L.t("Supervivencia por tipo"), L.t("Solo aparecen Pokémon de tipo %s (y sus jefes). +50%% de monedas.") % L.t(String(MD.TYPE_NAME[ty])), func(): _start_mode("type"), "m_type")
	var tb := Button.new()
	tb.text = L.t("Cambiar tipo: %s") % L.t(String(MD.TYPE_NAME[ty]))
	tb.custom_minimum_size = Vector2(0, 52)
	tb.focus_mode = Control.FOCUS_ALL
	tb.pressed.connect(func():
		SV.d["mode_type"] = String(TYPE_IDS[(TYPE_IDS.find(ty) + 1) % TYPE_IDS.size()])
		SV.save()
		_refresh_modes())
	modes_box.add_child(tb)
	var tl: Array = SV.team_list()
	var names: Array = []
	for x in tl:
		names.append(_name_of(int(x)))
	if SV.owned_count() >= 2:
		_mode_card(L.t("Modo Equipo"), L.t("Lleva hasta 3 Pokémon y cámbialos en plena partida (botón táctil de la derecha, tocando su ficha, R3 o Tab). Si uno cae, entra el siguiente; los de banca se recuperan. Equipo: %s") % ", ".join(names), func(): _start_mode("team"), "m_team")
		var eb := Button.new()
		eb.text = L.t("Elegir equipo (hasta 3)")
		eb.custom_minimum_size = Vector2(0, 52)
		eb.focus_mode = Control.FOCUS_ALL
		eb.pressed.connect(func():
			dex_pick_team = true
			SV.d["team"] = []
			toast(L.t("Toca hasta 3 Pokémon tuyos para el equipo"))
			_show("dex"))
		modes_box.add_child(eb)
	else:
		_mode_card(L.t("Modo Equipo"), L.t("Necesitas al menos 2 Pokémon para formar un equipo."), func(): toast(L.t("Consigue otro Pokémon primero")), "m_team")
	modes_box.add_child(_label(L.t("Modificadores (todos los modos menos Diario y Fiesta): +25% de monedas por cada uno activo"), 22, C_GOLD))
	for id in SV.MOD_IDS:
		var cb := CheckButton.new()
		cb.text = L.t(String(MOD_INFO[id][0])) + " — " + L.t(String(MOD_INFO[id][1]))
		cb.focus_mode = Control.FOCUS_ALL
		cb.icon = IC.btn_tex(String(MOD_ICON[id]), 32)
		cb.add_theme_constant_override("icon_max_width", 32)
		cb.add_theme_font_size_override("font_size", 20)
		cb.button_pressed = SV.run_mods.has(id)
		cb.toggled.connect(func(on: bool):
			if on and not SV.run_mods.has(id):
				SV.run_mods.append(id)
			elif not on:
				SV.run_mods.erase(id)
			SV.d["mods"] = SV.run_mods.duplicate()
			SV.save())
		modes_box.add_child(cb)
	focus_first = first


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
	var ttl: String = String(SV.d.get("title", ""))
	if ttl != "":
		main_info.text += "\n" + L.t(ttl)
	PG.ensure()
	PG.check()
	var pn: int = PG.pending()
	goals_btn.text = L.t("Misiones y logros") + ("  (%d)" % pn if pn > 0 else "")
	var st: Dictionary = SV.d["stats"]
	main_stats.text = L.t("Partidas %d · Mejor tiempo %d:%02d\nMejor nivel %d · Derrotados %d\nPokémon %d / %d") % [int(st["runs"]), int(st["best_time"]) / 60, int(st["best_time"]) % 60, int(st["best_level"]), int(st["kills"]), SV.owned_count(), SV.dex_list.size()]
	focus_first = main_play_btn


# Pantalla de fin de partida como la del original: titulo, cuadricula de datos,
# monedas con desglose, tickets, movimientos y boton de volver.
func _stat_cell(label: String, value: String, col: Color = Color.WHITE, wide: bool = false) -> PanelContainer:
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", _sb(Color(0.05, 0.1, 0.26, 0.55), Color(0.5, 0.62, 0.9, 0.35), 2, 10))
	pc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	pc.add_child(v)
	v.add_child(_label(label, 16, Color("#9fb4dc")))
	var l := _label(value, 28 if not wide else 24, col)
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	v.add_child(l)
	return pc


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
	pc.custom_minimum_size = Vector2(620, 0)
	pc.add_theme_stylebox_override("panel", _sb(Color("#27489a"), Color("#f4f8ff"), 3, 14))
	c.add_child(pc)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 3)
	pc.add_child(v)
	var title := _label("Has caído…" if bool(r.get("dead", true)) else "Partida terminada", 38, Color.WHITE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	var t: int = int(r["time"])
	var g := GridContainer.new()
	g.columns = 2
	g.add_theme_constant_override("h_separation", 8)
	g.add_theme_constant_override("v_separation", 8)
	v.add_child(g)
	g.add_child(_stat_cell(L.t("Tiempo"), "%02d:%02d" % [t / 60, t % 60]))
	g.add_child(_stat_cell(L.t("Nivel"), str(int(r["level"]))))
	g.add_child(_stat_cell(L.t("Derrotados"), str(int(r["kills"]))))
	g.add_child(_stat_cell(L.t("Jefes"), str(int(r["bosses"]))))
	var jr: Dictionary = r.get("judge", {})
	if not jr.is_empty():
		var jt: int = int(jr["time"])
		var jb: int = int(jr["bosses"])
		var jc := _stat_cell(L.t("Ante Arceus"), "%d:%02d · %d %s" % [jt / 60, jt % 60, jb, L.t("legendario") if jb == 1 else L.t("legendarios")], C_GOLD, true)
		v.add_child(jc)
	# monedas con desglose
	var cc := PanelContainer.new()
	cc.add_theme_stylebox_override("panel", _sb(Color(0.05, 0.1, 0.26, 0.55), Color(0.5, 0.62, 0.9, 0.35), 2, 10))
	var cv := VBoxContainer.new()
	cv.add_theme_constant_override("separation", 2)
	cc.add_child(cv)
	cv.add_child(_label("Pokémonedas ganadas", 16, Color("#9fb4dc")))
	var gr := HBoxContainer.new()
	gr.add_theme_constant_override("separation", 8)
	gr.add_child(IC.rect("coin", 28))
	var gl := _label("+%d" % int(r["coins"]), 28, Color("#ffd23f"))
	gl.autowrap_mode = TextServer.AUTOWRAP_OFF
	gr.add_child(gl)
	cv.add_child(gr)
	if String(r.get("breakdown", "")) != "":
		var bl := _label(L.t("Recogidas %d · Tiempo +%d · Derrotados +%d") % _bd_nums(String(r["breakdown"])), 13, Color("#9fb4dc"))
		bl.autowrap_mode = TextServer.AUTOWRAP_OFF
		cv.add_child(bl)
	var mid := HBoxContainer.new()
	mid.add_theme_constant_override("separation", 8)
	cc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.add_child(cc)
	v.add_child(mid)
	if int(r["tickets"]) > 0 or int(r.get("tickets10", 0)) > 0:
		var tc := PanelContainer.new()
		tc.add_theme_stylebox_override("panel", _sb(Color(0.05, 0.1, 0.26, 0.55), Color(0.5, 0.62, 0.9, 0.35), 2, 10))
		var tv := VBoxContainer.new()
		tv.add_theme_constant_override("separation", 2)
		tc.add_child(tv)
		tv.add_child(_label("Tickets del gacha", 16, Color("#9fb4dc")))
		var tr := HBoxContainer.new()
		tr.add_theme_constant_override("separation", 8)
		if int(r["tickets"]) > 0:
			tr.add_child(IC.rect("ticket", 26))
			var tl1 := _label("+%d" % int(r["tickets"]), 26, Color("#ffd23f"))
			tl1.autowrap_mode = TextServer.AUTOWRAP_OFF
			tr.add_child(tl1)
		if int(r.get("tickets10", 0)) > 0:
			tr.add_child(IC.rect("ticket10", 26))
			var tl2 := _label("+%d ×10" % int(r["tickets10"]), 26, Color("#c47bff"))
			tl2.autowrap_mode = TextServer.AUTOWRAP_OFF
			tr.add_child(tl2)
		tv.add_child(tr)
		tc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		mid.add_child(tc)
	# movimientos de la partida
	var mc := PanelContainer.new()
	mc.add_theme_stylebox_override("panel", _sb(Color(0.05, 0.1, 0.26, 0.55), Color(0.5, 0.62, 0.9, 0.35), 2, 10))
	var mv := VBoxContainer.new()
	mv.add_theme_constant_override("separation", 4)
	mc.add_child(mv)
	mv.add_child(_label("Daño y derrotas por movimiento", 16, Color("#9fb4dc")))
	var mlist: Array = r.get("moves", []).duplicate()
	mlist.sort_custom(func(x, y): return int(x.get("dmg", 0)) > int(y.get("dmg", 0)))
	var tot_dmg: int = int(r.get("other_dmg", 0))
	tot_dmg += int(r.get("ally_dmg", 0))
	for m0 in mlist:
		tot_dmg += int(m0.get("dmg", 0))
	var mg := GridContainer.new()
	mg.columns = 3
	mg.add_theme_constant_override("h_separation", 18)
	mg.add_theme_constant_override("v_separation", 3)
	if mlist.size() > 5:
		var msc := ScrollContainer.new()
		msc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		msc.custom_minimum_size = Vector2(0, 170)
		mg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		msc.add_child(mg)
		mv.add_child(msc)
	else:
		mv.add_child(mg)
	if mlist.is_empty():
		mg.add_child(_label("—", 18))
	else:
		var h1 := _label("Movimiento", 13, Color("#7f93c2"))
		h1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h1.autowrap_mode = TextServer.AUTOWRAP_OFF
		mg.add_child(h1)
		var h2 := _label("Daño", 13, Color("#7f93c2"))
		h2.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		h2.autowrap_mode = TextServer.AUTOWRAP_OFF
		mg.add_child(h2)
		var h3 := _label("Derrotados", 13, Color("#7f93c2"))
		h3.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		h3.autowrap_mode = TextServer.AUTOWRAP_OFF
		mg.add_child(h3)
	for m in mlist:
		var mr := HBoxContainer.new()
		mr.add_theme_constant_override("separation", 6)
		mr.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		mr.add_child(IC.rect(("evo:" if bool(m.get("evo", false)) else "move:") + String(m["id"]), 20))
		var ml := _label("%s Nv.%d" % [L.t(String(m["name"])), int(m["lvl"])], 17)
		ml.autowrap_mode = TextServer.AUTOWRAP_OFF
		mr.add_child(ml)
		mg.add_child(mr)
		var md_: int = int(m.get("dmg", 0))
		var pct: int = roundi(100.0 * float(md_) / float(maxi(1, tot_dmg)))
		var dl := _label("%s (%d%%)" % [_fmt_n(md_), pct], 17, Color("#ffd23f"))
		dl.autowrap_mode = TextServer.AUTOWRAP_OFF
		dl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		mg.add_child(dl)
		var kl := _label(str(int(m.get("kills", 0))), 17)
		kl.autowrap_mode = TextServer.AUTOWRAP_OFF
		kl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		mg.add_child(kl)
	if int(r.get("ally_dmg", 0)) > 0 or int(r.get("ally_kills", 0)) > 0:
		var al := _label("Compañero / equipo", 17, Color("#8fe3b0"))
		al.autowrap_mode = TextServer.AUTOWRAP_OFF
		mg.add_child(al)
		var ad := _label("%s (%d%%)" % [_fmt_n(int(r.get("ally_dmg", 0))), roundi(100.0 * float(int(r.get("ally_dmg", 0))) / float(maxi(1, tot_dmg)))], 17, Color("#8fe3b0"))
		ad.autowrap_mode = TextServer.AUTOWRAP_OFF
		ad.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		mg.add_child(ad)
		var ak := _label(str(int(r.get("ally_kills", 0))), 17, Color("#8fe3b0"))
		ak.autowrap_mode = TextServer.AUTOWRAP_OFF
		ak.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		mg.add_child(ak)
	if int(r.get("other_dmg", 0)) > 0 or int(r.get("other_kills", 0)) > 0:
		var ol := _label("Otros (estados, trampas, objetos)", 15, Color("#9fb4dc"))
		ol.autowrap_mode = TextServer.AUTOWRAP_OFF
		mg.add_child(ol)
		var od := _label(_fmt_n(int(r.get("other_dmg", 0))), 15, Color("#9fb4dc"))
		od.autowrap_mode = TextServer.AUTOWRAP_OFF
		od.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		mg.add_child(od)
		var ok2 := _label(str(int(r.get("other_kills", 0))), 15, Color("#9fb4dc"))
		ok2.autowrap_mode = TextServer.AUTOWRAP_OFF
		ok2.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		mg.add_child(ok2)
	v.add_child(mc)
	if bool(r.get("record", false)):
		var rl := _label("¡Nuevo récord de tiempo!", 22, C_GOLD)
		rl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(rl)
	var ok := _btn("Volver al menú", func(): ov.queue_free(); _update_top(); focus_first = main_play_btn; main_play_btn.grab_focus(), Vector2(260, 56))
	ok.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(ok)
	_gf(ok)
	_update_top()


func _fmt_n(n: int) -> String:
	if n >= 1000000:
		return "%.1fM" % (float(n) / 1000000.0)
	if n >= 10000:
		return "%.1fk" % (float(n) / 1000.0)
	return str(n)


func _bd_nums(bd: String) -> Array:
	var out: Array = []
	for part in bd.split(" · "):
		out.append(int(part.get_slice(" ", part.get_slice_count(" ") - 1).replace("+", "")))
	while out.size() < 3:
		out.append(0)
	return out


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
		if (dex_only_owned or dex_pick_team or dex_pick_coop) and not dex_pick_party and not SV.owns(int(p["dex"])):
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
		b.text = ("#%d %s" % [dx, L.t(String(p["name"]))]) if (owned or dex_pick_party) else "#%d ???" % dx
		b.add_theme_font_size_override("font_size", 13)
		if not owned and not dex_pick_party:
			for k in ["icon_normal_color", "icon_hover_color", "icon_pressed_color", "icon_focus_color"]:
				b.add_theme_color_override(k, Color(0, 0, 0, 0.85))
		if dx == int(SV.d["selected"]):
			b.add_theme_stylebox_override("normal", _sb(Color("#3a6a2e"), C_GOLD, 3))
		if dex_pick_party:
			b.pressed.connect(func():
				SV.party_dex = dx
				dex_pick_party = false
				toast(L.t("Pokémon de la fiesta: %s") % _name_of(dx))
				_show("modes"))
		elif dex_pick_coop:
			b.pressed.connect(func():
				SV.d["coop_dex"] = dx
				SV.save()
				dex_pick_coop = false
				toast(L.t("Compañero: %s") % _name_of(dx))
				_show("modes"))
		elif dex_pick_team:
			if Array(SV.d.get("team", [])).has(dx):
				b.add_theme_stylebox_override("normal", _sb(Color("#2e6a5a"), C_GOLD, 3))
			b.pressed.connect(func():
				var tm: Array = Array(SV.d.get("team", []))
				if tm.has(dx):
					tm.erase(dx)
				elif tm.size() < 3:
					tm.append(dx)
				SV.d["team"] = tm
				SV.save()
				if tm.size() >= 3:
					dex_pick_team = false
					toast(L.t("¡Equipo listo!"))
					_show("modes")
				else:
					toast(L.t("Equipo: %d / 3") % tm.size())
					_refresh_dex())
		else:
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
	dex_detail.add_child(_label("#%d  %s" % [dx, L.t(String(p["name"]))], 30, C_GOLD))
	var trow := HBoxContainer.new()
	trow.add_theme_constant_override("separation", 6)
	for t in SV.dex_by[dx]["types"]:
		trow.add_child(IC.rect("type:" + String(t), 32))
	var tlb := _label(_type_text(dx), 22)
	tlb.autowrap_mode = TextServer.AUTOWRAP_OFF
	trow.add_child(tlb)
	dex_detail.add_child(trow)
	dex_detail.add_child(_label(L.t("PS %d · Velocidad %d · Ataque x%.2f") % [int(p["hp"]), int(p["spd"]), float(p["atk"])], 18, Color("#c8d6ee")))
	var abd: Dictionary = AB.FX[AB.of(dx)]
	dex_detail.add_child(_label(L.t("Habilidad: %s") % L.t(String(abd["name"])), 18, Color("#ffd98a")))
	dex_detail.add_child(_label(L.t(String(abd["desc"])), 15, Color("#c8d6ee")))
	var zl: Array = SV.zm_types(dx)
	if zl.is_empty():
		dex_detail.add_child(_label(L.t("Movimiento Z: bloqueado (derrota %d Pokémon de su tipo)") % ZM.NEED, 15, Color("#8a96b0")))
	else:
		var zcur: String = SV.zm_type_for(dx)
		dex_detail.add_child(_icon_label("zc:" + zcur, L.t("Movimiento Z: %s") % L.t(String(ZM.DEF[zcur]["name"])), 18, Color("#ffb86b"), 32.0))
		if zl.size() > 1:
			dex_detail.add_child(_btn(L.t("Cambiar movimiento Z"), func():
				var nx: String = String(zl[(zl.find(zcur) + 1) % zl.size()])
				SV.d["pz"][str(dx)] = nx
				SV.save()
				_dex_detail(), Vector2(0, 46)))
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
	up_box.add_theme_constant_override("separation", 12)
	sc.add_child(up_box)


const UP_ICON := {"hp": "heart", "atk": "fist", "spd": "boot", "cd": "clock", "def": "shield", "regen": "sprout", "magnet": "magnet", "xp": "book", "coins": "coin", "moves": "cards", "crit": "star", "size": "size", "reroll": "bond", "ban": "ban", "revive": "revive", "bag": "bag", "tm": "tm"}


# Reconstruye la pantalla de mejoras sin perder la seleccion del mando ni el scroll.
func _refresh_up_keep(key: String) -> void:
	var sc: ScrollContainer = null
	var p: Node = up_box.get_parent()
	while p != null and not (p is ScrollContainer):
		p = p.get_parent()
	if p != null:
		sc = p as ScrollContainer
	var sv: int = sc.scroll_vertical if sc != null else 0
	_refresh_up()
	await get_tree().process_frame
	await get_tree().process_frame
	if not is_instance_valid(up_box) or cur != "up":
		return
	if sc != null:
		sc.scroll_vertical = sv
	var cand: Array = []
	for b in up_box.find_children("*", "Control", true, false):
		if b is BaseButton or b is OptionButton:
			cand.append(b)
	var target: Control = null
	var idx_key := -1
	for i in range(cand.size()):
		if String(cand[i].get_meta("fk", "")) == key:
			idx_key = i
			if not cand[i].disabled:
				target = cand[i]
			break
	if target == null and idx_key >= 0:
		# el boton quedo desactivado (maximo / sin monedas): el siguiente activo, o el anterior
		for i in range(idx_key + 1, cand.size()):
			if not cand[i].disabled:
				target = cand[i]
				break
		if target == null:
			for i in range(idx_key - 1, -1, -1):
				if not cand[i].disabled:
					target = cand[i]
					break
	if target != null:
		target.grab_focus()
		if sc != null:
			sc.scroll_vertical = sv
			sc.ensure_control_visible(target)


func _refresh_up() -> void:
	_clear(up_box)
	if not SV.owns(up_dex):
		up_dex = int(SV.d["selected"])
	var first: Button = null
	# --- cabecera: retrato animado + selector de Pokemon
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 16)
	up_box.add_child(head)
	var por := Portrait.new()
	por.custom_minimum_size = Vector2(190, 160)
	head.add_child(por)
	var tcol := Color("#ff7b3d")
	var types: Array = SV.dex_by[up_dex]["types"]
	if not types.is_empty():
		tcol = Color.html(String(MD.TYPE_COLOR.get(String(types[0]), "#ff7b3d")))
	por.setup(up_dex, tcol)
	var hv := VBoxContainer.new()
	hv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hv.alignment = BoxContainer.ALIGNMENT_CENTER
	head.add_child(hv)
	hv.add_child(_label("Cada Pokémon tiene sus propias mejoras: solo cuentan cuando juegas con él.", 20, Color("#c8d6ee")))
	var orow := HBoxContainer.new()
	hv.add_child(orow)
	var owned: Array = _up_owned()
	var cur_i: int = maxi(owned.find(up_dex), 0)
	var prev_b := _btn("◀", func(): _up_step(-1), Vector2(64, 56))
	prev_b.set_meta("fk", "upprev")
	orow.add_child(prev_b)
	var par0: String = L.t(" (compañero)") if up_dex == int(SV.d["selected"]) else ""
	var pick_b := _btn(L.t("%s%s · %d niveles") % [_name_of(up_dex), par0, SV.up_total(up_dex)] + "  ▾", _open_up_picker, Vector2(360, 56))
	pick_b.set_meta("fk", "uppick")
	pick_b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pick_b.add_theme_font_size_override("font_size", 22)
	orow.add_child(pick_b)
	var next_b := _btn("▶", func(): _up_step(1), Vector2(64, 56))
	next_b.set_meta("fk", "upnext")
	orow.add_child(next_b)
	if owned.size() < 2:
		prev_b.disabled = true
		next_b.disabled = true
	if up_dex != int(SV.d["selected"]):
		var pb := _btn("Usar de compañero", func(): SV.d["selected"] = up_dex; SV.save(); toast(L.t("Compañero: %s") % _name_of(up_dex)); _refresh_up(), Vector2(0, 56))
		orow.add_child(pb)
	# --- tarjetas de mejoras
	var grid := GridContainer.new()
	grid.columns = 3 if get_viewport_rect().size.x >= 1150.0 else 2
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 12)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	up_box.add_child(grid)
	var up_anchors: Array = []
	var up_extra: Array = []
	for u in SV.UPGRADES:
		var id: String = String(u["id"])
		var lv: int = SV.up_level(id, up_dex)
		var mx: int = int(u["max"])
		var card := PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.add_theme_stylebox_override("panel", _card_sb())
		grid.add_child(card)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		card.add_child(row)
		var uic := IC.rect(String(UP_ICON.get(id, "star")), 36)
		uic.custom_minimum_size.x = 44
		row.add_child(uic)
		var col := VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.add_theme_constant_override("separation", 2)
		row.add_child(col)
		col.add_child(_label(String(u["name"]), 22))
		col.add_child(_label(String(u["unit"]), 16, Color("#c8d6ee")))
		var pips := Pips.new()
		pips.setup(lv, mx)
		col.add_child(pips)
		var btn: Button
		if lv >= mx:
			btn = _btn("Máximo", func(): pass, Vector2(120, 52))
			btn.disabled = true
			btn.add_theme_stylebox_override("disabled", _sb(Color("#2b3452"), Color("#4a5578"), 3, 12))
		else:
			var cost: int = SV.up_cost(id, lv)
			btn = _cost_btn("", str(cost), "", "coin", func(): _buy(id), Vector2(120, 52), int(SV.d["coins"]) >= cost, false, true)
			btn.set_meta("fk", "u:" + id)
			if first == null and not btn.disabled:
				first = btn
		btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		up_anchors.append(btn if not btn.disabled else null)
		up_extra.append(null)
		if id == "tm" and lv > 0:
			var tmcol := VBoxContainer.new()
			tmcol.add_theme_constant_override("separation", 6)
			tmcol.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			var et := _btn(L.t("Elegir"), func(): tm_open = not tm_open; _refresh_up_keep("tmelegir"), Vector2(120, 44))
			et.set_meta("fk", "tmelegir")
			up_extra[up_extra.size() - 1] = et
			tmcol.add_child(et)
			tmcol.add_child(btn)
			row.add_child(tmcol)
		elif id == "ban" and lv > 0:
			var bcol := VBoxContainer.new()
			bcol.add_theme_constant_override("separation", 6)
			bcol.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			var nb: int = mini(SV.ban_list(up_dex).size(), lv)
			var eb := _btn(L.t("Elegir (%d/%d)") % [nb, lv], func(): ban_open = not ban_open; _refresh_up_keep("elegir"), Vector2(120, 44))
			eb.set_meta("fk", "elegir")
			up_extra[up_extra.size() - 1] = eb
			bcol.add_child(eb)
			bcol.add_child(btn)
			row.add_child(bcol)
		else:
			row.add_child(btn)
	focus_first = first
	# Izquierda/derecha: cicla dentro de la fila de tarjetas (con vuelta al otro extremo).
	var ncol: int = grid.columns
	var ri := 0
	while ri < up_anchors.size():
		var rowb: Array = []
		var rowx: Array = []
		for ci in range(ncol):
			if ri + ci < up_anchors.size() and up_anchors[ri + ci] != null:
				rowb.append(up_anchors[ri + ci])
				rowx.append(up_extra[ri + ci])
		for k in range(rowb.size()):
			var nxt: Control = rowb[(k + 1) % rowb.size()]
			var prv: Control = rowb[posmod(k - 1, rowb.size())]
			for bb in [rowb[k], rowx[k]]:
				if bb == null:
					continue
				bb.focus_neighbor_right = bb.get_path_to(nxt)
				bb.focus_neighbor_left = bb.get_path_to(prv)
		ri += ncol
	if SV.up_level("tm", up_dex) > 0 and tm_open:
		up_box.add_child(_tm_panel())
	var ban_lv: int = SV.up_level("ban", up_dex)
	if ban_lv > 0 and ban_open:
		up_box.add_child(_ban_panel(ban_lv))
	up_box.add_child(_bind_panel())


# MT: elige el movimiento con el que empiezas cada partida (gratis cambiarlo cuando quieras).
func _tm_panel() -> Control:
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", _card_sb())
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	pc.add_child(v)
	var cur: String = SV.start_move_of(up_dex)
	var sub := _label(L.t("Elige el movimiento con el que empiezas cada partida. Puedes cambiarlo gratis cuando quieras."), 18, Color("#c8d6ee"))
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(sub)
	var fl := HFlowContainer.new()
	fl.add_theme_constant_override("h_separation", 8)
	fl.add_theme_constant_override("v_separation", 8)
	v.add_child(fl)
	var ids: Array = SV.tm_pool(up_dex)
	ids.sort_custom(func(a, b): return L.t(String(MD.MOVES[a]["name"])) < L.t(String(MD.MOVES[b]["name"])))
	for id in ids:
		var on: bool = String(id) == cur
		var b := _btn(("✔ " if on else "") + L.t(String(MD.MOVES[id]["name"])), func():
			SV.tm_set(up_dex, String(id))
			Aud.sfx("select")
			_refresh_up_keep("tm:" + String(id)), Vector2(0, 40))
		b.set_meta("fk", "tm:" + String(id))
		if on:
			b.add_theme_stylebox_override("normal", _sb(Color("#7a5a14"), Color("#ffd23f"), 3, 10))
		fl.add_child(b)
	return pc


# Veto: toca los movimientos que no quieres que te salgan en las cartas de este Pokemon.
func _ban_panel(max_n: int) -> Control:
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", _card_sb())
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	pc.add_child(v)
	var l := SV.ban_list(up_dex)
	var sub := _label(L.t("Toca los movimientos que no quieres que te salgan en las cartas (%d/%d). El movimiento de inicio no se puede vetar.") % [l.size(), max_n], 18, Color("#c8d6ee"))
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(sub)
	var fl := HFlowContainer.new()
	fl.add_theme_constant_override("h_separation", 8)
	fl.add_theme_constant_override("v_separation", 8)
	v.add_child(fl)
	var ids: Array = SV.move_pool(up_dex)
	ids.sort_custom(func(a, b): return L.t(String(MD.MOVES[a]["name"])) < L.t(String(MD.MOVES[b]["name"])))
	for id in ids:
		var on: bool = l.has(id)
		var b := _btn(("✕ " if on else "") + L.t(String(MD.MOVES[id]["name"])), func():
			if SV.ban_toggle(up_dex, String(id), max_n):
				Aud.sfx("select")
			else:
				Aud.sfx("error")
				toast(L.t("Ya tienes %d vetados: quita uno primero") % max_n)
			_refresh_up_keep("b:" + String(id)), Vector2(0, 40))
		b.set_meta("fk", "b:" + String(id))
		if on:
			b.add_theme_stylebox_override("normal", _sb(Color("#7a2438"), Color("#ff6b7a"), 3, 10))
		fl.add_child(b)
	return pc


# Atajos: que movimiento va siempre en cada hueco (teclas 1-4 o iconos de abajo).
func _bind_panel() -> Control:
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", _card_sb())
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	pc.add_child(v)
	v.add_child(_label("Atajos de movimientos", 22))
	var sub := _label("Elige qué movimiento va siempre en cada hueco (teclas 1-4 o los iconos de abajo), para la memoria muscular. Si aún no tienes tantos movimientos, va al hueco más cercano.", 17, Color("#c8d6ee"))
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(sub)
	var ids: Array = SV.move_pool(up_dex)
	ids.append(SV.start_move_of(up_dex))
	ids.sort_custom(func(a, b): return L.t(String(MD.MOVES[a]["name"])) < L.t(String(MD.MOVES[b]["name"])))
	var cur: Array = SV.bind_list(up_dex)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	v.add_child(row)
	for i in range(4):
		var num := _label(str(i + 1), 22, C_GOLD)
		row.add_child(num)
		var ob := OptionButton.new()
		ob.custom_minimum_size = Vector2(150, 46)
		ob.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ob.focus_mode = Control.FOCUS_ALL
		ob.add_item(L.t("Libre"), 0)
		var sel := 0
		for k in range(ids.size()):
			ob.add_item(L.t(String(MD.MOVES[ids[k]]["name"])), k + 1)
			if String(cur[i]) == String(ids[k]):
				sel = k + 1
		ob.select(sel)
		var slot: int = i
		ob.item_selected.connect(func(idx: int):
			var pick: String = "" if idx == 0 else String(ids[idx - 1])
			SV.bind_set(up_dex, slot, pick)
			Aud.sfx("select")
			_refresh_up_keep("bind%d" % slot))
		ob.set_meta("fk", "bind%d" % slot)
		row.add_child(ob)
	return pc


func _up_owned() -> Array:
	var owned: Array = []
	for k in SV.d["owned"].keys():
		owned.append(int(k))
	owned.sort()
	return owned


func _up_step(d: int) -> void:
	var owned: Array = _up_owned()
	if owned.is_empty():
		return
	var i: int = posmod(maxi(owned.find(up_dex), 0) + d, owned.size())
	up_dex = int(owned[i])
	Aud.sfx("select")
	_refresh_up_keep("uppick")


func _close_up_picker() -> void:
	if up_picker != null and is_instance_valid(up_picker):
		up_picker.queue_free()
	up_picker = null


# Selector grande y tactil (la lista desplegable normal es dificil de usar en el movil).
func _open_up_picker() -> void:
	pk_gen = 0
	pk_type = ""
	pk_q = ""
	pk_focus = ""
	_build_up_picker()


func _pk_filter_row(parent: Control, items: Array, cur_val, on_pick: Callable, prefix: String) -> void:
	var sc := ScrollContainer.new()
	sc.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.custom_minimum_size = Vector2(0, 58)
	sc.get_h_scroll_bar().custom_minimum_size.y = 12
	parent.add_child(sc)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 6)
	sc.add_child(hb)
	for it in items:
		var key: String = prefix + str(it["v"])
		var b := _btn(String(it["t"]), func():
			pk_focus = key
			on_pick.call(it["v"]), Vector2(0, 44))
		b.add_theme_font_size_override("font_size", 16)
		if it["v"] == cur_val:
			b.add_theme_stylebox_override("normal", _sb(Color("#3a6a2e"), C_GOLD, 3))
		if it.has("c"):
			b.add_theme_color_override("font_color", Color.html(String(it["c"])))
		hb.add_child(b)
		if key == pk_focus:
			b.call_deferred("grab_focus")


func _build_up_picker() -> void:
	_close_up_picker()
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	root.z_index = 50
	add_child(root)
	up_picker = root
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.72)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)
	var pan := PanelContainer.new()
	pan.add_theme_stylebox_override("panel", _sb(Color(0.05, 0.1, 0.26, 0.98), Color(0.5, 0.62, 0.9, 0.8), 3, 14))
	pan.anchor_left = 0.06
	pan.anchor_right = 0.94
	pan.anchor_top = 0.05
	pan.anchor_bottom = 0.95
	pan.offset_left = 0
	pan.offset_right = 0
	pan.offset_top = 0
	pan.offset_bottom = 0
	root.add_child(pan)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	pan.add_child(v)
	var top := HBoxContainer.new()
	v.add_child(top)
	var tl := _label("Elegir Pokémon", 26, C_GOLD)
	tl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(tl)
	top.add_child(_btn("Cerrar", _close_up_picker, Vector2(150, 56)))
	var search := LineEdit.new()
	search.text = pk_q
	search.placeholder_text = L.t("Buscar Pokémon por nombre…")
	search.clear_button_enabled = true
	search.custom_minimum_size = Vector2(0, 52)
	search.add_theme_font_size_override("font_size", 24)
	v.add_child(search)
	var gens: Array = [{"v": 0, "t": L.t("Todas")}]
	for gi in range(SV.REGIONS.size()):
		gens.append({"v": gi + 1, "t": "%d · %s" % [gi + 1, L.t(SV.REGIONS[gi])]})
	_pk_filter_row(v, gens, pk_gen, func(x): pk_gen = int(x); _build_up_picker(), "g")
	var tys: Array = [{"v": "", "t": L.t("Todas")}]
	for tk in MD.TYPE_NAME.keys():
		tys.append({"v": String(tk), "t": L.t(String(MD.TYPE_NAME[tk])), "c": String(MD.TYPE_COLOR.get(tk, "#ffffff"))})
	_pk_filter_row(v, tys, pk_type, func(x): pk_type = String(x); _build_up_picker(), "t")
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.get_v_scroll_bar().custom_minimum_size.x = 30
	v.add_child(sc)
	var grid := GridContainer.new()
	grid.columns = 3 if get_viewport_rect().size.x >= 1150.0 else 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	sc.add_child(grid)
	var focus_b: Button = null
	var shown := 0
	for dx in _up_owned():
		var d: int = int(dx)
		var info: Dictionary = SV.dex_by[d]
		if pk_gen != 0 and int(info["gen"]) != pk_gen:
			continue
		if pk_type != "" and not Array(info["types"]).has(pk_type):
			continue
		shown += 1
		var par: String = L.t(" (compañero)") if d == int(SV.d["selected"]) else ""
		var mark: String = "✔ " if d == up_dex else ""
		var b := _btn(mark + L.t("%s%s · %d niveles") % [_name_of(d), par, SV.up_total(d)], func():
			up_dex = d
			_close_up_picker()
			Aud.sfx("select")
			_refresh_up_keep("uppick"), Vector2(0, 76))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size", 19)
		b.clip_text = true
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var tx: Texture2D = _icon_tex(d, false)
		if tx != null:
			b.icon = tx
			b.expand_icon = true
			b.add_theme_constant_override("icon_max_width", 56)
		b.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.set_meta("q", (_name_of(d) + " " + String(info["name"]) + " " + str(d)).to_lower())
		grid.add_child(b)
		if d == up_dex and pk_focus == "":
			focus_b = b
	var none_l := _label("Ninguno coincide con el filtro.", 20, Color("#c8d6ee"))
	none_l.visible = shown == 0
	grid.add_child(none_l)
	var apply_q := func(t: String):
		pk_q = t
		var q: String = t.strip_edges().to_lower()
		var vis := 0
		for ch in grid.get_children():
			if ch == none_l:
				continue
			var ok: bool = q == "" or String(ch.get_meta("q", "")).contains(q)
			ch.visible = ok
			if ok:
				vis += 1
		none_l.visible = vis == 0
	search.text_changed.connect(apply_q)
	if pk_q != "":
		apply_q.call(pk_q)
	if focus_b != null and pk_q == "":
		await get_tree().process_frame
		if is_instance_valid(focus_b):
			focus_b.grab_focus()
			sc.ensure_control_visible(focus_b)


func _buy(id: String) -> void:
	if SV.buy_upgrade(id, up_dex):
		Aud.sfx("buy")
		toast("¡Mejora comprada!")
	else:
		Aud.sfx("error")
	_update_top()
	_refresh_up_keep("u:" + id)


# ---------------------------------------------------------------
# Gacha
# ---------------------------------------------------------------
func _build_gacha() -> void:
	var s: Control = _screen("gacha")
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	s.add_child(sc)
	gacha_box = VBoxContainer.new()
	gacha_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gacha_box.add_theme_constant_override("separation", 12)
	sc.add_child(gacha_box)
	gacha_result = ColorRect.new()
	gacha_result.color = Color(0, 0, 0, 0.7)
	gacha_result.set_anchors_preset(Control.PRESET_FULL_RECT)
	gacha_result.z_index = 30
	gacha_result.visible = false
	add_child(gacha_result)


# Por region: 2 legendarios a los lados, uno popular en el centro, y colores del escenario.
const BANNERS := [
	{"legs": [150, 151], "star": 6, "c1": "#5b2f8f", "c2": "#1f6f7a"},
	{"legs": [249, 250], "star": 157, "c1": "#b07a1c", "c2": "#27428c"},
	{"legs": [383, 382], "star": 257, "c1": "#9a2f2f", "c2": "#1a4f9a"},
	{"legs": [483, 484], "star": 448, "c1": "#3b2f9a", "c2": "#9a2f78"},
	{"legs": [643, 644], "star": 571, "c1": "#2b2f3b", "c2": "#5f6fa0"},
	{"legs": [716, 717], "star": 658, "c1": "#2f62a8", "c2": "#a8304f"},
	{"legs": [791, 792], "star": 778, "c1": "#c76a2a", "c2": "#2a8f93"},
	{"legs": [888, 889], "star": 815, "c1": "#8f2f8f", "c2": "#2f6fcf"},
	{"legs": [1007, 1005], "star": 908, "c1": "#c0581a", "c2": "#5a2fa0"},
]
const RARITY_COL := ["#c8d6ee", "#5fe08a", "#5fa8ff", "#c47bff", "#ffd33d"]
const RARITY_BALL := ["ball", "ball2", "ball3", "ball4", "ballLux"]


func _region_counts(region: int) -> Vector2i:
	var pool: Array = SV.region_pool(region)
	var n := 0
	for p in pool:
		if SV.owns(int(p["dex"])):
			n += 1
	return Vector2i(n, pool.size())


func _refresh_gacha() -> void:
	_clear(gacha_box)
	var first: Button = null
	# --- pestanas de region
	var tabs := HFlowContainer.new()
	tabs.add_theme_constant_override("h_separation", 8)
	tabs.add_theme_constant_override("v_separation", 8)
	gacha_box.add_child(tabs)
	tab_row = tabs
	for i in range(1, 10):
		var r: int = i
		var tb := _btn(L.t(SV.REGIONS[r - 1]) + "\n" + L.t("Gen %d") % r, func(): gacha_region = r; _refresh_gacha(); _gf(tab_sel), Vector2(112, 62))
		tb.add_theme_font_size_override("font_size", 20)
		if r == gacha_region:
			tb.add_theme_stylebox_override("normal", _sb(Color("#2a4aa8"), C_GOLD, 3, 12))
			tb.add_theme_color_override("font_color", C_GOLD)
			first = tb
			tab_sel = tb
		tabs.add_child(tb)
	# --- escenario + probabilidades
	var main := HBoxContainer.new()
	main.add_theme_constant_override("separation", 16)
	gacha_box.add_child(main)
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 12)
	main.add_child(left)
	var bd: Dictionary = BANNERS[gacha_region - 1]
	var banner := Banner.new()
	banner.c1 = Color.html(String(bd["c1"]))
	banner.c2 = Color.html(String(bd["c2"]))
	banner.custom_minimum_size = Vector2(0, 360)
	banner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_child(banner)
	var cnt: Vector2i = _region_counts(gacha_region)
	var tx := VBoxContainer.new()
	tx.set_anchors_preset(Control.PRESET_TOP_WIDE)
	tx.offset_left = 22
	tx.offset_top = 16
	tx.offset_right = -22
	tx.add_theme_constant_override("separation", 6)
	banner.add_child(tx)
	var ttl := _label(L.t("Misterio de %s") % L.t(SV.REGIONS[gacha_region - 1]), 44, C_GOLD)
	ttl.autowrap_mode = TextServer.AUTOWRAP_OFF
	tx.add_child(ttl)
	tx.add_child(_label(L.t("Los %d Pokémon de la generación %d. ¡Los legendarios te esperan!") % [cnt.y, gacha_region], 22))
	tx.add_child(_label(L.t("Tienes %d de %d") % [cnt.x, cnt.y], 20, Color("#cfd9f5")))
	banner.add_mon(int(bd["legs"][0]), 3.2, 0.0, 0.36)
	banner.add_mon(int(bd["star"]), 3.2, 0.34, 0.66)
	banner.add_mon(int(bd["legs"][1]), 3.2, 0.64, 1.0)
	# --- botones de tirada
	var brow := HBoxContainer.new()
	brow.add_theme_constant_override("separation", 12)
	left.add_child(brow)
	var b1 := _cost_btn(L.t("Tirada ×1"), "1", "", "ticket", func(): _do_pull(1, "t1"), Vector2(0, 64), SV.can_pull(1, "t1"), false, true)
	var b10 := _cost_btn(L.t("Tirada ×10"), "10", "", "ticket", func(): _do_pull(10, "t1"), Vector2(0, 64), SV.can_pull(10, "t1"), false, true)
	var bt := _cost_btn(L.t("Tirada ×10"), "1", "", "ticket10", func(): _do_pull(10, "t10"), Vector2(0, 64), SV.can_pull(10, "t10"), false, true)
	for b in [b1, b10, bt]:
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		brow.add_child(b)
	var have := HBoxContainer.new()
	have.add_theme_constant_override("separation", 8)
	_nw(have, _label(L.t("Tienes"), 20, Color("#c8d6ee")))
	have.add_child(IC.rect("ticket", 24))
	_nw(have, _label(str(int(SV.d["tickets"])), 22, Color("#ffd23f")))
	_nw(have, _label(L.t("tickets y"), 20, Color("#c8d6ee")))
	have.add_child(IC.rect("ticket10", 24))
	_nw(have, _label(str(int(SV.d.get("tickets10", 0))), 22, Color("#c47bff")))
	_nw(have, _label(L.t("tickets ×10"), 20, Color("#c8d6ee")))
	left.add_child(have)
	var pity: int = int(SV.d["pity"].get(str(gacha_region), 0))
	left.add_child(_label(L.t("Tiradas sin legendario en %s: %d / %d") % [L.t(SV.REGIONS[gacha_region - 1]), pity, SV.PITY_5], 18, Color("#c8d6ee")))
	if first == null:
		first = b1
	# --- panel de probabilidades
	var pool: Array = SV.region_pool(gacha_region)
	var counts: Array = [0, 0, 0, 0, 0]
	for p in pool:
		counts[clampi(int(p["rarity"]) - 1, 0, 4)] += 1
	var op := PanelContainer.new()
	op.custom_minimum_size = Vector2(330, 0)
	op.add_theme_stylebox_override("panel", _card_sb())
	main.add_child(op)
	var ov := VBoxContainer.new()
	ov.add_theme_constant_override("separation", 5)
	op.add_child(ov)
	ov.add_child(_label("Probabilidades", 26))
	for j in range(4, -1, -1):
		var rr := HBoxContainer.new()
		rr.add_theme_constant_override("separation", 8)
		rr.add_child(IC.rect(String(RARITY_BALL[j]), 24))
		var rn := _label(SV.RARITY_NAME[j], 20, Color.html(String(RARITY_COL[j])))
		rn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rn.autowrap_mode = TextServer.AUTOWRAP_OFF
		rr.add_child(rn)
		var pc := _label("%s%% · %d" % [str(SV.PULL_RATES[j]), int(counts[j])], 20, Color("#dfe8ff"))
		pc.autowrap_mode = TextServer.AUTOWRAP_OFF
		rr.add_child(pc)
		ov.add_child(rr)
	var sr := HBoxContainer.new()
	sr.add_theme_constant_override("separation", 8)
	sr.add_child(IC.rect("shiny", 24))
	var sn := _label("Shiny", 20)
	sn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sr.add_child(sn)
	var s32 := _label("1%", 20, Color("#dfe8ff"))
	s32.autowrap_mode = TextServer.AUTOWRAP_OFF
	sr.add_child(s32)
	ov.add_child(sr)
	# Cristales Z: probabilidad y cuales ya tienes (los desbloqueados brillan, el resto se ve apagado)
	var zr := HBoxContainer.new()
	zr.add_theme_constant_override("separation", 8)
	zr.add_child(IC.rect("zc:" + String(ZM.ORDER[0]), 24))
	var zn := _label("Cristal Z", 20, Color("#7fe0ff"))
	zn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	zn.autowrap_mode = TextServer.AUTOWRAP_OFF
	zr.add_child(zn)
	var zp := _label("%d%% · ×10" % roundi(SV.Z_CRYSTAL_P * 100.0), 20, Color("#dfe8ff"))
	zp.autowrap_mode = TextServer.AUTOWRAP_OFF
	zr.add_child(zp)
	ov.add_child(zr)
	var zg := GridContainer.new()
	zg.columns = 9
	zg.add_theme_constant_override("h_separation", 2)
	zg.add_theme_constant_override("v_separation", 2)
	for zt in ZM.ORDER:
		var zi = IC.rect("zc:" + String(zt), 32)
		if not ZM.unlocked(String(zt), SV.d["stats"]):
			zi.modulate = Color(0.35, 0.35, 0.4, 0.45)
		zg.add_child(zi)
	ov.add_child(zg)
	ov.add_child(_label(L.t("· La tirada ×10 garantiza al menos un Pokémon muy raro."), 16, Color("#c8d6ee")))
	ov.add_child(_label(L.t("· A las %d tiradas sin legendario en un banner, la siguiente lo es.") % SV.PITY_5, 16, Color("#c8d6ee")))
	ov.add_child(_label(L.t("· Los repetidos dan Pokémonedas. Los shiny no se repiten."), 16, Color("#c8d6ee")))
	ov.add_child(_label(L.t("· Los tickets se consiguen jugando: algunos Pokémon los sueltan al caer, y los jefes y los cofres a veces dan tickets ×10."), 16, Color("#c8d6ee")))
	focus_first = first


func _nw(parent: Node, l: Label) -> void:
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	parent.add_child(l)


func _do_pull(n: int, use: String) -> void:
	if not SV.can_pull(n, use):
		toast(L.t("No tienes tickets suficientes: consíguelos jugando"))
		return
	var results: Array = SV.pull(gacha_region, n, use)
	SV.save()
	_update_top()
	_play_slots(results)


# Tragaperras animada (como el original); al terminar muestra la lista de premios.
func _play_slots(results: Array) -> void:
	if slots_ui == null or not is_instance_valid(slots_ui):
		slots_ui = SLOTS.new()
		slots_ui.z_index = 31
		slots_ui.visible = false
		add_child(slots_ui)
	slots_busy = true
	slots_ui.play(results)
	await slots_ui.finished
	slots_busy = false
	slots_ui.visible = false
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
		var nm := _label(L.t(String(r["name"])) + (" ✨" if bool(r["shiny"]) else ""), 18)
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
	if SV.last_crystal != "":
		var zc: String = SV.last_crystal
		var zrow := _icon_label("zc:" + zc, L.t("¡Cristal Z encontrado! Desbloqueas: %s") % L.t(String(ZM.DEF[zc]["name"])), 20, Color("#ffd23f"), 40.0)
		zrow.alignment = BoxContainer.ALIGNMENT_CENTER
		v.add_child(zrow)
		Aud.sfx("legend")
	var ok := _btn("Aceptar", func(): gacha_result.visible = false; _refresh_gacha(), Vector2(0, 54))
	v.add_child(ok)
	gacha_result.visible = true
	_gf(ok)


# ---------------------------------------------------------------
# Misiones, logros y titulos (progress.gd)
# ---------------------------------------------------------------
var ach_cat := "coleccion"
var goals_btn: Button
var goals_tabs: HBoxContainer


func _build_goals() -> void:
	var s: Control = _screen("goals")
	var pc := PanelContainer.new()
	s.add_child(pc)
	var v := VBoxContainer.new()
	pc.add_child(v)
	goals_tabs = HBoxContainer.new()
	v.add_child(goals_tabs)
	for t in [["m", "Misiones"], ["a", "Logros"], ["z", "Cristales Z"], ["p", "Perfil"], ["r", "Récords"]]:
		var k: String = String(t[0])
		var tb := _btn(String(t[1]), func(): goals_tab = k; _refresh_goals(); _gf(tab_sel), Vector2(200, 46))
		if k == "a":
			tb.icon = IC.btn_tex("medal1", 28)
			tb.expand_icon = false
		elif k == "z":
			tb.icon = IC.btn_tex("zc:ice", 28)
			tb.expand_icon = false
		goals_tabs.add_child(tb)
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(sc)
	goals_box = VBoxContainer.new()
	goals_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	goals_box.add_theme_constant_override("separation", 8)
	sc.add_child(goals_box)


# ---------------------------------------------------------------
# Lexico: objetos, movimientos y estados alterados
# ---------------------------------------------------------------
var lex_tab := "i"
var lex_tabs: HBoxContainer
var lex_box: VBoxContainer
const LEX_STATUS := [
	["freeze", "Congelado", "El enemigo no se mueve ni ataca y recibe un 25% más de daño. Los jefes lo resisten."],
	["para", "Paralizado", "El enemigo va mucho más lento y recibe más daño eléctrico. Los jefes lo resisten."],
	["sleep", "Dormido", "El enemigo no actúa, recibe un 30% más de daño y se despierta con el primer golpe. Darkrai es inmune."],
	["conf", "Confundido", "El enemigo se mueve sin rumbo y ataca a otros enemigos. Los jefes lo resisten."],
	["burn", "Quemado", "Daño continuo y el enemigo hace menos daño."],
	["poison", "Envenenado", "Daño continuo según su vida máxima (menos contra jefes)."],
	["slow", "Ralentizado", "El enemigo se mueve más despacio durante un rato."],
]


func _build_lexicon() -> void:
	var s: Control = _screen("lexicon")
	var pc := PanelContainer.new()
	s.add_child(pc)
	var v := VBoxContainer.new()
	pc.add_child(v)
	lex_tabs = HBoxContainer.new()
	v.add_child(lex_tabs)
	for t in [["i", "Objetos"], ["m", "Movimientos"], ["s", "Estados"], ["a", "Habilidades"], ["z", "Z y Dynamax"]]:
		var k: String = String(t[0])
		var tb := _btn(String(t[1]), func(): lex_tab = k; _refresh_lexicon(); _gf(tab_sel), Vector2(200, 46))
		lex_tabs.add_child(tb)
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(sc)
	lex_box = VBoxContainer.new()
	lex_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lex_box.add_theme_constant_override("separation", 8)
	sc.add_child(lex_box)


func _lex_card(icon: Control, title: String, sub: String, sub_col: Color, desc: String, dim: bool = false) -> PanelContainer:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _card_sb())
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	card.add_child(h)
	if icon != null:
		icon.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		h.add_child(icon)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 2)
	h.add_child(col)
	var tl := _label(title, 22, Color.WHITE if not dim else Color("#8fa3c4"))
	tl.autowrap_mode = TextServer.AUTOWRAP_OFF
	col.add_child(tl)
	if sub != "":
		var sl := _label(sub, 15, sub_col)
		sl.autowrap_mode = TextServer.AUTOWRAP_OFF
		col.add_child(sl)
	var dl := _label(desc, 16, Color("#c8d6ee"))
	dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(dl)
	return card


func _lex_grid(cols: int) -> GridContainer:
	var g := GridContainer.new()
	g.columns = cols
	g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	g.add_theme_constant_override("h_separation", 10)
	g.add_theme_constant_override("v_separation", 10)
	lex_box.add_child(g)
	return g


func _refresh_lexicon() -> void:
	_clear(lex_box)
	var tbs: Array = lex_tabs.get_children()
	for i in range(tbs.size()):
		var key: String = ["i", "m", "s", "a", "z"][i]
		_gold_btn(tbs[i], key == lex_tab)
		if key == lex_tab:
			tab_sel = tbs[i]
	tab_row = lex_tabs
	var cols: int = 2 if get_viewport_rect().size.x >= 900.0 else 1
	if lex_tab == "i":
		var found: Dictionary = SV.d.get("itemsFound", {})
		lex_box.add_child(_label(L.t("Objetos: %d / %d encontrados") % [found.size(), TD.ITEMS.size()], 24, C_GOLD))
		var g := _lex_grid(cols)
		for it in TD.ITEMS:
			var id: String = String(it["id"])
			var ok: bool = found.has(id)
			g.add_child(_lex_card(IC.rect(id, 40), L.t(String(it["name"])), L.t("✔ Encontrado") if ok else L.t("Aún sin encontrar"), Color("#8fe3b0") if ok else Color("#8fa3c4"), L.t(String(it["desc"])), not ok))
	elif lex_tab == "m":
		var moves: Dictionary = MD.MOVES
		lex_box.add_child(_label(L.t("Movimientos: %d") % moves.size(), 24, C_GOLD))
		for ty in TYPE_IDS:
			var ids: Array = []
			for mid in MD.ORDER:
				if moves.has(mid) and String(moves[mid]["type"]) == ty:
					ids.append(mid)
			if ids.is_empty():
				continue
			var tcol: Color = Color.html(String(MD.TYPE_COLOR.get(ty, "#ffffff")))
			lex_box.add_child(_label(L.t(String(MD.TYPE_NAME[ty])), 22, tcol))
			var g2 := _lex_grid(cols)
			for mid in ids:
				var m: Dictionary = moves[mid]
				var desc: String = L.t(String(m["desc"]))
				if MD.EVO.has(mid):
					desc += "\n" + L.t("Evoluciona en: %s") % L.t(String(MD.EVO[mid][0]))
				if MD.EVO_ALT.has(mid):
					desc += "\n" + L.t("Evoluciona en: %s") % L.t(String(MD.EVO_ALT[mid][0]))
				g2.add_child(_lex_card(IC.rect("move:" + String(mid), 36), L.t(String(m["name"])), L.t(String(MD.TYPE_NAME[ty])), tcol, desc))
	elif lex_tab == "z":
		lex_box.add_child(_label(L.t("Movimientos Z: %d") % ZM.ORDER.size(), 24, C_GOLD))
		lex_box.add_child(_label(L.t("Se recargan cada 4 minutos, desde el nivel %d. Se desbloquean derrotando %d Pokémon de ese tipo.") % [ZM.MIN_LEVEL, ZM.NEED], 16, Color("#c8d6ee")))
		var dn: int = int(SV.d["stats"].get("dens", 0))
		var dok: bool = dn >= 1
		var gd := _lex_grid(cols)
		gd.add_child(_lex_card(null, "Dynamax", L.t("Desbloqueado") if dok else L.t("Vence una guarida Dynamax: %d/1") % dn, Color("#ff7a9a"),
			L.t("Cada 4 minutos (desde el nivel %d): tu Pokémon se vuelve gigante %d s con +30% a todos sus atributos y lanza ondas Max de su tipo. Cada guarida Dynamax vencida lo recarga al instante.") % [DYN.MIN_LEVEL, int(DYN.DUR)], not dok))
		var gz := _lex_grid(cols)
		for zt in ZM.ORDER:
			var zd: Dictionary = ZM.DEF[zt]
			var zn: int = int(SV.d["stats"].get("tk_" + zt, 0))
			var zok: bool = ZM.unlocked(zt, SV.d["stats"])
			var zcol: Color = Color.html(String(MD.TYPE_COLOR.get(zt, "#ffffff")))
			var zsub: String = L.t(String(MD.TYPE_NAME[zt])) + " · " + (L.t("Desbloqueado") if zok else L.t("Derrota %d Pokémon de tipo %s: %d/%d") % [ZM.NEED, L.t(String(MD.TYPE_NAME[zt])), zn, ZM.NEED])
			gz.add_child(_lex_card(IC.rect("zc:" + zt, 48), L.t(String(zd["name"])), zsub, zcol, L.t(String(zd["desc"])), not zok))
	elif lex_tab == "a":
		lex_box.add_child(_label(L.t("Habilidades: %d") % AB.FX.size(), 24, C_GOLD))
		var g4 := _lex_grid(cols)
		for aid in AB.FX:
			var ad: Dictionary = AB.FX[aid]
			g4.add_child(_lex_card(null, L.t(String(ad["name"])), "", Color.WHITE, L.t(String(ad["desc"]))))
	else:
		lex_box.add_child(_label(L.t("Estados alterados"), 24, C_GOLD))
		var g3 := _lex_grid(cols)
		for st in LEX_STATUS:
			g3.add_child(_lex_card(null, L.t(String(st[1])), "", Color.WHITE, L.t(String(st[2]))))
	focus_first = tbs[0]
	if tab_sel != null:
		focus_first = tab_sel
	_update_top()


func _reward_box(r: Dictionary, w: float = 170.0) -> HBoxContainer:
	var rw := HBoxContainer.new()
	rw.custom_minimum_size = Vector2(w, 0)
	rw.add_theme_constant_override("separation", 6)
	if int(r.get("coins", 0)) > 0:
		rw.add_child(IC.rect("coin", 24))
		var l1 := _label("%d" % int(r["coins"]), 20, C_GOLD)
		l1.autowrap_mode = TextServer.AUTOWRAP_OFF
		rw.add_child(l1)
	if int(r.get("t1", 0)) > 0:
		rw.add_child(IC.rect("ticket", 24))
		var l2 := _label("%d" % int(r["t1"]), 20, Color("#ffd23f"))
		l2.autowrap_mode = TextServer.AUTOWRAP_OFF
		rw.add_child(l2)
	if int(r.get("t10", 0)) > 0:
		rw.add_child(IC.rect("ticket10", 24))
		var l3 := _label("%d ×10" % int(r["t10"]), 20, Color("#c47bff"))
		l3.autowrap_mode = TextServer.AUTOWRAP_OFF
		rw.add_child(l3)
	return rw


func _refresh_goals() -> void:
	PG.ensure()
	PG.check()
	_clear(goals_box)
	var first: Button = null
	var tbs: Array = goals_tabs.get_children()
	for i in range(tbs.size()):
		var key: String = ["m", "a", "z", "p", "r"][i]
		_gold_btn(tbs[i], key == goals_tab)
		if key == goals_tab:
			tab_sel = tbs[i]
	tab_row = goals_tabs
	if goals_tab == "m":
		first = _goals_missions()
	elif goals_tab == "a":
		first = _goals_ach()
	elif goals_tab == "z":
		first = _goals_zcrystals()
	elif goals_tab == "r":
		first = _goals_records()
	else:
		first = _goals_profile()
	focus_first = first if first != null else tbs[0]
	_update_top()


func _mission_row(m: Dictionary, weekly: bool, idx: int) -> Button:
	var def: Dictionary = PG.def_of(String(m["id"]))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	goals_box.add_child(row)
	var gic := IC.rect("flag", 36)
	gic.custom_minimum_size.x = 48
	row.add_child(gic)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(col)
	col.add_child(_label(PG.mission_text(m), 22))
	var pb := ProgressBar.new()
	pb.max_value = float(m["goal"])
	pb.value = minf(float(m["prog"]), float(m["goal"]))
	pb.custom_minimum_size = Vector2(0, 16)
	pb.show_percentage = false
	col.add_child(pb)
	row.add_child(_reward_box(def["reward"]))
	var out: Button = null
	var mm: Dictionary = m
	if not weekly and not PG.m_done(m) and not bool(SV.d["missions"].get("rerolled", false)):
		var rb := _btn("Cambiar", func(): _reroll(idx), Vector2(120, 46))
		row.add_child(rb)
		out = rb
	var b: Button
	if bool(m["claimed"]):
		b = _btn("Reclamado", func(): pass, Vector2(160, 46))
		b.disabled = true
	elif PG.m_done(m):
		b = _btn("¡Reclamar!", func(): _claim_mission(mm, weekly), Vector2(160, 46))
		out = b
	else:
		b = _btn("%d / %d" % [mini(int(m["prog"]), int(m["goal"])), int(m["goal"])], func(): pass, Vector2(160, 46))
		b.disabled = true
	row.add_child(b)
	return out


func _goals_missions() -> Button:
	var first: Button = null
	var M: Dictionary = SV.d["missions"]
	goals_box.add_child(_label("Misiones diarias", 28, C_GOLD))
	var i := 0
	for m in M["daily"]:
		var b: Button = _mission_row(m, false, i)
		if first == null and b != null:
			first = b
		i += 1
	goals_box.add_child(_label("Misiones semanales", 28, C_GOLD))
	for m in M["weekly"]:
		var b2: Button = _mission_row(m, true, 0)
		if first == null and b2 != null:
			first = b2
	goals_box.add_child(_label("Cambian a las 00:00 (hora de Puerto Rico). Puedes cambiar una diaria al día.", 16, Color("#c8d6ee")))
	return first


func _reroll(i: int) -> void:
	if PG.reroll(i):
		Aud.sfx("confirm")
	_refresh_goals()


func _claim_mission(m: Dictionary, weekly: bool) -> void:
	if PG.claim(m, weekly):
		Aud.sfx("buy")
		toast(L.t("¡Recompensa reclamada!"))
	_refresh_goals()


func _goals_ach() -> Button:
	var all: Array = PG.list()
	var ach: Dictionary = SV.d.get("ach", {})
	var total := 0
	for a in all:
		if ach.has(String(a["id"])):
			total += 1
	goals_box.add_child(_label(L.t("Logros: %d / %d") % [total, all.size()], 28, C_GOLD))
	var chips := HFlowContainer.new()
	chips.add_theme_constant_override("h_separation", 8)
	chips.add_theme_constant_override("v_separation", 8)
	goals_box.add_child(chips)
	var first: Button = null
	for c in PG.CATS:
		var ck: String = String(c[0])
		var n := 0
		var d := 0
		for a in all:
			if String(a["cat"]) == ck:
				n += 1
				if ach.has(String(a["id"])):
					d += 1
		var cb := _btn("%s  %d/%d" % [L.t(String(c[1])), d, n], func(): ach_cat = ck; _refresh_goals(), Vector2(0, 44))
		_gold_btn(cb, ck == ach_cat)
		chips.add_child(cb)
		if first == null:
			first = cb
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	goals_box.add_child(grid)
	for a in all:
		if String(a["cat"]) != ach_cat or int(a["dex"]) > 0:
			continue
		grid.add_child(_ach_card(a, ach.has(String(a["id"]))))
	if ach_cat == "legendarios":
		var legs: Array = []
		var beaten := 0
		for a in all:
			if int(a["dex"]) > 0:
				legs.append(a)
				if ach.has(String(a["id"])):
					beaten += 1
		goals_box.add_child(_label(L.t("Legendarios vencidos %d / %d") % [beaten, legs.size()], 24, Color.WHITE))
		var lg := GridContainer.new()
		lg.columns = 10
		lg.add_theme_constant_override("h_separation", 6)
		lg.add_theme_constant_override("v_separation", 6)
		lg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		goals_box.add_child(lg)
		for a in legs:
			var ok: bool = ach.has(String(a["id"]))
			var cell := PanelContainer.new()
			cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			cell.add_theme_stylebox_override("panel", _sb(Color(0, 0, 0, 0.25), Color(1.0, 0.82, 0.25, 0.5) if ok else Color.TRANSPARENT, 2, 8))
			var cv := VBoxContainer.new()
			cv.alignment = BoxContainer.ALIGNMENT_CENTER
			cell.add_child(cv)
			var tr := TextureRect.new()
			tr.texture = _icon_tex(int(a["dex"]), false)
			tr.custom_minimum_size = Vector2(0, 56)
			tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			if not ok:
				tr.modulate = Color(0.0, 0.0, 0.0, 0.55)
			cv.add_child(tr)
			var nl := _label(String(a["arg"]) if ok else "???", 12, Color("#b9cbf0"))
			nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			cv.add_child(nl)
			lg.add_child(cell)
	return first


func _goals_zcrystals() -> Button:
	var zl: Array = PG.zlist()
	var nd := 0
	for zm in zl:
		if PG.zdone(zm):
			nd += 1
	goals_box.add_child(_label(L.t("Cristales Z: %d / %d") % [nd, zl.size()], 28, C_GOLD))
	var hint := _label(L.t("Cumple la misión de un tipo para desbloquear su movimiento Z. También se desbloquea derrotando a 250 Pokémon de ese tipo o con un cristal del gacha."), 16, Color("#b9cbf0"))
	goals_box.add_child(hint)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	goals_box.add_child(grid)
	for zm in zl:
		grid.add_child(_zmis_card(zm, PG.zdone(zm)))
	return null


func _zmis_card(zm: Dictionary, done: bool) -> PanelContainer:
	var t: String = String(zm["type"])
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_FILL
	card.add_theme_stylebox_override("panel", _sb(Color(0, 0, 0, 0.2), Color(1.0, 0.82, 0.25, 0.6) if done else Color(0.96, 0.97, 1.0, 0.1), 2, 8))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	card.add_child(row)
	var mi := IC.rect("zc:" + t, 48)
	mi.custom_minimum_size.x = 52
	if not done:
		mi.modulate = Color(0.35, 0.35, 0.4, 0.55)
	row.add_child(mi)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 2)
	row.add_child(col)
	col.add_child(_label(L.t(String(ZM.DEF[t]["name"])), 22, Color.WHITE))
	col.add_child(_label(L.t(String(zm["desc"])), 16, Color("#b9cbf0")))
	var v: int = mini(PG.stat(String(zm["stat"])), int(zm["goal"]))
	if not done:
		var pb := ProgressBar.new()
		pb.max_value = float(zm["goal"])
		pb.value = float(v)
		pb.custom_minimum_size = Vector2(0, 12)
		pb.show_percentage = false
		col.add_child(pb)
	var fl := HFlowContainer.new()
	fl.add_theme_constant_override("h_separation", 6)
	fl.add_theme_constant_override("v_separation", 0)
	col.add_child(fl)
	var st: String = L.t("¡Conseguido!") if done else "%s / %s" % [PG._thousands(v), PG._thousands(int(zm["goal"]))]
	var l0 := _label(st, 18, Color.WHITE)
	l0.autowrap_mode = TextServer.AUTOWRAP_OFF
	fl.add_child(l0)
	fl.add_child(_label("·", 18, Color.WHITE))
	fl.add_child(_reward_box({"coins": PG.ZMIS_COINS}, 0.0))
	return card


func _ach_card(a: Dictionary, done: bool) -> PanelContainer:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_FILL
	card.add_theme_stylebox_override("panel", _sb(Color(0, 0, 0, 0.2), Color(1.0, 0.82, 0.25, 0.6) if done else Color(0.96, 0.97, 1.0, 0.1), 2, 8))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	card.add_child(row)
	var mi := IC.rect(("medal%d" % int(a["tier"])) if done else "medalOff", 36)
	mi.custom_minimum_size.x = 48
	row.add_child(mi)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 2)
	row.add_child(col)
	col.add_child(_label(PG.name_of(a), 24, Color.WHITE))
	var ds: String = PG.desc_of(a)
	if PG.is_multi(a):
		ds += " " + L.t("(Requiere multijugador: no disponible en esta versión)")
	col.add_child(_label(ds, 16, Color("#b9cbf0")))
	var v: int = mini(PG.value(a), int(a["goal"]))
	if not done:
		var pb := ProgressBar.new()
		pb.max_value = float(a["goal"])
		pb.value = float(v)
		pb.custom_minimum_size = Vector2(0, 12)
		pb.show_percentage = false
		col.add_child(pb)
	var fl := HFlowContainer.new()
	fl.add_theme_constant_override("h_separation", 6)
	fl.add_theme_constant_override("v_separation", 0)
	col.add_child(fl)
	var st: String = L.t("¡Conseguido!") if done else "%s / %s" % [PG._thousands(v), PG._thousands(int(a["goal"]))]
	var l0 := _label(st, 18, Color.WHITE)
	l0.autowrap_mode = TextServer.AUTOWRAP_OFF
	fl.add_child(l0)
	fl.add_child(_label("·", 18, Color.WHITE))
	var rb := _reward_box(a["reward"], 0.0)
	fl.add_child(rb)
	if String(a["title"]) != "":
		fl.add_child(_label("·", 18, Color.WHITE))
		var tl := _label(L.t("Título: %s") % L.t(String(a["title"])), 18, C_GOLD)
		tl.autowrap_mode = TextServer.AUTOWRAP_OFF
		fl.add_child(tl)
	return card


# ---------------------------------------------------------------
# Perfil del jugador (sin online): nombre, Pokemon actual, 3 favoritos, titulo y tarjeta
# ---------------------------------------------------------------
func _nick() -> String:
	var n: String = String(SV.d.get("nick", "")).strip_edges()
	return n if n != "" else L.t("Entrenador")


func _goals_profile() -> Button:
	goals_box.add_child(_label("Así te ve el juego: tu tarjeta de entrenador.", 20, Color("#c8d6ee")))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	goals_box.add_child(row)
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 8)
	row.add_child(left)
	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(300, 0)
	right.add_theme_constant_override("separation", 6)
	row.add_child(right)
	# nombre
	left.add_child(_label("Nombre de entrenador", 24, C_GOLD))
	var le := LineEdit.new()
	le.text = String(SV.d.get("nick", ""))
	le.placeholder_text = L.t("Entrenador")
	le.max_length = 16
	le.custom_minimum_size = Vector2(0, 52)
	le.add_theme_font_size_override("font_size", 26)
	var save_nick := func(_t = ""):
		SV.d["nick"] = le.text.strip_edges()
		SV.save()
		_update_top()
	le.text_submitted.connect(save_nick)
	le.focus_exited.connect(save_nick)
	left.add_child(le)
	# favoritos
	left.add_child(_label("Tus 3 Pokémon favoritos", 24, C_GOLD))
	var favs: Array = SV.d.get("favs", [0, 0, 0])
	var fr := HBoxContainer.new()
	fr.add_theme_constant_override("separation", 12)
	left.add_child(fr)
	var first: Button = null
	for i in range(3):
		var slot: int = i
		var dex: int = int(favs[i]) if i < favs.size() else 0
		var b := _btn("", func(): _fav_picker(slot), Vector2(150, 150))
		if dex > 0 and SV.dex_by.has(dex):
			b.text = ""
			var pv := Preview.new()
			pv.mouse_filter = Control.MOUSE_FILTER_IGNORE
			pv.set_anchors_preset(Control.PRESET_FULL_RECT)
			b.add_child(pv)
			pv.setup(dex, false, 3.0)
			var nl := _label(_name_of(dex), 16)
			nl.autowrap_mode = TextServer.AUTOWRAP_OFF
			nl.set_anchors_preset(Control.PRESET_FULL_RECT)
			nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			nl.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
			nl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			b.add_child(nl)
		else:
			b.text = L.t("Elegir")
		fr.add_child(b)
		if first == null:
			first = b
	# titulo
	left.add_child(_label("Título", 24, C_GOLD))
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 12)
	left.add_child(hb)
	var ob := OptionButton.new()
	ob.custom_minimum_size = Vector2(300, 52)
	ob.add_theme_font_size_override("font_size", 22)
	ob.focus_mode = Control.FOCUS_ALL
	ob.add_item(L.t("(sin título)"))
	ob.set_item_metadata(0, "")
	var cur_t: String = String(SV.d.get("title", ""))
	var sel := 0
	for t in PG.titles():
		ob.add_item(L.t(String(t)))
		ob.set_item_metadata(ob.item_count - 1, String(t))
		if String(t) == cur_t:
			sel = ob.item_count - 1
	ob.select(sel)
	ob.item_selected.connect(func(idx: int):
		SV.d["title"] = String(ob.get_item_metadata(idx))
		SV.save()
		Aud.sfx("confirm")
		_update_top())
	hb.add_child(ob)
	hb.add_child(_btn("Ver mi tarjeta de entrenador", _show_card, Vector2(0, 52)))
	# Pokemon actual (derecha)
	right.add_child(_label("Tu Pokémon", 24, C_GOLD))
	var sd: int = int(SV.d.get("selected", 25))
	var pb := PanelContainer.new()
	pb.add_theme_stylebox_override("panel", _sb(Color(0.05, 0.1, 0.26, 0.55), Color(0.5, 0.62, 0.9, 0.5), 2, 12))
	right.add_child(pb)
	var pv2 := Preview.new()
	pv2.custom_minimum_size = Vector2(280, 260)
	pb.add_child(pv2)
	pv2.setup(sd, bool(SV.d.get("shiny_on", false)), 5.0)
	var nm := _label(_name_of(sd) if SV.dex_by.has(sd) else "?", 28)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	right.add_child(nm)
	if SV.dex_by.has(sd):
		var tl := _label(_type_text(sd), 18, Color("#c8d6ee"))
		tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		right.add_child(tl)
	return first


# Elegir uno de tus Pokemon para un hueco de favoritos.
func _fav_picker(slot: int) -> void:
	_clear(gacha_result)
	var c := CenterContainer.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	gacha_result.add_child(c)
	var pc := PanelContainer.new()
	c.add_child(pc)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	pc.add_child(v)
	v.add_child(_label("Elige un favorito", 30, C_GOLD))
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(760, 360)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(sc)
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	sc.add_child(grid)
	var keys: Array = []
	for k in SV.d["owned"].keys():
		keys.append(int(k))
	keys.sort()
	var firstb: Button = null
	for dex in keys:
		var d2: int = int(dex)
		if not SV.dex_by.has(d2):
			continue
		var b := _btn("", func(): _set_fav(slot, d2), Vector2(140, 120))
		var pv := Preview.new()
		pv.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pv.set_anchors_preset(Control.PRESET_FULL_RECT)
		b.add_child(pv)
		pv.setup(d2, false, 2.0)
		var nl := _label(_name_of(d2), 14)
		nl.autowrap_mode = TextServer.AUTOWRAP_OFF
		nl.set_anchors_preset(Control.PRESET_FULL_RECT)
		nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nl.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		nl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(nl)
		grid.add_child(b)
		if firstb == null:
			firstb = b
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 12)
	v.add_child(hb)
	hb.add_child(_btn("Quitar", func(): _set_fav(slot, 0), Vector2(180, 52)))
	var cancel := _btn("Cancelar", func(): gacha_result.visible = false; _refresh_goals(), Vector2(180, 52))
	hb.add_child(cancel)
	gacha_result.visible = true
	_gf(firstb if firstb != null else cancel)


func _set_fav(slot: int, dex: int) -> void:
	var favs: Array = SV.d.get("favs", [0, 0, 0])
	while favs.size() < 3:
		favs.append(0)
	favs[slot] = dex
	SV.d["favs"] = favs
	SV.save()
	Aud.sfx("confirm")
	gacha_result.visible = false
	_refresh_goals()


# Tarjeta de entrenador: lo que antes era "ver mi perfil publico", pero sin conexion.
func _show_card() -> void:
	_clear(gacha_result)
	var c := CenterContainer.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	gacha_result.add_child(c)
	var pc := PanelContainer.new()
	c.add_child(pc)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	v.custom_minimum_size = Vector2(620, 0)
	pc.add_child(v)
	var nm := _label(_nick(), 40, C_GOLD)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(nm)
	var tt: String = String(SV.d.get("title", ""))
	var tl := _label(L.t(tt) if tt != "" else L.t("(sin título)"), 24, Color("#c8d6ee"))
	tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(tl)
	var pr := HBoxContainer.new()
	pr.alignment = BoxContainer.ALIGNMENT_CENTER
	pr.add_theme_constant_override("separation", 14)
	v.add_child(pr)
	var sd: int = int(SV.d.get("selected", 25))
	var main_pv := Preview.new()
	main_pv.custom_minimum_size = Vector2(180, 150)
	pr.add_child(main_pv)
	main_pv.setup(sd, bool(SV.d.get("shiny_on", false)), 4.0)
	var favs: Array = SV.d.get("favs", [0, 0, 0])
	for i in range(3):
		var dex: int = int(favs[i]) if i < favs.size() else 0
		if dex > 0 and SV.dex_by.has(dex):
			var fp := Preview.new()
			fp.custom_minimum_size = Vector2(100, 90)
			pr.add_child(fp)
			fp.setup(dex, false, 2.0)
	var st: Dictionary = SV.d["stats"]
	var g := GridContainer.new()
	g.columns = 3
	g.add_theme_constant_override("h_separation", 8)
	g.add_theme_constant_override("v_separation", 8)
	v.add_child(g)
	var bt: int = int(st.get("best_time", 0))
	g.add_child(_stat_cell(L.t("Partidas"), str(int(st.get("runs", 0)))))
	g.add_child(_stat_cell(L.t("Mejor tiempo"), "%02d:%02d" % [bt / 60, bt % 60]))
	g.add_child(_stat_cell(L.t("Mejor nivel"), str(int(st.get("best_level", 0)))))
	g.add_child(_stat_cell(L.t("Derrotados"), str(int(st.get("kills", 0)))))
	g.add_child(_stat_cell(L.t("Jefes"), str(int(st.get("bosses", 0)))))
	g.add_child(_stat_cell(L.t("Cofres"), str(int(st.get("chests", 0)))))
	g.add_child(_stat_cell(L.t("Pokémon"), "%d / %d" % [SV.owned_count(), SV.dex_list.size()]))
	g.add_child(_stat_cell(L.t("Logros"), "%d / %d" % [SV.d.get("ach", {}).size(), PG.list().size()]))
	var tm: int = int(st.get("total_time", 0))
	g.add_child(_stat_cell(L.t("Tiempo jugado"), "%dh %02dm" % [tm / 3600, (tm % 3600) / 60]))
	var ok := _btn("Cerrar", func(): gacha_result.visible = false; _refresh_goals(), Vector2(220, 52))
	var hb := HBoxContainer.new()
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.add_child(ok)
	v.add_child(hb)
	gacha_result.visible = true
	_gf(ok)


# Ranking local: tus 10 mejores partidas (tiempo aguantado) guardadas en este dispositivo.
func _goals_records() -> Button:
	goals_box.add_child(_label("Tus mejores partidas", 28, C_GOLD))
	var top: Array = SV.d.get("top", [])
	if top.is_empty():
		goals_box.add_child(_label("Aún no hay partidas. ¡Juega una para aparecer aquí!", 20, Color("#c8d6ee")))
		return null
	for i in range(top.size()):
		var e: Dictionary = top[i]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		goals_box.add_child(row)
		var rk := _label("#%d" % (i + 1), 26, C_GOLD if i == 0 else Color.WHITE)
		rk.custom_minimum_size.x = 56
		rk.autowrap_mode = TextServer.AUTOWRAP_OFF
		row.add_child(rk)
		var pv := Preview.new()
		pv.custom_minimum_size = Vector2(56, 48)
		row.add_child(pv)
		pv.setup(int(e.get("dex", 25)), false, 1.0)
		var tm: int = int(e["time"])
		var col := VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(col)
		var nm: String = _name_of(int(e.get("dex", 25))) if SV.dex_by.has(int(e.get("dex", 25))) else "?"
		col.add_child(_label("%02d:%02d · %s" % [tm / 60, tm % 60, nm], 24))
		col.add_child(_label(L.t("Nv. %d") % int(e["level"]) + "  ·  " + L.t("Derrotados: %d") % int(e["kills"]) + "  ·  " + String(e.get("date", "")), 16, Color("#c8d6ee")))
	return null


func _goals_titles() -> Button:
	var cur_t: String = String(SV.d.get("title", ""))
	goals_box.add_child(_label(L.t("Título en uso: %s") % (L.t(cur_t) if cur_t != "" else L.t("ninguno")), 28, C_GOLD))
	var first: Button = null
	var nb := _btn("Sin título", func(): _set_title(""), Vector2(220, 46))
	goals_box.add_child(nb)
	first = nb
	var ach: Dictionary = SV.d.get("ach", {})
	for a in PG.list():
		var t: String = String(a["title"])
		if t == "":
			continue
		var done: bool = ach.has(String(a["id"]))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		goals_box.add_child(row)
		var mi := IC.rect(("medal%d" % int(a["tier"])) if done else "medalOff", 36)
		mi.custom_minimum_size.x = 48
		row.add_child(mi)
		var col := VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(col)
		col.add_child(_label(L.t(t), 24, C_GOLD if done else Color("#8a94b0")))
		col.add_child(_label(L.t("Logro: %s") % PG.name_of(a), 16, Color("#c8d6ee")))
		var b: Button
		if not done:
			b = _btn("Bloqueado", func(): pass, Vector2(170, 46))
			b.disabled = true
		elif cur_t == t:
			b = _btn("En uso", func(): pass, Vector2(170, 46))
			b.disabled = true
		else:
			b = _btn("Usar", func(): _set_title(t), Vector2(170, 46))
		row.add_child(b)
	return first


func _set_title(t: String) -> void:
	SV.d["title"] = t
	SV.save()
	Aud.sfx("confirm")
	_refresh_goals()


# ---------------------------------------------------------------
# Ajustes
# ---------------------------------------------------------------
var set_tab := 0
var set_tabs_row: HFlowContainer
var listening := ""
var last_act := ""
var import_armed := false
const SET_TABS := ["Sonido", "Gráficos", "Controles", "Cuenta", "Acerca de"]
const REPO_URL := "https://github.com/JayElDragon/poke-survivor"


func _build_settings() -> void:
	var s: Control = _screen("settings")
	var pc := PanelContainer.new()
	s.add_child(pc)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	pc.add_child(v)
	var hd := HBoxContainer.new()
	v.add_child(hd)
	var tt := _label("Ajustes", 38)
	tt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tt.autowrap_mode = TextServer.AUTOWRAP_OFF
	hd.add_child(tt)
	hd.add_child(_btn("Cerrar", func(): _leave(), Vector2(130, 44)))
	set_tabs_row = HFlowContainer.new()
	set_tabs_row.add_theme_constant_override("h_separation", 10)
	set_tabs_row.add_theme_constant_override("v_separation", 8)
	v.add_child(set_tabs_row)
	var ssc := ScrollContainer.new()
	ssc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	ssc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(ssc)
	settings_box = VBoxContainer.new()
	settings_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	settings_box.add_theme_constant_override("separation", 8)
	ssc.add_child(settings_box)


# Pantalla de novedades, como la pestana "What's new" del original: una tarjeta por version con etiquetas de color.
func _build_news() -> void:
	var s: Control = _screen("news")
	var pc := PanelContainer.new()
	s.add_child(pc)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	pc.add_child(v)
	var hd := HBoxContainer.new()
	v.add_child(hd)
	var tt := _label("Novedades", 38)
	tt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tt.autowrap_mode = TextServer.AUTOWRAP_OFF
	hd.add_child(tt)
	hd.add_child(_btn("Cerrar", func(): _leave(), Vector2(130, 44)))
	news_scroll = ScrollContainer.new()
	news_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	news_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(news_scroll)
	news_box = VBoxContainer.new()
	news_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	news_box.add_theme_constant_override("separation", 10)
	news_scroll.add_child(news_box)


func _news_tag(text: String, col: Color) -> Control:
	var wrap := HBoxContainer.new()
	var pc := PanelContainer.new()
	var sb := _sb(col, col.darkened(0.25), 2, 8)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 3
	sb.content_margin_bottom = 3
	pc.add_theme_stylebox_override("panel", sb)
	var l := _label(text, 18, Color("#10243f"))
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	pc.add_child(l)
	wrap.add_child(pc)
	return wrap


func _refresh_news() -> void:
	for c in news_box.get_children():
		news_box.remove_child(c)
		c.queue_free()
	var first_entry := true
	for e in PN.ENTRIES:
		if not first_entry:
			news_box.add_child(HSeparator.new())
		first_entry = false
		var t := _label(L.t(String(e["title"])), 30, C_GOLD)
		t.add_theme_constant_override("outline_size", 0)
		news_box.add_child(t)
		news_box.add_child(_label("%s  ·  v%s" % [PN.fmt_date(String(e["date"]), L.lang()), String(e["ver"])], 20, Color("#aebbd6")))
		for sec in [["new", "Nuevo", Color("#5ddc8a")], ["changes", "Cambios", Color("#4db3ff")], ["fixes", "Arreglos", Color("#ffb347")]]:
			var lines: Array = e.get(String(sec[0]), [])
			if lines.is_empty():
				continue
			news_box.add_child(_news_tag(L.t(String(sec[1])), sec[2]))
			for ln in lines:
				var brow := HBoxContainer.new()
				brow.add_theme_constant_override("separation", 10)
				var dot := _label("•", 22)
				dot.autowrap_mode = TextServer.AUTOWRAP_OFF
				dot.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
				brow.add_child(dot)
				var bl := _label(L.t(String(ln)), 22)
				bl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				brow.add_child(bl)
				news_box.add_child(brow)
	news_scroll.scroll_vertical = 0
	for b in news_box.get_parent().get_parent().find_children("*", "Button", true, false):
		focus_first = b
		break
	var cb: Control = null
	for b2 in news_scroll.get_parent().get_child(0).get_children():
		if b2 is Button:
			cb = b2
	if cb != null:
		focus_first = cb


func _slider_row(label: String, key: String) -> void:
	var row := HBoxContainer.new()
	settings_box.add_child(row)
	var sic := IC.rect("sound", 28)
	sic.custom_minimum_size.x = 40
	row.add_child(sic)
	var l := _label(label, 22)
	l.custom_minimum_size = Vector2(200, 0)
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


func _view_row() -> void:
	var box := VBoxContainer.new()
	settings_box.add_child(box)
	var row := HBoxContainer.new()
	box.add_child(row)
	var sic := IC.rect("phone", 28)
	sic.custom_minimum_size.x = 40
	row.add_child(sic)
	var l := _label("Tamaño de pantalla", 22)
	l.custom_minimum_size = Vector2(200, 0)
	row.add_child(l)
	var sl := HSlider.new()
	sl.min_value = DSP.MIN_PCT
	sl.max_value = DSP.MAX_PCT
	sl.step = 5
	sl.value = float(DSP.pct())
	sl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sl.custom_minimum_size = Vector2(0, 40)
	sl.focus_mode = Control.FOCUS_ALL
	row.add_child(sl)
	var pl := _label("%d%%" % DSP.pct(), 22, C_GOLD)
	pl.custom_minimum_size = Vector2(80, 0)
	pl.autowrap_mode = TextServer.AUTOWRAP_OFF
	row.add_child(pl)
	var rs := _btn("Restablecer", func(): pass, Vector2(150, 40))
	row.add_child(rs)
	var info := _label("", 16, Color("#c8d6ee"))
	box.add_child(info)
	var upd := func():
		pl.text = "%d%%" % DSP.pct()
		info.text = L.t("Pantalla (px) → vista del juego: ") + DSP.info(get_tree())
	upd.call()
	sl.value_changed.connect(func(v: float):
		DSP.set_pct(get_tree(), int(v))
		upd.call())
	rs.pressed.connect(func():
		sl.value = 100.0)


func _sec(title: String) -> void:
	var l := _label(title, 28, C_GOLD)
	l.add_theme_constant_override("outline_size", 0)
	settings_box.add_child(l)


# Fila: titulo + descripcion a la izquierda, control a la derecha.
func _srow(title: String, desc: String, ctrl: Control) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	settings_box.add_child(row)
	var tv := VBoxContainer.new()
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tv.add_theme_constant_override("separation", 0)
	row.add_child(tv)
	tv.add_child(_label(title, 22))
	if desc != "":
		tv.add_child(_label(desc, 16, Color("#c8d6ee")))
	row.add_child(ctrl)
	var sep := HSeparator.new()
	settings_box.add_child(sep)


# Selector de opciones: la elegida lleva borde dorado.
func _seg(opts: Array, cur_i: int, cb: Callable, translate: bool = true) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	for i in range(opts.size()):
		var b := _btn(L.t(String(opts[i])) if translate else String(opts[i]), func(): cb.call(i), Vector2(0, 44))
		if i == cur_i:
			for st in ["normal", "hover", "pressed"]:
				b.add_theme_stylebox_override(st, _sb(C_BTN_H, C_GOLD, 3, 22))
			b.add_theme_color_override("font_color", C_GOLD)
		h.add_child(b)
	return h


func _yesno(on: bool, cb: Callable) -> Button:
	var b := _btn(L.t("Sí") if on else L.t("No"), func(): cb.call(not on), Vector2(90, 46))
	if on:
		_gold_btn(b, true)
	return b


func _toggle_set(key: String, inverted: bool = false) -> Button:
	var on: bool = bool(SV.d["settings"][key])
	if inverted:
		on = not on
	return _yesno(on, func(v: bool):
		SV.d["settings"][key] = (not v) if inverted else v
		SV.save()
		_refresh_settings())


func _refresh_settings() -> void:
	reset_armed = false
	import_armed = false
	listening = ""
	_clear(set_tabs_row)
	var first_tab: Button = null
	for i in range(SET_TABS.size()):
		var tb := _btn(L.t(SET_TABS[i]), func(): set_tab = i; last_act = ""; _refresh_settings(); _gf(tab_sel), Vector2(0, 46))
		if i == set_tab:
			for st in ["normal", "hover", "pressed"]:
				tb.add_theme_stylebox_override(st, _sb(Color("#3b5aa8"), C_GOLD, 3, 14))
			first_tab = tb
			tab_sel = tb
		set_tabs_row.add_child(tb)
	tab_row = set_tabs_row
	_clear(settings_box)
	focus_first = first_tab
	match set_tab:
		0:
			_set_sound()
		1:
			_set_graphics()
		2:
			_set_controls()
		3:
			_set_account()
		4:
			_set_about()


func _set_sound() -> void:
	_sec("Sonido")
	_slider_row("Volumen general", "master")
	_slider_row("Música", "music")
	_slider_row("Efectos", "sfx")
	var muted: bool = bool(SV.d["settings"]["mute"])
	var mb := _btn(L.t("Activar sonido") if muted else L.t("Silenciar todo"), func():
		SV.d["settings"]["mute"] = not muted
		SV.save()
		if Aud.inst != null:
			Aud.inst.apply()
		_refresh_settings(), Vector2(220, 50))
	if not muted:
		_gold_btn(mb, true)
	mb.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	settings_box.add_child(mb)


func _set_graphics() -> void:
	_sec("Idioma")
	settings_box.add_child(_label("El juego se recarga al cambiarlo.", 18, Color("#c8d6ee")))
	var lg := GridContainer.new()
	lg.columns = 2
	lg.add_theme_constant_override("h_separation", 8)
	lg.add_theme_constant_override("v_separation", 8)
	var cur_lang: String = L.lang()
	for entry in L.LANGS:
		var code: String = entry[0]
		var lb := _btn(String(entry[1]), func():
			if code == L.lang():
				return
			SV.d["settings"]["lang"] = code
			SV.save()
			L.apply()
			SV.reopen = "settings"
			get_tree().reload_current_scene(), Vector2(0, 46))
		lb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lb.add_theme_font_size_override("font_size", 20)
		if code == cur_lang:
			for st in ["normal", "hover", "pressed"]:
				lb.add_theme_stylebox_override(st, _sb(C_BTN_H, C_GOLD, 3, 22))
			lb.add_theme_color_override("font_color", C_GOLD)
		lg.add_child(lb)
	settings_box.add_child(lg)
	_sec("Calidad")
	_srow("Efectos y partículas", "Cuántos efectos se dibujan. Auto los baja solo si el juego va a tirones.", _seg(["Auto", "Alta", "Media", "Baja"], int(SV.d["settings"]["quality"]), func(i: int):
		SV.d["settings"]["quality"] = i
		SV.save()
		_refresh_settings()))
	_sec("Pantalla")
	_view_row()
	_srow("Números de daño", "Los números que salen al golpear o ser golpeado.", _toggle_set("dmg_numbers"))
	_srow("Menos sacudidas y destellos", "La cámara tiembla menos y los destellos son más suaves.", _toggle_set("shake", true))
	_srow("Vibración", "Vibra el móvil cuando te golpean.", _toggle_set("vibration"))
	_srow("Mostrar FPS", "Cuadros por segundo, en la esquina.", _toggle_set("fps"))
	_srow("Caja de estadísticas", "Muestra tus estadísticas (daño, velocidad…) arriba a la izquierda.", _toggle_set("stats_box"))
	_srow("Dificultad adaptativa", "En la partida normal, el juego empieza fácil y se pone más difícil según tus mejoras: más vida y daño, más enemigos, hordas más seguidas y más experiencia por nivel.", _toggle_set("adaptive"))


func _set_controls() -> void:
	_sec("En móvil o tableta")
	settings_box.add_child(_label("Pon el dedo en cualquier parte y arrástralo para moverte: el joystick aparece donde tocas. Toca un movimiento abajo para cambiar a él y el botón de arriba a la derecha para pausar. Juega en horizontal.", 20, Color("#c8d6ee")))
	_srow("Tamaño del joystick", "Cuánto tienes que arrastrar el dedo.", _seg(["Pequeño", "Mediano", "Grande"], clampi(int(SV.d["settings"]["stick"]), 0, 2), func(i: int):
		SV.d["settings"]["stick"] = i
		SV.save()
		_refresh_settings()))
	_srow("Joystick fijo", "El joystick se queda siempre abajo a la izquierda en vez de aparecer donde tocas.", _toggle_set("stick_fixed"))
	_sec("Mando")
	settings_box.add_child(_label("Stick izquierdo o cruceta: moverte y navegar por los menús. Pulsa un botón de la lista y luego el botón del mando que quieras asignarle.", 20, Color("#c8d6ee")))
	_srow("Tipo de mando", "Cambia los nombres de los botones y restablece la asignación.", _seg(PAD.NAMES, PAD.layout(), func(i: int):
		PAD.reset(i)
		_refresh_settings(), false))
	for a in PAD.ACTIONS:
		var act: String = a
		var txt: String = L.t("Pulsa un botón…") if listening == act else ""
		var cb := _btn(txt, func():
			listening = "" if listening == act else act
			last_act = act
			_refresh_listen(), Vector2(190, 46))
		if listening == act:
			_gold_btn(cb, true)
		else:
			cb.icon = PADI.tex(PAD.btn(act))
			cb.expand_icon = true
			cb.add_theme_constant_override("icon_max_width", 36)
			cb.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_srow(PAD.LABELS[act], "", cb)
		if act == last_act:
			focus_first = cb
	var rb := _btn("Restablecer asignación", func(): PAD.reset(); last_act = ""; _refresh_settings(), Vector2(280, 46))
	settings_box.add_child(rb)


# Redibuja la pestana de controles manteniendo el modo "escuchando".
func _refresh_listen() -> void:
	var keep := listening
	_clear(settings_box)
	_set_controls()
	listening = keep
	if focus_first != null and is_instance_valid(focus_first):
		_gf(focus_first)


func _set_account() -> void:
	_sec("Cuenta")
	var l1 := _label("Local (este dispositivo)", 22, Color("#dfe8ff"))
	l1.autowrap_mode = TextServer.AUTOWRAP_OFF
	_srow("Tipo de cuenta", "", l1)
	var l2 := _label("En este dispositivo", 22, Color("#dfe8ff"))
	l2.autowrap_mode = TextServer.AUTOWRAP_OFF
	_srow("Guardado", "", l2)
	settings_box.add_child(_label("Tu partida se guarda en este dispositivo. Para tenerla a salvo o pasarla a otro dispositivo: copia el código de guardado, pégalo en una nota de Google Keep, en Google Drive, en un correo o en un mensaje a ti mismo, y en el otro dispositivo usa «Pegar código de guardado».", 18, Color("#c8d6ee")))
	_sec("Copia de seguridad")
	var cb := _btn("Copiar código de guardado", func():
		var js := JSON.stringify(SV.d)
		DisplayServer.clipboard_set(Marshalls.utf8_to_base64(js))
		toast(L.t("Código copiado")), Vector2(0, 50))
	settings_box.add_child(cb)
	focus_first = cb
	var ib := _btn("Pegar código de guardado", func(): pass, Vector2(0, 50))
	ib.pressed.connect(func():
		if not import_armed:
			import_armed = true
			ib.text = L.t("¿Reemplazar tu progreso actual? Pulsa otra vez")
			return
		import_armed = false
		var parsed = JSON.parse_string(Marshalls.base64_to_utf8(DisplayServer.clipboard_get().strip_edges()))
		if parsed is Dictionary and parsed.has("owned") and parsed.has("coins"):
			SV.d = SV._merge(SV.default_data(), parsed)
			SV._migrate_upgrades()
			SV.save()
			L.apply()
			SV.reopen = "settings"
			get_tree().reload_current_scene()
		else:
			ib.text = L.t("Pegar código de guardado")
			toast(L.t("Código no válido")))
	settings_box.add_child(ib)
	_sec("Zona peligrosa")
	var rb := _btn("Borrar todo el progreso", func(): pass, Vector2(0, 50))
	_danger(rb)
	rb.pressed.connect(func():
		if not reset_armed:
			reset_armed = true
			rb.text = L.t("¿Seguro? Pulsa otra vez para borrar TODO")
		else:
			SV.reset_all()
			_show("test"))
	settings_box.add_child(rb)


func _danger(b: Button) -> void:
	for st in ["normal", "hover", "pressed"]:
		b.add_theme_stylebox_override(st, _sb(Color("#8a1f2d"), Color("#ff7a85"), 3, 12))
	b.add_theme_stylebox_override("focus", _sb(Color("#a92a3b"), Color.WHITE, 5, 12))


func _set_about() -> void:
	var t := _label("PokéSurvivor", 52, C_GOLD)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	settings_box.add_child(t)
	var by := _label("Port de Android por JayElDragon", 30)
	by.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	settings_box.add_child(by)
	var ver := _label(L.t("Versión") + " " + UPD.APP_VERSION + " · Android", 20, Color("#c8d6ee"))
	ver.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	settings_box.add_child(ver)
	settings_box.add_child(_label("Juego de fans gratis y sin ánimo de lucro: sin anuncios ni compras. Pokémon y sus personajes pertenecen a Nintendo, Creatures y GAME FREAK; este proyecto no está afiliado con ellos.", 20, Color("#c8d6ee")))
	_sec("Créditos")
	for line in ["• Juego original (web): JPTER78.", "• Port de Android: JayElDragon.", "• Sprites: PMD SpriteCollab y sus artistas (CC BY-NC 4.0).", "• Datos Pokémon: PokéAPI.", "• Fuente: Pixelify Sans (OFL)."]:
		settings_box.add_child(_label(line, 20))
	var hb := HFlowContainer.new()
	hb.add_theme_constant_override("h_separation", 10)
	hb.alignment = FlowContainer.ALIGNMENT_CENTER
	settings_box.add_child(hb)
	var dxb := _btn("Pokédex", func(): _show("dex"), Vector2(0, 50))
	hb.add_child(dxb)
	hb.add_child(_btn("Mi repositorio en GitHub", func(): OS.shell_open(REPO_URL), Vector2(0, 50)))
	focus_first = dxb
