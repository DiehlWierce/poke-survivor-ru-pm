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
const CAVEI = preload("res://scripts/cave_int.gd")
const FUS = preload("res://scripts/fusions.gd")
const KCX = preload("res://scripts/kecleon.gd")
const DYN = preload("res://scripts/dynamax.gd")
const ST = preload("res://scripts/starters_data.gd")
const IC = preload("res://scripts/icons.gd")
const CH = preload("res://scripts/challenges.gd")
const GP = preload("res://scripts/gachapon.gd")
const PXF = preload("res://scripts/pxfont.gd")
const DSP = preload("res://scripts/display.gd")
const SLOTS = preload("res://scripts/slots.gd")
const PAD = preload("res://scripts/pad.gd")
const PADI = preload("res://scripts/padicons.gd")
const UPD = preload("res://scripts/updater.gd")
const PN = preload("res://scripts/patchnotes.gd")
const KO = preload("res://scripts/keys_only.gd")

# Темы интерфейса (V5.1): панель, тёмная панель, акцент, кнопка, кнопка под курсором. Индекс 1 — прежний синий вид.
const UI_THEMES := [
	["#9a2e27", "#6a1e18", Color("#c8362c"), "#8c1c1c", "#c92f2f"],
	["#27449a", "#18296a", Color("#2f58c9"), "#1c3a8c", "#2f58c9"],
	["#2a8a3e", "#1a5a28", Color("#34b04c"), "#1c7a30", "#2fc94f"],
	["#5a2a9a", "#3a186a", Color("#7a3fd0"), "#4c1c8c", "#7a2fc9"],
]
var C_PANEL := Color("#27449a")
var C_PANEL_D := Color("#18296a")
var C_BTN := Color("#1c3a8c")
var C_BTN_H := Color("#2f58c9")
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
var main_credit: VBoxContainer   # credito (autor del port de Android y del port a PortMaster) bajo el retrato de la pantalla principal
var pad_hint: HBoxContainer
var pad_hint_key := ""
var shade: ColorRect
var focus_first: Control = null
var sum_ov: Control = null          # fondo del cuadro de resultados de la partida
var modal_prev: Control = null      # control enfocado antes de abrirse un cuadro
var modal_was := false
var news_top: Button
var news_box: VBoxContainer
var news_scroll: ScrollContainer

# estado de pantallas
var dex_gen := 0
var dex_page := 0
var dex_only_owned := false
var dex_heart: Button
var dex_sort := 0   # 0 numero asc, 1 desc, 2 nombre, 3 rareza, 4 favoritos primero
var dex_sel := 25
var dex_grid: GridContainer
var dex_page_lbl: Label
var dex_detail: VBoxContainer
var dex_prev: Preview
var gacha_region := 1
var gacha_box: VBoxContainer
var gacha_tabs: HFlowContainer
var gacha_content: VBoxContainer
var gacha_pages := {}   # region -> {"page": Control, "fp": huella, "first": Button} (la de la region en pantalla)
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
var up_tail: VBoxContainer = null    # paneles de debajo de las tarjetas (MT, veto, atajos)
var up_tail_key := ""
var up_sig := ""                     # estructura de las tarjetas construidas (ver _up_sig)
var up_cards: Array = []             # [{id, u, pips, btn, extra}]
var up_ui := {}                      # piezas de la cabecera
var up_focus_id := ""
var up_dex := 25
var store_box: VBoxContainer
var store_dex := -1
var store_return := "up"
var ban_open := false
var tm_open := false
var main_prev: Control   # Preview
var main_card: PanelContainer
var main_info: Label
var main_stats: Label
var test_box: VBoxContainer
var test_idx := 0
var test_scores := {}
var test_result_dex := 0
var reset_armed := false
var save_notice: PanelContainer = null   # aviso fijo si el guardado esta bloqueado (SV.save_blocked)
static var _save_toast_done := false     # el aviso de copia/campos restaurados sale una sola vez por ejecucion
var settings_box: VBoxContainer
var settings_host: VBoxContainer
var settings_pages := {}   # pestana -> pagina ya construida

# --- Adaptacion a la pantalla: ventana (720x480 ... 1280x720) y % de vista (60-140 %) ---
# A 140 % la zona util baja a ~914x514, asi que nada puede asumir 1280x720. Todo se recoloca en
# get_viewport().size_changed (tambien al mover el deslizador de Ajustes), agrupado en un solo paso por fotograma
# y sin reconstruir pantallas: solo se tocan margenes, tamanos minimos y columnas.
var top_bar: HBoxContainer
var top_sp: Control                 # separador elastico de la barra superior
var fit_pending := false
var fit_key := ""                   # zona util + margenes seguros: si no cambia, no se hace nada
var mode_key := ""                  # modo discreto (estrecho / bajo / ancho): solo si cambia se rehacen paginas
var lay_gen := 0                    # +1 cada vez que cambia el modo: las paginas guardadas con otro valor se rehacen
var compact := false                # zona util estrecha (< 1000)
var short := false                  # zona util baja (< 560)
var wide := false                   # zona util ancha (>= 1150): 3 columnas donde se pueda
var scr_m := Vector4(24, 72, 24, 18)  # margenes de las pantallas (izq, arriba, der, abajo)
var scr_ch := Vector2(48, 90)
var fit_scrolls: Array = []         # [{sc, v, chrome, center}] ScrollContainers que no pueden pasar de la zona util
var main_scroll: ScrollContainer
var main_ui := {}                   # piezas de la pantalla principal que se compactan
var dex_dp: PanelContainer
var dex_filters: HFlowContainer
var dex_scroll: ScrollContainer
var test_pc: PanelContainer
var ins_c := Vector4.ZERO            # margenes seguros (se actualizan en _fit_layout)
var main_prev_min := Vector2(340, 240)
var pill_sbs: Array = []              # estilos de las pildoras de la barra superior (margenes laterales segun el modo)


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
	# Animacion y hoja cacheadas: en la consola buscar el archivo en cada fotograma costaba milisegundos.
	var _an: Dictionary = {}
	var _tx: Texture2D = null
	var _cdex := -1
	var _cshiny := false
	# Cache de hojas ya cargadas (clave "dex|anim|shiny"); se vacia si crece demasiado para no ocupar memoria.
	static var _tex_cache: Dictionary = {}

	func _init() -> void:
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	func setup(d: int, shn: bool = false, k: float = 5.0, drk: bool = false) -> void:
		dex = d
		shiny = shn
		scale_k = k
		dark = drk
		frame = 0
		t = 0.0
		_sync()
		queue_redraw()

	static func anim_of(d: int) -> Dictionary:
		var sm: Dictionary = SV.smeta.get(str(d), {})
		if sm.is_empty():
			return {}
		var a: Dictionary = sm["a"]
		var nm := "Idle" if a.has("Idle") else "Walk"
		return {"name": nm, "info": a[nm], "sm": sm}

	# Rutas con carga en hilo pedida y aun no recogida: la lectura y el decodificado de la hoja salen del hilo principal.
	static var _pend: Dictionary = {}
	static var _drain_t := 0.0

	static func _path_of(d: int, nm: String, shn: bool) -> String:
		if shn:
			var ps := "res://assets/pokemon/%d/s/%s.png" % [d, nm]
			if ResourceLoader.exists(ps):
				return ps
		var p := "res://assets/pokemon/%d/%s.png" % [d, nm]
		return p if ResourceLoader.exists(p) else ""

	# Pide en segundo plano la hoja del icono de un Pokemon (Dex, selector, logros) antes de necesitarla.
	static func prefetch(d: int, shn: bool) -> void:
		var an: Dictionary = anim_of(d)
		if an.is_empty():
			return
		var nm: String = String(an["name"])
		if _tex_cache.has("%d|%s|%d" % [d, nm, 1 if shn else 0]):
			return
		var p := _path_of(d, nm, shn)
		if p == "" or _pend.has(p):
			return
		if ResourceLoader.load_threaded_request(p) == OK:
			_pend[p] = true

	# Recoge las cargas terminadas que nadie reclamo (se cambio de pagina): si no, quedan retenidas.
	static func drain() -> void:
		if _pend.is_empty():
			return
		var now := Time.get_ticks_msec() / 1000.0
		if now - _drain_t < 0.5:
			return
		_drain_t = now
		for p in _pend.keys():
			var st: int = ResourceLoader.load_threaded_get_status(p)
			if st == ResourceLoader.THREAD_LOAD_LOADED:
				ResourceLoader.load_threaded_get(p)
				_pend.erase(p)
			elif st != ResourceLoader.THREAD_LOAD_IN_PROGRESS:
				_pend.erase(p)

	static func tex_of(d: int, nm: String, shn: bool) -> Texture2D:
		var key := "%d|%s|%d" % [d, nm, 1 if shn else 0]
		if _tex_cache.has(key):
			return _tex_cache[key]
		var res: Texture2D = null
		var p := _path_of(d, nm, shn)
		if p != "":
			if _pend.has(p):
				res = ResourceLoader.load_threaded_get(p) as Texture2D
				_pend.erase(p)
			else:
				res = load(p)
		if _tex_cache.size() >= 64:
			_tex_cache.clear()
		_tex_cache[key] = res
		return res

	# Recarga la animacion y la hoja solo cuando cambia el Pokemon.
	func _sync() -> void:
		if _cdex == dex and _cshiny == shiny:
			return
		_cdex = dex
		_cshiny = shiny
		_an = anim_of(dex)
		_tx = null
		if not _an.is_empty():
			_tx = tex_of(dex, String(_an["name"]), shiny)

	func _process(delta: float) -> void:
		if not is_visible_in_tree():
			return
		_sync()
		if _an.is_empty():
			return
		var info: Dictionary = _an["info"]
		t += delta * 60.0
		var guard := 0
		var old := frame
		while t >= float(info["d"][frame]) and guard < 12:
			guard += 1
			t -= float(info["d"][frame])
			frame = (frame + 1) % int(info["n"])
		if frame != old:
			queue_redraw()   # solo se redibuja cuando cambia el fotograma

	func _draw() -> void:
		_sync()
		if _an.is_empty():
			return
		var info: Dictionary = _an["info"]
		if _tx == null:
			draw_rect(Rect2(size * 0.5 - Vector2(16, 16), Vector2(32, 32)), Color(1, 1, 1, 0.15))
			return
		var w: float = float(info["w"])
		var h: float = float(info["h"])
		var k: float = scale_k
		# ajusta para que no se salga del cuadro
		k = minf(k, minf(size.x / w, size.y / h) * 0.92)
		var pos := Vector2(size.x * 0.5 - float(info["ax"]) * k, size.y * 0.84 - float(info["ay"]) * k)
		draw_set_transform(Vector2(size.x * 0.5, size.y * 0.84), 0.0, Vector2(1.0, 0.35))
		draw_circle(Vector2.ZERO, w * k * 0.28, Color(0, 0, 0, 0.3))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		# se dibuja directo (antes: TextureRect + AtlasTexture nuevos en cada fotograma)
		draw_texture_rect_region(_tx, Rect2(pos, Vector2(w * k, h * k)), Rect2(float(frame) * w, 0.0, w, h), Color(0, 0, 0, 0.9) if dark else Color.WHITE)



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
	# Hojas por animacion y ultimo estado aplicado: _apply() ya no recarga la textura en cada fotograma.
	var _texs: Dictionary = {}
	var _la := ""
	var _lf := -1
	var _ld := -1
	var _lk := -1.0

	func setup(d: int, kk: float, shn: bool, b: Rect2, wd: bool = true) -> void:
		dex = d
		k = kk
		shiny = shn
		bounds = b
		wander = wd
		var sm: Dictionary = SV.smeta.get(str(d), {})
		meta = sm.get("a", {})
		_texs.clear()
		_la = ""
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
		queue_redraw()   # la sombra es fija: se dibuja una sola vez

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
		if anim == _la and frame == _lf and dir == _ld and k == _lk:
			return   # nada ha cambiado: no se vuelve a tocar el sprite
		if not _texs.has(anim):
			_texs[anim] = Preview.tex_of(dex, anim, shiny)
		var tx: Texture2D = _texs[anim]
		if tx == null:
			sprite.visible = false
			return
		var new_sheet: bool = anim != _la
		_la = anim
		_lf = frame
		_ld = dir
		_lk = k
		sprite.visible = true
		if new_sheet:
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
		if meta.is_empty() or not meta.has(anim) or not is_visible_in_tree():
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
	# Consola: el mismo mundo vivo que en el menu original, con el coste acotado. Antes (400b7544) se quito del todo:
	# start() generaba 9 trozos y horneaba 9 texturas de golpe (en la consola, segundos a ~7 fps) y cada trozo nuevo
	# era un tiron de ~150 ms. Ahora el terreno de cada trozo (el ruido, lo caro) se calcula en un hilo sobre una copia
	# de tileworld, el suelo lo hornea el hilo de tileworld, el trozo se genera en el hilo principal ya sin ruido (~1/10)
	# y el fondo aparece con un fundido cuando lo visible esta listo: abrir el menu no espera al fondo.
	const LITE_MONS := 12      # Pokemon a la vez en la consola (el original: los 20)
	const LITE_FADE := 0.5     # s del fundido de entrada
	const LITE_AMB_HZ := 30.0  # las particulas de ambiente se redibujan a 30 Hz
	var lite: bool = OS.has_feature("handheld") or "--keys-only" in OS.get_cmdline_user_args()
	var warm: Node2D = null    # copia de tileworld fuera del arbol: calcula el terreno de un trozo en un hilo
	var warm_key := Vector2i(99999, 99999)
	var warm_tid := -1
	var shown := true          # consola: false hasta que lo visible esta generado y horneado
	var fade := 1.0
	var amb_acc := 0.0

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
		if lite:
			warm = TW.new()
			warm.seed_v = tw.seed_v
			warm.liq_base = tw.liq_base
			warm.liq_grow = tw.liq_grow
			warm.wall_grow = tw.wall_grow
			shown = false
			fade = 0.0
			modulate.a = 0.0
			tw.set_process(false)   # hasta que se vea: el suelo lo hornea solo el hilo (sin horneado sincrono en el principal)
			_update_chunks()
		else:
			_update_chunks(true)
			tw.flush_bake()
			for i in range(pool.size()):
				_spawn_mon(true)
		amb = Ambient.new()
		amb.modulate.a = modulate.a
		get_parent().add_child(amb)
		get_parent().move_child(amb, get_index() + 1)
		tree_exiting.connect(func():
			if warm_tid >= 0:
				WorkerThreadPool.wait_for_task_completion(warm_tid)
				warm_tid = -1
			if is_instance_valid(warm):
				warm.free()
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
		if lite:
			_lite_gen()
			return
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

	# Consola: un trozo por paso. El terreno (22x22 casillas: el trozo y 3 de margen, lo que lee _gen_chunk) se calcula en
	# un hilo sobre la copia "warm"; al terminar pasa a la cache de tileworld y el trozo se genera aqui ya sin ruido.
	func _lite_gen() -> void:
		if warm_tid >= 0:
			if not WorkerThreadPool.is_task_completed(warm_tid):
				return
			WorkerThreadPool.wait_for_task_completion(warm_tid)
			warm_tid = -1
			tw.terr.merge(warm.terr, true)
			warm.terr.clear()
			if warm.raw_c.size() > 6000:
				warm.raw_c.clear()
			if gen_q.has(warm_key) and not gen.chunks.has(warm_key):
				gen.chunks[warm_key] = gen._gen_chunk(warm_key.x, warm_key.y)
				gen_q.erase(warm_key)
			return   # un trozo por fotograma como mucho
		while not gen_q.is_empty():
			var nk: Vector2i = gen_q[0]
			if gen.chunks.has(nk):
				gen_q.pop_front()
				continue
			warm_key = nk
			warm_tid = WorkerThreadPool.add_task(_warm_run.bind(nk), false, "menu_terrain")
			break

	func _warm_run(key: Vector2i) -> void:
		var bx: int = key.x * TW.N - 3
		var by: int = key.y * TW.N - 3
		for j in range(TW.N + 6):
			for i in range(TW.N + 6):
				warm.terrain(bx + i, by + j)

	# Lo que se ve ya tiene objetos y suelo horneado.
	func _view_ready() -> bool:
		var r := Rect2(cam - vs * 0.5, vs)
		for ky in range(floori(r.position.y / TW.CW), floori((r.end.y - 0.01) / TW.CW) + 1):
			for kx in range(floori(r.position.x / TW.CW), floori((r.end.x - 0.01) / TW.CW) + 1):
				var k := Vector2i(kx, ky)
				if not gen.chunks.has(k) or not tw.chunks.has(k) or tw.chunks[k]["tex"] == null:
					return false
		return true

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
		if not shown:
			tw._bake_tick()   # solo hilo: arranca tareas y recoge una textura por fotograma
			if not _view_ready():
				return
			shown = true
			tw.set_process(true)
		if fade < 1.0:
			fade = minf(1.0, fade + delta / LITE_FADE)
			modulate.a = fade
			if amb != null:
				amb.modulate.a = fade
		if lite and mons.size() < LITE_MONS and fade < 1.0:
			_spawn_mon(true)   # durante el fundido, de uno en uno: aparecen con el mundo
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
				if not lite or mons.size() < LITE_MONS:
					_spawn_mon(false)
		# ambiente: bosque -> cueva de cristal -> volcan, como el original: el mismo mapa con los recursos de cada bioma
		var bi: int = int(floor(t / PERIOD)) % 3
		if bi != biome_i:
			biome_i = bi
			tw.set_biome(bi)
		if lite:
			amb_acc += delta
			if amb_acc < 1.0 / LITE_AMB_HZ:
				return
			amb_acc = 0.0
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

	func _init() -> void :
		clip_contents = true

	func add_mon(d: int, kk: float, f0: float, f1: float) -> void :
		var m := Mon.new()
		m.fx0 = f0
		m.fx1 = f1
		add_child(m)
		m.setup(d, kk, false, Rect2(f0 * 700.0, 250.0, (f1 - f0) * 700.0, 60.0), false)
		m.fixed = true
		m.fdir = 1
		m.dir = 1
		m.wait = 0.5 + 0.9 * float(mons.size())
		mons.append(m)
		_layout()

	func _notification(what: int) -> void :
		if what == NOTIFICATION_RESIZED:
			_layout()

	func _layout() -> void :
		for m in mons:

			m.home = Vector2((m.fx0 + m.fx1) * 0.5 * size.x, size.y * 0.8)
			m.position = m.home

	func _draw() -> void :
		var w: float = size.x
		var h: float = size.y
		var pts := PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, h), Vector2(0, h)])
		var cols := PackedColorArray([c1, c1.lerp(c2, 0.5), c2, c1.lerp(c2, 0.5)])
		draw_polygon(pts, cols)
		draw_circle(Vector2(w * 0.55, h * 0.4), h * 0.6, Color(1, 1, 1, 0.05))
		draw_rect(Rect2(0, h * 0.64, w, h * 0.36), Color(0, 0, 0, 0.12))
		draw_rect(Rect2(1.5, 1.5, w - 3.0, h - 3.0), Color(0.7, 0.78, 1.0, 0.75), false, 3.0)



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
const TOWER_FLOORS_M := 60

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


func _apply_ui_theme(i: int) -> void:
	i = clampi(i, 0, UI_THEMES.size() - 1)
	SV.d["ui_theme"] = i
	SV.save()
	var t: Array = UI_THEMES[i]
	C_PANEL = Color(String(t[0]))
	C_PANEL_D = Color(String(t[1]))
	C_BTN = Color(String(t[3]))
	C_BTN_H = Color(String(t[4]))
	_build_theme()


func _ready() -> void:
	SV.ensure()
	var th0: Array = UI_THEMES[clampi(int(SV.d.get("ui_theme", 1)), 0, UI_THEMES.size() - 1)]
	C_PANEL = Color(String(th0[0]))
	C_PANEL_D = Color(String(th0[1]))
	C_BTN = Color(String(th0[3]))
	C_BTN_H = Color(String(th0[4]))
	is_overlay = bool(Engine.get_meta("menu_overlay", false))
	Engine.set_meta("menu_overlay", false)
	L.apply()
	DSP.apply(get_tree())
	PAD.apply()
	if not is_overlay:
		DSP.apply_window()
		Aud.setup(self)
		Aud.music("village")
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_calc_mode()
	_build_theme()
	RenderingServer.set_default_clear_color(Color("#16233a"))
	# fondo: un trozo del mapa que se desplaza solo, con Pokemon caminando (como el menu original, tambien en la consola:
	# alli MenuWorld va en modo "lite", ver la clase)
	if not is_overlay:
		var world := MenuWorld.new()
		world.z_index = -4000   # el fondo siempre queda detras de toda la interfaz
		add_child(world)
		world.start()
		if OS.get_name() == "Android":   # el aviso de actualizacion descarga un APK: solo tiene sentido en Android
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
	top_bar = top
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_bottom = 58   # los margenes laterales y de arriba los pone _fit_layout (dependen del % de vista)
	add_child(top)
	back_btn = _btn("◀ Volver", func(): _leave(), Vector2(150, 44))
	top.add_child(back_btn)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_sp = sp
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
	name_pill.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
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
	# Solo la pantalla principal se construye ahora; las demas, la primera vez que se abren (_ensure): volver al menu tras cada partida cuesta menos.
	if not is_overlay:   # los Ajustes dentro de la partida no usan la pantalla principal
		_build_main()
	_build_save_notice()
	NAVG.veto = _nav_veto
	get_viewport().size_changed.connect(_fit_later)   # Callable de un metodo: se desconecta solo al liberar el menu
	_fit_layout()
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


# ---------------------------------------------------------------
# Adaptacion a la pantalla
# ---------------------------------------------------------------
# ScrollContainer que sigue al control enfocado: con mando/teclado nada queda fuera de la vista.
func _new_scroll() -> ScrollContainer:
	var sc := ScrollContainer.new()
	sc.follow_focus = true
	return sc


# Modo segun la zona util (rect visible - margenes seguros): estrecho / bajo / ancho.
func _calc_mode() -> void:
	var ar: Rect2 = DSP.area(get_tree())
	var ins: Vector4 = DSP.insets(get_tree())
	compact = ar.size.x < 1000.0
	short = ar.size.y < 560.0
	wide = ar.size.x >= 1150.0
	var side: float = 16.0 if compact else 24.0
	var mt: float = 66.0 if short else 72.0
	var mb: float = 12.0 if short else 18.0
	scr_m = Vector4(side + ins.x, mt + ins.y, side + ins.z, mb + ins.w)
	scr_ch = Vector2(side * 2.0, mt + mb)   # lo mismo sin los margenes seguros (DSP.area ya los resta)


func _screen_margins(c: Control) -> void:
	c.add_theme_constant_override("margin_left", int(scr_m.x))
	c.add_theme_constant_override("margin_top", int(scr_m.y))
	c.add_theme_constant_override("margin_right", int(scr_m.z))
	c.add_theme_constant_override("margin_bottom", int(scr_m.w))


# Varios size_changed seguidos (arrastrar el deslizador de Ajustes, redimensionar la ventana) se juntan en un paso.
func _fit_later() -> void:
	if fit_pending:
		return
	fit_pending = true
	_fit_layout.call_deferred()


func _fit_layout() -> void:
	fit_pending = false
	if not is_inside_tree() or top_bar == null:
		return
	var ar: Rect2 = DSP.area(get_tree())
	var ins: Vector4 = DSP.insets(get_tree())
	var key := "%d_%d_%d_%d_%d_%d" % [roundi(ar.size.x), roundi(ar.size.y), roundi(ins.x), roundi(ins.y), roundi(ins.z), roundi(ins.w)]
	if key != fit_key:
		fit_key = key
		_calc_mode()
		for k in screens:
			_screen_margins(screens[k])
		_fit_float(ar, ins)
		_fit_main(ar)
		_fit_main_late.call_deferred()
		_fit_dex(ar)
		_fit_test(ar)
		_fit_top()
		var mk := "%d%d%d" % [int(compact), int(short), int(wide)]
		if mk != mode_key:
			mode_key = mk
			lay_gen += 1
			_fit_mode_changed()
		elif cur == "modes" and modes_cols_now != _modes_cols():
			_refresh_modes()   # cambia el numero de columnas de la lista de modos
	_fit_scrolls_now()


# Si cambia el modo, la pantalla abierta rehace lo que dependa de el (las demas lo hacen al abrirse: _show las reconstruye).
func _fit_mode_changed() -> void:
	if not screens.has(cur):
		return
	match cur:
		"up":
			_refresh_up()
		"goals":
			_refresh_goals()
		"lexicon":
			_refresh_lexicon()
		"gacha":
			_refresh_gacha()
		"modes":
			_refresh_modes()
	gi_dirty = true


# Avisos flotantes dentro de la zona segura.
func _fit_float(ar: Rect2, ins: Vector4) -> void:
	ins_c = ins
	var hw: float = minf(300.0, ar.size.x * 0.5 - 8.0)
	toast_lbl.offset_left = -hw
	toast_lbl.offset_right = hw
	toast_lbl.offset_top = -80.0 - ins.w
	toast_lbl.offset_bottom = -30.0 - ins.w
	pad_hint.offset_left = 24.0 + ins.x
	pad_hint.offset_top = -46.0 - ins.w
	pad_hint.offset_bottom = -6.0 - ins.w


# Barra superior: debe caber en la zona util. Si no cabe, primero Novedades se queda en icono
# y por ultimo el nombre se recorta.
func _fit_top() -> void:
	if top_bar == null:
		return
	var ar: Rect2 = DSP.area(get_tree())
	var ins: Vector4 = ins_c
	top_bar.offset_left = 16.0 + ins.x
	top_bar.offset_right = -16.0 - ins.z
	top_bar.offset_top = 10.0 + ins.y
	top_bar.offset_bottom = 58.0 + ins.y
	if save_notice != null:
		save_notice.offset_left = 16.0 + ins.x
		save_notice.offset_right = -16.0 - ins.z
		save_notice.offset_top = 62.0 + ins.y
	var avail: float = ar.size.x - 32.0
	top_sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	news_top.text = L.t("Novedades")
	news_top.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	news_top.custom_minimum_size.x = 0.0
	# el nombre se recorta con "..." (OVERRUN_TRIM_ELLIPSIS), asi que su ancho minimo hay que ponerlo a mano: icono + nombre
	name_pill.clip_text = false
	var nfont: Font = name_pill.get_theme_font("font")
	var nsz: int = name_pill.get_theme_font_size("font_size")
	var nsb: StyleBox = name_pill.get_theme_stylebox("normal")
	name_pill.custom_minimum_size.x = ceilf(nfont.get_string_size(name_pill.text, HORIZONTAL_ALIGNMENT_LEFT, -1, nsz).x + 26.0 + 10.0 + nsb.get_minimum_size().x) + 4.0
	for psb in pill_sbs:
		(psb as StyleBoxFlat).content_margin_left = 10.0 if compact else 16.0
		(psb as StyleBoxFlat).content_margin_right = 10.0 if compact else 16.0
	var over: float = top_bar.get_combined_minimum_size().x - avail
	if over > 0.0:
		news_top.text = ""
		news_top.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		news_top.custom_minimum_size.x = 52.0
		over = top_bar.get_combined_minimum_size().x - avail
	if over > 0.0:
		var nat: float = name_pill.get_combined_minimum_size().x
		name_pill.clip_text = true
		name_pill.custom_minimum_size.x = maxf(100.0, nat - over)


# Pantalla principal: los botones y el retrato se encogen hasta que la columna cabe en la altura util
# (si aun asi no cupiese, el ScrollContainer de main_scroll la desplaza).
func _fit_main(ar: Rect2) -> void:
	if main_ui.is_empty():
		return
	var ah: float = ar.size.y - scr_ch.y
	var right: VBoxContainer = main_ui["right"]
	var mv: VBoxContainer = main_ui["mv"]
	var stats: Label = main_ui["stats"]
	right.custom_minimum_size.x = 380.0 if ar.size.x >= 840.0 else maxf(250.0, ar.size.x * 0.40)
	var big: bool = ah >= 640.0
	var mid: bool = ah >= 470.0
	(main_ui["title"] as Label).add_theme_font_size_override("font_size", 56 if big else (44 if mid else 36))
	(main_ui["sub"] as Label).add_theme_font_size_override("font_size", 22 if mid else 18)
	(main_ui["info"] as Label).add_theme_font_size_override("font_size", 26 if big else (22 if mid else 18))
	stats.add_theme_font_size_override("font_size", 18 if mid else 15)
	main_card.custom_minimum_size = Vector2(360, 260) if big else (Vector2(300, 190) if mid else Vector2(250, 140))
	main_prev_min = Vector2(340, 240) if big else (Vector2(280, 170) if mid else Vector2(230, 120))
	if is_instance_valid(main_prev):
		main_prev.custom_minimum_size = main_prev_min
	var btns: Array = main_ui["btns"]
	# primero con las estadisticas debajo de los botones; si asi no cabe, en la columna izquierda
	var sp2: Control = main_ui["sp2"]
	var cfs: int = 16 if mid else 13
	for cl2 in main_credit.get_children():
		(cl2 as Label).add_theme_font_size_override("font_size", cfs)
	# primero con credito y botones de >= 44; si no cabe, sin credito; y como ultimo recurso se compactan mas los botones
	var done := false
	for cred in [true, false]:
		main_credit.visible = cred
		if _fit_main_pass(btns, right, mv, sp2, ah, [58, 52, 48, 44]):
			done = true
			break
	if not done:
		_fit_main_pass(btns, right, mv, sp2, ah, [42, 38, 34])


func _fit_main_pass(btns: Array, right: Control, mv: Control, sp2: Control, ah: float, heights: Array) -> bool:
	for tgt in [right, main_ui["left"]]:
		if sp2.get_parent() != tgt:
			sp2.reparent(tgt, false)
		for bh in heights:
			mv.add_theme_constant_override("separation", 10 if bh >= 52 else (6 if bh >= 48 else 3))
			for b in btns:
				(b as Button).custom_minimum_size.y = bh
				(b as Button).add_theme_font_size_override("font_size", clampi(roundi(bh * 0.45), 17, 26))
				# el icono de 36 px fija el alto minimo del boton (52): al compactar se escala al alto disponible
				(b as Button).expand_icon = bh < 58
				(b as Button).add_theme_constant_override("icon_max_width", 40 if bh >= 58 else bh - 10)
			if _row_min_y(main_ui["row"]) <= ah:
				return true
	return false


# Los textos con salto de linea (autowrap) solo dan su alto real cuando ya tienen ancho: se repite el ajuste un par de fotogramas despues.
func _fit_main_late() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if is_inside_tree() and not main_ui.is_empty():
		_fit_main(DSP.area(get_tree()))


# Alto minimo de la fila principal (la mayor de sus columnas).
func _row_min_y(row: Control) -> float:
	return row.get_combined_minimum_size().y


func _fit_test(ar: Rect2) -> void:
	if test_pc != null:
		test_pc.custom_minimum_size.x = minf(820.0, ar.size.x - scr_ch.x)


# Coleccion: el panel de detalle se estrecha y las columnas de la cuadricula se ajustan al ancho (6 / 4 / 3 / 2).
func _fit_dex(ar: Rect2) -> void:
	if dex_dp == null:
		return
	var dpw: float = 360.0 if not compact else 270.0
	dex_dp.custom_minimum_size.x = dpw
	var bar: float = dex_scroll.get_v_scroll_bar().get_combined_minimum_size().x
	var rw: float = ar.size.x - scr_ch.x - dpw - 10.0 - bar
	var cols := 2
	for c in [6, 4, 3]:
		if float(c) * 118.0 + float(c - 1) * 6.0 <= rw:
			cols = c
			break
	dex_grid.columns = cols
	var fh: int = 44
	for b in dex_filters.get_children():
		(b as Control).custom_minimum_size.y = fh


# ScrollContainer cuyo tamano minimo no puede pasar de la zona util (se recalcula en cada cambio de tamano).
# center: CenterContainer a pantalla completa que se ajusta a la zona segura (cuadros flotantes).
func _fit_reg(sc: ScrollContainer, v: Control, chrome: Vector2, screen_level: bool, center: Control = null) -> void:
	fit_scrolls.append({"sc": sc, "v": v, "chrome": chrome, "screen": screen_level, "center": center})
	v.minimum_size_changed.connect(_fit_later)
	_fit_later()


# Variante: un ScrollContainer de tamano "ideal" cap que se encoge hasta lo que quede de zona util (chrome = lo que va alrededor).
func _fit_cap(sc: ScrollContainer, cap: Vector2, chrome: Vector2, center: Control = null) -> void:
	fit_scrolls.append({"sc": sc, "v": sc, "chrome": chrome, "cap": cap, "screen": false, "center": center})
	_fit_later()


func _fit_scrolls_now() -> void:
	var i: int = fit_scrolls.size() - 1
	while i >= 0:
		var e: Dictionary = fit_scrolls[i]
		var sc = e["sc"]
		var v = e["v"]
		if not is_instance_valid(sc) or not is_instance_valid(v):
			fit_scrolls.remove_at(i)
		elif e.has("cap"):
			if is_instance_valid(e["center"]):
				DSP.fit_to_safe(get_tree(), e["center"])
			var avc: Vector2 = DSP.area(get_tree(), 6.0).size - (e["chrome"] as Vector2)
			var cap: Vector2 = e["cap"]
			(sc as ScrollContainer).custom_minimum_size = Vector2(minf(cap.x, avc.x), minf(cap.y, maxf(120.0, avc.y)))
		else:
			var ch: Vector2 = e["chrome"]
			if bool(e["screen"]):
				ch += scr_ch
			elif is_instance_valid(e["center"]):
				DSP.fit_to_safe(get_tree(), e["center"])
			DSP.fit_scroll(get_tree(), sc, v, ch, 0.0 if bool(e["screen"]) else 6.0)
		i -= 1


# Cuadro flotante sobre gacha_result / un ColorRect: el contenido v va en un ScrollContainer que no pasa de la zona util.
func _pop_wrap(center: Control, pc: PanelContainer, v: Control) -> void:
	var sc := _new_scroll()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	pc.add_child(sc)
	sc.add_child(v)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sb: StyleBox = pc.get_theme_stylebox("panel")
	_fit_reg(sc, v, sb.get_minimum_size() + Vector2(8, 8), false, center)
	_fit_scrolls_now()


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
	pill_sbs.append(sbx)
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
		_gold_look(b, enabled)
		tcol = Color.WHITE if enabled else Color.BLACK
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
	b.set_meta("cl", cl)   # para cambiar el coste y el aspecto en su sitio (_cost_update)
	b.set_meta("on", enabled)
	holder.add_child(cr)
	hb.add_child(holder)
	b.add_child(hb)
	return b


# Estilos del boton dorado: activo (dorado) o apagado (arena; los estilos se crean una vez y se comparten).
var _gold_off_sbs: Array = []


func _gold_look(b: Button, enabled: bool) -> void:
	_gold_btn(b, enabled)
	if not enabled:
		if _gold_off_sbs.is_empty():
			_gold_off_sbs = [_sb(Color("#a89c82"), Color("#6b6250"), 3, 12), _sb_focus(Color("#b8ad94"))]
		for st0 in ["normal", "hover", "pressed", "disabled"]:
			b.add_theme_stylebox_override(st0, _gold_off_sbs[0])
		b.add_theme_stylebox_override("focus", _gold_off_sbs[1])


# Cambia el coste y si se puede pagar de un boton hecho con _cost_btn (gold) sin rehacerlo.
# Solo se toca lo que cambia: cada override de tema de un nodo ya en el arbol relanza su cache de tema.
func _cost_update(b: Button, cost: String, enabled: bool) -> void:
	var cl: Label = b.get_meta("cl")
	if cl.text != cost:
		cl.text = cost
	if b.disabled == (not enabled) and bool(b.get_meta("on", enabled)) == enabled:
		return
	b.set_meta("on", enabled)
	b.disabled = not enabled
	_gold_look(b, enabled)
	cl.add_theme_color_override("font_color", Color.WHITE if enabled else Color.BLACK)
	cl.add_theme_constant_override("outline_size", 5 if enabled else 0)


# Boton dorado (se puede pagar) o marron apagado (no alcanza).
# Los estilos se crean una sola vez y se comparten (antes: 5 StyleBoxFlat nuevos en cada llamada).
var _gold_sbs := {}


func _gold_btn(b: Button, on: bool) -> void:
	if not _gold_sbs.has(on):
		var c := Color("#f7b733") if on else Color("#8c7f66")
		var edge := Color("#fff4d0") if on else Color("#5b5240")
		_gold_sbs[on] = [_sb(c, edge, 3, 12), _sb_focus(c.lightened(0.15))]
	var sbs: Array = _gold_sbs[on]
	for st in ["normal", "hover", "pressed", "disabled"]:
		b.add_theme_stylebox_override(st, sbs[0])
	b.add_theme_stylebox_override("focus", sbs[1])


# Dorado si esta activo; si no, vuelve al estilo normal del tema (quita los estilos propios).
func _gold_on(b: Button, on: bool) -> void:
	if on:
		_gold_btn(b, true)
	else:
		for st in ["normal", "hover", "pressed", "disabled", "focus"]:
			b.remove_theme_stylebox_override(st)


# Estilo de tarjeta: uno solo compartido (ninguna tarjeta lo modifica).
var _card_sb_c: StyleBoxFlat = null


func _card_sb() -> StyleBoxFlat:
	if _card_sb_c == null:
		_card_sb_c = _sb(Color(0.08, 0.14, 0.36, 0.8), Color("#33498f"), 2, 14)
		_card_sb_c.content_margin_top = 12
		_card_sb_c.content_margin_bottom = 12
	return _card_sb_c


# Estilos compartidos de las tarjetas de logros / cristales Z (hecho o pendiente) y de las celdas de datos.
var _flat_sbs := {}


func _flat_sb(done: bool) -> StyleBoxFlat:
	if not _flat_sbs.has(done):
		_flat_sbs[done] = _sb(Color(0, 0, 0, 0.2), Color(1.0, 0.82, 0.25, 0.6) if done else Color(0.96, 0.97, 1.0, 0.1), 2, 8)
	return _flat_sbs[done]


# Fila [icono] texto
func _icon_label(icon: String, text: String, size: int = 22, col: Color = Color.WHITE, isz: float = 24.0, wrap: bool = false) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	var ir := IC.rect(icon, isz)
	ir.size_flags_vertical = Control.SIZE_SHRINK_BEGIN if wrap else Control.SIZE_FILL
	h.add_child(ir)
	var l := _label(text, size, col)
	# wrap: el texto largo (otros idiomas) salta de linea en vez de ensanchar el panel
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if wrap else TextServer.AUTOWRAP_OFF
	if wrap:
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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
# Si el foco no puede ir mas abajo (o arriba) pero la pagina sigue, el D-pad la desplaza a pasos de ~1/3 de alto
# (mantener pulsado acelera); en paginas sin botones (novedades, lexico, "Acerca de") desplaza aunque el foco este en las pestanas.
var scr_hold := 0         # pasos seguidos (mantener pulsado acelera)
var scr_last := 0.0
var scr_echo := false     # el evento de direccion que se esta tratando es una repeticion
var scr_pick: ScrollContainer = null    # el scroll principal de la pantalla / cuadro abierto (ver _scroll_main)
var scr_pick_key := ""
var scr_pick_free := true               # ese scroll no tiene ningun control enfocable (solo se lee)
var scr_axis_t := 0.0


func _scroll_of(c: Node) -> ScrollContainer:
	var p: Node = c.get_parent()
	while p != null and not (p is ScrollContainer):
		p = p.get_parent()
	return p as ScrollContainer


# Un paso de desplazamiento; false si ya no puede moverse. frac = parte del alto visible (1/3, o casi una pagina con L2/R2).
func _scroll_step(sc: ScrollContainer, down: bool, frac: float = 0.0) -> bool:
	var bar: ScrollBar = sc.get_v_scroll_bar()
	var mx: int = int(maxf(0.0, bar.max_value - bar.page))
	var v: int = sc.scroll_vertical
	if (down and v >= mx) or (not down and v <= 0):
		return false
	var now: float = Time.get_ticks_msec() / 1000.0
	if scr_echo or now - scr_last < 0.2:
		scr_hold += 1
	else:
		scr_hold = 0
	scr_last = now
	var step: float = clampf(sc.size.y / 3.0, 60.0, 360.0) if frac <= 0.0 else maxf(60.0, sc.size.y * frac)
	step *= 1.0 + minf(float(scr_hold) / 6.0, 2.0)
	sc.scroll_vertical = clampi(v + int(step) * (1 if down else -1), 0, mx)
	return sc.scroll_vertical != v


# Raiz donde manda la entrada: el cuadro abierto o, si no hay, la pantalla actual.
func _input_root() -> Control:
	var mr: Control = _modal_root()
	if mr != null:
		return mr
	return screens[cur] if screens.has(cur) else null


# El ScrollContainer mas grande y visible de la raiz (se guarda mientras no cambie la pantalla, el cuadro ni el numero de nodos).
func _scroll_main(root: Control) -> ScrollContainer:
	var key := "%s|%d|%d" % [cur, root.get_instance_id(), int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))]
	if key == scr_pick_key and scr_pick != null and is_instance_valid(scr_pick) and scr_pick.is_visible_in_tree():
		return scr_pick
	var best: ScrollContainer = null
	var best_a := -1.0
	var cands: Array = root.find_children("*", "ScrollContainer", true, false)
	if root is ScrollContainer:
		cands.append(root)
	for n in cands:
		var sc := n as ScrollContainer
		if not sc.is_visible_in_tree():
			continue
		var ar: float = sc.size.x * sc.size.y
		if ar > best_a:
			best_a = ar
			best = sc
	scr_pick = best
	scr_pick_key = key
	scr_pick_free = best == null or NAVG.focusables(best).is_empty()
	return best


# pre = antes de mover el foco: solo para paginas que se leen (sin botones) con el foco fuera del scroll.
# Si no, despues de que el foco no se haya podido mover.
func _scroll_text(down: bool, pre: bool) -> bool:
	if _popup_open() or listening != "":
		return false
	var root: Control = _input_root()
	if root == null:
		return false
	var f: Control = get_viewport().gui_get_focus_owner()
	var fsc: ScrollContainer = null
	if f != null and root.is_ancestor_of(f):
		fsc = _scroll_of(f)
	var sc: ScrollContainer = null
	if pre:
		if fsc != null:
			return false
		sc = _scroll_main(root)
		if sc == null or not scr_pick_free:
			return false
		if not down and sc.scroll_vertical <= 0:
			return false
	else:
		sc = fsc if fsc != null else _scroll_main(root)
	if sc == null:
		return false
	return _scroll_step(sc, down)


func _scroll_fallback(down: bool) -> bool:
	return _scroll_text(down, false)


# L2 / R2 (en la consola: Z / C) y stick derecho: pagina arriba / abajo sin mover el foco; -1 / +1, 0 si no es.
func _page_dir(event: InputEvent) -> int:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_Z:
			return -1
		if event.keycode == KEY_C:
			return 1
	elif event is InputEventJoypadMotion and absf(event.axis_value) > 0.6:
		var now: float = Time.get_ticks_msec() / 1000.0
		if (event.axis == JOY_AXIS_RIGHT_Y or event.axis == JOY_AXIS_TRIGGER_LEFT or event.axis == JOY_AXIS_TRIGGER_RIGHT) and now - scr_axis_t > 0.18:
			scr_axis_t = now
			if event.axis == JOY_AXIS_TRIGGER_LEFT:
				return -1
			if event.axis == JOY_AXIS_TRIGGER_RIGHT:
				return 1
			return 1 if event.axis_value > 0.0 else -1
	return 0


func _scroll_page(down: bool) -> bool:
	var root: Control = _input_root()
	if root == null:
		return false
	var f: Control = get_viewport().gui_get_focus_owner()
	var sc: ScrollContainer = null
	if f != null and root.is_ancestor_of(f):
		sc = _scroll_of(f)
	if cur == "dex" and sc == dex_scroll and dex_dp != null:
		sc = dex_dp.get_child(0) as ScrollContainer   # en el Pokedex L2/R2 pasan la ficha (la lista ya se recorre con el foco)
	if sc == null:
		sc = _scroll_main(root)
	return sc != null and _scroll_step(sc, down, 0.85)


# Veto de navgrid: el siguiente control queda lejos (hay texto entre medias) y fuera de la vista: primero se desplaza,
# asi el texto de en medio se lee; el foco se mueve cuando el destino ya cabe.
func _nav_veto(from: Control, to: Control, dy: int) -> bool:
	if not is_visible_in_tree():
		return false
	var sc: ScrollContainer = _scroll_of(to)
	if sc == null or not sc.is_visible_in_tree():
		return false
	var view: Rect2 = sc.get_global_rect()
	var tr: Rect2 = to.get_global_rect()
	var fr: Rect2 = from.get_global_rect()
	var from_in: bool = sc.is_ancestor_of(from)
	var gap := 0.0
	if dy > 0:
		if tr.end.y <= view.end.y + 1.0:
			return false
		gap = tr.position.y - (fr.end.y if from_in else view.position.y)
	else:
		if tr.position.y >= view.position.y - 1.0:
			return false
		gap = (fr.position.y if from_in else view.end.y) - tr.end.y
	if gap < 56.0:
		return false
	return _scroll_step(sc, dy > 0)


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
		_follow_late(p as ScrollContainer, c)


# Las paginas recien puestas terminan de repartir el alto (textos con salto de linea) un fotograma despues: se repite una vez.
func _follow_late(sc: ScrollContainer, c: Control) -> void:
	await get_tree().process_frame
	if is_instance_valid(sc) and is_instance_valid(c) and c.is_inside_tree() and c.has_focus():
		sc.ensure_control_visible(c)


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
	_screen_margins(c)
	c.visible = false
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(c)
	screens[name] = c
	return c


func _leave() -> void :
	if cur == "chal":
		_show("modes")
		return
	if cur == "store":
		_show(store_return if store_return != "store" else "up")
		return
	if is_overlay:
		closed.emit()
		queue_free()
	else:
		_show("main")


func _ensure(name: String) -> void:
	if screens.has(name):
		return
	call("_build_" + name)
	var ar: Rect2 = DSP.area(get_tree())
	match name:
		"main":
			_fit_main(ar)
			_fit_main_late.call_deferred()
		"dex":
			_fit_dex(ar)
		"test":
			_fit_test(ar)
	gi_dirty = true


func _show(name: String) -> void:
	if name == "store" and cur != "store":
		store_return = cur
	_ensure(name)
	if name == "up" and cur != "up":
		up_dex = int(SV.d["selected"])
	_close_up_picker()
	_flush_save()
	if cur != name:
		_release_screen(cur)
	cur = name
	gi_dirty = true
	pad_chk = 0.0
	if name != "dex":
		dex_pick_party = false
		dex_pick_team = false
		dex_pick_coop = false
	for k in screens:
		screens[k].visible = k == name
	back_btn.visible = name != "main" and name != "test"
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


# Al salir de una pantalla pesada se libera su contenido (las paginas guardadas de Lexico / Gacha y la lista de Misiones):
# no se queda oculto en el arbol haciendo crecer los nodos. Al volver a entrar se reconstruye.
func _release_screen(name: String) -> void:
	if not screens.has(name):
		return
	match name:
		"modes":
			_mode_prev_free()
		"lexicon":
			_fq_cancel(lex_box, true)
			lex_pages.clear()
			for ch in lex_box.get_children():
				lex_box.remove_child(ch)
				ch.queue_free()
		"gacha":
			_fq_cancel(gacha_content, true)
			gacha_pages.clear()
			for ch in gacha_content.get_children():
				gacha_content.remove_child(ch)
				ch.queue_free()
		"goals":
			_fq_cancel(goals_box, true)
			_clear(goals_box)
		"chal":
			_fq_cancel(chal_box, true)
			_clear(chal_box)
		"gachapon":
			if gp_machine == null or not gp_machine.busy():
				_clear(gp_info)
		"settings":
			_fq_cancel(settings_host, true)
			settings_pages.clear()
			for ch in settings_host.get_children():
				settings_host.remove_child(ch)
				ch.queue_free()
			settings_box = settings_host


func _gf(c: Control) -> void:
	call_deferred("_do_focus", c)


func _do_focus(c: Control) -> void:
	if is_instance_valid(c) and c.is_inside_tree() and c.is_visible_in_tree():
		c.grab_focus()
		_refocus_scroll.call_deferred(c)   # el contenido recien construido puede dejar el scroll mal colocado


func _refocus_scroll(c: Control) -> void:
	await get_tree().process_frame
	if is_instance_valid(c) and c.is_visible_in_tree() and get_viewport().gui_get_focus_owner() == c:
		_follow(c)


func _update_top() -> void:
	coin_lbl.text = "%d" % int(SV.d["coins"])
	ticket_lbl.text = "%d" % int(SV.d["tickets"])
	ticket10_lbl.text = "%d" % int(SV.d.get("tickets10", 0))
	var tt: String = String(SV.d.get("title", ""))
	name_lbl.text = _nick()
	var muted: bool = bool(SV.d["settings"].get("mute", false))
	var mn: String = "mute" if muted else "sound"
	mute_top.icon = IC.tex(mn, IC.scale_for(mn, 26))
	_fit_top()


# Problemas con el guardado (B5): si esta bloqueado, aviso fijo (sin foco, no atrapa el mando) con el motivo y por donde se
# borra; si se cargo la copia o se restauraron campos, un aviso breve, una sola vez.
func _build_save_notice() -> void:
	if is_overlay:
		return
	if SV.save_blocked:
		var why: String = SV.last_save_error.get_slice("\n", 0).strip_edges()
		if why.length() > 90:
			why = why.substr(0, 87) + "..."
		var txt: String = L.t("¡Tu progreso no se guarda!") + "\n" + L.t("El archivo de guardado está dañado o es de una versión más nueva. Para empezar de cero:") + " " + L.t("Ajustes") + " › " + L.t("Zona peligrosa") + " › " + L.t("Borrar todo el progreso")
		if why != "":
			txt += "\n" + L.t("Motivo") + ": " + why
		save_notice = PanelContainer.new()
		save_notice.set_anchors_preset(Control.PRESET_TOP_WIDE)
		save_notice.add_theme_stylebox_override("panel", _sb(Color(0.45, 0.1, 0.15, 0.94), Color("#ff7a85"), 2, 8))
		save_notice.mouse_filter = Control.MOUSE_FILTER_IGNORE
		save_notice.z_index = 48
		var lb := _label(txt, 14 if (compact or short) else 16, Color.WHITE)
		lb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		save_notice.add_child(lb)
		add_child(save_notice)
	elif not _save_toast_done and (SV.recovered_from_backup or SV.last_save_error != ""):
		_save_toast_done = true
		toast(L.t("Se ha cargado la copia de seguridad de tu partida.") if SV.recovered_from_backup else L.t("Se han restaurado algunos datos dañados de tu partida."))


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


# Guardado diferido (deslizadores): evita escribir el archivo en cada paso al mantener la direccion.
var save_t := 0.0
# Comprobacion de la ayuda de mando: no hace falta cada fotograma.
var pad_chk := 0.0


func _save_later() -> void:
	save_t = 0.5


func _flush_save() -> void:
	if save_t > 0.0:
		save_t = 0.0
		SV.save()


func _exit_tree() -> void:
	_mode_prev_free()
	_flush_save()
	for e in fq:
		if e[2] != null and is_instance_valid(e[2]):
			(e[2] as Node).free()
	fq.clear()
	# las paginas guardadas que no estan en el arbol no cuelgan de nadie: hay que liberarlas a mano
	for sn in ["lexicon", "gacha", "settings"]:
		_release_screen(sn)


func _process(delta: float) -> void:
	_pump()
	Preview.drain()
	if save_t > 0.0:
		save_t -= delta
		if save_t <= 0.0:
			save_t = 0.0
			SV.save()
	_modal_tick()
	pad_chk -= delta
	if pad_hint != null and pad_chk <= 0.0:
		pad_chk = 0.5
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
		var apx: float = (get_viewport_rect().size.x - ach_pop.size.x) * 0.5
		ach_pop.position.x = clampf(apx, ins_c.x + 8.0, maxf(ins_c.x + 8.0, get_viewport_rect().size.x - ach_pop.size.x - ins_c.z - 8.0))
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
	if sum_ov != null and is_instance_valid(sum_ov) and not sum_ov.is_queued_for_deletion():
		_close_summary()
		return
	if gacha_result != null and gacha_result.visible:
		gacha_result.visible = false
		kb_open = false
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


# Cuadro abierto encima de la pantalla (resultados de la partida, resultado del gacha / favoritos / tarjeta / nombre, selector, tragaperras):
# mientras exista, el foco y la entrada se quedan dentro de el. null si no hay ninguno.
func _modal_root() -> Control:
	if sum_ov != null and is_instance_valid(sum_ov) and not sum_ov.is_queued_for_deletion():
		return sum_ov
	if up_picker != null and is_instance_valid(up_picker):
		return up_picker
	if gacha_result != null and is_instance_valid(gacha_result) and gacha_result.visible:
		return gacha_result
	if slots_busy and slots_ui != null and is_instance_valid(slots_ui):
		return slots_ui
	return null


func _close_summary() -> void:
	if sum_ov != null and is_instance_valid(sum_ov):
		sum_ov.queue_free()
	sum_ov = null
	_update_top()
	focus_first = main_play_btn
	main_play_btn.grab_focus()


# Al cerrar un cuadro el foco vuelve al boton que lo abrio (si sigue ahi; si la pagina se rehizo, la pagina pone el suyo).
func _modal_tick() -> void:
	var mr: Control = _modal_root()
	if mr != null:
		modal_was = true
		return
	kb_open = false
	if modal_was:
		modal_was = false
		_modal_restore.call_deferred()
		return
	modal_prev = get_viewport().gui_get_focus_owner()


func _modal_restore() -> void:
	var f: Control = get_viewport().gui_get_focus_owner()
	var p: Control = modal_prev
	if (f == null or not f.is_visible_in_tree()) and p != null and is_instance_valid(p) and p.is_inside_tree() and p.is_visible_in_tree() and p.focus_mode == Control.FOCUS_ALL:
		p.grab_focus()
		_follow(p)


func _popup_open() -> bool:
	# El desplegable abierto conserva el foco: basta mirar el control enfocado (antes: find_children por todo el arbol).
	var f: Control = get_viewport().gui_get_focus_owner()
	return f is OptionButton and (f as OptionButton).get_popup().visible


# Pantallas con pestanas: L1/R1 (o Q/E, RePag/AvPag) las cambian al instante.
const TAB_SCREENS := ["settings", "goals", "lexicon", "gacha"]
const GOALS_TABS := ["m", "a", "h", "z", "p", "r"]
const LEX_TABS := ["i", "m", "f", "s", "a", "z", "k", "n"]
# Con izquierda/derecha sobre la fila de pestanas el foco se queda en la fila (se pueden encadenar);
# con L1/R1 y al pulsar una pestana el foco salta al primer elemento del contenido.
const TAB_ROW_KEEPS_FOCUS := true


# -1 / +1 si el evento es "pestana anterior / siguiente"; 0 si no.
func _tab_dir(event: InputEvent) -> int:
	if event is InputEventJoypadButton and event.pressed:
		if event.button_index == PAD.btn("prev"):
			return -1
		if event.button_index == PAD.btn("next"):
			return 1
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_Q, KEY_PAGEUP:
				return -1
			KEY_E, KEY_PAGEDOWN:
				return 1
	return 0


# Hay un cuadro encima (resultado del gacha / selector de favorito / tragaperras): las pestanas no responden.
func _tab_blocked() -> bool:
	if listening != "" or slots_busy or _popup_open() or _modal_root() != null:
		return true
	if gacha_result != null and gacha_result.visible:
		return true
	if up_picker != null and is_instance_valid(up_picker):
		return true
	var f: Control = get_viewport().gui_get_focus_owner()
	return f is LineEdit


func _tab_count() -> int:
	match cur:
		"settings":
			return SET_TABS.size()
		"goals":
			return GOALS_TABS.size()
		"lexicon":
			return LEX_TABS.size()
		"gacha":
			return SV.REGIONS.size()
	return 0


# Cambia de pestana d posiciones (con vuelta) y reconstruye solo el contenido.
func _tab_step(d: int, to_content: bool) -> void:
	var n: int = _tab_count()
	if n <= 1:
		return
	match cur:
		"settings":
			set_tab = posmod(set_tab + d, n)
			last_act = ""
			_refresh_settings()
		"goals":
			goals_tab = GOALS_TABS[posmod(GOALS_TABS.find(goals_tab) + d, n)]
			_refresh_goals()
		"lexicon":
			lex_tab = LEX_TABS[posmod(LEX_TABS.find(lex_tab) + d, n)]
			_refresh_lexicon()
		"gacha":
			gacha_region = posmod(gacha_region - 1 + d, n) + 1
			_refresh_gacha()
	_tab_scroll_top()
	Aud.sfx("hover")
	if to_content:
		_focus_content()
	elif tab_sel != null and is_instance_valid(tab_sel):
		tab_sel.grab_focus()


# Raiz del contenido de la pestana actual (lo que cambia al cambiar de pestana).
func _tab_content_root() -> Node:
	match cur:
		"settings":
			return settings_box
		"goals":
			return goals_box
		"lexicon":
			return lex_box
		"gacha":
			return gacha_content
	return null


func _tab_scroll_top() -> void:
	var root: Node = _tab_content_root()
	var p: Node = root.get_parent() if root != null else null
	while p != null and not (p is ScrollContainer):
		p = p.get_parent()
	if p != null:
		(p as ScrollContainer).scroll_vertical = 0


# Foco al primer elemento del contenido (si no hay ninguno, se queda en la pestana).
func _focus_content() -> void:
	var root: Node = _tab_content_root()
	var f: Control = null
	if root != null:
		if focus_first != null and is_instance_valid(focus_first) and root.is_ancestor_of(focus_first) and focus_first.is_visible_in_tree():
			f = focus_first
		else:
			var items: Array = NAVG.focusables(root)
			if not items.is_empty():
				f = items[0]
	if f == null:
		f = tab_sel
	if f != null and is_instance_valid(f):
		f.grab_focus()
		NAVG.sticky_for = null
		call_deferred("_follow_focus")


func _input(event: InputEvent) -> void:
	# Lo que no es una pulsacion no hace nada aqui: movimiento del raton, soltar teclas/botones...
	if event is InputEventMouse or event is InputEventScreenTouch or event is InputEventScreenDrag:
		return
	if (event is InputEventKey or event is InputEventJoypadButton) and not event.pressed:
		return
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
	# Con un cuadro abierto el foco y las direcciones no salen de el (antes seguian navegando por la pantalla de detras)
	var mr: Control = _modal_root()
	if mr != null and not _popup_open():
		var fm: Control = get_viewport().gui_get_focus_owner()
		var tabk: bool = event is InputEventKey and event.keycode == KEY_TAB
		if mr == slots_ui:
			if _dir_event(event) or tabk:
				get_viewport().set_input_as_handled()
				return
		elif (_dir_event(event) or tabk or event.is_action_pressed("ui_accept")) and (fm == null or not mr.is_ancestor_of(fm)):
			var mf: Array = NAVG.focusables(mr)
			if not mf.is_empty():
				(mf[0] as Control).grab_focus()
				_follow(mf[0])
			get_viewport().set_input_as_handled()
			return
		elif tabk:
			get_viewport().set_input_as_handled()
			return
	if kb_open and _kb_input(event):
		get_viewport().set_input_as_handled()
		return
	# L2 / R2 y stick derecho: pagina arriba / abajo
	var pgd: int = _page_dir(event)
	if pgd != 0 and not _popup_open() and listening == "":
		if _scroll_page(pgd > 0):
			get_viewport().set_input_as_handled()
			return
	# botón cíclico (Límite de FPS): izquierda / derecha cambian el valor sin salir de la fila
	if event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right"):
		var fcy: Control = get_viewport().gui_get_focus_owner()
		if fcy != null and fcy.has_meta("cycle") and not _popup_open():
			(fcy.get_meta("cycle") as Callable).call(-1 if event.is_action_pressed("ui_left") else 1)
			get_viewport().set_input_as_handled()
			return
	var on_tabs: bool = cur in TAB_SCREENS and tab_row != null and is_instance_valid(tab_row)
	if on_tabs and not _tab_blocked():
		# L1 / R1: pestana anterior / siguiente al instante, y el foco al primer elemento
		var td: int = _tab_dir(event)
		if td != 0:
			_tab_step(td, true)
			get_viewport().set_input_as_handled()
			return
		# izquierda / derecha con el foco en la fila de pestanas: cambia de pestana sin confirmar
		var lr: int = 0
		if event.is_action_pressed("ui_left", true):
			lr = -1
		elif event.is_action_pressed("ui_right", true):
			lr = 1
		if lr != 0:
			var fr: Control = get_viewport().gui_get_focus_owner()
			if fr != null and tab_row.is_ancestor_of(fr):
				_tab_step(lr, not TAB_ROW_KEEPS_FOCUS)
				get_viewport().set_input_as_handled()
				return
	if event.is_action_pressed("ui_left") and on_tabs and tab_sel != null and is_instance_valid(tab_sel):
		var f0: Control = get_viewport().gui_get_focus_owner()
		if f0 != null and not tab_row.is_ancestor_of(f0) and screens.has(cur) and screens[cur].is_ancestor_of(f0):
			var nb: Control = f0.find_valid_focus_neighbor(SIDE_LEFT)
			if nb == null or not screens[cur].is_ancestor_of(nb):
				tab_sel.grab_focus()
				get_viewport().set_input_as_handled()
				return
	# Paginas que solo se leen (novedades, lexico, "Acerca de"...): arriba / abajo desplazan aunque el foco este en las pestanas
	var vdir: bool = event.is_action_pressed("ui_down", true) or event.is_action_pressed("ui_up", true)
	scr_echo = vdir and event is InputEventKey and event.echo
	if vdir and _scroll_text(event.is_action_pressed("ui_down", true), true):
		get_viewport().set_input_as_handled()
		return
	var nav: bool = _nav_event(event)
	if _dir_event(event) and _grid_nav(event):
		get_viewport().set_input_as_handled()
		call_deferred("_follow_focus")
		return
	if vdir and _scroll_fallback(event.is_action_pressed("ui_down", true)):
		get_viewport().set_input_as_handled()
		return
	if mr != null and _dir_event(event):
		var fd: Control = get_viewport().gui_get_focus_owner()
		if not (fd is Slider or fd is OptionButton or fd is LineEdit):
			get_viewport().set_input_as_handled()   # la direccion no sale del cuadro
			return
	if nav:
		call_deferred("_follow_focus")
		if get_viewport().gui_get_focus_owner() == null:
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
# La lista de controles enfocables se guarda y solo se recalcula si cambia la pantalla, se reconstruye
# algo (_clear / _show), cambia el numero de nodos o el control enfocado no esta en ella.
var gi_cache: Array = []
var gi_key := ""
var gi_nodes := -1
var gi_dirty := true


func _grid_items() -> Array:
	var root: Node = self
	var key := "m"
	if gacha_result != null and gacha_result.visible:
		root = gacha_result
		key = "r"
	if up_picker != null and is_instance_valid(up_picker):
		root = up_picker
		key = "p"
	if sum_ov != null and is_instance_valid(sum_ov) and not sum_ov.is_queued_for_deletion():
		root = sum_ov
		key = "s"
	key += cur
	var nc: int = int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	if not gi_dirty and key == gi_key and nc == gi_nodes and _gi_valid():
		return gi_cache
	var out: Array = []
	if root == self:
		# solo lo visible: la pantalla abierta, la barra superior y los cuadros encima (no las pantallas ocultas)
		for k in get_children():
			if k is Node2D or (k is Control and not (k as Control).visible):
				continue
			if k is Control and (k as Control).focus_mode == Control.FOCUS_ALL and (k as Control).is_visible_in_tree():
				out.append(k)
			out.append_array(NAVG.focusables(k))
	else:
		out = NAVG.focusables(root)
	gi_cache = out
	gi_key = key
	gi_nodes = nc
	gi_dirty = false
	return out


# La lista guardada sigue valiendo si todos sus controles siguen vivos, visibles y activos.
func _gi_valid() -> bool:
	for c in gi_cache:
		if not is_instance_valid(c):
			return false
		var ctl := c as Control
		if not ctl.is_visible_in_tree():
			return false
		if ctl is BaseButton and (ctl as BaseButton).disabled:
			return false
	var f: Control = get_viewport().gui_get_focus_owner()
	return f == null or gi_cache.has(f) or f is LineEdit


func _grid_nav(event: InputEvent) -> bool:
	if _popup_open() or listening != "":
		return false
	return NAVG.move(get_viewport(), event, _grid_items())


# Cruceta / flechas / stick (admite repeticion al mantener la tecla).
func _dir_event(event: InputEvent) -> bool:
	return event.is_action_pressed("ui_down", true) or event.is_action_pressed("ui_up", true) or event.is_action_pressed("ui_left", true) or event.is_action_pressed("ui_right", true)


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
	if sum_ov != null and is_instance_valid(sum_ov) and not sum_ov.is_queued_for_deletion():
		root = sum_ov
	elif gacha_result != null and gacha_result.visible:
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
	gi_dirty = true


# ---------------------------------------------------------------
# Construccion por porciones
# ---------------------------------------------------------------
# Colgar cientos de nodos del arbol de golpe (tema, minimos, texto con salto de linea) costaba 10-35 ms por pantalla.
# Los trozos pesados (una tarjeta, una fila, un boton) son pasos de esta cola y _process ejecuta pasos hasta gastar
# BUD_US: ningun fotograma del menu pasa de ~2 ms (en la consola x40) y lo primero que se ve sale en el mismo fotograma.
const BUD_US := 600
var fq: Array = []   # pasos pendientes: [duenyo (Control), Callable, nodo suelto a liberar si el duenyo muere, es_liberacion]


var fq_f0 := -1   # fotograma en que la cola paso de vacia a con pasos: ese fotograma ya lleva la accion del usuario, no se carga mas


func _later(owner: Control, f: Callable, junk: Node = null, retire: bool = false, weight: int = 0) -> void:
	if fq.is_empty():
		fq_f0 = Engine.get_process_frames()
	fq.append([owner, f, junk, retire, weight])


# Ejecuta pasos hasta gastar el presupuesto. Los de un duenyo fuera del arbol (pagina guardada, pantalla oculta) esperan.
func _pump(force: bool = false) -> void:
	if fq.is_empty() or (not force and Engine.get_process_frames() == fq_f0):
		return
	var t0 := Time.get_ticks_usec()
	var i := 0
	var did := false
	var extra := 0   # coste que no se ve en el reloj: liberar un nodo se paga al final del fotograma
	while i < fq.size():
		var e: Array = fq[i]
		var ow = e[0]
		if not is_instance_valid(ow) or (ow as Node).is_queued_for_deletion():
			fq.remove_at(i)
			if e[2] != null and is_instance_valid(e[2]):
				(e[2] as Node).queue_free()
			continue
		if not (ow as Control).is_visible_in_tree() and not _bg_ok(ow as Control):
			i += 1
			continue
		fq.remove_at(i)
		(e[1] as Callable).call()
		did = true
		extra += int(e[4])
		if Time.get_ticks_usec() - t0 + extra >= BUD_US:
			break
	if did:
		gi_dirty = true


# Pagina oculta que se prepara en segundo plano (meta "bg", p. ej. las pestanas de Ajustes): sus pasos corren
# mientras su contenedor se vea.
func _bg_ok(ow: Control) -> bool:
	if not ow.has_meta("bg"):
		return false
	var pr: Control = ow.get_parent() as Control
	return pr != null and pr.is_visible_in_tree()


# Ejecuta ya todos los pasos pendientes de un contenedor (en orden), sin presupuesto.
func _fq_flush(owner: Node) -> void:
	var i := 0
	var did := false
	while i < fq.size():
		var e: Array = fq[i]
		if e[0] == owner and not bool(e[3]):
			fq.remove_at(i)
			(e[1] as Callable).call()
			did = true
		else:
			i += 1
	if did:
		gi_dirty = true


# Descarta los pasos de construccion de un contenedor que se va a rehacer (los de liberacion siguen, salvo con all).
func _fq_cancel(owner: Node, all: bool = false) -> void:
	var i := 0
	while i < fq.size():
		var e: Array = fq[i]
		if e[0] == owner and (all or not bool(e[3])):
			fq.remove_at(i)
			if e[2] != null and is_instance_valid(e[2]):
				(e[2] as Node).queue_free()
		else:
			i += 1


func _fq_pending(owner: Node) -> bool:
	for e in fq:
		if e[0] == owner:
			return true
	return false


# Libera un arbol grande poco a poco (soltar 500 nodos de golpe cuesta ~3 ms): se oculta ya y se deshace por porciones.
# holder es un contenedor que sigue en pantalla mientras tanto (de el cuelga n).
func _retire(n: Node, holder: Control) -> void:
	if n.has_meta("old"):
		return
	n.set_meta("old", true)
	if n is CanvasItem:
		(n as CanvasItem).visible = false
	var units: Array = []
	_retire_units(n, units)
	for u in units:
		var w: int = 6 * ((u as Node).find_children("*", "", true, false).size() + 1)
		_later(holder, func():
			if is_instance_valid(u):
				var pr: Node = (u as Node).get_parent()
				if pr != null:
					pr.remove_child(u)
				(u as Node).queue_free(), null, true, w)
	_later(holder, func():
		if is_instance_valid(n):
			var pr2: Node = n.get_parent()
			if pr2 != null:
				pr2.remove_child(n)
			n.queue_free(), null, true, 60)


func _retire_units(n: Node, out: Array) -> void:
	for c in n.get_children():
		if c.get_child_count() > 0 and c.find_children("*", "", true, false).size() > 24:
			_retire_units(c, out)
		else:
			out.append(c)


# Pasa los hijos de src (suelto, fuera del arbol, ya construido) a dst (en el arbol) poco a poco.
# Un hijo con meta "drip" (una cuadricula) se cuelga vacio y sus celdas van detras, una a una.
func _drip(src: Node, dst: Control) -> void:
	var hold := Node.new()   # aparca las celdas de las cuadriculas mientras tanto (cuelga de src: se libera con el)
	src.add_child(hold)
	for k in src.get_children():
		if k == hold:
			continue
		if k.has_meta("drip") and k.get_child_count() > 1:
			var cells: Array = k.get_children()
			for c in cells:
				k.remove_child(c)
				hold.add_child(c)
			_later(dst, func():
				src.remove_child(k)
				dst.add_child(k), src)
			for c2 in cells:
				_later(dst, func():
					hold.remove_child(c2)
					(k as Node).add_child(c2), src)
		else:
			_later(dst, func():
				src.remove_child(k)
				dst.add_child(k), src)
	_later(dst, func(): src.queue_free(), src)


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
	# la fila va en un ScrollContainer: _fit_main la encoge para que quepa, y si aun asi no cabe se desplaza
	main_scroll = _new_scroll()
	main_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	s.add_child(main_scroll)
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_scroll.add_child(row)
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
	main_ui["title"] = title
	main_ui["sub"] = sub
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _sb(Color("#0f1a34"), Color("#ff9a4d"), 4, 10))
	card.custom_minimum_size = Vector2(360, 260)
	card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	left.add_child(card)
	main_card = card
	main_info = _label("", 26)
	main_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	left.add_child(main_info)
	main_ui["info"] = main_info
	# credito: autor del proyecto (DiehlWierce); se oculta si no cabe (ver _fit_main)
	main_credit = VBoxContainer.new()
	main_credit.add_theme_constant_override("separation", 0)
	main_credit.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left.add_child(main_credit)
	for ct in ["Un proyecto de DiehlWierce"]:
		var cl := _label(L.t(ct), 16, Color("#ffe9a8"))
		cl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cl.add_theme_color_override("font_outline_color", Color.BLACK)
		cl.add_theme_constant_override("outline_size", 5)
		cl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cl.autowrap_mode = TextServer.AUTOWRAP_OFF   # una linea fija (el alto no depende del ancho): si falta sitio se recorta con "..."
		cl.clip_text = true
		cl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		main_credit.add_child(cl)
	# columna derecha: menu
	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(380, 0)
	row.add_child(right)
	var p := PanelContainer.new()
	right.add_child(p)
	var mv := VBoxContainer.new()
	p.add_child(mv)
	main_ui["row"] = row
	main_ui["right"] = right
	main_ui["left"] = left
	main_ui["mv"] = mv
	var mbtns: Array = []
	main_ui["btns"] = mbtns
	var entries := [["Jugar", "play", "flag"], ["Pokémon", "dex", "ball"], ["Mejoras", "up", "up"], ["Gacha", "gacha", "ballLux"], ["TM Gachapon", "gachapon", "gcoin"], ["Misiones y logros", "goals", "trophy"], ["Léxico", "lexicon", "book"], ["Ajustes", "settings", "gear"]]
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
		mbtns.append(b)
		if first:
			first = false
			main_play_btn = b
		if key == "goals":
			goals_btn = b
	main_stats = _label("", 18, Color("#c8d6ee"))
	var sp2 := PanelContainer.new()
	right.add_child(sp2)
	sp2.add_child(main_stats)
	main_ui["stats"] = main_stats
	main_ui["sp2"] = sp2
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
const MOD_ICON := {"fast": "boot", "horde": "m_horde", "tank": "shield", "hard": "fist", "frail": "heart", "nohealing": "berry", "slow": "r_heavy", "brainy": "r_scholar", "glass": "r_glass", "rich": "r_l_bag", "plague": "r_swarm"}
const MOD_INFO := {
	"fast": ["Veloces", "Los enemigos corren un 40% más rápido."],
	"horde": ["Horda", "Casi el doble de enemigos."],
	"tank": ["Resistentes", "Los enemigos tienen un 60% más de vida."],
	"hard": ["Golpes duros", "Los enemigos hacen un 50% más de daño."],
	"frail": ["Frágil", "Tu vida máxima se reduce a la mitad."],
	"nohealing": ["Sin curación", "No recuperas vida (solo la que te da subir de Vida)."],
	"slow": ["Pesado", "Te mueves un 20% más lento."],
	"brainy": ["Mente brillante", "Ganas un 50% más de experiencia, pero los enemigos tienen un 25% más de vida."],
	"glass": ["Cañón de cristal", "Haces un 50% más de daño, pero los enemigos hacen el doble."],
	"rich": ["Fiebre del oro", "Las monedas valen el doble, pero los enemigos tienen un 30% más de vida."],
	"plague": ["Plaga", "Aparecen 2,5 veces más enemigos, pero con un 35% menos de vida."],
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
	pc.add_theme_stylebox_override("panel", StyleBoxEmpty.new())   # sin panel de fondo: se ve el mundo del menu entre las tarjetas
	s.add_child(pc)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	pc.add_child(v)
	var ttl := PanelContainer.new()
	ttl.add_theme_stylebox_override("panel", _sb(Color(0.03, 0.07, 0.18, 0.86), Color("#33498f"), 2, 10))
	ttl.add_child(_label("Elige un modo", 30, C_GOLD))
	v.add_child(ttl)
	var sc := _new_scroll()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(sc)
	modes_box = VBoxContainer.new()
	modes_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	modes_box.add_theme_constant_override("separation", 14)
	sc.add_child(modes_box)


# Ancho util para el contenido de una pantalla a pantalla completa (zona util - margenes de la pantalla - panel y barra de scroll).
func _content_w() -> float:
	return DSP.area(get_tree()).size.x - scr_ch.x - 64.0


# Columnas de la lista de modos segun el ancho util: 1 en 640x480 a 140 %, 2 en ~914 de ancho, 3 a partir de ~1260.
func _modes_cols() -> int:
	if compact or get_window().size.x < 900:
		return 1   # pantallas pequenas (consolas 640x480, ventana fisica < 900 px): una columna, se leen mejor y se ve el fondo
	return DSP.cols(_content_w(), 400.0, 12.0, 3)


# Tarjeta de modo (sin colgarla): icono + titulo + descripcion; mas compacta en pantallas estrechas.
func _mode_card(title: String, desc: String, cb: Callable, icon: String = "", vid: String = "") -> Button:
	var b := Button.new()
	b.set_meta("vid", vid)
	var isz: int = 48 if compact else 64
	if icon != "":
		b.icon = IC.btn_tex(icon, isz)
		b.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_constant_override("h_separation", 12 if compact else 16)
		b.add_theme_constant_override("icon_max_width", isz)
	b.text = title + "\n" + desc
	# tarjeta semitransparente con borde: separa bien los modos y deja ver el fondo
	b.add_theme_stylebox_override("normal", _sb(Color(0.04, 0.09, 0.24, 0.84), Color("#33498f"), 2, 10))
	b.add_theme_stylebox_override("hover", _sb(Color(0.1, 0.2, 0.5, 0.9), C_GOLD, 2, 10))
	b.add_theme_stylebox_override("pressed", _sb(Color(0.07, 0.15, 0.4, 0.92), C_GOLD, 3, 10))
	b.add_theme_stylebox_override("focus", _sb(Color(0.14, 0.28, 0.68, 0.92), C_GOLD, 3, 10))
	b.custom_minimum_size = Vector2(0, 76 if compact else 92)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.size_flags_vertical = Control.SIZE_EXPAND_FILL
	b.focus_mode = Control.FOCUS_ALL
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.add_theme_font_size_override("font_size", 18 if compact else 20)
	b.pressed.connect(cb)
	b.pressed.connect(func(): Aud.sfx("click"))
	b.focus_entered.connect(func(): Aud.sfx("hover"))
	return b


# Boton auxiliar de un modo (elegir compañero, cambiar tipo...) debajo de su tarjeta.
func _mode_aux(text: String, cb: Callable) -> Button:
	var b := _btn(text, cb, Vector2(0, 48))
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.clip_text = true
	b.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	return b


# --- Vista previa en video de las tarjetas de modo ---
# Un solo VideoStreamPlayer para toda la pantalla: el flujo se carga solo para la tarjeta con el foco y se libera
# al perderlo o al salir de la pantalla. Con perf >= 1 no hay video: un fotograma fijo (assets/previews/<id>.png)
# si existe; si no, la tarjeta se queda sin vista previa.
const PREV_VID := Vector2(640.0, 360.0)
var mode_vp: VideoStreamPlayer = null
var mode_vp_slot: Control = null


func _daily_vid(ds: int) -> String:
	var dmv: String = SV.natural_start_of(SV.daily_dex(ds))
	if not ResourceLoader.exists("res://assets/previews/daily_%s.ogv" % dmv):
		dmv = String(MD.START.get(String(SV.dex_by[SV.daily_dex(ds)]["types"][0]), "tackle"))
	return "daily_" + dmv


func _mode_prev_free() -> void:
	if mode_vp != null and is_instance_valid(mode_vp):
		mode_vp.stop()
		mode_vp.stream = null
		if mode_vp.get_parent() != null:
			mode_vp.get_parent().remove_child(mode_vp)
		mode_vp.queue_free()
	mode_vp = null
	if mode_vp_slot != null and is_instance_valid(mode_vp_slot):
		for c in mode_vp_slot.get_children():
			c.queue_free()
		mode_vp_slot.visible = false
	mode_vp_slot = null


func _mode_prev_wire(cell: VBoxContainer, card: Button) -> void:
	var vid: String = String(card.get_meta("vid", ""))
	if vid == "":
		return
	var slot := Control.new()
	slot.visible = false
	slot.clip_contents = true
	slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slot.custom_minimum_size = Vector2(0, 150 if compact else 190)
	cell.add_child(slot)
	card.focus_entered.connect(func(): _mode_prev_show(slot, vid))
	card.focus_exited.connect(func():
		if mode_vp_slot == slot:
			_mode_prev_free())


func _mode_prev_show(slot: Control, vid: String) -> void:
	_mode_prev_free()
	var vpath := "res://assets/previews/%s.ogv" % vid
	if SV.perf() >= 1:
		var fpath := "res://assets/previews/%s.png" % vid
		if not ResourceLoader.exists(fpath):
			return
		var tr := TextureRect.new()
		tr.texture = load(fpath)
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tr.set_anchors_preset(Control.PRESET_FULL_RECT)
		slot.add_child(tr)
		slot.visible = true
		mode_vp_slot = slot
		return
	if not ResourceLoader.exists(vpath):
		return
	var vp := VideoStreamPlayer.new()
	vp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vp.stream = load(vpath)
	vp.expand = true
	vp.loop = true
	slot.add_child(vp)
	slot.visible = true
	mode_vp = vp
	mode_vp_slot = slot
	_mode_prev_fit()
	if not slot.resized.is_connected(_mode_prev_fit):
		slot.resized.connect(_mode_prev_fit)
	vp.play()


# Video a cubrir todo el hueco (recorta lo que sobra).
func _mode_prev_fit() -> void:
	if mode_vp == null or not is_instance_valid(mode_vp) or mode_vp_slot == null or not is_instance_valid(mode_vp_slot):
		return
	var sz: Vector2 = mode_vp_slot.size
	var k: float = maxf(sz.x / PREV_VID.x, sz.y / PREV_VID.y)
	mode_vp.size = PREV_VID * k
	mode_vp.position = (sz - mode_vp.size) * 0.5


# Un modo = tarjeta + (opcional) su boton auxiliar; las celdas se reparten en la cuadricula de modes_grid.
func _mode_cell(grid: GridContainer, card: Button, aux: Button = null) -> void:
	var cell := VBoxContainer.new()
	cell.add_theme_constant_override("separation", 4)
	cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cell.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cell.add_child(card)
	_mode_prev_wire(cell, card)
	if aux != null:
		cell.add_child(aux)
	grid.add_child(cell)


func _modes_grid(cols: int) -> GridContainer:
	var g := GridContainer.new()
	g.columns = cols
	g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if cols == 1 and get_window().size.x < 900:
		# una columna con el ancho de una de las dos: se ve el mundo del menu a los lados
		g.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		g.custom_minimum_size.x = floorf((_content_w() - 12.0) / 2.0)
	g.add_theme_constant_override("h_separation", 12)
	g.add_theme_constant_override("v_separation", 14)
	modes_box.add_child(g)
	return g


var modes_cols_now := 0


func _refresh_modes() -> void:
	_mode_prev_free()
	_fq_cancel(modes_box)
	for c in modes_box.get_children():
		_retire(c, modes_box)
	gi_dirty = true
	var mcols: int = _modes_cols()
	modes_cols_now = mcols
	var mg: GridContainer = _modes_grid(mcols)
	SV.run_mods = Array(SV.d.get("mods", []))
	# La primera tarjeta ya (recibe el foco); las demas, una por paso.
	var first: Button = _mode_card(L.t("Partida normal"), L.t("La experiencia de siempre, igual que el juego original."), func(): _start_mode("normal"), "flag", "normal")
	_mode_cell(mg, first)
	_later(modes_box, func():
		var ds: int = SV.daily_seed()
		var dd: Dictionary = SV.d.get("daily", {})
		var best: int = int(dd.get("best", 0)) if int(dd.get("date", 0)) == ds else 0
		var dm: String = SV.daily_mod(ds)
		var dtxt: String = L.t("Hoy: %s con la regla «%s» (misma para todos). +25%% de monedas.") % [_name_of(SV.daily_dex(ds)), L.t(String(MOD_INFO[dm][0]))]
		dtxt += "  " + (L.t("Tu mejor tiempo de hoy: %s") % ("%d:%02d" % [best / 60, best % 60]) if best > 0 else L.t("Aún no lo has jugado hoy."))
		_mode_cell(mg, _mode_card(L.t("Desafío diario"), dtxt, func(): _start_mode("daily"), "m_daily", _daily_vid(ds))))
	_later(modes_box, func():
		var rb: int = int(SV.d.get("rush_best", 0))
		_mode_cell(mg, _mode_card(L.t("Rush de Jefes"), L.t("Solo jefes y legendarios, uno tras otro, cada vez más fuertes. Récord: %d jefes.") % rb, func(): _start_mode("rush"), "m_rush", "rush")))
	_later(modes_box, func():
		var pd: int = SV.party_dex
		var pb: Button = _mode_aux(L.t("Elegir Pokémon de la fiesta"), func():
			dex_pick_party = true
			toast(L.t("Toca un Pokémon para la fiesta"))
			_show("dex"))
		_mode_cell(mg, _mode_card(L.t("Modo Fiesta"), L.t("Cualquier Pokémon, no puedes morir y no se guarda progreso. Pokémon: %s") % _name_of(pd), func(): _start_mode("party"), "m_party", "party"), pb))
	_later(modes_box, func():
		var cdx: int = int(SV.d.get("coop_dex", 0))
		if cdx <= 0 or not SV.dex_by.has(cdx):
			cdx = 133
			for x in SV.team_list():
				if int(x) != int(SV.d["selected"]):
					cdx = int(x)
					break
		var cb2: Button = _mode_aux(L.t("Elegir compañero"), func():
			dex_pick_coop = true
			toast(L.t("Toca el Pokémon que será tu compañero"))
			_show("dex"))
		_mode_cell(mg, _mode_card(L.t("Modo Cooperativo"), L.t("Un segundo Pokémon te acompaña y ataca solo. Si conectas un segundo mando, el jugador 2 lo mueve con su stick izquierdo. Comparte tus mejoras. -20%% de monedas. Compañero: %s") % _name_of(cdx), func(): _start_mode("coop"), "m_coop", "coop"), cb2))
	_later(modes_box, func():
		var tw: Dictionary = SV.d.get("tower", {})
		var tbest: int = int(tw.get("best", 0))
		var rel: int = SV.tower_relics()
		var tstarts: Array = [1]
		var tcl: Dictionary = tw.get("claimed", {})
		for k in range(5, TOWER_FLOORS_M, 5):
			if tcl.has(str(k)):
				tstarts.append(k + 1)
		var tcur: int = int(SV.d.get("tower_start", 1))
		if not tstarts.has(tcur):
			tcur = 1
			SV.d["tower_start"] = 1
		var tsb: Button = null
		if tstarts.size() > 1:
			tsb = _mode_aux(L.t("Piso inicial: %d") % tcur, func():
				var i: int = tstarts.find(int(SV.d.get("tower_start", 1)))
				SV.d["tower_start"] = int(tstarts[(i + 1) % tstarts.size()])
				SV.save()
				_refresh_modes())
		_mode_cell(mg, _mode_card(L.t("Torre de pisos"), _fmt_d(L.t("60 pisos, cada uno con un jefe fijo. Cada piso da un premio la primera vez y cada 5 pisos ganas una reliquia permanente (+6 de vida y +2% de ataque dentro de la Torre). Entre pisos eliges descanso y pactos de riesgo. Mejor piso: %d · Reliquias: %d / 12."), [tbest, rel]), func(): _start_mode("tower"), "m_tower", "tower"), tsb))
	_later(modes_box, func():
		var rbest: int = int(SV.d.get("rifts_best", 0))
		_mode_cell(mg, _mode_card(L.t("Contrarreloj de grietas"), L.t("8 minutos: las grietas se abren sin parar. Gana todas las peleas que puedas. +25%% de monedas. Récord: %d grietas.") % rbest, func(): _start_mode("rifts"), "m_clock", "rifts")))
	_later(modes_box, func():
		CH.st()
		for ce in [["p", "Retos permanentes", ["100 retos de 10 minutos como máximo.", "Cada uno da su premio una sola vez.", "Los más difíciles dan Gachapon Coin Dorada."], "gcoin"], ["d", "Retos diarios", ["3 retos nuevos cada día.", "Cada uno da 1 Gachapon Coin la primera vez."], "gcoin"], ["w", "Retos semanales", ["5 retos nuevos cada semana.", "Uno es de nivel Experto y da Gachapon Coin Dorada."], "gcoin_gold"]]:
			var ck: String = String(ce[0])
			_mode_cell(mg, _mode_card(L.t(String(ce[1])), " ".join((ce[2] as Array).map(func(x): return L.t(String(x)))), func():
				chal_cat = ck
				_show("chal"), String(ce[3]))))
	_later(modes_box, func():
		var ty: String = String(SV.d.get("mode_type", "fire"))
		if not TYPE_IDS.has(ty):
			ty = "fire"
		var tb: Button = _mode_aux(L.t("Cambiar tipo: %s") % L.t(String(MD.TYPE_NAME[ty])), func():
			SV.d["mode_type"] = String(TYPE_IDS[(TYPE_IDS.find(ty) + 1) % TYPE_IDS.size()])
			SV.save()
			_refresh_modes())
		_mode_cell(mg, _mode_card(L.t("Supervivencia por tipo"), L.t("Solo aparecen Pokémon de tipo %s (y sus jefes). +50%% de monedas.") % L.t(String(MD.TYPE_NAME[ty])), func(): _start_mode("type"), "m_type"), tb))
	_later(modes_box, func():
		var tl: Array = SV.team_list()
		var names: Array = []
		for x in tl:
			names.append(_name_of(int(x)))
		if SV.owned_count() >= 2:
			var eb: Button = _mode_aux(L.t("Elegir equipo (hasta 3)"), func():
				dex_pick_team = true
				SV.d["team"] = []
				toast(L.t("Toca hasta 3 Pokémon tuyos para el equipo"))
				_show("dex"))
			_mode_cell(mg, _mode_card(L.t("Modo Equipo"), L.t("Lleva hasta 3 Pokémon y cámbialos en plena partida (botón táctil de la derecha, tocando su ficha, R3 o Tab). Si uno cae, entra el siguiente; los de banca se recuperan. Equipo: %s") % ", ".join(names), func(): _start_mode("team"), "m_team", "team"), eb)
		else:
			_mode_cell(mg, _mode_card(L.t("Modo Equipo"), L.t("Necesitas al menos 2 Pokémon para formar un equipo."), func(): toast(L.t("Consigue otro Pokémon primero")), "m_team", "team")))
	var mm: Array = [null]
	_later(modes_box, func():
		modes_box.add_child(_label(L.t("Modificadores (todos los modos menos Diario y Fiesta): +25% de monedas por cada uno activo"), 22, C_GOLD))
		mm[0] = _modes_grid(mcols))
	for id in SV.MOD_IDS:
		_later(modes_box, func():
			var cb := CheckButton.new()
			cb.text = L.t(String(MOD_INFO[id][0])) + " — " + L.t(String(MOD_INFO[id][1]))
			cb.focus_mode = Control.FOCUS_ALL
			cb.icon = IC.btn_tex(String(MOD_ICON[id]), 32)
			cb.add_theme_constant_override("icon_max_width", 32)
			cb.add_theme_font_size_override("font_size", 18 if compact else 20)
			cb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			cb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			cb.custom_minimum_size = Vector2(0, 48)
			cb.button_pressed = SV.run_mods.has(id)
			cb.toggled.connect(func(on: bool):
				if on and not SV.run_mods.has(id):
					SV.run_mods.append(id)
				elif not on:
					SV.run_mods.erase(id)
				SV.d["mods"] = SV.run_mods.duplicate()
				SV.save())
			(mm[0] as Control).add_child(cb))
	focus_first = first


var chal_box: VBoxContainer
var chal_cat := "p"
var chal_diff := ""


func _build_chal() -> void:
	var s: Control = _screen("chal")
	var pc := PanelContainer.new()
	s.add_child(pc)
	var sc := _new_scroll()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	pc.add_child(sc)
	chal_box = VBoxContainer.new()
	chal_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chal_box.add_theme_constant_override("separation", 8)
	sc.add_child(chal_box)


func _coin_row(n: int, gold: bool, size: int = 26) -> HBoxContainer:
	var r := HBoxContainer.new()
	r.add_theme_constant_override("separation", 6)
	r.add_child(IC.rect("gcoin_gold" if gold else "gcoin", size))
	var l := _label("×%d" % n, int(size * 0.85), Color("#ffd23f") if gold else Color("#9fd0ff"))
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	r.add_child(l)
	return r


# Tarjeta de reto; devuelve su boton "Jugar" (null si ya esta reclamado o no esta disponible).
func _chal_card(d: Dictionary, inst: Dictionary) -> Button:
	var done: bool = CH.is_done(String(inst["key"]))
	var ok: bool = CH.available(d)
	var gold: bool = CH.reward_gold(inst)
	var dcol: Color = CH.DIFF_COL[String(d["d"])]
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", _sb(Color(0.08, 0.14, 0.36, 0.8) if ok else Color(0.1, 0.1, 0.16, 0.7), Color("#ffd23f") if (gold and ok) else Color("#33498f"), 3 if gold else 2, 14))
	chal_box.add_child(pc)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	pc.add_child(col)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	col.add_child(top)
	var num := _label("#%03d" % int(d["id"]), 16 if compact else 18, Color("#8fa3d0"))
	num.autowrap_mode = TextServer.AUTOWRAP_OFF
	top.add_child(num)
	var nm := _label(CH.name_of(d), 20 if compact else 24, Color.WHITE if ok else Color("#8a93a8"))
	nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(nm)
	var dl := _label(L.t(String(CH.DIFF_NAME[String(d["d"])])), 15 if compact else 16, dcol)
	dl.autowrap_mode = TextServer.AUTOWRAP_OFF
	top.add_child(dl)
	for ln in CH.lines(d, CH.new_metrics()):
		col.add_child(_label("• " + String(ln[0]), 16 if compact else 18, Color("#d6e2ff") if ok else Color("#7d869b")))
	for rt in CH.restrictions(d):
		col.add_child(_label("⚠ " + String(rt), 15 if compact else 17, Color("#ffb454") if ok else Color("#7d869b")))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	col.add_child(row)
	var cr := _coin_row(1, gold)
	cr.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(cr)
	var out: Button = null
	var b: Button
	if done:
		b = _btn("Reclamado", func(): pass, Vector2(180, 44))
		b.disabled = true
	elif not ok:
		b = _btn("Próximamente", func(): pass, Vector2(180, 44))
		b.disabled = true
	else:
		var ii: Dictionary = inst
		b = _btn("Jugar", func(): _chal_play(ii), Vector2(180, 44))
		out = b
	b.text = L.t(b.text)
	row.add_child(b)
	return out


func _chal_play(inst: Dictionary) -> void:
	SV.run_mode = "chal"
	SV.run_chal = inst.duplicate()
	SV.run_mods = []
	SV.run_dex = int(SV.d["selected"])
	SV.run_type = String(SV.d.get("mode_type", "fire"))
	SV.save()
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _refresh_chal() -> void:
	_fq_cancel(chal_box, true)
	_clear(chal_box)
	gi_dirty = true
	CH.st()
	var bal := HBoxContainer.new()
	bal.add_theme_constant_override("separation", 18)
	var t1 := _label(L.t("Retos de 10 minutos"), 24 if compact else 28, C_GOLD)
	t1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bal.add_child(t1)
	bal.add_child(_coin_row(int(SV.d.get("gcoins", 0)), false, 28))
	bal.add_child(_coin_row(int(SV.d.get("gold_coins", 0)), true, 28))
	chal_box.add_child(bal)
	var chips := HFlowContainer.new()
	chips.add_theme_constant_override("h_separation", 8)
	chips.add_theme_constant_override("v_separation", 8)
	chal_box.add_child(chips)
	var sel_chip: Button = null
	for c in [["p", "Permanentes"], ["d", "Diarios"], ["w", "Semanales"]]:
		var ck: String = String(c[0])
		var cb := _btn(L.t(String(c[1])), func(): chal_cat = ck; _refresh_chal(), Vector2(170, 44))
		_gold_btn(cb, ck == chal_cat)
		chips.add_child(cb)
		if ck == chal_cat:
			sel_chip = cb
			tab_sel = cb
	tab_row = chips
	var info := _label(L.t("Cada intento dura 10 minutos como máximo. Si no lo logras, no hay premio y puedes reintentar. Cada reto da su premio una sola vez."), 16, Color("#c8d6ee"))
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	chal_box.add_child(info)
	var cards: Array = []
	if chal_cat == "p":
		var dch := HFlowContainer.new()
		dch.add_theme_constant_override("h_separation", 8)
		dch.add_theme_constant_override("v_separation", 8)
		chal_box.add_child(dch)
		for f in [["", "Todos"], ["e", "Fácil"], ["n", "Normal"], ["h", "Difícil"], ["x", "Nivel experto"]]:
			var fk: String = String(f[0])
			var fb := _btn(L.t(String(f[1])), func(): chal_diff = fk; _refresh_chal(), Vector2(110, 40))
			_gold_btn(fb, fk == chal_diff)
			dch.add_child(fb)
		var done_n := 0
		for d in CH.all():
			if CH.is_done(CH.key_perm(int(d["id"]))):
				done_n += 1
		chal_box.add_child(_label(L.t("Completados: %d / 100") % done_n, 20, Color("#cfd9f5")))
		for d in CH.all():
			if chal_diff == "" or String(d["d"]) == chal_diff:
				cards.append([d, CH.instance_perm(d)])
	else:
		var wk: bool = chal_cat == "w"
		chal_box.add_child(_label(L.t("Se renuevan en %s") % CH.fmt_left(CH.secs_to_reset(wk)), 20, Color("#ffd23f")))
		for inst in (CH.weekly() if wk else CH.daily()):
			cards.append([CH.by_id(int(inst["id"])), inst])
	# Las tarjetas se construyen por tandas (100 retos permanentes de golpe congelan la consola).
	for cd in cards:
		_later(chal_box, func():
			_chal_card(cd[0], cd[1]))
	focus_first = sel_chip


var gp_machine
var gp_info: VBoxContainer
var gp_msg: Label
var gp_btn1: Button
var gp_btn2: Button
var gp_focus: Control
var gp_collection: HFlowContainer
var gp_pending: Array = []


func _build_gachapon() -> void:
	var s: Control = _screen("gachapon")
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12 if compact else 18)
	s.add_child(row)
	var lp := PanelContainer.new()
	lp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(lp)
	gp_machine = GP.Machine.new()
	gp_machine.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gp_machine.size_flags_vertical = Control.SIZE_EXPAND_FILL
	gp_machine.sfx_cb = func(n: String): Aud.sfx(n)
	gp_machine.finished.connect(_gp_finished)
	lp.add_child(gp_machine)
	var rp := PanelContainer.new()
	rp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rp.size_flags_stretch_ratio = 1.25
	row.add_child(rp)
	var sc := _new_scroll()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	rp.add_child(sc)
	gp_info = VBoxContainer.new()
	gp_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gp_info.add_theme_constant_override("separation", 8 if compact else 10)
	sc.add_child(gp_info)


func _refresh_gachapon() -> void:
	_ensure_result()
	_clear(gp_info)
	gacha_result.visible = false
	var hd := _label(L.t("Máquina TM Gachapon"), 28 if compact else 36, C_GOLD)
	hd.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	gp_info.add_child(hd)
	gp_info.add_child(_label(L.t("Inserta una Gachapon Coin y gira la palanca: te sale una cápsula con un movimiento nuevo. La moneda dorada da 2 movimientos."), 17 if compact else 21, Color("#c8d6ee")))
	var bal := HBoxContainer.new()
	bal.add_theme_constant_override("separation", 22)
	bal.add_child(_coin_row(int(SV.d.get("gcoins", 0)), false, 30))
	bal.add_child(_coin_row(int(SV.d.get("gold_coins", 0)), true, 30))
	gp_info.add_child(bal)
	var bb := VBoxContainer.new()
	bb.add_theme_constant_override("separation", 8)
	gp_info.add_child(bb)
	gp_btn1 = _btn(L.t("Usar Gachapon Coin  (1 movimiento)"), func(): _gp_insert(false), Vector2(0, 50))
	gp_btn1.icon = IC.tex("gcoin", IC.scale_for("gcoin", 28))
	gp_btn1.add_theme_font_size_override("font_size", 18 if compact else 22)
	bb.add_child(gp_btn1)
	gp_btn2 = _btn(L.t("Usar Gachapon Coin dorada  (2 movimientos)"), func(): _gp_insert(true), Vector2(0, 50))
	gp_btn2.icon = IC.tex("gcoin_gold", IC.scale_for("gcoin_gold", 28))
	gp_btn2.add_theme_font_size_override("font_size", 18 if compact else 22)
	bb.add_child(gp_btn2)
	gp_btn1.disabled = int(SV.d.get("gcoins", 0)) <= 0
	gp_btn2.disabled = int(SV.d.get("gold_coins", 0)) <= 0
	gp_msg = _label("", 18, Color("#ff9a8a"))
	gp_info.add_child(gp_msg)
	if gp_btn1.disabled and gp_btn2.disabled:
		gp_msg.text = L.t("No tienes monedas. Consigue Gachapon Coins superando retos.")
	elif GP.locked_ids().is_empty():
		gp_msg.text = L.t("¡Ya desbloqueaste todos los movimientos de la máquina!")
	var tot: int = GP.DATA.MOVES.size()
	gp_info.add_child(_label(L.t("Movimientos desbloqueados: %d / %d") % [GP.unlocked().size(), tot], 20 if compact else 24, C_GOLD))
	gp_collection = HFlowContainer.new()
	gp_collection.add_theme_constant_override("h_separation", 8)
	gp_collection.add_theme_constant_override("v_separation", 8)
	gp_info.add_child(gp_collection)
	for m in GP.DATA.MOVES:
		var d = GP.Disc.new(GP.type_color(String(m["type"])), 40.0 if compact else 46.0)
		d.locked = not GP.is_unlocked(String(m["id"]))
		d.tooltip_text = "" if d.locked else String(m["name"])
		gp_collection.add_child(d)
	gp_focus = gp_btn1 if not gp_btn1.disabled else (gp_btn2 if not gp_btn2.disabled else null)
	focus_first = gp_focus


func _gp_insert(gold: bool) -> void:
	if gp_machine.busy():
		return
	var got: Array = GP.spend(gold)
	if got.is_empty():
		gp_msg.text = L.t("No se pudo usar la moneda.")
		return
	gp_pending = got
	var cols: Array = []
	for id in got:
		cols.append(GP.type_color(String(GP.def_of(String(id))["type"])))
	gp_btn1.disabled = true
	gp_btn2.disabled = true
	gp_machine.play(gold, cols)
	_update_top()


func _gp_finished() -> void:
	var rows: Array = gp_pending
	gp_pending = []
	if cur != "gachapon":
		return
	_ensure_result()
	_clear(gacha_result)
	gacha_result.visible = true
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	gacha_result.add_child(cc)
	var pc := PanelContainer.new()
	pc.custom_minimum_size = Vector2(minf(620.0, DSP.area(get_tree()).size.x - 40.0), 0)
	cc.add_child(pc)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10 if compact else 14)
	pc.add_child(v)
	var tt := _label(L.t("¡Movimiento desbloqueado!") if rows.size() == 1 else L.t("¡Movimientos desbloqueados!"), 28 if compact else 34, C_GOLD)
	tt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(tt)
	for id in rows:
		var m: Dictionary = GP.def_of(String(id))
		var col: Color = GP.type_color(String(m["type"]))
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 16)
		v.add_child(hb)
		hb.add_child(GP.Disc.new(col, 64.0 if compact else 84.0))
		var vb := VBoxContainer.new()
		vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hb.add_child(vb)
		vb.add_child(_label(String(m["name"]), 24 if compact else 28, col.lightened(0.25)))
		vb.add_child(_label(L.t("Tipo: %s") % L.t(String(MD.TYPE_NAME[String(m["type"])])), 18, Color("#c8d6ee")))
		vb.add_child(_label(String(m["desc"]), 18 if compact else 20))
	var ok := _btn(L.t("Aceptar"), func():
		gacha_result.visible = false
		_refresh_gachapon()
		_gf(gp_focus if gp_focus != null else back_btn), Vector2(220, 52))
	ok.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(ok)
	gi_dirty = true
	_gf(ok)


func _refresh_main() -> void:
	var dex: int = int(SV.d["selected"])
	if not SV.owns(dex) and SV.owned_count() > 0:
		dex = int(SV.d["owned"].keys()[0])
		SV.d["selected"] = dex
	var shn: bool = bool(SV.d["shiny_on"]) and SV.owns(dex) and bool(SV.d["owned"][str(dex)]["shiny"])
	if not is_instance_valid(main_prev):   # el retrato se crea una vez; si el Pokemon no cambia, setup no hace nada
		main_prev = Preview.new()   # como en el original: el fondo vivo vuelve a estar tambien en la consola
		main_prev.custom_minimum_size = main_prev_min
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
	sum_ov = ov
	var c := CenterContainer.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	ov.add_child(c)
	var pc := PanelContainer.new()
	pc.custom_minimum_size = Vector2(620, 0)
	pc.add_theme_stylebox_override("panel", _sb(Color("#27489a"), Color("#f4f8ff"), 3, 14))
	c.add_child(pc)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 3)
	_pop_wrap(c, pc, v)
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
	var cc := _sum_coins_box(r)
	var mid := HBoxContainer.new()
	mid.add_theme_constant_override("separation", 8)
	cc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.add_child(cc)
	v.add_child(mid)
	if int(r["tickets"]) > 0 or int(r.get("tickets10", 0)) > 0:
		mid.add_child(_sum_tickets_box(r))
	var mc := _sum_moves_box(r, c)
	v.add_child(mc)
	if bool(r.get("record", false)):
		var rl := _label("¡Nuevo récord de tiempo!", 22, C_GOLD)
		rl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(rl)
	var ok := _btn("Volver al menú", func(): _close_summary(), Vector2(260, 56))
	ok.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(ok)
	_gf(ok)
	_update_top()


# Resumen de partida: monedas ganadas con desglose.
func _sum_coins_box(r: Dictionary) -> PanelContainer:
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
	return cc


# Resumen de partida: tickets del gacha ganados.
func _sum_tickets_box(r: Dictionary) -> PanelContainer:
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
	return tc


# Resumen de partida: dano y derrotas por movimiento (filas por porciones; c se muestra al terminar).
func _sum_moves_box(r: Dictionary, c: Control) -> PanelContainer:
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
		var msc := _new_scroll()
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
	# Las filas entran por porciones (cada una lleva icono y tres textos); el cuadro se muestra cuando estan todas,
	# para que no se mueva al ir creciendo.
	c.modulate.a = 0.0
	for m in mlist:
		_later(mg, func():
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
			mg.add_child(kl))
	if int(r.get("ally_dmg", 0)) > 0 or int(r.get("ally_kills", 0)) > 0:
		_later(mg, func():
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
			mg.add_child(ak))
	if int(r.get("other_dmg", 0)) > 0 or int(r.get("other_kills", 0)) > 0:
		_later(mg, func():
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
			mg.add_child(ok2))
	_later(mg, func(): c.modulate.a = 1.0)
	return mc



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
	test_pc = pc
	test_box = VBoxContainer.new()
	test_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# preguntas y resultado pueden ser mas altos que la zona util: el contenido va en un scroll
	var tsc := _new_scroll()
	tsc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	pc.add_child(tsc)
	tsc.add_child(test_box)
	_fit_reg(tsc, test_box, pc.get_theme_stylebox("panel").get_minimum_size(), true)


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
	dex_dp = dp
	dex_detail = VBoxContainer.new()
	dex_detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# la ficha puede ser mas alta que la zona util: va en un scroll (con mando, el foco desplaza)
	var dsc := _new_scroll()
	dsc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	dp.add_child(dsc)
	dsc.add_child(dex_detail)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(right)
	var filters := HFlowContainer.new()
	filters.add_theme_constant_override("h_separation", 6)
	right.add_child(filters)
	dex_filters = filters
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
	var so := OptionButton.new()
	so.custom_minimum_size = Vector2(190, 40)
	so.add_theme_font_size_override("font_size", 16)
	for o in ["Número (asc.)", "Número (desc.)", "Nombre (A-Z)", "Rareza", "Favoritos primero"]:
		so.add_item(L.t(String(o)))
	so.select(dex_sort)
	so.item_selected.connect(func(ix: int): dex_sort = ix; dex_page = 0; _refresh_dex())
	filters.add_child(so)
	dex_grid = GridContainer.new()
	dex_grid.columns = 6   # _fit_dex lo ajusta al ancho disponible
	dex_grid.add_theme_constant_override("h_separation", 6)
	dex_grid.add_theme_constant_override("v_separation", 6)
	dex_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dex_scroll = _new_scroll()
	dex_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	dex_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(dex_scroll)
	dex_scroll.add_child(dex_grid)
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
	match dex_sort:
		1:
			out.sort_custom(func(a, b): return int(a["dex"]) > int(b["dex"]))
		2:
			out.sort_custom(func(a, b): return L.t(String(a["name"])) < L.t(String(b["name"])))
		3:
			out.sort_custom(func(a, b): return int(a["rarity"]) > int(b["rarity"]) or (int(a["rarity"]) == int(b["rarity"]) and int(a["dex"]) < int(b["dex"])))
		4:
			out.sort_custom(func(a, b):
				var fa: bool = _is_fav(int(a["dex"]))
				var fb: bool = _is_fav(int(b["dex"]))
				return (fa and not fb) or (fa == fb and int(a["dex"]) < int(b["dex"])))
	return out


func _is_fav(dx: int) -> bool:
	return Dictionary(SV.d.get("dex_fav", {})).has(str(dx))


func _fav_toggle(dx: int) -> void:
	var fv: Dictionary = Dictionary(SV.d.get("dex_fav", {}))
	if fv.has(str(dx)):
		fv.erase(str(dx))
	else:
		fv[str(dx)] = true
	SV.d["dex_fav"] = fv
	SV.save()
	_dex_detail()
	if is_instance_valid(dex_heart):
		dex_heart.grab_focus()


func _refresh_dex() -> void:
	var list: Array = _dex_filtered()
	var pages: int = maxi(1, ceili(float(list.size()) / float(PER_PAGE)))
	dex_page = clampi(dex_page, 0, pages - 1)
	_fq_cancel(dex_grid)
	_clear(dex_grid)
	var lo: int = dex_page * PER_PAGE
	var hi: int = mini(list.size(), (dex_page + 1) * PER_PAGE)
	# las hojas de los iconos se leen y decodifican en segundo plano mientras se van colgando los botones
	for i in range(lo, hi):
		var dxp: int = int(list[i]["dex"])
		Preview.prefetch(dxp, SV.owns(dxp) and bool(SV.d["owned"][str(dxp)]["shiny"]) and bool(SV.d["shiny_on"]))
	var first: Button = null
	for i in range(lo, hi):
		var mk := func():
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
			b.clip_text = true   # el nombre largo (otros idiomas) se recorta con "..." en vez de ensanchar la columna
			b.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			if not owned and not dex_pick_party:
				for k in ["icon_normal_color", "icon_hover_color", "icon_pressed_color", "icon_focus_color"]:
					b.add_theme_color_override(k, Color(0, 0, 0, 0.85))
			if owned and _is_fav(dx):
				b.add_theme_stylebox_override("normal", _sb(Color("#4a2a4a"), Color("#ff4d6d"), 2))
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
			return b
		if i == lo:
			first = mk.call()   # el primero ya, para dar foco; el resto por porciones
		else:
			_later(dex_grid, mk)
		if i == lo:
			_later(dex_grid, func(): _dex_detail())   # la ficha va justo despues del primer boton
	dex_page_lbl.text = L.t("Página %d / %d  (%d)") % [dex_page + 1, pages, list.size()]
	if not SV.dex_by.has(dex_sel) or not SV.owns(dex_sel):
		dex_sel = int(SV.d["selected"])
	if hi <= lo:
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
	var nrow := HBoxContainer.new()
	nrow.add_theme_constant_override("separation", 8)
	dex_detail.add_child(nrow)
	var nlb := _label("#%d  %s" % [dx, L.t(String(p["name"]))], 30, C_GOLD)
	nlb.autowrap_mode = TextServer.AUTOWRAP_OFF
	nlb.clip_text = true
	nlb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nrow.add_child(nlb)
	var hb := Button.new()
	hb.flat = true
	hb.icon = IC.btn_tex("heart", 28.0)
	hb.add_theme_constant_override("icon_max_width", 28)
	hb.custom_minimum_size = Vector2(44, 40)
	hb.modulate = Color(1, 0.3, 0.42) if _is_fav(dx) else Color(0.55, 0.6, 0.8, 0.9)
	hb.pressed.connect(func(): _fav_toggle(dx))
	nrow.add_child(hb)
	dex_heart = hb
	var trow := HBoxContainer.new()
	trow.add_theme_constant_override("separation", 6)
	for t in SV.dex_by[dx]["types"]:
		trow.add_child(IC.rect("type:" + String(t), 32))
	var tlb := _label(_type_text(dx), 22)
	tlb.autowrap_mode = TextServer.AUTOWRAP_OFF
	trow.add_child(tlb)
	dex_detail.add_child(trow)
	dex_detail.add_child(_label(L.t("PS %d · Velocidad %d · Ataque x%.2f") % [int(p["hp"]), int(p["spd"]), float(p["atk"])], 18, Color("#c8d6ee")))
	var nature: Dictionary = SV.nature_of(dx)
	var nature_name: String = L.t(String(nature["name"]))
	dex_detail.add_child(_label(L.t("Naturaleza: %s") % nature_name, 18, Color("#ffd98a")))
	dex_detail.add_child(_label(L.t("Vida x%.2f · Ataque x%.2f · Velocidad x%.2f") % [float(nature["hp"]), float(nature["atk"]), float(nature["spd"])], 15, Color("#c8d6ee")))
	var mint_use := _btn(L.t("Usar menta de naturaleza (%d)") % int(SV.d.get("nature_mints", 0)), func(): _use_nature_mint(dx), Vector2(0, 42))
	mint_use.disabled = int(SV.d.get("nature_mints", 0)) <= 0
	dex_detail.add_child(mint_use)
	var abd: Dictionary = AB.FX[AB.of(dx)]
	dex_detail.add_child(_label(L.t("Habilidad: %s") % L.t(String(abd["name"])), 18, Color("#ffd98a")))
	dex_detail.add_child(_label(L.t(String(abd["desc"])), 15, Color("#c8d6ee")))
	var capsule_use := _btn(L.t("Usar cápsula para cambiar habilidad (%d)") % int(SV.d.get("ability_capsules", 0)), func(): _use_ability_capsule(dx), Vector2(0, 44))
	capsule_use.disabled = int(SV.d.get("ability_capsules", 0)) <= 0
	dex_detail.add_child(capsule_use)
	dex_detail.add_child(_btn(L.t("Abrir tienda diaria"), func(): _show("store"), Vector2(0, 44)))
	var zl: Array = SV.zm_types(dx)
	if zl.is_empty():
		dex_detail.add_child(_label(L.t("Movimiento Z: bloqueado (derrota %d Pokémon de su tipo)") % ZM.NEED, 15, Color("#8a96b0")))
	else:
		var zcur: String = SV.zm_type_for(dx)
		dex_detail.add_child(_icon_label("zc:" + zcur, L.t("Movimiento Z: %s") % L.t(String(ZM.DEF[zcur]["name"])), 18, Color("#ffb86b"), 32.0, true))
		if zl.size() > 1:
			dex_detail.add_child(_btn(L.t("Cambiar movimiento Z"), func():
				var nx: String = String(zl[(zl.find(zcur) + 1) % zl.size()])
				SV.d["pz"][str(dx)] = nx
				SV.save()
				_dex_detail(), Vector2(0, 46)))
	var mv: String = SV.start_move_of(dx)
	dex_detail.add_child(_icon_label("move:" + mv, L.t("Movimiento inicial: %s") % L.t(String(MD.MOVES[mv]["name"])), 18, Color("#c8d6ee"), 32.0, true))
	var teachable: Array = SV.teachable_moves(dx)
	if not teachable.is_empty():
		dex_detail.add_child(_label(L.t("Enseñar movimiento con TM · 400 monedas"), 17, C_GOLD))
		var tm_pick := OptionButton.new()
		tm_pick.custom_minimum_size = Vector2(0, 44)
		tm_pick.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		teachable.sort_custom(func(a, b): return L.t(String(MD.MOVES[a]["name"])) < L.t(String(MD.MOVES[b]["name"])) )
		for id in teachable:
			tm_pick.add_item(L.t(String(MD.MOVES[id]["name"])))
			tm_pick.set_item_metadata(tm_pick.item_count - 1, String(id))
		dex_detail.add_child(tm_pick)
		dex_detail.add_child(_btn(L.t("Comprar y enseñar"), func(): _buy_and_teach_tm(dx, tm_pick), Vector2(0, 44)))
	for id in Array(SV.d.get("learned_tms", {}).get(str(dx), [])):
		dex_detail.add_child(_icon_label("move:" + String(id), L.t("TM aprendida: %s") % L.t(String(MD.MOVES[String(id)]["name"])), 16, Color("#a8e6cf"), 28.0, true))
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


func _use_ability_capsule(dex: int) -> void:
	if SV.use_ability_capsule(dex):
		Aud.sfx("select")
		_dex_detail()
	else:
		Aud.sfx("error")


func _use_nature_mint(dex: int) -> void:
	if SV.use_nature_mint(dex):
		Aud.sfx("select")
		_dex_detail()
	else:
		Aud.sfx("error")


func _buy_and_teach_tm(dex: int, picker: OptionButton) -> void:
	if picker.item_count <= 0:
		return
	var move_id: String = String(picker.get_item_metadata(picker.selected))
	if SV.buy_and_teach_tm(dex, move_id):
		Aud.sfx("coin")
		_dex_detail()
	else:
		Aud.sfx("error")
		toast(L.t("No tienes suficientes Pokémonedas."))


# ---------------------------------------------------------------
# Mejoras permanentes
# ---------------------------------------------------------------
func _build_store() -> void:
	var s: Control = _screen("store")
	var pc := PanelContainer.new()
	s.add_child(pc)
	var v := VBoxContainer.new()
	pc.add_child(v)
	v.add_child(_label(L.t("Tienda diaria"), 32, C_GOLD))
	var sc := _new_scroll()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(sc)
	store_box = VBoxContainer.new()
	store_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	store_box.add_theme_constant_override("separation", 10)
	sc.add_child(store_box)


func _refresh_store() -> void:
	if store_box == null:
		return
	_clear(store_box)
	var owned: Array = []
	for key in SV.d.get("owned", {}).keys():
		owned.append(int(key))
	owned.sort()
	if owned.is_empty():
		store_box.add_child(_label(L.t("Consigue un Pokémon para usar la tienda."), 20))
		return
	if not owned.has(store_dex):
		store_dex = int(SV.d.get("selected", owned[0]))
		if not owned.has(store_dex):
			store_dex = int(owned[0])
	var picker := OptionButton.new()
	picker.custom_minimum_size = Vector2(0, 48)
	for dex in owned:
		var species: Dictionary = SV.dex_by[int(dex)]
		picker.add_item("#%d %s" % [int(dex), L.t(String(species["name"]))])
		picker.set_item_metadata(picker.item_count - 1, int(dex))
		if int(dex) == store_dex:
			picker.select(picker.item_count - 1)
	picker.item_selected.connect(func(index: int):
		store_dex = int(picker.get_item_metadata(index))
		_refresh_store())
	store_box.add_child(_label(L.t("Elige un Pokémon para aprender TM"), 19, Color("#c8d6ee")))
	store_box.add_child(picker)
	store_box.add_child(_label(L.t("Pokémonedas: %d") % int(SV.d.get("coins", 0)), 18, C_GOLD))
	store_box.add_child(_btn(L.t("Comprar menta de naturaleza · 350 monedas"), func(): _buy_store_mint(), Vector2(0, 44)))
	store_box.add_child(_btn(L.t("Comprar cápsula · 400 monedas"), func(): _buy_store_capsule(), Vector2(0, 44)))
	store_box.add_child(_label(L.t("TMs del día"), 24, C_GOLD))
	var stock: Array = SV.daily_tm_stock(store_dex)
	var teachable: Array = SV.teachable_moves(store_dex)
	if stock.is_empty():
		store_box.add_child(_label(L.t("No hay movimientos disponibles para este Pokémon."), 18))
	else:
		for move_id in stock:
			var id := String(move_id)
			var name := L.t(String(MD.MOVES[id]["name"]))
			var button := _btn(L.t("TM: %s · 250 monedas") % name, func(): _buy_daily_tm(store_dex, id), Vector2(0, 44))
			button.disabled = not teachable.has(id) or int(SV.d.get("coins", 0)) < 250
			store_box.add_child(button)
	if store_box.get_child_count() > 0:
		focus_first = store_box.get_child(1) as Control
		call_deferred("_gf", focus_first)


func _buy_store_mint() -> void:
	if SV.buy_nature_mint():
		Aud.sfx("coin")
		_refresh_store()
		_update_top()
	else:
		Aud.sfx("error")
		toast(L.t("No tienes suficientes Pokémonedas."))


func _buy_store_capsule() -> void:
	if SV.buy_ability_capsule():
		Aud.sfx("coin")
		_refresh_store()
		_update_top()
	else:
		Aud.sfx("error")
		toast(L.t("No tienes suficientes Pokémonedas."))


func _buy_daily_tm(dex: int, id: String) -> void:
	if SV.buy_and_teach_tm(dex, id, 250):
		Aud.sfx("coin")
		_refresh_store()
		_update_top()
	else:
		Aud.sfx("error")
		toast(L.t("No tienes suficientes Pokémonedas."))


func _build_up() -> void:
	var s: Control = _screen("up")
	var pc := PanelContainer.new()
	s.add_child(pc)
	var v := VBoxContainer.new()
	pc.add_child(v)
	v.add_child(_label("Mejoras permanentes", 32, C_GOLD))
	v.add_child(_btn(L.t("Abrir tienda diaria"), func(): _show("store"), Vector2(0, 48)))
	var sc := _new_scroll()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(sc)
	up_box = VBoxContainer.new()
	up_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	up_box.add_theme_constant_override("separation", 12)
	sc.add_child(up_box)


const UP_ICON := {"hp": "heart", "atk": "fist", "spd": "boot", "cd": "clock", "def": "shield", "regen": "sprout", "magnet": "magnet", "xp": "book", "coins": "coin", "moves": "cards", "crit": "star", "size": "size", "reroll": "bond", "ban": "ban", "revive": "revive", "bag": "bag", "bag3": "bag", "tm": "tm", "wslot": "cards"}



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
	# la reconstruccion llega por porciones: se espera a que termine (como mucho ~2 s)
	var guard := 0
	while (_fq_pending(up_box) or _fq_pending(up_tail)) and guard < 90:
		guard += 1
		await get_tree().process_frame
	if not is_instance_valid(up_box) or cur != "up":
		return
	if sc != null:
		sc.scroll_vertical = sv
	var cand: Array = []
	for b in up_box.find_children("*", "Control", true, false):
		if b is BaseButton or b is OptionButton:
			if not b.is_queued_for_deletion() and b.is_visible_in_tree():
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


# Lo que decide la estructura de las tarjetas: si coincide con lo construido solo se actualizan los valores.
func _up_sig(cols: int) -> String:
	# La estructura de las tarjetas no cambia al alcanzar el nivel maximo: se actualiza el mismo boton.
	return "%d_%d_%d_%d_%d" % [lay_gen, cols, int(up_dex == int(SV.d["selected"])), int(SV.up_level("tm", up_dex) > 0), int(SV.up_level("ban", up_dex) > 0)]


func _refresh_up() -> void:
	if not SV.owns(up_dex):
		up_dex = int(SV.d["selected"])
	var cols: int = maxi(2, DSP.cols(_content_w(), 340.0, 10.0, 3))
	var sg := _up_sig(cols)
	if sg == up_sig and up_box.get_child_count() > 0 and not _fq_pending(up_box):
		_up_update()
	else:
		_up_build(cols, sg)
	_up_tail()


func _up_head_text() -> String:
	var par0: String = L.t(" (compañero)") if up_dex == int(SV.d["selected"]) else ""
	return L.t("%s%s · %d niveles") % [_name_of(up_dex), par0, SV.up_total(up_dex)] + "  ▾"


func _up_type_col() -> Color:
	var tcol := Color("#ff7b3d")
	var types: Array = SV.dex_by[up_dex]["types"]
	if not types.is_empty():
		tcol = Color.html(String(MD.TYPE_COLOR.get(String(types[0]), "#ff7b3d")))
	return tcol


# Primera construccion (o cambio de estructura): cabecera ya, tarjetas por porciones.
func _up_build(cols: int, sg: String) -> void:
	_fq_cancel(up_box)
	for c in up_box.get_children():
		_retire(c, up_box)
	up_sig = sg
	up_cards = []
	up_ui = {}
	up_tail_key = ""
	focus_first = null
	# --- cabecera: retrato animado + selector de Pokemon
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 16)
	up_box.add_child(head)
	var por := Portrait.new()
	por.custom_minimum_size = Vector2(190, 160)
	head.add_child(por)
	por.setup(up_dex, _up_type_col())
	var hv := VBoxContainer.new()
	hv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hv.alignment = BoxContainer.ALIGNMENT_CENTER
	head.add_child(hv)
	hv.add_child(_label("Cada Pokémon tiene sus propias mejoras: solo cuentan cuando juegas con él.", 20, Color("#c8d6ee")))
	var orow := HBoxContainer.new()
	hv.add_child(orow)
	var owned: Array = _up_owned()
	var prev_b := _btn("◀", func(): _up_step(-1), Vector2(64, 56))
	prev_b.set_meta("fk", "upprev")
	orow.add_child(prev_b)
	var pick_b := _btn(_up_head_text(), _open_up_picker, Vector2(120 if compact else 360, 56))
	pick_b.set_meta("fk", "uppick")
	pick_b.clip_text = true   # el nombre largo se recorta en vez de ensanchar la pantalla
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
		# en pantallas estrechas va debajo (a 140 % no cabe junto al selector)
		if compact:
			hv.add_child(pb)
		else:
			orow.add_child(pb)
	up_ui = {"por": por, "pick": pick_b, "prev": prev_b, "next": next_b, "dex": up_dex}
	# --- tarjetas de mejoras
	var grid := GridContainer.new()
	grid.columns = cols
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 12)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	up_box.add_child(grid)
	up_tail = VBoxContainer.new()
	up_tail.add_theme_constant_override("separation", 12)
	up_box.add_child(up_tail)
	# la primera mejora que se puede pagar recibe el foco cuando se construye su tarjeta
	up_focus_id = ""
	for u0 in SV.UPGRADES:
		var lv0: int = SV.up_level(String(u0["id"]), up_dex)
		if lv0 < int(u0["max"]) and int(SV.d["coins"]) >= SV.up_cost(String(u0["id"]), lv0):
			up_focus_id = String(u0["id"])
			break
	var n_cards: int = SV.UPGRADES.size()
	for ci in range(n_cards):
		_later(up_box, func(): _up_card(grid, SV.UPGRADES[ci]))
	_later(up_box, func(): _up_wire(cols))


func _up_card(grid: GridContainer, u: Dictionary) -> void:
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
	var cost: int = SV.up_cost(id, lv) if lv < mx else 0
	var btn := _cost_btn("", str(cost), "", "coin", func(): _buy(id), Vector2(120, 52), lv < mx and int(SV.d["coins"]) >= cost, false, true)
	btn.set_meta("fk", "u:" + id)
	btn.set_meta("maxed", false)
	_up_button_update(btn, id, lv, mx)
	if lv < mx and id == up_focus_id:
		focus_first = btn
		up_focus_id = ""
		if cur == "up" and get_viewport().gui_get_focus_owner() == null:
			_gf(btn)
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var ent := {"id": id, "u": u, "pips": pips, "btn": btn, "extra": null}
	if id == "tm" and lv > 0:
		var tmcol := VBoxContainer.new()
		tmcol.add_theme_constant_override("separation", 6)
		tmcol.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var et := _btn(L.t("Elegir"), func(): tm_open = not tm_open; _refresh_up_keep("tmelegir"), Vector2(120, 44))
		et.set_meta("fk", "tmelegir")
		ent["extra"] = et
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
		ent["extra"] = eb
		bcol.add_child(eb)
		bcol.add_child(btn)
		row.add_child(bcol)
	else:
		row.add_child(btn)
	up_cards.append(ent)


# Izquierda/derecha: cicla dentro de la fila de tarjetas (con vuelta al otro extremo).
func _up_wire(ncol: int) -> void:
	var ri := 0
	while ri < up_cards.size():
		var rowb: Array = []
		var rowx: Array = []
		for ci in range(ncol):
			if ri + ci < up_cards.size():
				var ent: Dictionary = up_cards[ri + ci]
				var bt: Button = ent["btn"]
				if not bt.disabled:
					rowb.append(bt)
					rowx.append(ent["extra"])
				else:
					bt.focus_neighbor_left = NodePath()
					bt.focus_neighbor_right = NodePath()
		for k in range(rowb.size()):
			var nxt: Control = rowb[(k + 1) % rowb.size()]
			var prv: Control = rowb[posmod(k - 1, rowb.size())]
			for bb in [rowb[k], rowx[k]]:
				if bb == null:
					continue
				bb.focus_neighbor_right = bb.get_path_to(nxt)
				bb.focus_neighbor_left = bb.get_path_to(prv)
		ri += ncol


# Misma estructura que la construida: solo cambian los valores (niveles, costes, nombre), sin tocar el arbol.
func _up_update() -> void:
	var owned: Array = _up_owned()
	if int(up_ui["dex"]) != up_dex:
		up_ui["dex"] = up_dex
		(up_ui["por"] as Portrait).setup(up_dex, _up_type_col())
	(up_ui["pick"] as Button).text = _up_head_text()
	(up_ui["prev"] as Button).disabled = owned.size() < 2
	(up_ui["next"] as Button).disabled = owned.size() < 2
	focus_first = null
	for ent in up_cards:
		var u: Dictionary = ent["u"]
		var id: String = String(ent["id"])
		var lv: int = SV.up_level(id, up_dex)
		if (ent["pips"] as Pips).lv != lv:
			(ent["pips"] as Pips).setup(lv, int(u["max"]))
		var bt: Button = ent["btn"]
		_up_button_update(bt, id, lv, int(u["max"]))
		if focus_first == null and not bt.disabled:
			focus_first = bt
		if id == "ban" and ent["extra"] != null:
			(ent["extra"] as Button).text = L.t("Elegir (%d/%d)") % [mini(SV.ban_list(up_dex).size(), lv), lv]
	_up_wire(maxi(2, DSP.cols(_content_w(), 340.0, 10.0, 3)))
	gi_dirty = true


func _up_button_update(bt: Button, id: String, lv: int, mx: int) -> void:
	var cl: Label = bt.get_meta("cl")
	var coin := cl.get_parent().get_child(0) as Control
	var maxed := lv >= mx
	if maxed:
		if cl.text != L.t("Máximo"):
			cl.text = L.t("Máximo")
		coin.visible = false
		bt.disabled = true
		if not bool(bt.get_meta("maxed", false)):
			_gold_on(bt, false)
			bt.add_theme_stylebox_override("disabled", _sb(Color("#2b3452"), Color("#4a5578"), 3, 12))
			cl.add_theme_color_override("font_color", Color("#9fb4dc"))
			cl.add_theme_constant_override("outline_size", 0)
			bt.set_meta("maxed", true)
		return
	coin.visible = true
	var cost: int = SV.up_cost(id, lv)
	if bool(bt.get_meta("maxed", false)):
		bt.set_meta("maxed", false)
		_gold_on(bt, false)
		bt.set_meta("on", int(SV.d["coins"]) < cost)
	_cost_update(bt, str(cost), int(SV.d["coins"]) >= cost)


# Paneles de debajo (MT, veto, atajos): se rehacen solo si lo que muestran cambia, por porciones.
func _up_tail() -> void:
	var show_tm: bool = SV.up_level("tm", up_dex) > 0 and tm_open
	var show_second: bool = SV.up_level("moves", up_dex) > 0
	var ban_lv: int = SV.up_level("ban", up_dex)
	var show_ban: bool = ban_lv > 0 and ban_open
	var key := "%d_%d_%d_%d_%d_%s_%s_%s_%s" % [up_dex, lay_gen, int(show_tm), int(show_second), int(show_ban), SV.start_move_of(up_dex) if show_tm else "", SV.second_start_move_of(up_dex) if show_second else "", ",".join(PackedStringArray(SV.ban_list(up_dex))) if show_ban else "", ",".join(PackedStringArray(SV.bind_list(up_dex)))]
	if key == up_tail_key:
		return
	up_tail_key = key
	_fq_cancel(up_tail)
	for c in up_tail.get_children():
		_retire(c, up_tail)
	if show_tm:
		_later(up_tail, func(): up_tail.add_child(_tm_panel()))
	if show_second:
		_later(up_tail, func(): up_tail.add_child(_second_start_panel()))
	if show_ban:
		_later(up_tail, func(): up_tail.add_child(_ban_panel(ban_lv)))
	_later(up_tail, func(): _bind_panel_into(up_tail))


# Elegir el segundo movimiento inicial tras desbloquear Repertorio; Aleatorio conserva el comportamiento anterior.
func _second_start_panel() -> Control:
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", _card_sb())
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	pc.add_child(v)
	var cur: String = SV.second_start_move_of(up_dex)
	var sub := _label(L.t("Elige el segundo movimiento inicial. Aleatorio conserva la selección normal."), 18, Color("#c8d6ee"))
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(sub)
	var fl := HFlowContainer.new()
	fl.add_theme_constant_override("h_separation", 8)
	fl.add_theme_constant_override("v_separation", 8)
	v.add_child(fl)
	var ids: Array = SV.second_start_pool(up_dex)
	ids.sort_custom(func(a, b): return L.t(String(MD.MOVES[a]["name"])) < L.t(String(MD.MOVES[b]["name"])))
	var choices: Array = [""] + ids
	for id in choices:
		var pick: String = String(id)
		var label: String = L.t("Aleatorio") if pick == "" else L.t(String(MD.MOVES[pick]["name"]))
		var b := _btn(("✔ " if pick == cur else "") + label, func():
			if SV.set_second_start_move(up_dex, pick):
				Aud.sfx("select")
			_refresh_up_keep("second:" + pick), Vector2(0, 40))
		b.set_meta("fk", "second:" + pick)
		if pick == cur:
			b.add_theme_stylebox_override("normal", _sb(Color("#7a5a14"), Color("#ffd23f"), 3, 10))
		fl.add_child(b)
	return pc


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
# Cuelga el panel de parent y crea los 4 desplegables (cada uno con su ventana emergente) uno por paso.
func _bind_panel_into(parent: Control) -> void:
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
	var dex_b: int = up_dex
	# 4 desplegables: en una fila, o 2x2 si la zona util es estrecha (cambia solo en _fit_layout)
	var row := GridContainer.new()
	row.columns = 4 if compact else 8
	row.add_theme_constant_override("h_separation", 10)
	row.add_theme_constant_override("v_separation", 8)
	v.add_child(row)
	parent.add_child(pc)
	for i in range(4):
		var slot: int = i
		_later(parent, func():
			var num := _label(str(slot + 1), 22, C_GOLD)
			row.add_child(num)
			var ob := OptionButton.new()
			ob.custom_minimum_size = Vector2(110, 46)
			ob.fit_to_longest_item = false   # si no, el ancho minimo es el del movimiento con el nombre mas largo
			ob.clip_text = true
			ob.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			ob.focus_mode = Control.FOCUS_ALL
			# lista del desplegable comoda con mando/dedo: filas altas, letra grande, y no mas alta que la pantalla
			var pop: PopupMenu = ob.get_popup()
			pop.add_theme_constant_override("v_separation", 12)
			pop.add_theme_font_size_override("font_size", 20)
			ob.add_item(L.t("Libre"), 0)
			var sel := 0
			for k in range(ids.size()):
				ob.add_item(L.t(String(MD.MOVES[ids[k]]["name"])), k + 1)
				if String(cur[slot]) == String(ids[k]):
					sel = k + 1
			ob.select(sel)
			ob.item_selected.connect(func(idx: int):
				var pick: String = "" if idx == 0 else String(ids[idx - 1])
				SV.bind_set(dex_b, slot, pick)
				Aud.sfx("select")
				_refresh_up_keep("bind%d" % slot))
			ob.set_meta("fk", "bind%d" % slot)
			row.add_child(ob))


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
		_retire(up_picker, self)   # se oculta ya y se libera por porciones (cientos de botones)
	up_picker = null


# Selector grande y tactil (la lista desplegable normal es dificil de usar en el movil).
func _open_up_picker() -> void:
	pk_gen = 0
	pk_type = ""
	pk_q = ""
	pk_focus = ""
	_build_up_picker()


func _pk_filter_row(parent: Control, items: Array, cur_val, on_pick: Callable, prefix: String, at: int = -1) -> void:
	var sc := _new_scroll()
	sc.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.custom_minimum_size = Vector2(0, 58)
	sc.get_h_scroll_bar().custom_minimum_size.y = 12
	parent.add_child(sc)
	if at >= 0:
		parent.move_child(sc, at)
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
	var pins: Vector4 = DSP.insets(get_tree())   # margenes seguros (notch / esquinas)
	pan.offset_left = pins.x
	pan.offset_right = -pins.z
	pan.offset_top = pins.y
	pan.offset_bottom = -pins.w
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
	# las dos filas de filtros entran en pasos propios (en su hueco: tras el buscador)
	_later(root, func(): _pk_filter_row(v, gens, pk_gen, func(x): pk_gen = int(x); _build_up_picker(), "g", 2))
	var tys: Array = [{"v": "", "t": L.t("Todas")}]
	for tk in MD.TYPE_NAME.keys():
		tys.append({"v": String(tk), "t": L.t(String(MD.TYPE_NAME[tk])), "c": String(MD.TYPE_COLOR.get(tk, "#ffffff"))})
	_later(root, func(): _pk_filter_row(v, tys, pk_type, func(x): pk_type = String(x); _build_up_picker(), "t", 3))
	var sc := _new_scroll()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.get_v_scroll_bar().custom_minimum_size.x = 30
	v.add_child(sc)
	var grid := GridContainer.new()
	grid.columns = maxi(2, DSP.cols(_content_w() * 0.88, 340.0, 10.0, 3))
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	sc.add_child(grid)
	var shown := 0
	var ds: Array = []   # los que pasan el filtro, en orden
	for dx in _up_owned():
		var info0: Dictionary = SV.dex_by[int(dx)]
		if pk_gen != 0 and int(info0["gen"]) != pk_gen:
			continue
		if pk_type != "" and not Array(info0["types"]).has(pk_type):
			continue
		ds.append(int(dx))
	shown = ds.size()
	for k in range(mini(ds.size(), 16)):
		Preview.prefetch(int(ds[k]), false)   # las primeras hojas se leen en segundo plano
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
		none_l.visible = vis == 0 and not _fq_pending(grid)
	search.text_changed.connect(apply_q)
	# los botones van llegando por porciones (cientos de iconos con texto en un solo fotograma tardaban ~200 ms)
	for k in range(ds.size()):
		var d: int = int(ds[k])
		_later(grid, func():
			if k + 16 < ds.size():
				Preview.prefetch(int(ds[k + 16]), false)
			var info: Dictionary = SV.dex_by[d]
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
			var mq: String = (_name_of(d) + " " + String(info["name"]) + " " + str(d)).to_lower()
			b.set_meta("q", mq)
			if pk_q != "":
				b.visible = mq.contains(pk_q.strip_edges().to_lower())
			grid.add_child(b)
			if d == up_dex and pk_focus == "" and pk_q == "":
				(func():
					await get_tree().process_frame
					await get_tree().process_frame
					if is_instance_valid(b) and b.is_visible_in_tree() and up_picker == root:
						b.grab_focus()
						sc.ensure_control_visible(b)).call())
	_later(grid, func(): apply_q.call(pk_q))


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
	var sc := _new_scroll()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	s.add_child(sc)
	gacha_box = VBoxContainer.new()
	gacha_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gacha_box.add_theme_constant_override("separation", 12)
	sc.add_child(gacha_box)
	# pestanas de region: se crean una vez; debajo va el contenido de la region (cambia al cambiar de pestana)
	gacha_tabs = HFlowContainer.new()
	gacha_tabs.add_theme_constant_override("h_separation", 8)
	gacha_tabs.add_theme_constant_override("v_separation", 8)
	gacha_box.add_child(gacha_tabs)
	for i in range(1, 10):
		var r: int = i
		var tb := _btn(L.t(SV.REGIONS[r - 1]) + "\n" + L.t("Gen %d") % r, func(): gacha_region = r; _refresh_gacha(); _tab_scroll_top(); _focus_content(), Vector2(112, 62))
		tb.add_theme_font_size_override("font_size", 20)
		gacha_tabs.add_child(tb)
	gacha_content = VBoxContainer.new()
	gacha_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gacha_box.add_child(gacha_content)


# Capa oscura de los cuadros (resultado del gacha, favoritos, tarjeta): se crea la primera vez que hace falta.
func _ensure_result() -> void:
	if gacha_result != null and is_instance_valid(gacha_result):
		return
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
	# pestanas de region (ya existen): se marca la activa
	var tbs: Array = gacha_tabs.get_children()
	for i in range(tbs.size()):
		var tb := tbs[i] as Button
		if i + 1 == gacha_region:
			if not _seg_sb.has("greg"):
				_seg_sb["greg"] = _sb(Color("#2a4aa8"), C_GOLD, 3, 12)
			tb.add_theme_stylebox_override("normal", _seg_sb["greg"])
			tb.add_theme_color_override("font_color", C_GOLD)
			tab_sel = tb
		else:
			tb.remove_theme_stylebox_override("normal")
			tb.remove_theme_color_override("font_color")
	tab_row = gacha_tabs
	# La pagina de la region se rehace cada vez, por porciones: volver a colgar una pagina guardada costaba casi lo mismo
	# que construirla (el coste esta en entrar al arbol), pero de golpe.
	var fp := "%d_%d_%d_%d" % [int(SV.d["tickets"]), int(SV.d.get("tickets10", 0)), int(SV.d["pity"].get(str(gacha_region), 0)), SV.owned_count()]
	_fq_cancel(gacha_content)
	for ch in gacha_content.get_children():
		_retire(ch, gacha_content)
	gacha_pages.clear()
	var ent: Dictionary = _build_gacha_page(fp)
	gacha_pages[gacha_region] = ent
	gacha_content.add_child(ent["page"])
	gi_dirty = true
	var gits: Array = NAVG.focusables(ent["page"])
	focus_first = gits[0] if not gits.is_empty() else tab_sel


# Contenido de la region actual (escenario, tiradas, probabilidades); se guarda por region.
func _build_gacha_page(fp: String) -> Dictionary:
	var pg := VBoxContainer.new()
	pg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pg.add_theme_constant_override("separation", 12)
	var first: Button = null
	var region: int = gacha_region
	# --- escenario + probabilidades
	var main := HBoxContainer.new()
	main.add_theme_constant_override("separation", 16)
	pg.add_child(main)
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 12)
	main.add_child(left)
	var bd: Dictionary = BANNERS[region - 1]
	for bdx in [int(bd["legs"][0]), int(bd["star"]), int(bd["legs"][1])]:
		Preview.prefetch(bdx, false)
	# el escenario (con sus tres Pokemon animados) es lo mas pesado: entra en pasos y se coloca el primero
	var bh: Array = [null]
	_later(pg, func():
		var banner := Banner.new()
		banner.c1 = Color.html(String(bd["c1"]))
		banner.c2 = Color.html(String(bd["c2"]))
		banner.custom_minimum_size = Vector2(0, 360)
		banner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		left.add_child(banner)
		left.move_child(banner, 0)
		bh[0] = banner
		var cnt: Vector2i = _region_counts(region)
		var tx := VBoxContainer.new()
		tx.set_anchors_preset(Control.PRESET_TOP_WIDE)
		tx.offset_left = 22
		tx.offset_top = 16
		tx.offset_right = -22
		tx.add_theme_constant_override("separation", 6)
		banner.add_child(tx)
		var ttl := _label(L.t("Misterio de %s") % L.t(SV.REGIONS[region - 1]), 44, C_GOLD)
		ttl.autowrap_mode = TextServer.AUTOWRAP_OFF
		tx.add_child(ttl)
		tx.add_child(_label(L.t("Los %d Pokémon de la generación %d. ¡Los legendarios te esperan!") % [cnt.y, region], 22))
		tx.add_child(_label(L.t("Tienes %d de %d") % [cnt.x, cnt.y], 20, Color("#cfd9f5"))))
	_later(pg, func(): (bh[0] as Node).call("add_mon", int(bd["legs"][0]), 3.2, 0.0, 0.36))
	_later(pg, func(): (bh[0] as Node).call("add_mon", int(bd["star"]), 3.2, 0.34, 0.66))
	_later(pg, func(): (bh[0] as Node).call("add_mon", int(bd["legs"][1]), 3.2, 0.64, 1.0))
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
	_later(pg, func():
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
		var pity: int = int(SV.d["pity"].get(str(region), 0))
		left.add_child(_label(L.t("Tiradas sin legendario en %s: %d / %d") % [L.t(SV.REGIONS[region - 1]), pity, SV.PITY_5], 18, Color("#c8d6ee"))))
	if first == null:
		first = b1
	# --- panel de probabilidades
	var pool: Array = SV.region_pool(region)
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
		_later(pg, func():
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
			ov.add_child(rr))
	_later(pg, func():
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
		ov.add_child(zr))
	var zg := GridContainer.new()
	zg.columns = 9
	zg.add_theme_constant_override("h_separation", 2)
	zg.add_theme_constant_override("v_separation", 2)
	_later(pg, func(): ov.add_child(zg))
	for zt in ZM.ORDER:
		_later(pg, func():
			var zi = IC.rect("zc:" + String(zt), 32)
			if not ZM.unlocked(String(zt), SV.d["stats"]):
				zi.modulate = Color(0.35, 0.35, 0.4, 0.45)
			zg.add_child(zi))
	_later(pg, func():
		ov.add_child(_label(L.t("· La tirada ×10 garantiza al menos un Pokémon muy raro."), 16, Color("#c8d6ee")))
		ov.add_child(_label(L.t("· A las %d tiradas sin legendario en un banner, la siguiente lo es.") % SV.PITY_5, 16, Color("#c8d6ee")))
		ov.add_child(_label(L.t("· Los repetidos dan Pokémonedas. Los shiny no se repiten."), 16, Color("#c8d6ee")))
		ov.add_child(_label(L.t("· Los tickets se consiguen jugando: algunos Pokémon los sueltan al caer, y los jefes y los cofres a veces dan tickets ×10."), 16, Color("#c8d6ee"))))
	return {"page": pg, "fp": fp, "first": first, "gen": lay_gen}


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
	_ensure_result()
	_clear(gacha_result)
	var c := CenterContainer.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	gacha_result.add_child(c)
	var pc := PanelContainer.new()
	c.add_child(pc)
	var v := VBoxContainer.new()
	_pop_wrap(c, pc, v)
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
		var zrow := _icon_label("zc:" + zc, L.t("¡Cristal Z encontrado! Desbloqueas: %s") % L.t(String(ZM.DEF[zc]["name"])), 20, Color("#ffd23f"), 40.0, true)
		zrow.alignment = BoxContainer.ALIGNMENT_CENTER
		v.add_child(zrow)
		Aud.sfx("legend")
	var ok := _btn("Aceptar", func(): gacha_result.visible = false; _refresh_gacha(); _focus_content(), Vector2(0, 54))
	v.add_child(ok)
	gacha_result.visible = true
	_gf(ok)


# ---------------------------------------------------------------
# Misiones, logros y titulos (progress.gd)
# ---------------------------------------------------------------
var ach_cat := "coleccion"
var goals_btn: Button
var goals_tabs: HFlowContainer


# Pestana de una fila de 5 (HFlowContainer): ancho comodo para el mando; si no caben en una fila pasan a la siguiente, sin recortar el texto.
func _tab_fit(tb: Button) -> void:
	tb.custom_minimum_size = Vector2(150, 46)
	tb.add_theme_constant_override("h_separation", 6)


func _build_goals() -> void:
	var s: Control = _screen("goals")
	var pc := PanelContainer.new()
	s.add_child(pc)
	var v := VBoxContainer.new()
	pc.add_child(v)
	goals_tabs = HFlowContainer.new()
	v.add_child(goals_tabs)
	for t in [["m", "Misiones"], ["a", "Logros"], ["h", "Medallas"], ["z", "Cristales Z"], ["p", "Perfil"], ["r", "Récords"]]:
		var k: String = String(t[0])
		var tb := _btn(String(t[1]), func(): goals_tab = k; _refresh_goals(); _tab_scroll_top(); _focus_content(), Vector2(60, 46))
		_tab_fit(tb)
		if k == "a":
			tb.icon = IC.btn_tex("medal1", 28)
			tb.expand_icon = false
		elif k == "h":
			tb.icon = IC.btn_tex("medal1", 28)
			tb.expand_icon = false
		elif k == "z":
			tb.icon = IC.btn_tex("zc:ice", 28)
			tb.expand_icon = false
		goals_tabs.add_child(tb)
	var sc := _new_scroll()
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
var lex_tab := "m"
var lex_tabs: HFlowContainer
var lex_box: VBoxContainer
const LEX_STATUS := [
	["freeze", "Congelado", "El enemigo no se mueve ni ataca y recibe un 25% más de daño. Los jefes lo resisten."],
	["para", "Paralizado", "El enemigo va mucho más lento y recibe más daño eléctrico. Los jefes lo resisten."],
	["sleep", "Dormido", "El enemigo no actúa, recibe un 30% más de daño y se despierta con el primer golpe. Darkrai es inmune."],
	["conf", "Confundido", "El enemigo se mueve sin rumbo y ataca a otros enemigos. Los jefes lo resisten."],
	["burn", "Quemado", "Daño continuo y el enemigo hace menos daño."],
	["poison", "Envenenado", "Daño continuo según su vida máxima (menos contra jefes)."],
	["slow", "Ralentizado", "El enemigo se mueve más despacio durante un rato."],
	["charm", "Enamorado", "El enemigo pelea de tu lado 20 s: ataca a otros enemigos y no te hace daño. Los jefes son inmunes y, al acabarse, no puede volver a enamorarse enseguida."],
]


func _build_lexicon() -> void:
	var s: Control = _screen("lexicon")
	var pc := PanelContainer.new()
	s.add_child(pc)
	var v := VBoxContainer.new()
	pc.add_child(v)
	lex_tabs = HFlowContainer.new()
	v.add_child(lex_tabs)
	for t in [["i", "Objetos"], ["m", "Movimientos"], ["f", "Fusion Dex"], ["s", "Estados"], ["a", "Habilidades"], ["z", "Z y Dynamax"], ["k", "Kecleon"], ["n", "Novedades"]]:
		var k: String = String(t[0])
		var tb := _btn(String(t[1]), func(): lex_tab = k; _refresh_lexicon(); _tab_scroll_top(); _focus_content(), Vector2(60, 46))
		_tab_fit(tb)
		lex_tabs.add_child(tb)
	var sc := _new_scroll()
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


func _lex_grid(page: Control, cols: int) -> GridContainer:
	var g := GridContainer.new()
	g.columns = cols
	g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	g.add_theme_constant_override("h_separation", 10)
	g.add_theme_constant_override("v_separation", 10)
	page.add_child(g)
	return g


# Pagina del lexico en pantalla (clave = pestana).
var lex_pages := {}


func _refresh_lexicon() -> void:
	var tbs: Array = lex_tabs.get_children()
	for i in range(tbs.size()):
		var key: String = LEX_TABS[i]
		_gold_btn(tbs[i], key == lex_tab)
		if key == lex_tab:
			tab_sel = tbs[i]
	tab_row = lex_tabs
	# La pagina anterior se libera y la de esta pestana se construye por porciones: volver a colgar una pagina entera
	# guardada costaba lo mismo que construirla (el coste esta en entrar al arbol), pero de golpe.
	for ch in lex_box.get_children():
		_retire(ch, lex_box)
	lex_pages.clear()
	var page := VBoxContainer.new()
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.add_theme_constant_override("separation", 8)
	lex_pages[lex_tab] = page
	lex_box.add_child(page)
	_lex_fill(page, lex_tab)   # las tarjetas van llegando por porciones (_pump)
	gi_dirty = true
	focus_first = tab_sel
	_update_top()


# Sustituye los "%d" en orden, sin interpretar otros "%" del texto (ej. "+30%": con el operador % da error de formato).
func _fmt_d(tpl: String, vals: Array) -> String:
	var out := ""
	var rest := tpl
	for v in vals:
		var i := rest.find("%d")
		if i < 0:
			break
		out += rest.substr(0, i) + str(v)
		rest = rest.substr(i + 2)
	return out + rest


const LEX_NEW := [
	["Altar legendario", "Un altar grande y sólido, con escaleras al frente. Sube por ellas, párate en el círculo central y espera a que la barra \"Invocando\" se llene (4 s). Si te sales, la barra se pausa y baja muy poco. Invoca a un Pokémon legendario que ataca solo con rayos de área y tiene vida visible: no se cura y los enemigos que lo tocan le hacen daño. Solo puede haber uno a la vez.", "tex:altar"],
	["Apuntado manual", "Opcional (Ajustes). Apunta tú mismo con el stick derecho del mando, el ratón o un segundo dedo arrastrando en la mitad derecha de la pantalla. Una flecha indica hacia dónde disparas. Si no apuntas, el juego apunta solo.", "tex:aim"],
	["Trampas más grandes", "Las trampas del mapa son más grandes y avisan del área real en la que actúan. Cada tipo (veneno, pegajosa, hielo, rayo, sueño, confusión y fuego) tiene su propia animación al estar armada y al estallar.", "tex:trap"],
	["Movimientos con patrón único", "Cada movimiento nuevo tiene su propio patrón de ataque, no solo otra animación: zonas, ondas, trampas, rastros, dashes, ráfagas y más. Lee la descripción de cada uno en la pestaña Movimientos.", "tex:pat"],
	["Huecos de arma", "Nueva mejora en la tienda: empiezas con 4 huecos de movimiento y puedes comprar hasta 2 más (máximo 6).", "cards"],
	["Objetos con tiempo de recarga", "Los objetos con recarga (Baya Zidra, Banda Focus, Política Débil...) aparecen en una caja en pantalla con su tiempo restante, o \"Listo\" cuando se pueden usar.", "clock"],
	["Dificultad progresiva", "A partir del minuto 20 los enemigos ganan más vida, daño y velocidad, y aparecen más élites. A los 60 min el reto es máximo.", "r_berserk"],
	["Bonus de terreno", "Si pisas un líquido de tu tipo (agua, lava, pantano, hielo, veneno o chispas), ganas un +12% de velocidad mientras estés en él.", "boot"],
	["Movimientos de vínculo", "Une como máximo 2 movimientos en un solo hueco y se lanzarán a la vez. Si los dos están evolucionados y al nivel máximo, se te ofrece fusionarlos en un Movimiento de Vínculo mucho más potente. Los originales se pierden el resto de la partida, pero puedes cancelar y conservarlos. Ocupa un solo hueco.", "bond"],
	["Enamorado", "Los movimientos de tipo Hada pueden enamorar a un enemigo durante 20 s (26 s con Pluma Hada). Un enemigo enamorado pelea de tu lado: ataca a otros enemigos y no te hace daño. Los jefes son inmunes y, al acabarse, el enemigo no puede volver a enamorarse enseguida.", "heart"],
	["Resumen de la partida", "En la pausa, el botón Resumen muestra cada movimiento con su tipo, nivel, daño total, derrotas y DPS de los últimos 20 s, además de tus mejoras y objetos.", "book"],
	["Partida Normal: Sentencia de Arceus", "La partida Normal termina a los 30 min con la Sentencia de Arceus. 00:30 pequeña oleada; 01:00 primera Grieta garantizada; 02:00 un Meowth que huye con monedas; 03:00 el primer jefe; 04:00 cambio único al siguiente mapa (cuando el jefe cae). Entre medias aparecen mini-jefes gigantes raros (Tyranitar, Wailord, Onix, Steelix y más). A los 30:00 llega ARCEUS: una arena enorme, Arceus invencible y un legendario cada 5 s con el doble de vida y daño que el anterior. Esa pelea no tiene límite de tiempo. Los demás modos no cambian.", "tex:eter"],
	["Objetos perdidos y paquetes", "Por el mapa aparecen objetos pequeños que se recogen solos al tocarlos: la Bolsa de Poké Balls (+3 Poké Balls), el Elixir (un potenciador al azar durante 25 s) y el Cristal Prisma (paraliza 2,5 s a los enemigos cercanos: una salida de emergencia). Si no te sirven en ese momento (Poké Balls al máximo, ya tienes un potenciador o no hay enemigos cerca) se quedan en el suelo. Los paquetes misteriosos se abren con el botón de acción (E, A del mando o el botón dorado en pantalla). Dan oro, experiencia, curación, un consumible o, rara vez, un ticket. Desaparecen con el tiempo.", "tex:pack"],
	["Cofres de pago y trampa", "Las huchas Poké Ball cuestan monedas de la partida (cuestan más con cada una que abres y cambian de tipo de bola). Acércate y pulsa el botón de acción: el precio se ve en el botón. Si no te alcanza, no se cobra. Cada hucha da una MEJORA gratis (subes de nivel y eliges una carta) o una Poké Ball; las más caras pueden dar las dos. Otras huchas son trampas: unas lucen sospechosas (ojos rojos) y otras están disfrazadas de hucha normal (fíjate en un colmillo). Si la abres sale una emboscada pequeña, pero puedes huir.", "tex:paid"],
	["Cajas de suministro", "Un aviso anuncia una caja que cae cerca. Llega hasta ella y pulsa el botón de acción antes de que se agote el tiempo (30 s). Hay cuatro tipos: médico y de recursos (sin enemigos extra), raro y excepcional (atraen enemigos, pero no hace falta derrotarlos). Solo hay una caja a la vez.", "tex:crate"],
	["Kecleon, el comerciante", "Un Kecleon de colores visita el mapa por un rato (60-75 s). Acércate y pulsa el botón de acción \"Comerciar\": te ofrece 3 objetos de su catálogo a cambio de monedas de la partida. Solo puedes comprar uno por visita y cambiar las ofertas una vez (el precio del cambio sube cada vez que lo usas). Cada color vende objetos distintos; el azul shiny es raro y vende los mejores. Solo hay un Kecleon a la vez.", "dex:352"],
	["Menú Pokémon renovado", "En Pokémon ves a tu compañero en un retrato con flechas para pasar al anterior o al siguiente, su tipo, sus barras de PS, Velocidad y Ataque, su habilidad y su movimiento inicial. A la derecha, pestañas por región, «Solo los míos», un buscador (por nombre, tipo o número) y un orden (número, nombre, rareza o favoritos). Toca el corazón de una tarjeta para marcar un favorito; la estrella indica a tu compañero. La misma pantalla sirve para elegir equipo, compañero cooperativo y Pokémon de la fiesta.", "ball"],
	["Rescates de Pokémon", "De vez en cuando aparece un Pokémon salvaje que necesita ayuda (sin entrenadores). Herido: quédate a su lado unos segundos. Amenazado: derrota a los 4 enemigos que lo atacan. Perdido: sigue la flecha, encuéntralo y pulsa el botón de acción. Si lo logras, te da las gracias, te regala un premio (monedas, EXP, ticket, curación u objeto) y se marcha; nunca se une a tu equipo. Si no llegas a tiempo, simplemente se va. Solo hay un rescate a la vez.", "tex:rescue"],
	["Poké Ball y Alfas", "A veces ronda un Alfa: un Pokémon enorme, rojizo y muy resistente. Es opcional. Si lo derrotas, queda aturdido 8 segundos: pulsa el botón de acción para lanzarle UNA Poké Ball (80% de éxito). Si lo logras, se une a ti como aliado el resto de la partida (se recupera poco a poco y ocupa el mismo hueco que el aliado del altar legendario). Con el apuntado manual activado, el lanzamiento debe apuntar al Alfa; si fallas el tiro, no se gasta la bola. Las Poké Balls son raras: salen a veces de cofres, mochilas, cajas de suministro y al cortar hierba. El número que llevas aparece junto a tus monedas.", "tex:ball"],
	["Legendarios salvajes", "Pasado el minuto 30 de la partida Normal, de vez en cuando aparece un legendario salvaje enorme y resistente. Si lo derrotas, recibes un premio especial (monedas, tickets y un objeto). No aparece durante grietas, cuevas, invasiones ni con otro jefe, y deja de aparecer poco antes de Eternatus.", "tex:wildleg"],
	["Regreso de la Grieta", "Al volver al mundo desde una Grieta o una guarida hay una cuenta atrás de 3-2-1: el tiempo de la partida y los enemigos se detienen y eres invulnerable hasta que termina.", "tex:return"],
	["Día y noche", "Cada partida alterna día, atardecer, noche y amanecer (ciclo de 8 minutos). De noche aparecen más Pokémon de tipo Fantasma, Siniestro y Bicho nocturnos; de día, más Pokémon diurnos. Algunos secretos solo se revelan de noche.", "tex:daynight"],
	["Peligros de bioma", "Los biomas extremos tienen peligros señalados antes de golpear: erupciones y quemaduras en volcanes, ráfagas que ralentizan en el hielo, rayos que pueden paralizar y burbujas tóxicas. Los Pokémon del tipo correspondiente son inmunes. Solo hay un aviso a la vez.", "tex:hazard"],
	["Cuevas y altares", "Se abre una cueva de un tipo (14 tipos). Derrota la oleada y pisa el altar: tus efectos de estado de ese tipo mejoran (quemar, veneno, ralentizar, dormir, paralizar…), hasta 3 niveles. Normal, Volador, Roca y Acero aún no tienen cueva.", "tex:cave"],
	["Invasiones", "Tras un aviso de 5 s, una invasión (fantasma, siniestra, eléctrica, estampida, brillante, mixta, Alfa o de pesadilla nocturna) dura 45 s. Sobrevive para ganar el premio; si caes, no hay premio.", "tex:invasion"],
	["Meteorito y Deoxys", "Un meteorito marca una zona: aléjate. Deja botín y, con un 10% de probabilidad, Deoxys emerge. Si lo derrotas antes de que escape, recibes un premio especial.", "tex:meteor"],
	["Proyecto Mewtwo", "Pasados los 13 minutos pueden aparecer 3 estaciones de investigación. Mantente en cada una unos segundos; al completarlas todas despierta Mewtwo, con ataques señalados. Una vez por partida.", "tex:mewtwo"],
	["Secretos", "Claros ocultos, runas que hay que pisar en orden, secretos lunares que se revelan de noche y nidos secretos. Cada uno da un premio modesto una sola vez.", "tex:secret"],
	["Mecanismos elementales", "Antorchas, fuentes, generadores y sellos que solo se activan al golpearlos con un movimiento del tipo correcto (no por acercarte). Son opcionales.", "tex:mech"],
	["Medallas", "Nueva pestaña en Misiones y Logros: medallas por explorar, rescatar, capturar Alfas y vencer eventos. Son cosméticas.", "tex:medals"],
	["Gachapon más ágil", "Toca la pantalla durante la animación para acelerarla, y vuelve atrás sin perder el premio.", "ticket"],
	["Fusiones y Fusion Dex", "Une dos movimientos evolucionados al máximo con Vínculo para crear un movimiento fusionado único (50 recetas). Cada receta descubierta queda en la Fusion Dex para siempre.", "book"],
	["Fusión automática", "Al vincular dos movimientos evolucionados y al nivel máximo se fusionan solos, con un gran aviso «FUSION!». Cada receta tiene su propio ataque especial con animación: tormentas, vórtices, rayos, prisiones, erupciones y más.", "book"],
	["Perfil del jugador", "Toca tu nombre de entrenador para abrir tu perfil: 3 Pokémon favoritos, estadísticas, medallas de tipo, tipo favorito con fondo propio, gorra, mochila y tema de la interfaz.", "tex:medals"],
	["Kecleon se marcha", "Tras tu compra, Kecleon desaparece del mapa (una compra por visita). Su tienda ahora usa el mismo estilo y fuente que el resto del juego, y todos sus objetos están en la pestaña Kecleon del Léxico.", "dex:352"],
	["Evoluciones con animación", "Cada movimiento evolucionado gana una habilidad propia que el base no tiene: ecos, vórtices, marcas que explotan, congelación y rotura, meteoros, saltos relámpago, rayos giratorios, sanguijuelas y más. Se activa sola al atacar (con su propia recarga) y viene con animación única. Respiro y Batido ahora también pueden evolucionar.", "move:inferno_tempest"],
	["Fusion Moves", "Si vinculas dos movimientos evolucionados y los subes al nivel máximo, se fusionan solos en un Fusion Move, con el aviso «FUSION!» y un sonido épico. Solo puedes tener UNO por partida: reemplaza a los dos movimientos originales, que ya no vuelven a salir en las mejoras. Ocupa un solo hueco, es más fuerte que cualquier evolucionado y lanza los dos ataques a la vez, además de un ataque especial único con animación propia cada pocos segundos (hay 50 recetas). Ya no se puede mejorar. Cada receta descubierta queda guardada en la Fusion Dex.", "move:inferno_tempest"],
	["Pantallas anchas", "El juego se adapta a pantallas 16:9 y 16:10 (como la Odin 3 Max): el campo de visión se amplía en lugar de recortarse y los botones se mantienen dentro de la pantalla.", "cards"],
	["Tamaño del texto", "En Ajustes puedes cambiar el tamaño del texto (Normal hasta Muy grande) para leer mejor en pantallas pequeñas.", "cards"],
]


func _fname(id: String) -> String:
	return L.t(String(MD.MOVES[id]["name"])) if MD.MOVES.has(id) else id


func _lex_news_icon(spec: String) -> Control:
	var tr := TextureRect.new()
	if spec.begins_with("tex:"):
		var p := "res://assets/world/lexn_%s.png" % spec.substr(4)
		if ResourceLoader.exists(p):
			tr.texture = load(p)
	else:
		return IC.rect(spec, 48)
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.custom_minimum_size = Vector2(48, 48)
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return tr


func _lex_fill(page: VBoxContainer, tab: String) -> void:
	var cols: int = DSP.cols(_content_w(), 420.0, 10.0, 3)
	if tab == "i":
		var found: Dictionary = SV.d.get("itemsFound", {})
		page.add_child(_label(L.t("Objetos: %d / %d encontrados") % [found.size(), TD.ITEMS.size()], 24, C_GOLD))
		var g := _lex_grid(page, cols)
		for it in TD.ITEMS:
			_later(page, func():
				var id: String = String(it["id"])
				var ok: bool = found.has(id)
				g.add_child(_lex_card(IC.rect(id, 40), L.t(String(it["name"])), L.t("✔ Encontrado") if ok else L.t("Aún sin encontrar"), Color("#8fe3b0") if ok else Color("#8fa3c4"), L.t(String(it["desc"])), not ok)))
	elif tab == "m":
		var moves: Dictionary = MD.MOVES
		page.add_child(_label(L.t("Movimientos: %d") % moves.size(), 24, C_GOLD))
		for ty in TYPE_IDS:
			var ids: Array = []
			for mid in MD.ORDER:
				if moves.has(mid) and String(moves[mid]["type"]) == ty:
					ids.append(mid)
			if ids.is_empty():
				continue
			var tcol: Color = Color.html(String(MD.TYPE_COLOR.get(ty, "#ffffff")))
			var gh: Array = [null]   # la cuadricula de este tipo se crea en su primer paso
			_later(page, func():
				page.add_child(_label(L.t(String(MD.TYPE_NAME[ty])), 22, tcol))
				gh[0] = _lex_grid(page, cols))
			for mid in ids:
				_later(page, func():
					var m: Dictionary = moves[mid]
					var desc: String = L.t(String(m["desc"]))
					if MD.EVO.has(mid):
						desc += "\n" + L.t("Evoluciona en: %s") % L.t(String(MD.EVO[mid][0]))
					if MD.EVO_ALT.has(mid):
						desc += "\n" + L.t("Evoluciona en: %s") % L.t(String(MD.EVO_ALT[mid][0]))
					(gh[0] as Control).add_child(_lex_card(IC.rect("move:" + String(mid), 36), L.t(String(m["name"])), L.t(String(MD.TYPE_NAME[ty])), tcol, desc)))
	elif tab == "z":
		page.add_child(_label(L.t("Movimientos Z: %d") % ZM.ORDER.size(), 24, C_GOLD))
		page.add_child(_label(L.t("Se recargan cada 4 minutos, desde el minuto 3. Se desbloquean derrotando %d Pokémon de ese tipo.") % ZM.NEED, 16, Color("#c8d6ee")))
		var dn: int = int(SV.d["stats"].get("dens", 0))
		var dok: bool = dn >= 1
		var gd := _lex_grid(page, cols)
		_later(page, func():
			gd.add_child(_lex_card(null, "Dynamax", L.t("Desbloqueado") if dok else L.t("Vence una guarida Dynamax: %d/1") % dn, Color("#ff7a9a"),
				L.t("Cada 4 minutos (desde el minuto 3): tu Pokémon se vuelve gigante %d s con +30%% a todos sus atributos y lanza ondas Max de su tipo. Cada guarida Dynamax vencida lo recarga al instante.") % [int(DYN.DUR)], not dok)))
		var gz := _lex_grid(page, cols)
		for zt in ZM.ORDER:
			_later(page, func():
				var zd: Dictionary = ZM.DEF[zt]
				var zn: int = int(SV.d["stats"].get("tk_" + zt, 0))
				var zok: bool = ZM.unlocked(zt, SV.d["stats"])
				var zcol: Color = Color.html(String(MD.TYPE_COLOR.get(zt, "#ffffff")))
				var zsub: String = L.t(String(MD.TYPE_NAME[zt])) + " · " + (L.t("Desbloqueado") if zok else L.t("Derrota %d Pokémon de tipo %s: %d/%d") % [ZM.NEED, L.t(String(MD.TYPE_NAME[zt])), zn, ZM.NEED])
				gz.add_child(_lex_card(IC.rect("zc:" + zt, 48), L.t(String(zd["name"])), zsub, zcol, L.t(String(zd["desc"])), not zok)))
	elif tab == "f":
		var fnd: Array = SV.d.get("fusions", [])
		page.add_child(_label("Fusion Dex: %d / %d" % [fnd.size(), FUS.R.size()], 24, C_GOLD))
		var gf := _lex_grid(page, cols)
		for fr in FUS.R:
			_later(page, func():
				if fnd.has(fr[0]):
					var fcol: Color = Color.html(String(fr[5]))
					gf.add_child(_lex_card(IC.rect("move:" + String(fr[0]), 48), L.t(String(fr[1])), _fname(String(fr[2])) + " + " + _fname(String(fr[3])), fcol, L.t(String(fr[4]))))
				else:
					gf.add_child(_lex_card(null, "???", L.t("Bloqueada"), Color("#8fa3c4"), L.t("Fusiona dos movimientos evolucionados para descubrir esta receta."), true)))
	elif tab == "k":
		var gk := _lex_grid(page, cols)
		for kv in KCX.ORDER:
			var kvc: Color = Color.html(String(KCX.VAR[kv]["col"]))
			for kid in KCX.CAT[kv]:
				if not KCX.ITEMS.has(kid):
					continue
				_later(page, func():
					var kit: Array = KCX.ITEMS[kid]
					gk.add_child(_lex_card(IC.rect("kec:" + String(kid), 48), L.t(String(kit[0])), L.t(String(KCX.VAR[kv]["name"])), kvc,
						L.t(String(kit[3])) + "\n" + L.t("Precio") + ": " + str(int(kit[1])) + "  ·  " + L.t("Máximo") + ": " + str(int(kit[2])))))
	elif tab == "n":
		var gn := _lex_grid(page, cols)
		for nw in LEX_NEW:
			_later(page, func(): gn.add_child(_lex_card(_lex_news_icon(String(nw[2])), L.t(String(nw[0])), "", Color.WHITE, L.t(String(nw[1])))))
	elif tab == "a":
		page.add_child(_label(L.t("Habilidades: %d") % AB.FX.size(), 24, C_GOLD))
		var g4 := _lex_grid(page, cols)
		for aid in AB.FX:
			_later(page, func():
				var ad: Dictionary = AB.FX[aid]
				g4.add_child(_lex_card(null, L.t(String(ad["name"])), "", Color.WHITE, L.t(String(ad["desc"])))))
	else:
		page.add_child(_label(L.t("Estados alterados"), 24, C_GOLD))
		var g3 := _lex_grid(page, cols)
		for st in LEX_STATUS:
			_later(page, func(): g3.add_child(_lex_card(null, L.t(String(st[1])), "", Color.WHITE, L.t(String(st[2])))))


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
	_fq_cancel(goals_box)
	for c in goals_box.get_children():
		_retire(c, goals_box)   # se oculta ya y se libera por porciones
	gi_dirty = true
	var first: Button = null
	var tbs: Array = goals_tabs.get_children()
	for i in range(tbs.size()):
		var key: String = ["m", "a", "h", "z", "p", "r"][i]
		_gold_btn(tbs[i], key == goals_tab)
		if key == goals_tab:
			tab_sel = tbs[i]
	tab_row = goals_tabs
	if goals_tab == "m":
		first = _goals_missions()
	elif goals_tab == "a":
		first = _goals_ach()
	elif goals_tab == "h":
		first = _goals_medals()
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
	var M: Dictionary = SV.d["missions"]
	# Hasta la primera fila con boton (la que recibe el foco) se construye en el acto; lo demas, por porciones.
	var st: Array = [null]
	var run := func(f: Callable):
		if st[0] != null:
			_later(goals_box, f)
		else:
			f.call()
	run.call(func(): goals_box.add_child(_label("Misiones diarias", 28, C_GOLD)))
	var i := 0
	for m in M["daily"]:
		var idx: int = i
		run.call(func():
			var b: Button = _mission_row(m, false, idx)
			if st[0] == null and b != null:
				st[0] = b)
		i += 1
	run.call(func(): goals_box.add_child(_label("Misiones semanales", 28, C_GOLD)))
	for m2 in M["weekly"]:
		run.call(func():
			var b2: Button = _mission_row(m2, true, 0)
			if st[0] == null and b2 != null:
				st[0] = b2)
	run.call(func(): goals_box.add_child(_label("Cambian a las 00:00 (hora de Puerto Rico). Puedes cambiar una diaria al día.", 16, Color("#c8d6ee"))))
	return st[0]


func _reroll(i: int) -> void:
	if PG.reroll(i):
		Aud.sfx("confirm")
	_refresh_goals()


func _claim_mission(m: Dictionary, weekly: bool) -> void:
	if PG.claim(m, weekly):
		Aud.sfx("buy")
		toast(L.t("¡Recompensa reclamada!"))
	_refresh_goals()


var med_cat := "explore"


func _type_medal_got(ty: String) -> bool:
	return int(SV.d["stats"].get("tk_" + ty, 0)) >= ZM.NEED or int(SV.d["stats"].get("zcr_" + ty, 0)) >= 1


func _medal_icon(ty: String, sz: int) -> Control:
	var tr := TextureRect.new()
	tr.texture = load("res://scripts/cave_int.gd").tex_in("medal", ty)
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.custom_minimum_size = Vector2(sz, sz)
	if not _type_medal_got(ty):
		tr.modulate = Color(0.16, 0.2, 0.32, 0.9)
	return tr


# Pestaña «Medallas» (V5.1): medallas de tipo (ZM.NEED derrotados) y logros de ach.gd por categoría
func _goals_medals() -> Button:
	const ACHM = preload("res://scripts/ach.gd")
	goals_box.add_child(_label(L.t("Medallas: %d / %d") % [ACHM.count_got(), ACHM.LIST.size()], 28, C_GOLD))
	goals_box.add_child(_label(L.t("Medallas de tipo"), 22, Color("#9fd0ff")))
	goals_box.add_child(_label(L.t("Derrota %d Pokémon de un tipo para ganar su medalla.") % ZM.NEED, 16, Color("#c8d6ee")))
	var tg := GridContainer.new()
	tg.columns = DSP.cols(_content_w(), 90.0, 8.0, 6)
	tg.add_theme_constant_override("h_separation", 8)
	tg.add_theme_constant_override("v_separation", 8)
	goals_box.add_child(tg)
	for ty2 in TYPE_IDS:
		var ty: String = String(ty2)
		_later(goals_box, func():
			var tcard := VBoxContainer.new()
			tcard.add_child(_medal_icon(ty, 64))
			var tl := _label("%d/%d" % [mini(int(SV.d["stats"].get("tk_" + ty, 0)), ZM.NEED), ZM.NEED], 14, Color("#c8d6ee"))
			tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			tl.autowrap_mode = TextServer.AUTOWRAP_OFF
			tcard.add_child(tl)
			tg.add_child(tcard))
	var chips := HFlowContainer.new()
	chips.add_theme_constant_override("h_separation", 8)
	chips.add_theme_constant_override("v_separation", 8)
	goals_box.add_child(chips)
	var first: Button = null
	for c in ACHM.CATS:
		var ck: String = String(c[0])
		var n := 0
		var d := 0
		for a in ACHM.LIST:
			if String(a[1]) == ck:
				n += 1
				if bool(ACHM.entry(String(a[0]))["got"]):
					d += 1
		var cb := _btn("%s  %d/%d" % [L.t(String(c[1])), d, n], func(): med_cat = ck; _refresh_goals(), Vector2(0, 44))
		_gold_btn(cb, ck == med_cat)
		chips.add_child(cb)
		if first == null:
			first = cb
	for a in ACHM.LIST:
		if String(a[1]) != med_cat:
			continue
		var e: Dictionary = ACHM.entry(String(a[0]))
		var got: bool = bool(e["got"])
		var prog: int = mini(int(e["prog"]), int(a[4]))
		var txt: String = ("★ " if got else "☆ ") + L.t(String(a[2])) + "  (" + str(prog) + "/" + str(int(a[4])) + ")\n" + L.t(String(a[3]))
		_later(goals_box, func():
			var lb := _label(txt, 18, C_GOLD if got else Color(0.7, 0.7, 0.75))
			lb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			goals_box.add_child(lb))
	return first


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
	grid.columns = DSP.cols(_content_w(), 360.0, 10.0, 3)   # segun el ancho util (2 a 140 % en 720x480)
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	goals_box.add_child(grid)
	for a in all:
		if String(a["cat"]) != ach_cat or int(a["dex"]) > 0:
			continue
		_later(goals_box, func(): grid.add_child(_ach_card(a, ach.has(String(a["id"])))))
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
			_later(goals_box, func():
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
				lg.add_child(cell))
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
	grid.columns = DSP.cols(_content_w(), 360.0, 10.0, 3)   # segun el ancho util (2 a 140 % en 720x480)
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	goals_box.add_child(grid)
	for zm in zl:
		_later(goals_box, func(): grid.add_child(_zmis_card(zm, PG.zdone(zm))))
	return null


func _zmis_card(zm: Dictionary, done: bool) -> PanelContainer:
	var t: String = String(zm["type"])
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_FILL
	card.add_theme_stylebox_override("panel", _flat_sb(done))
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
	card.add_theme_stylebox_override("panel", _flat_sb(done))
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
var fav_btns: Array = []   # los 3 huecos de favoritos de la pagina Perfil (el foco vuelve al que se acaba de cambiar)


func _hh() -> bool:
	return OS.has_feature("handheld") or "--keys-only" in OS.get_cmdline_user_args()


# Sin teclado fisico (consola o mando conectado): el nombre se escribe con el teclado en pantalla.
func _pad_mode() -> bool:
	return _hh() or Input.get_connected_joypads().size() > 0


func _nick() -> String:
	var n: String = String(SV.d.get("nick", "")).strip_edges()
	return n if n != "" else L.t("Entrenador")


func _goals_profile() -> Button:
	for pf in Array(SV.d.get("favs", [0, 0, 0])) + [int(SV.d.get("selected", 25))]:
		if int(pf) > 0 and SV.dex_by.has(int(pf)):
			Preview.prefetch(int(pf), false)   # las hojas se leen en segundo plano mientras se arma la pagina
	goals_box.add_child(_label("Así te ve el juego: tu tarjeta de entrenador.", 20, Color("#c8d6ee")))
	var row: BoxContainer = VBoxContainer.new() if compact else HBoxContainer.new()   # estrecho: la tarjeta va debajo de los datos
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
	var name_btn: Button = null
	if _pad_mode():
		# con mando no hay teclado: el nombre se escribe en un teclado en pantalla (_name_kb)
		name_btn = _btn(_nick(), _name_kb, Vector2(0, 52))
		name_btn.add_theme_font_size_override("font_size", 26)
		name_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		name_btn.clip_text = true
		left.add_child(name_btn)
	else:
		var le := LineEdit.new()
		le.text = String(SV.d.get("nick", ""))
		le.placeholder_text = L.t("Entrenador")
		le.max_length = KB_MAX
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
	fav_btns = []
	for i in range(3):
		var slot: int = i
		var dex: int = int(favs[i]) if i < favs.size() else 0
		var b := _btn("", func(): _fav_picker(slot), Vector2(150, 150))
		fav_btns.append(b)
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
	# tema de la interfaz (V5.1) y medallas de tipo
	left.add_child(_label("Tema de la interfaz", 24, C_GOLD))
	var thr := HBoxContainer.new()
	thr.add_theme_constant_override("separation", 8)
	left.add_child(thr)
	var cur_th: int = int(SV.d.get("ui_theme", 1))
	for ti in range(UI_THEMES.size()):
		var tix: int = ti
		var tb := _btn("", func(): _apply_ui_theme(tix); _refresh_goals(), Vector2(0, 56))
		tb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var sel_t: bool = ti == cur_th
		for stn in ["normal", "hover", "pressed", "focus"]:
			tb.add_theme_stylebox_override(stn, _sb(Color(0, 0, 0, 0), C_GOLD if (sel_t or stn == "focus") else Color(0, 0, 0, 0), 4 if (sel_t or stn == "focus") else 0, 12))
		var tic := TextureRect.new()
		tic.texture = CAVEI.tex_in("ui", "theme" + str(ti))
		tic.stretch_mode = TextureRect.STRETCH_SCALE
		tic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tic.set_anchors_preset(Control.PRESET_FULL_RECT)
		tic.offset_left = 2
		tic.offset_top = 2
		tic.offset_right = -2
		tic.offset_bottom = -2
		tic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tb.add_child(tic)
		thr.add_child(tb)
	left.add_child(_label("Medallas de tipo", 24, C_GOLD))
	var mg := HFlowContainer.new()
	mg.add_theme_constant_override("h_separation", 6)
	mg.add_theme_constant_override("v_separation", 6)
	left.add_child(mg)
	for ty3 in TYPE_IDS:
		mg.add_child(_medal_icon(String(ty3), 40))
	return name_btn if name_btn != null else first


# Elegir uno de tus Pokemon para un hueco de favoritos.
func _fav_picker(slot: int) -> void:
	_ensure_result()
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
	var sc := _new_scroll()
	sc.custom_minimum_size = Vector2(760, 360)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(sc)
	_fit_cap(sc, Vector2(760, 360), pc.get_theme_stylebox("panel").get_minimum_size() + Vector2(8, 150), c)
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
	var cancel := _btn("Cancelar", func(): gacha_result.visible = false, Vector2(180, 52))
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
	if slot < fav_btns.size():
		_gf(fav_btns[slot])


# ---------------------------------------------------------------
# Teclado en pantalla para el nombre de entrenador (D-pad + A; X borra, Y pone un espacio, B/Esc cancela)
# ---------------------------------------------------------------
const KB_MAX := 16   # como max_length del campo de texto del original
const KB_LAT := "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
const KB_RU := "АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ"
const KB_NUM := "0123456789"
var kb_open := false
var kb_text := ""
var kb_upper := true
var kb_ru := false
var kb_lbl: Label
var kb_grid: GridContainer
var kb_first: Button = null


func _name_kb() -> void:
	_ensure_result()
	_clear(gacha_result)
	kb_text = String(SV.d.get("nick", ""))
	kb_ru = L.lang() == "ru"
	kb_upper = kb_text == ""
	var c := CenterContainer.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	gacha_result.add_child(c)
	var pc := PanelContainer.new()
	c.add_child(pc)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	v.custom_minimum_size = Vector2(minf(560.0, DSP.area(get_tree()).size.x - 80.0), 0)
	_pop_wrap(c, pc, v)
	var tt := _label("Nombre de entrenador", 26, C_GOLD)
	tt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(tt)
	kb_lbl = _label("_", 32)
	kb_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kb_lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
	kb_lbl.clip_text = true
	v.add_child(kb_lbl)
	kb_grid = GridContainer.new()
	kb_grid.columns = clampi(int((DSP.area(get_tree()).size.x - 120.0) / 52.0), 6, 10)
	kb_grid.add_theme_constant_override("h_separation", 4)
	kb_grid.add_theme_constant_override("v_separation", 4)
	kb_grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(kb_grid)
	var sp := HFlowContainer.new()
	sp.alignment = FlowContainer.ALIGNMENT_CENTER
	sp.add_theme_constant_override("h_separation", 6)
	sp.add_theme_constant_override("v_separation", 4)
	v.add_child(sp)
	sp.add_child(_btn("Aa", func(): kb_upper = not kb_upper; _kb_case(), Vector2(56, 44)))
	if L.lang() == "ru":
		sp.add_child(_btn("RU/EN", func(): kb_ru = not kb_ru; _kb_fill(); _gf(kb_first), Vector2(86, 44)))
	sp.add_child(_btn("Espacio", func(): _kb_add(" "), Vector2(0, 44)))
	sp.add_child(_btn("Borrar", func(): _kb_back(), Vector2(0, 44)))
	var okb := _btn("OK", func(): _kb_ok(), Vector2(70, 44))
	sp.add_child(okb)
	sp.add_child(_btn("Cancelar", func(): _kb_close(), Vector2(0, 44)))
	var hint := _label("X: borrar · Y: espacio · B: cancelar", 15, Color("#c8d6ee"))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(hint)
	_kb_fill()
	_kb_show()
	kb_open = true
	gacha_result.visible = true
	_gf(kb_first if kb_first != null else okb)


# Las teclas de letras y cifras (se rehacen solo al cambiar de alfabeto; mayusculas/minusculas solo cambian el texto)
func _kb_fill() -> void:
	for ch in kb_grid.get_children():
		kb_grid.remove_child(ch)
		ch.queue_free()
	kb_first = null
	for chs in [KB_RU if kb_ru else KB_LAT, KB_NUM]:
		for i in range(String(chs).length()):
			var cc: String = String(chs)[i]
			var kbtn := _btn(cc, func(): _kb_add(String(_kb_ch(cc))), Vector2(46, 44))
			kbtn.set_meta("ch", cc)
			kbtn.add_theme_font_size_override("font_size", 22)
			kb_grid.add_child(kbtn)
			if kb_first == null:
				kb_first = kbtn
	_kb_case()


func _kb_ch(cc: String) -> String:
	return cc.to_upper() if kb_upper else cc.to_lower()


func _kb_case() -> void:
	for b in kb_grid.get_children():
		(b as Button).text = _kb_ch(String(b.get_meta("ch")))


func _kb_show() -> void:
	kb_lbl.text = kb_text + "_"


func _kb_add(ch: String) -> void:
	if kb_text.length() >= KB_MAX:
		return
	kb_text += ch
	var up: bool = ch == " "   # tras la primera letra, minusculas; tras un espacio, mayuscula
	if kb_upper != up:
		kb_upper = up
		_kb_case()
	_kb_show()


func _kb_back() -> void:
	if kb_text.is_empty():
		return
	kb_text = kb_text.substr(0, kb_text.length() - 1)
	if kb_text.is_empty() or kb_text.ends_with(" "):
		kb_upper = true
		_kb_case()
	_kb_show()


func _kb_close() -> void:
	kb_open = false
	gacha_result.visible = false


func _kb_ok() -> void:
	SV.d["nick"] = kb_text.strip_edges()
	SV.save()
	Aud.sfx("confirm")
	_update_top()
	_kb_close()
	_refresh_goals()
	_focus_content()


# Teclas del teclado en pantalla: X (R en la consola) borra, Y (B) pone un espacio; con teclado fisico se escribe directamente.
func _kb_input(event: InputEvent) -> bool:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_BACKSPACE or (_hh() and event.keycode == KEY_R):
			_kb_back()
			return true
		if _hh():
			if event.keycode == KEY_B:
				_kb_add(" ")
				return true
		elif event.unicode > 32 and not event.echo and String.chr(event.unicode).strip_edges() != "" and (KB_LAT + KB_LAT.to_lower() + KB_NUM + KB_RU + KB_RU.to_lower()).contains(String.chr(event.unicode)):
			_kb_add(String.chr(event.unicode))
			return true
	elif event is InputEventJoypadButton and event.pressed and not _hh():
		if event.button_index == JOY_BUTTON_X:
			_kb_back()
			return true
		if event.button_index == JOY_BUTTON_Y:
			_kb_add(" ")
			return true
	return false


# Tarjeta de entrenador: lo que antes era "ver mi perfil publico", pero sin conexion.
func _show_card() -> void:
	_ensure_result()
	_clear(gacha_result)
	var c := CenterContainer.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	gacha_result.add_child(c)
	var pc := PanelContainer.new()
	c.add_child(pc)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	v.custom_minimum_size = Vector2(620, 0)
	_pop_wrap(c, pc, v)
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
	var ok := _btn("Cerrar", func(): gacha_result.visible = false, Vector2(220, 52))
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
const REPO_URL_PM := "https://github.com/DiehlWierce/poke-survivor-ru-pm"


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
	# las pestanas se crean una sola vez: al cambiar de pestana solo se repinta la marcada y se rehace el contenido
	for i in range(SET_TABS.size()):
		var ti: int = i
		set_tabs_row.add_child(_btn(L.t(SET_TABS[i]), func(): _settings_pick(ti), Vector2(0, 46)))
	var ssc := _new_scroll()
	ssc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	ssc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(ssc)
	# settings_host es fijo; las paginas (una por pestana) cuelgan de el y settings_box apunta a la pagina actual
	settings_host = VBoxContainer.new()
	settings_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ssc.add_child(settings_host)
	settings_box = settings_host


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
	news_scroll = _new_scroll()
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
	_fq_cancel(news_box)
	for c in news_box.get_children():
		_retire(c, news_box)
	var first_entry := true
	for e in PN.ENTRIES:
		var sep: bool = not first_entry
		first_entry = false
		_later(news_box, func():
			if sep:
				news_box.add_child(HSeparator.new())
			var t := _label(L.t(String(e["title"])), 30, C_GOLD)
			t.add_theme_constant_override("outline_size", 0)
			news_box.add_child(t)
			news_box.add_child(_label("%s  ·  v%s" % [PN.fmt_date(String(e["date"]), L.lang()), String(e["ver"])], 20, Color("#aebbd6"))))
		for sec in [["new", "Nuevo", Color("#5ddc8a")], ["changes", "Cambios", Color("#4db3ff")], ["fixes", "Arreglos", Color("#ffb347")]]:
			var lines: Array = e.get(String(sec[0]), [])
			if lines.is_empty():
				continue
			_later(news_box, func(): news_box.add_child(_news_tag(L.t(String(sec[1])), sec[2])))
			for ln in lines:
				_later(news_box, func():
					var brow := HBoxContainer.new()
					brow.add_theme_constant_override("separation", 10)
					var dot := _label("•", 22)
					dot.autowrap_mode = TextServer.AUTOWRAP_OFF
					dot.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
					brow.add_child(dot)
					var bl := _label(L.t(String(ln)), 22)
					bl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
					brow.add_child(bl)
					news_box.add_child(brow))
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
		_save_later()
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
		_fit_later()
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
# Se repinta solo al pulsar (sin reconstruir la pagina); cb recibe el indice elegido.
func _seg(opts: Array, cur_i: int, cb: Callable, translate: bool = true) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	var btns: Array = []
	for i in range(opts.size()):
		var idx: int = i
		var b := _btn(L.t(String(opts[i])) if translate else String(opts[i]), func():
			_seg_mark(btns, idx)
			cb.call(idx), Vector2(0, 44))
		btns.append(b)
		h.add_child(b)
	_seg_mark(btns, cur_i)
	return h


func _seg_mark(btns: Array, sel: int) -> void:
	for j in range(btns.size()):
		var b: Button = btns[j]
		if not is_instance_valid(b):
			continue
		if j == sel:
			if not _seg_sb.has("on"):
				_seg_sb["on"] = _sb(C_BTN_H, C_GOLD, 3, 22)
			for st in ["normal", "hover", "pressed"]:
				b.add_theme_stylebox_override(st, _seg_sb["on"])
			b.add_theme_color_override("font_color", C_GOLD)
		else:
			for st in ["normal", "hover", "pressed"]:
				b.remove_theme_stylebox_override(st)
			b.remove_theme_color_override("font_color")


var _seg_sb := {}


# Si/No: al pulsar cambia solo su propio texto y color (antes se reconstruia toda la pestana).
func _yesno(on: bool, cb: Callable) -> Button:
	var state := [on]
	var b := _btn("", func(): pass, Vector2(90, 46))
	_yesno_look(b, on)
	b.pressed.connect(func():
		state[0] = not bool(state[0])
		_yesno_look(b, bool(state[0]))
		cb.call(bool(state[0])))
	return b


func _yesno_look(b: Button, on: bool) -> void:
	b.text = L.t("Sí") if on else L.t("No")
	_gold_on(b, on)


func _toggle_set(key: String, inverted: bool = false) -> Button:
	var on: bool = bool(SV.d["settings"][key])
	if inverted:
		on = not on
	return _yesno(on, func(v: bool):
		SV.d["settings"][key] = (not v) if inverted else v
		SV.save())


# Pulsar una pestana (raton / toque): cambia y el foco va al primer elemento.
func _settings_pick(i: int) -> void:
	set_tab = i
	last_act = ""
	_refresh_settings()
	_tab_scroll_top()
	_focus_content()


func _mark_tab(b: Button, on: bool) -> void:
	if on:
		if not _seg_sb.has("tab"):
			_seg_sb["tab"] = _sb(Color("#3b5aa8"), C_GOLD, 3, 14)
		for st in ["normal", "hover", "pressed"]:
			b.add_theme_stylebox_override(st, _seg_sb["tab"])
	else:
		for st in ["normal", "hover", "pressed"]:
			b.remove_theme_stylebox_override(st)


# Marca la pestana activa (las pestanas ya existen) y rehace el contenido.
func _refresh_settings() -> void:
	reset_armed = false
	import_armed = false
	if listening != "":
		listening = ""
		_refresh_listen()
	var tbs: Array = set_tabs_row.get_children()
	for i in range(tbs.size()):
		_mark_tab(tbs[i], i == set_tab)
		if i == set_tab:
			tab_sel = tbs[i]
	tab_row = set_tabs_row
	_settings_content()


# Pone la pagina de la pestana actual al instante. Antes cada cambio de pestana tiraba la pagina y la rehacia por porciones
# (_sx): durante varios fotogramas se veia la pagina vacia o a medias ("parpadeo"). Ahora las cinco paginas se hacen una
# vez por visita a Ajustes: la marcada entera antes de mostrarse y las demas ocultas, en segundo plano con el presupuesto
# de _pump; cambiar de pestana solo cambia la visible (si la pagina aun no estaba lista se termina en ese momento).
func _settings_content() -> void:
	focus_first = null
	var page: VBoxContainer = settings_pages.get(set_tab) as VBoxContainer
	if page == null or not is_instance_valid(page) or page.is_queued_for_deletion():
		page = _settings_make(set_tab)
	_fq_flush(page)   # lo que quede por construir de esta pagina, ya: nunca se ve a medias
	for k in settings_pages:
		var pg: Control = settings_pages[k]
		if is_instance_valid(pg):
			pg.visible = pg == page
	settings_box = page
	if page.has_meta("on_show"):
		(page.get_meta("on_show") as Callable).call()   # p. ej. Cuenta: quitar los avisos "pulsa otra vez"
	var ff: Control = page.get_meta("ff") as Control if page.has_meta("ff") else null
	if ff != null and is_instance_valid(ff) and page.is_ancestor_of(ff):
		focus_first = ff
	else:
		var items: Array = NAVG.focusables(page)
		focus_first = items[0] if not items.is_empty() else tab_sel
	gi_dirty = true
	# el resto de pestanas, ocultas y por porciones (sin tirones): al cambiar a ellas ya estan hechas
	for i in range(SET_TABS.size()):
		if not settings_pages.has(i):
			_settings_make(i)


# Crea (oculta) la pagina de la pestana i y encola su construccion; los pasos corren aunque este oculta (meta "bg").
func _settings_make(i: int) -> VBoxContainer:
	var page := VBoxContainer.new()
	page.set_meta("gen", lay_gen)
	page.set_meta("bg", true)
	page.visible = false
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.add_theme_constant_override("separation", 8)
	settings_host.add_child(page)
	settings_pages[i] = page
	var keep_box: VBoxContainer = settings_box
	var keep_ff: Control = focus_first
	focus_first = null
	settings_box = page
	match i:
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
	if focus_first != null:
		page.set_meta("ff", focus_first)
	focus_first = keep_ff
	settings_box = keep_box
	return page


# Un trozo de la pagina de Ajustes que se construye mas tarde, apuntando a su pagina aunque ya se haya cambiado de pestana.
func _sx(f: Callable) -> void:
	var pg: VBoxContainer = settings_box
	_later(pg, func():
		var keep: VBoxContainer = settings_box
		var keep_ff: Control = focus_first
		settings_box = pg
		focus_first = null
		f.call()
		if focus_first != null:
			pg.set_meta("ff", focus_first)
			if not pg.visible:
				focus_first = keep_ff
		settings_box = keep)


# Rehace la pagina de la pestana manteniendo el foco en el mismo lugar (para cambios que afectan a otros controles).
func _settings_rebuild() -> void:
	var idx := -1
	var f: Control = get_viewport().gui_get_focus_owner()
	if f != null and settings_box.is_ancestor_of(f):
		idx = NAVG.focusables(settings_box).find(f)
	var sc := settings_host.get_parent() as ScrollContainer
	var keep_scroll: int = sc.scroll_vertical if sc != null else 0
	var keep_listen := listening
	if settings_pages.has(set_tab):
		var old: Node = settings_pages[set_tab]
		settings_pages.erase(set_tab)
		settings_host.remove_child(old)
		old.queue_free()
	_settings_content()
	listening = keep_listen
	if sc != null:
		sc.scroll_vertical = keep_scroll
	if idx >= 0:
		var items: Array = NAVG.focusables(settings_box)
		if idx < items.size():
			(items[idx] as Control).grab_focus()


func _set_sound() -> void:
	_sec("Sonido")
	_slider_row("Volumen general", "master")
	_slider_row("Música", "music")
	_slider_row("Efectos", "sfx")
	var mb := _btn("", func(): pass, Vector2(220, 50))
	var mute_look := func():
		var m: bool = bool(SV.d["settings"]["mute"])
		mb.text = L.t("Activar sonido") if m else L.t("Silenciar todo")
		_gold_on(mb, not m)
	mute_look.call()
	mb.pressed.connect(func():
		SV.d["settings"]["mute"] = not bool(SV.d["settings"]["mute"])
		SV.save()
		if Aud.inst != null:
			Aud.inst.apply()
		mute_look.call()
		_update_top())
	mb.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	settings_box.add_child(mb)
	settings_box.set_meta("on_show", mute_look)   # el sonido se puede silenciar tambien desde la barra superior


func _set_graphics() -> void:
	var lgh: Array = [null]
	_sx(func():
		_sec("Idioma")
		settings_box.add_child(_label("El juego se recarga al cambiarlo.", 18, Color("#c8d6ee")))
		var lg := GridContainer.new()
		lg.columns = 2
		lg.add_theme_constant_override("h_separation", 8)
		lg.add_theme_constant_override("v_separation", 8)
		settings_box.add_child(lg)
		lgh[0] = lg)
	for entry in L.LANGS:
		var code: String = entry[0]
		_sx(func():
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
			if code == L.lang():
				for st in ["normal", "hover", "pressed"]:
					lb.add_theme_stylebox_override(st, _sb(C_BTN_H, C_GOLD, 3, 22))
				lb.add_theme_color_override("font_color", C_GOLD)
			(lgh[0] as Control).add_child(lb))
	_sx(func():
		_sec("Calidad")
		_srow("Efectos y partículas", "Cuántos efectos se dibujan. Auto los baja solo si el juego va a tirones.", _seg(["Auto", "Alta", "Media", "Baja"], int(SV.d["settings"]["quality"]), func(i: int):
			SV.d["settings"]["quality"] = i
			SV.save())))
	_sx(func(): _srow("Rendimiento", "Si el juego va a tirones (sobre todo con movimientos fusión): Ahorro y Mínimo quitan efectos, estelas y números de daño sueltos y simplifican los disparos. No cambia el daño ni la dificultad.", _seg(["Normal", "Ahorro", "Mínimo"], SV.perf(), func(i: int):
		SV.set_perf(i))))
	_sx(func():
		_sec("Pantalla")
		_view_row())
	if DSP.is_desktop():
		_sx(func(): _srow("Modo de ventana", "Ventana o pantalla completa (solo en PC).", _seg(["Ventana", "Pantalla completa"], DSP.win_mode(), func(i: int):
			DSP.set_window(i, DSP.win_res())
			_refresh_settings())))
		_sx(func():
			var res_names: Array = []
			for rv in DSP.WIN_RES:
				res_names.append("%d×%d" % [rv.x, rv.y])
			_srow("Resolución de la ventana", "Tamaño de la ventana en PC. Si no cabe en tu pantalla se ajusta solo. No se usa en pantalla completa.", _seg(res_names, DSP.win_res(), func(i: int):
				DSP.set_window(DSP.win_mode(), i)
				_refresh_settings(), false)))
	_sx(func(): _srow("Límite de FPS", "Máximo de cuadros por segundo. En la consola 30 suele ir más fluido; más sube la velocidad, pero puede dar tirones.", _fps_btn()))
	_sx(func(): _srow("Números de daño", "Los números que salen al golpear o ser golpeado.", _toggle_set("dmg_numbers")))
	_sx(func(): _srow("Menos sacudidas y destellos", "La cámara tiembla menos y los destellos son más suaves.", _toggle_set("shake", true)))
	_sx(func(): _srow("Vibración", "Vibra el móvil cuando te golpean.", _toggle_set("vibration")))
	_sx(func(): _srow("Mostrar FPS", "Cuadros por segundo, en la esquina.", _toggle_set("fps")))
	_sx(func(): _srow("Caja de estadísticas", "Muestra tus estadísticas (daño, velocidad…) arriba a la izquierda.", _toggle_set("stats_box")))
	_sx(func(): _srow("Dificultad adaptativa", "En la partida normal, el juego empieza fácil y se pone más difícil según tus mejoras: más vida y daño, más enemigos, hordas más seguidas y más experiencia por nivel.", _toggle_set("adaptive")))


# Límite de cuadros: botón cíclico (pulsar o izquierda/derecha cambia el valor; ver "cycle" en _input).
const FPS_OPTS := [30, 40, 60, 0]   # 0 = sin límite


func _fps_cur() -> int:
	var v: int = int(SV.d["settings"].get("max_fps", -1))
	return v if v >= 0 else Engine.max_fps


func _fps_text(v: int) -> String:
	return "< %s >" % (L.t("Sin límite") if v == 0 else "%d FPS" % v)


func _fps_btn() -> Button:
	var b := _btn("", func(): pass, Vector2(220, 46))
	var step := func(d: int):
		var v: int = _fps_cur()
		var i: int = FPS_OPTS.find(v)
		if i < 0:   # valor ajeno (maxfps.txt): al siguiente mayor / menor de la lista
			i = 3
			for k in range(3):
				if int(FPS_OPTS[k]) >= v:
					i = k
					break
			i = clampi(i + (0 if d > 0 else -1), 0, 3)
		else:
			i = posmod(i + d, FPS_OPTS.size())
		SV.d["settings"]["max_fps"] = int(FPS_OPTS[i])
		SV.save()
		KO.apply_fps()
		b.text = _fps_text(int(FPS_OPTS[i]))
		Aud.sfx("hover")
	b.text = _fps_text(_fps_cur())
	b.pressed.connect(func(): step.call(1))
	b.set_meta("cycle", step)
	return b


func _set_controls() -> void:
	pad_btns = {}
	_sx(func():
		_sec("En móvil o tableta")
		settings_box.add_child(_label("Pon el dedo en cualquier parte y arrástralo para moverte: el joystick aparece donde tocas. Toca un movimiento abajo para cambiar a él y el botón de arriba a la derecha para pausar. Juega en horizontal.", 20, Color("#c8d6ee"))))
	_sx(func(): _srow("Tamaño del joystick", "Cuánto tienes que arrastrar el dedo.", _seg(["Pequeño", "Mediano", "Grande"], clampi(int(SV.d["settings"]["stick"]), 0, 2), func(i: int):
		SV.d["settings"]["stick"] = i
		SV.save())))
	_sx(func(): _srow("Joystick fijo", "El joystick se queda siempre abajo a la izquierda en vez de aparecer donde tocas.", _toggle_set("stick_fixed")))
	_sx(func():
		_sec("Mando")
		settings_box.add_child(_label("Stick izquierdo o cruceta: moverte y navegar por los menús. Pulsa un botón de la lista y luego el botón del mando que quieras asignarle.", 20, Color("#c8d6ee"))))
	_sx(func(): _srow("Tipo de mando", "Cambia los nombres de los botones y restablece la asignación.", _seg(PAD.NAMES, PAD.layout(), func(i: int):
		PAD.reset(i)
		_refresh_listen(), false)))
	for a in PAD.ACTIONS:
		var act: String = a
		_sx(func():
			var cb := _btn("", func():
				listening = "" if listening == act else act
				last_act = act
				_refresh_listen(), Vector2(190, 46))
			pad_btns[act] = cb
			_pad_btn_look(act)
			_srow(PAD.LABELS[act], "", cb)
			if act == last_act:
				focus_first = cb
				_gf(cb))
	_sx(func():
		var rb := _btn("Restablecer asignación", func(): PAD.reset(); last_act = ""; _refresh_listen(), Vector2(280, 46))
		settings_box.add_child(rb))


# Botones de asignacion de la pestana Controles (accion -> boton): se repintan en su sitio.
var pad_btns := {}


func _pad_btn_look(act: String) -> void:
	var cb: Button = pad_btns.get(act)
	if cb == null or not is_instance_valid(cb):
		return
	if listening == act:
		cb.text = L.t("Pulsa un botón…")
		cb.icon = null
		_gold_btn(cb, true)
	else:
		cb.text = ""
		_gold_on(cb, false)
		cb.icon = PADI.tex(PAD.btn(act))
		cb.expand_icon = true
		cb.add_theme_constant_override("icon_max_width", 36)
		cb.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER


# Repinta los botones de la pestana de controles (modo "escuchando" / asignacion nueva) sin reconstruir la pagina.
func _refresh_listen() -> void:
	for a in PAD.ACTIONS:
		_pad_btn_look(String(a))


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
	# la pagina se guarda entre pestanas: al volver a ella los botones vuelven a su texto normal
	settings_box.set_meta("on_show", func():
		if is_instance_valid(ib):
			ib.text = "Pegar código de guardado"   # como en _btn: el boton lo traduce solo
		if is_instance_valid(rb):
			rb.text = "Borrar todo el progreso")


func _danger(b: Button) -> void:
	for st in ["normal", "hover", "pressed"]:
		b.add_theme_stylebox_override(st, _sb(Color("#8a1f2d"), Color("#ff7a85"), 3, 12))
	b.add_theme_stylebox_override("focus", _sb(Color("#a92a3b"), Color.WHITE, 5, 12))


func _set_about() -> void:
	var t := _label("PokéSurvivor", 52, C_GOLD)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	settings_box.add_child(t)
	var pmb := _label(L.t("Un proyecto de DiehlWierce"), 26, C_GOLD)
	pmb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	settings_box.add_child(pmb)
	var ver := _label(L.t("Versión") + " " + UPD.APP_VERSION + " · PortMaster", 20, Color("#c8d6ee"))
	ver.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	settings_box.add_child(ver)
	settings_box.add_child(_label("Juego de fans gratis y sin ánimo de lucro: sin anuncios ni compras. Pokémon y sus personajes pertenecen a Nintendo, Creatures y GAME FREAK; este proyecto no está afiliado con ellos.", 20, Color("#c8d6ee")))
	_sec("Créditos")
	for line in ["• Proyecto, port para PortMaster y pruebas: DiehlWierce.", "• Basado en el juego original PokéSurvivor de JPTER78.", "• Y en el port a Godot/Android de JayElDragon.", "• Sprites: PMD SpriteCollab y sus artistas (CC BY-NC 4.0).", "• Datos Pokémon: PokéAPI.", "• Fuente: Pixelify Sans (OFL)."]:
		settings_box.add_child(_label(line, 20))
	var hb := HFlowContainer.new()
	hb.add_theme_constant_override("h_separation", 10)
	hb.alignment = FlowContainer.ALIGNMENT_CENTER
	settings_box.add_child(hb)
	var dxb := _btn("Pokédex", func(): _show("dex"), Vector2(0, 50))
	hb.add_child(dxb)
	hb.add_child(_btn("Repositorio del proyecto en GitHub", func(): OS.shell_open(REPO_URL_PM), Vector2(0, 50)))
	focus_first = dxb
