extends Node2D
# main.gd - Etapa 6: tabla de tipos, clima, objetos y estados (sobre la etapa 5: 64 movimientos).
# Teclado (WASD / flechas), mando (stick izquierdo / cruceta) o joystick tactil.
# Movimientos: teclas 1-4 / Q / E, LB / RB del mando, o toca el icono abajo a la derecha.
# Provisional: F1 / F2 (o boton Back del mando) cambian de Pokemon y reinician.
# Al caer: cualquier tecla, boton del mando o toque de pantalla reinicia.
# Cartas de nivel: tocalas, o 1/2/3, o izquierda/derecha + A en el mando.

const MD = preload("res://scripts/moves_data.gd")
const TD = preload("res://scripts/types_data.gd")
const SV = preload("res://scripts/save_data.gd")
const Aud = preload("res://scripts/audio.gd")
const L = preload("res://scripts/lang.gd")
const IC = preload("res://scripts/icons.gd")
const PXF = preload("res://scripts/pxfont.gd")
const DSP = preload("res://scripts/display.gd")
const PAD = preload("res://scripts/pad.gd")
const ARENA = preload("res://scripts/arena.gd")
const TW = preload("res://scripts/tileworld.gd")
const JDM = preload("res://scripts/judgment.gd")
const PG = preload("res://scripts/progress.gd")
const VFX = preload("res://scripts/vfx.gd")
const PFX = preload("res://scripts/pfx.gd")
const PAUSEUI = preload("res://scripts/pause_ui.gd")


const ENEMY_CAP := 64
const AIM_REACH := 520.0
const MAX_MOVES := 4
const ORB_CAP := 420
const BASE_MAGNET := 78.0
const XP_ENEMY := 20.0
const CHUNK := 768.0
const SAFE_R := 260.0
const POWERS := [
	{"id": "fury", "name": "Furia", "desc": "+50% de daño", "color": "#ff6b4a"},
	{"id": "haste", "name": "Impulso", "desc": "+40% de velocidad", "color": "#ffd33d"},
	{"id": "aegis", "name": "Égida", "desc": "-40% de daño recibido", "color": "#7fc8ff"},
	{"id": "frenzy", "name": "Frenesí", "desc": "-35% de recarga", "color": "#c47bff"},
]
const LIFT := 18.0
# Paredes de tierra: tamano del sprite (px nativos) y rectangulos solidos (px nativos desde la esquina sup. izq.)
const WALLS := {
	"wall_a": [Vector2i(39, 53), [Rect2(15, 0, 24, 16), Rect2(0, 16, 39, 37)]],
	"wall_af": [Vector2i(39, 53), [Rect2(0, 0, 24, 16), Rect2(0, 16, 39, 37)]],
	"wall_b": [Vector2i(39, 40), [Rect2(0, 0, 39, 40)]],
	"wall_c": [Vector2i(25, 53), [Rect2(0, 0, 25, 53)]],
	"wall_cf": [Vector2i(25, 53), [Rect2(0, 0, 25, 53)]],
}
const WALL_NAMES := ["wall_a", "wall_af", "wall_b", "wall_c", "wall_cf"]

const MULT_KEYS := ["dmg", "cd", "speed", "radius", "dur", "amount", "arc", "width", "spread", "life", "size", "rate"]
const ADD_KEYS := ["count", "pierce", "stacks"]
const TARGETED := ["melee", "beam", "projectile", "boomerang", "chain", "meteor", "dash", "cone"]

const FLASH_SHADER := "shader_type canvas_item;\nuniform float flash : hint_range(0.0, 1.0) = 0.0;\nvoid fragment() {\n\tvec4 m = COLOR;\n\tvec4 c = texture(TEXTURE, UV);\n\tCOLOR = vec4(mix(c.rgb, vec3(1.0), flash), c.a) * m;\n}\n"

# Animaciones de cada Pokemon (sprites.js) y la que se usa al lanzar cada tipo de movimiento.
const ANIMS := ["Idle", "Walk", "Attack", "Shoot", "Charge", "Hurt", "Faint"]
const ANIM_FOR := {
	"melee": "Attack", "beam": "Shoot", "projectile": "Shoot", "nova": "Attack", "aura": "Charge",
	"buff": "Charge", "orbit": "Charge", "boomerang": "Shoot", "chain": "Shoot", "mine": "Charge",
	"meteor": "Charge", "turret": "Charge", "dash": "Attack", "trail": "Walk", "cone": "Shoot",
}

# Tramos de enemigos (enemies.js): minuto de entrada (en segundos), rango de stats base y plantilla.
const TIERS := [
	{"from": 0, "bst": [180, 330], "hp": 17, "spd": 56, "dmg": 6.0, "xp": 3.5, "cast": 7},
	{"from": 70, "bst": [300, 405], "hp": 32, "spd": 62, "dmg": 8.5, "xp": 5.0, "cast": 7},
	{"from": 160, "bst": [385, 465], "hp": 52, "spd": 60, "dmg": 11.0, "xp": 8.0, "cast": 7},
	{"from": 260, "bst": [445, 515], "hp": 88, "spd": 70, "dmg": 14.0, "xp": 13.0, "cast": 7},
	{"from": 380, "bst": [495, 560], "hp": 150, "spd": 66, "dmg": 22.0, "xp": 24.0, "cast": 7},
	{"from": 500, "bst": [530, 620], "hp": 250, "spd": 72, "dmg": 28.0, "xp": 38.0, "cast": 7},
]
# Franjas de jefe: segundo en que salen, PV base, dano, experiencia y rango de stats base.
const BOSS_SLOTS := [
	{"at": 180, "hp": 1400, "dmg": 34, "xp": 220, "bst": [490, 545]},
	{"at": 360, "hp": 3200, "dmg": 42, "xp": 420, "bst": [520, 580]},
	{"at": 540, "hp": 5600, "dmg": 48, "xp": 680, "bst": [540, 600]},
	{"at": 720, "hp": 9000, "dmg": 56, "xp": 1000, "bst": [580, 700]},
	{"at": 900, "hp": 16000, "dmg": 68, "xp": 1800, "bst": [600, 700]},
]
const HEAL_SET := [35, 36, 113, 173, 183, 184, 242, 301, 440, 531, 594, 700, 764, 858]
const SHIELD_SET := [95, 122, 208, 213, 227, 306, 375, 410, 411, 436, 437, 439, 476, 703]
const BOMB_SET := [74, 75, 76, 100, 101, 102, 109, 110, 337, 338, 343, 344]
# Invocador -> Pokemon de su manada.
const SUMMON_MAP := {15: 13, 18: 16, 24: 23, 28: 27, 31: 29, 34: 32, 42: 41, 51: 50, 53: 52, 57: 56, 59: 58,
	62: 60, 68: 66, 73: 72, 78: 77, 82: 81, 85: 84, 91: 90, 117: 116, 130: 129, 168: 167, 169: 41,
	199: 79, 230: 116, 262: 261, 334: 333, 405: 403, 416: 415, 462: 81, 466: 239, 553: 551, 637: 636}
const PLAIN_B := ["chase", "charger", "ranged", "tank"]
const SUPPORT_B := ["healer", "shielder", "summoner"]
const KEEP_DIST := ["ranged", "fan", "beamer", "zoner", "healer", "summoner"]
const DMG_K := 2.4
const XP_K := 5.6
const SHINY_RATE := 1.0 / 4096.0

# Mejoras de estadistica (levelup.js). "w" = peso al sortear la carta.
const STAT_ICON := {"hp": "heart", "atk": "fist", "spd": "boot", "cd": "clock", "def": "shield", "rgn": "sprout", "mag": "magnet", "xp": "book", "heal": "berry"}
const STAT_IDS := ["hp", "atk", "spd", "cd", "def", "rgn", "mag", "xp", "heal"]
const STATS := {
	"hp": {"title": "Vigor", "desc": "+20 de vida máxima (y la recupera).", "max": 9999},
	"atk": {"title": "Potencia", "desc": "+10% de daño con todos los movimientos.", "max": 40},
	"spd": {"title": "Carrera", "desc": "+7% de velocidad de movimiento.", "max": 8},
	"cd": {"title": "Reflejos", "desc": "-8% de recarga en todos los movimientos.", "max": 10},
	"def": {"title": "Coraza", "desc": "+6% de reducción de daño recibido.", "max": 12},
	"rgn": {"title": "Síntesis", "desc": "+0.9 de vida regenerada por segundo.", "max": 9999},
	"mag": {"title": "Imán", "desc": "+30% de radio de recogida de experiencia.", "max": 6},
	"xp": {"title": "Aprendizaje", "desc": "+12% de experiencia ganada.", "max": 8},
	"heal": {"title": "Baya Zidra", "desc": "Recupera el 45% de tu vida ahora mismo.", "max": 99999},
}

var flash_shader: Shader
var ground: Node2D
var biome_idx := 0
var gen_q: Array = []
var gfx: Node2D
var world: Node2D
var fx: Node2D
var pfx: Node2D
var player: Player
var cam: Camera2D
var jd = null
var ui_layer: CanvasLayer
var hud: Hud
var stick: Stick
var slots: Slots
var cards: Cards
var enemies: Array = []
var bullets: Array = []
var orbs: Array = []
var fields: Array = []
var target: Node2D = null
var run_time := 0.0
var kills := 0
var spawn_acc := 0.0
var shake := 0.0
var death_t := 0.0
const DEATH_SLOW := 0.3      # camara lenta al desmayarse
const DEATH_SLOW_T := 0.6    # segundos de juego en camara lenta (0,6 / 0,3 = 2 s reales)
var choosing := false
var pending_levels := 0
var stat_lv := {}
var base_spd := 100.0
var base_atk := 1.0
var item := ""
var sash_t := -999.0
var bell_heal := 0.0
var wx_kind := ""
var wx_t := 0.0
var wx_dur := 0.0
var wx_check := 60.0
var wx_chip := 0.0
var wx_banner := 0.0
var wx: WeatherFx
var cast_run: Array = []
var boss_run: Array = []
var boss_idx := 0
var surge_t := 90.0
var preload_t := 0.0
var banner_text := ""
var banner_t := 0.0
var event_id := ""
var event_t := 0.0
var horde_defs: Array = []
var last_event := ""
var next_event_t := 270.0
var thief_t := 180.0
var thieves := 0
var hazards: Array = []
var ebullets: Array = []
var player_vel := Vector2.ZERO
var coins := 0
var paused := false
var pause_ui: CanvasLayer
var mini: Node2D
var cam_zoom := 1.65  # campo de vision: ajustable en la pausa (100-200 %), se guarda en Ajustes
var settings_open := false
var run_saved := false
var run_bosses := 0
var run_chests := 0
var perks: Dictionary = {}
var rerolls := 0
var bans := 0
var banned := {}
var dmg_on := true
var shake_on := true
var quality := 0
var q_auto := 1.0
var q_bad_t := 0.0
var world_seed := 0
var chunks := {}
var player_chunk := Vector2i(99999, 99999)
var power_kind := ""
var power_t := 0.0
var player_lava_t := 0.0
var trap_slow_t := 0.0
var tickets := 0
var tickets10 := 0
# --- grietas y arenas legendarias ---
const ARENA_POS := Vector2(60000.0, 60000.0)
const RIFT_START := 75.0
const RIFT_EVERY := 30.0
const RIFT_END := 1680.0
const ARENA_LIMIT := 120.0
var rift: Node2D = null
var rift_info := {}
var rift_check := RIFT_START
var rift_miss := 0
var arena: Node2D = null
var ainfo := {}
var bonds := 0
var bond_ids: Array = []
var bond_first := ""


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("#16233a"))
	randomize()
	L.apply()
	PXF.apply()
	DSP.apply(get_tree())
	DisplayServer.screen_set_keep_on(true)   # que el movil no se apague en plena partida
	PAD.apply()
	Aud.setup(self)
	Aud.music("forest")
	_add_input_actions()
	flash_shader = Shader.new()
	flash_shader.code = FLASH_SHADER

	ground = TW.new()
	add_child(ground)
	gfx = Node2D.new()
	add_child(gfx)
	world = Node2D.new()
	world.y_sort_enabled = true
	add_child(world)
	fx = Node2D.new()
	add_child(fx)
	pfx = PFX.new()
	pfx.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	fx.add_child(pfx)

	_load_data()
	_roll_run()
	surge_t = 90.0
	next_event_t = randf_range(240.0, 300.0)
	thief_t = randf_range(120.0, 240.0)
	perks = SV.perks()
	rerolls = int(perks["rerolls"])
	# Veto como en el original: los movimientos vetados se eligen en Mejoras (por Pokemon).
	bans = 0
	var _bl: Array = SV.ban_list(SV.run_dex)
	for _bi in range(mini(_bl.size(), int(perks["bans"]))):
		banned[String(_bl[_bi])] = true
	dmg_on = bool(SV.setting("dmg_numbers"))
	shake_on = bool(SV.setting("shake"))
	Actor.flash_k = 1.0 if shake_on else 0.35
	quality = int(SV.setting("quality"))
	pfx.setup([1.0, 1.0, 0.65, 0.35][clampi(quality, 0, 3)])
	var sel_dex: int = SV.run_dex
	var st: Dictionary = _dex_by[sel_dex]
	player = Player.new()
	player.setup(sel_dex, _sm(sel_dex), flash_shader)
	if SV.owns(sel_dex) and bool(SV.d["owned"][str(sel_dex)]["shiny"]) and bool(SV.d["shiny_on"]):
		player.set_shiny()
	player.max_hp = float(st["hp"]) + float(perks["hp"])
	player.hp = player.max_hp
	player.spd = float(st["spd"])
	player.atk = float(st["atk"])
	player.types = st["types"]
	base_spd = player.spd * float(perks["spd"])
	base_atk = player.atk * float(perks["atk"])
	for sid in STAT_IDS:
		stat_lv[sid] = 0
	player.xp_next = float(_xp_for(1))
	var first_move: String = SV.start_move_of(sel_dex)
	player.moves = [_new_move(first_move, 1)]
	if int(perks["moves"]) >= 2:
		var cands: Array = []
		for mid in MD.ORDER:
			var md: Dictionary = MD.MOVES[mid]
			var ty: String = String(md["type"])
			if mid != first_move and String(md["kind"]) != "buff" and (ty == "normal" or player.types.has(ty)):
				cands.append(mid)
		if not cands.is_empty():
			var okc: Array = []
			for cid in cands:
				if not banned.has(cid):
					okc.append(cid)
			if okc.is_empty():
				okc = cands
			player.moves.append(_new_move(String(okc[randi() % okc.size()]), 1))
	player.slot = 0
	_arrange()
	world.add_child(player)
	world_seed = randi() % 100000
	ground.setup(world_seed)
	Prop.tw = ground
	_update_world(0.0)
	cam = Camera2D.new()
	player.add_child(cam)
	_apply_fov()
	cam.make_current()

	var ui := CanvasLayer.new()
	add_child(ui)
	ui_layer = ui
	jd = JDM.new()
	jd.m = self
	wx = WeatherFx.new()
	ui.add_child(wx)
	hud = Hud.new()
	hud.show_fps = bool(SV.setting("fps"))
	hud.poke_name = L.t(String(st["name"]))
	ui.add_child(hud)
	mini = Minimap.new()
	mini.m = self
	mini.position = Vector2(8.0 + DSP.insets(get_tree()).x, 92.0)
	ui.add_child(mini)
	pause_ui = PAUSEUI.new()
	add_child(pause_ui)
	pause_ui.build()
	pause_ui.resume.connect(func(): paused = false)
	pause_ui.fov_changed.connect(func(_p: int): _apply_fov())
	pause_ui.stick_fixed_changed.connect(func(on: bool): stick.fixed = on; stick.queue_redraw())
	pause_ui.quit_run.connect(_abandon)
	pause_ui.open_settings.connect(_open_settings)
	stick = Stick.new()
	stick.radius = [70.0, 90.0, 120.0][clampi(int(SV.setting("stick")), 0, 2)]
	stick.fixed = bool(SV.d["settings"].get("stick_fixed", false))
	ui.add_child(stick)
	slots = Slots.new()
	ui.add_child(slots)
	slots.picked.connect(_set_active)
	cards = Cards.new()
	ui.add_child(cards)
	cards.chosen.connect(_on_card_chosen)
	cards.reroll_pressed.connect(_on_reroll)
	cards.ban_picked.connect(_on_ban)

	# Unos pocos al empezar, para que no se vea vacio al probar.
	for i in range(3):
		_spawn_one(randf() * TAU, true)


func _add_input_actions() -> void:
	if InputMap.has_action("move_left"):
		return
	var keys := {
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"move_up": [KEY_W, KEY_UP],
		"move_down": [KEY_S, KEY_DOWN],
	}
	var dpad := {
		"move_left": JOY_BUTTON_DPAD_LEFT,
		"move_right": JOY_BUTTON_DPAD_RIGHT,
		"move_up": JOY_BUTTON_DPAD_UP,
		"move_down": JOY_BUTTON_DPAD_DOWN,
	}
	var sticks := {
		"move_left": [JOY_AXIS_LEFT_X, -1.0],
		"move_right": [JOY_AXIS_LEFT_X, 1.0],
		"move_up": [JOY_AXIS_LEFT_Y, -1.0],
		"move_down": [JOY_AXIS_LEFT_Y, 1.0],
	}
	for action in keys:
		InputMap.add_action(action, 0.2)
		for k in keys[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = k
			InputMap.action_add_event(action, ev)
		var b := InputEventJoypadButton.new()
		b.button_index = dpad[action]
		InputMap.action_add_event(action, b)
		var m := InputEventJoypadMotion.new()
		m.axis = sticks[action][0]
		m.axis_value = sticks[action][1]
		InputMap.action_add_event(action, m)


func _unhandled_input(event: InputEvent) -> void:
	if settings_open:
		return
	var slot := -1
	var cyc := 0
	var go := false
	var toggle_pause := false
	var confirm := false
	var cancel := false
	var tpos := Vector2(-1.0, -1.0)
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1:
				slot = 0
			KEY_2:
				slot = 1
			KEY_3:
				slot = 2
			KEY_4:
				slot = 3
			KEY_Q:
				cyc = -1
			KEY_E:
				cyc = 1
			KEY_ESCAPE, KEY_P:
				toggle_pause = true
			KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
				confirm = true
			KEY_BACKSPACE, KEY_X:
				cancel = true
			_:
				go = true
	elif event is InputEventJoypadButton and event.pressed:
		var bi: int = event.button_index
		if bi == PAD.btn("confirm"):
			confirm = true
		elif bi == PAD.btn("cancel"):
			cancel = true
		elif bi == PAD.btn("prev"):
			cyc = -1
		elif bi == PAD.btn("next"):
			cyc = 1
		elif bi == PAD.btn("pause") or (bi == JOY_BUTTON_BACK and not PAD.is_mapped(JOY_BUTTON_BACK)):
			toggle_pause = true
		else:
			go = true
	elif event is InputEventScreenTouch and event.pressed:
		go = true
		tpos = event.position
	if player.dead:
		if (go or confirm or cancel or toggle_pause or slot >= 0) and death_t > 1.3:
			_go_menu()
	elif paused:
		if toggle_pause or cancel:
			paused = false
	elif not choosing:
		if toggle_pause:
			paused = true
		elif tpos.x >= 0.0 and hud.pause_rects()[0].has_point(tpos):
			paused = true
		elif slot >= 0:
			_set_active(slot)
		elif cyc != 0:
			_set_active(posmod(player.slot + cyc, _slot_list().size()))


# Boton atras de Android: pausa / reanuda; en la pantalla final vuelve al menu.
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and player != null:
		if player.dead:
			if death_t > 1.3:
				_go_menu()
		elif paused:
			paused = false
		elif not choosing:
			paused = true


# Ajustes dentro de la partida: la misma pantalla del menu, encima de la pausa.
func _open_settings() -> void:
	settings_open = true
	pause_ui.close()
	Engine.set_meta("menu_overlay", true)
	var cl := CanvasLayer.new()
	cl.layer = 100
	add_child(cl)
	var m: Control = load("res://scenes/menu.tscn").instantiate()
	cl.add_child(m)
	m.closed.connect(func():
		cl.queue_free()
		settings_open = false
		if paused:
			pause_ui.open())


func _go_menu() -> void:
	Engine.time_scale = 1.0
	get_tree().change_scene_to_file("res://scenes/menu.tscn")


func _finish_run() -> void:
	if run_saved:
		return
	run_saved = true
	var js: Dictionary = jd.summary()
	if not js.is_empty():
		var stt: Dictionary = SV.d["stats"]
		stt["judgeTime"] = maxi(int(stt.get("judgeTime", 0)), int(js["time"]))
		stt["judgeBosses"] = maxi(int(stt.get("judgeBosses", 0)), int(js["bosses"]))
	var mv_list: Array = []
	for mv in player.moves:
		mv_list.append({"id": String(mv["id"]), "name": String(mv["name"]), "lvl": int(mv["lvl"]), "evo": bool(mv["evolved"])})
	SV.finish_run({"judge": js, "time": run_time, "kills": kills, "level": player.level, "bosses": run_bosses,
		"chests": run_chests, "coins": coins, "tickets": tickets, "tickets10": tickets10, "dex": SV.run_dex,
		"dead": player.dead, "moves": mv_list})
	PG.event("runEnd", {"time": run_time, "level": player.level, "coins": coins, "types": player.types, "group": false})
	PG.check()


func _abandon() -> void:
	_finish_run()
	_go_menu()


func _on_reroll() -> void:
	if rerolls <= 0:
		return
	var picks: Array = _offer()
	if picks.is_empty():
		return
	rerolls -= 1
	var heading: String = cards.title
	var head: String = cards.headline
	cards.show_cards(picks, heading, head, true)
	cards.rerolls = rerolls
	cards.bans = bans


func _on_ban(idx: int) -> void:
	if bans <= 0 or idx < 0 or idx >= cards.items.size():
		return
	banned[String(cards.items[idx]["id"])] = true
	bans -= 1
	var picks: Array = _offer()
	if picks.is_empty():
		return
	var heading: String = cards.title
	var head: String = cards.headline
	cards.show_cards(picks, heading, head, true)
	cards.rerolls = rerolls
	cards.bans = bans


func _fx_cap() -> int:
	match quality:
		1:
			return 600
		2:
			return 160
		3:
			return 50
	return int(600.0 * q_auto) if q_auto > 0.2 else 50


func _process(delta: float) -> void:
	hud.paused = paused
	if not settings_open:
		var want_ui: bool = paused and not player.dead
		if want_ui != pause_ui.visible:
			if want_ui:
				pause_ui.open()
			else:
				pause_ui.close()
	if hud.toast_t > 0.0:
		hud.toast_t -= delta
	elif not PG.toasts.is_empty():
		var tt: Dictionary = PG.toasts.pop_front()
		hud.toast = {"text": L.t(String(tt["title"])) % L.t(String(tt["arg"])), "tier": int(tt["tier"]),
			"sub": (L.t(String(tt["sub"])) % String(tt["subarg"]) if String(tt["subarg"]) != "" else L.t(String(tt["sub"]))) if String(tt["sub"]) != "" else ""}
		hud.toast_t = 2.8
		Aud.sfx(String(tt.get("snd", "legend")))
	if quality == 0:
		# Auto: baja los efectos si el juego va a tirones.
		if Engine.get_frames_per_second() < 40 and run_time > 5.0:
			q_bad_t += delta
			if q_bad_t > 2.0:
				q_auto = maxf(0.1, q_auto * 0.6)
				q_bad_t = 0.0
		else:
			q_bad_t = 0.0
	var fcap := _fx_cap()
	if fx.get_child_count() > fcap:
		var over: int = fx.get_child_count() - fcap
		for i in range(fx.get_child_count()):
			if over <= 0:
				break
			var ch: Node = fx.get_child(i)
			if ch is Fx and not ch.is_queued_for_deletion():
				ch.queue_free()
				over -= 1
	if player.dead:
		death_t += delta
		if death_t >= DEATH_SLOW_T and Engine.time_scale != 1.0:
			Engine.time_scale = 1.0
		if not run_saved:
			_finish_run()
			Aud.music("")
			Aud.sfx("gameover")
	elif jd.cinematic() and not paused:
		jd.cine_tick(delta)
	elif not choosing and not paused:
		run_time += delta
		Aud.music(jd.music() if jd.active() else "rift" if arena != null else ("boss" if _boss_alive() else ["forest", "cave", "volcano"][biome_idx % 3]))
		_update_player(delta)
		if arena == null:
			_update_world(delta)
			_update_biome()
			_update_spawner(delta)
			_update_rift(delta)
			jd.update(delta)
			if run_time >= JDM.ARC_AT and not jd.done and pending_levels == 0:
				jd.begin()
		else:
			_update_arena(delta)
			if jd.active():
				jd.update(delta)
		_update_weather(delta)
		_update_enemies(delta)
		_update_hazards(delta)
		_update_ebullets(delta)
		_update_fields(delta)
		_update_bullets(delta)
		_update_orbs(delta)
		_cleanup_enemies()
		if pending_levels > 0 and not choosing:
			_open_cards()
		elif bonds > 0 and not choosing and arena == null:
			_offer_bond(true)
	ground.center = player.position
	cam.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * shake * (1.0 if shake_on else 0.0)
	shake = maxf(0.0, shake - 30.0 * delta)
	hud.hp = player.hp
	hud.max_hp = player.max_hp
	hud.run_time = run_time
	hud.kills = kills
	hud.dead = player.dead
	hud.death_t = death_t
	hud.show_end = player.dead and death_t > 1.3
	hud.level = player.level
	hud.xp = player.xp
	hud.xp_next = player.xp_next
	hud.buff_text = (_buff_text() + "  " + _power_text()).strip_edges()
	hud.power_id = power_kind
	hud.item_name = _item_name()
	hud.item_id = item
	hud.weather_text = _weather_text()
	hud.banner = banner_text if banner_t > 0.0 else _weather_banner()
	hud.coins = coins
	hud.tickets = tickets
	hud.tickets10 = tickets10
	_update_rift_hud()
	wx.kind = wx_kind
	wx.level = _wx_level()
	_refresh_slots()


func _refresh_slots() -> void:
	var info: Array = []
	var sl: Array = _slot_list()
	for g in sl:
		var m: Dictionary = g[0]
		var cdm: float = maxf(0.05, _f(m, "cd") * _cd_mul())
		info.append({
			"name": String(m["name"]),
			"color": _col(m),
			"lvl": int(m["lvl"]),
			"max": _max_lvl(m),
			"frac": clampf(1.0 - maxf(0.0, _f(m, "t")) / cdm, 0.0, 1.0),
			"evo": bool(m["evolved"]),
			"icon": ("evo:" if bool(m["evolved"]) else "move:") + String(m["id"]),
			"n": g.size(),
		})
	slots.info = info
	slots.active = player.slot
	slots.enabled = not choosing and not player.dead


# ---------------------------------------------------------------
# Estadisticas de la run (levelup.js / player.js)
# ---------------------------------------------------------------
func _lv(id: String) -> int:
	return int(stat_lv.get(id, 0))


func _buff_mul(stat: String) -> float:
	var b: Dictionary = player.buffs[stat]
	return float(b["n"]) * float(b["amount"])


func _has_item(id: String) -> bool:
	return item == id


func _item_name() -> String:
	if item == "":
		return ""
	for it in TD.ITEMS:
		if String(it["id"]) == item:
			return String(it["name"])
	return ""


func _atk() -> float:
	var k: float = 1.0
	if _has_item("choiceband"):
		k = 1.4
	elif _has_item("lifeorb"):
		k = 1.3
	return base_atk * pow(1.10, float(_lv("atk"))) * (1.0 + _buff_mul("atk")) * k * (1.5 if _pw("fury") else 1.0)


func _spd() -> float:
	var k: float = 1.35 if _has_item("choicescarf") else 1.0
	return base_spd * pow(1.07, float(_lv("spd"))) * (1.0 + _buff_mul("spd")) * k * (1.4 if _pw("haste") else 1.0)


func _cd_mul() -> float:
	var k: float = 0.8 if _has_item("quickclaw") else 1.0
	return pow(0.92, float(_lv("cd"))) * k * float(perks["cd"]) * (0.65 if _pw("frenzy") else 1.0)


func _reduction() -> float:
	var vest: float = 0.2 if _has_item("assaultvest") else 0.0
	return minf(0.8, minf(0.7, 0.06 * float(_lv("def"))) + vest + float(perks["def"]) + _buff_mul("def") + (0.4 if _pw("aegis") else 0.0))


func _regen() -> float:
	var left: float = player.max_hp * 0.015 if _has_item("leftovers") else 0.0
	return 0.9 * float(_lv("rgn")) + float(perks["regen"]) + _buff_mul("regen") + left


func _magnet() -> float:
	return BASE_MAGNET * pow(1.30, float(_lv("mag"))) * float(perks["magnet"])


func _xp_mul() -> float:
	var k: float = 1.3 if _has_item("luckyegg") else 1.0
	return pow(1.12, float(_lv("xp"))) * k * float(perks["xp"])


func _buff_text() -> String:
	var parts: Array = []
	var names := {"atk": "ATQ", "spd": "VEL", "def": "DEF", "regen": "REG"}
	for k in names:
		var b: Dictionary = player.buffs[k]
		if int(b["n"]) > 0:
			parts.append("%s x%d" % [L.t(String(names[k])), int(b["n"])])
	return "  ".join(parts)


# ---------------------------------------------------------------
# Movimientos: instancias, mejoras y evolucion (moves.js)
# ---------------------------------------------------------------
func _f(m: Dictionary, key: String, def: float = 0.0) -> float:
	return float(m.get(key, def))


func _col(m: Dictionary) -> Color:
	return Color.html(String(MD.TYPE_COLOR[String(m["type"])]))


func _apply_mods(m: Dictionary, mods: Dictionary) -> void:
	for k in mods:
		if MULT_KEYS.has(k) and m.has(k):
			m[k] = float(m[k]) * float(mods[k])
		elif ADD_KEYS.has(k):
			m[k] = float(m.get(k, 0)) + float(mods[k])
		else:
			m[k] = mods[k]


func _new_move(id: String, lvl: int) -> Dictionary:
	var def: Dictionary = MD.MOVES[id]
	var m: Dictionary = def.duplicate(true)
	m["lvl"] = 1
	m["t"] = 0.0
	m["evolved"] = false
	var ladder: Array = MD.LADDERS[String(m["kind"])]
	for i in range(lvl - 1):
		_apply_mods(m, ladder[i]["m"])
		m["lvl"] = int(m["lvl"]) + 1
	return m


func _max_lvl(m: Dictionary) -> int:
	var ladder: Array = MD.LADDERS[String(m["kind"])]
	return ladder.size() + 1


func _level_up_move(m: Dictionary) -> void:
	var ladder: Array = MD.LADDERS[String(m["kind"])]
	var lv: int = int(m["lvl"])
	if lv >= _max_lvl(m):
		return
	_apply_mods(m, ladder[lv - 1]["m"])
	m["lvl"] = lv + 1


# Devuelve {} si no puede evolucionar todavia.
func _evo_info(m: Dictionary) -> Dictionary:
	var id: String = String(m["id"])
	var kind: String = String(m["kind"])
	if not MD.EVO.has(id) or bool(m["evolved"]) or int(m["lvl"]) < _max_lvl(m) or not MD.EVO_MODS.has(kind):
		return {}
	var e: Array = MD.EVO[id]
	var needs: String = String(e[1])
	return {
		"name": String(e[0]),
		"needs": needs,
		"need_name": String(MD.NEED_NAME[needs]),
		"text": String(MD.EVO_MODS[kind]["t"]),
		"ready": _lv(needs) > 0,
	}


func _evolve(m: Dictionary) -> void:
	var id: String = String(m["id"])
	if not MD.EVO.has(id) or bool(m["evolved"]):
		return
	var e: Array = MD.EVO[id]
	_apply_mods(m, MD.EVO_MODS[String(m["kind"])]["m"])
	m["name"] = String(e[0])
	m["evolved"] = true
	PG.event("evolve", {"move": String(m["id"])})
	_ring(player.position, 8.0, 120.0, Color("#ffd23f"), 0.8)
	shake = 6.0


func _set_active(i: int) -> void:
	var sl: Array = _slot_list()
	if i < 0 or i >= sl.size() or i == player.slot:
		return
	if _has_item("choiceband"):
		add_text(player.position + Vector2(0.0, -player.body_h - 8.0), L.t("Cinta Elección"), Color("#ff8ad8"))
		return
	_clear_orbit_orbs()
	player.slot = i
	for m in sl[i]:
		m["t"] = minf(_f(m, "t"), _f(m, "cd") * 0.35)
	_ring(player.position, 6.0, player.radius * 3.4, _col(sl[i][0]), 0.3)


func _clear_orbit_orbs() -> void:
	for i in range(bullets.size() - 1, -1, -1):
		if bullets[i].orb:
			bullets[i].queue_free()
			bullets.remove_at(i)


# ---------------------------------------------------------------
# Jugador
# ---------------------------------------------------------------
func _update_player(delta: float) -> void:
	var v: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if v == Vector2.ZERO and stick.axis.length() > 0.15:
		v = stick.axis
	if v.length() > 1.0:
		v = v.normalized()
	var moving: bool = v.length() > 0.05
	var spd: float = _spd() * _player_terrain(delta) * (0.55 if trap_slow_t > 0.0 else 1.0)
	var old_pos: Vector2 = player.position
	player.position += v * spd * delta
	player.position = _collide(player.position, player.radius * 0.55)
	player_vel = (player.position - old_pos) / maxf(delta, 0.0001)
	player.invuln = maxf(0.0, player.invuln - delta)
	if bell_heal > 0.0:
		var bh: float = minf(bell_heal, 4.0 * delta)
		player.hp = minf(player.max_hp, player.hp + bh)
		bell_heal -= bh
	var reg: float = _regen()
	if reg > 0.0:
		player.hp = minf(player.max_hp, player.hp + reg * delta)
	player.attack_face = maxf(0.0, player.attack_face - delta)
	# Los potenciadores caducan.
	for k in player.buffs:
		var b: Dictionary = player.buffs[k]
		if int(b["n"]) > 0:
			b["t"] = float(b["t"]) - delta
			if float(b["t"]) <= 0.0:
				b["n"] = 0

	target = _nearest_enemy(player.position, AIM_REACH)
	if target != null:
		player.aim = (target.position - player.position).angle()
	elif moving:
		player.aim = v.angle()

	var face: float = player.aim
	if moving and player.attack_face <= 0.0:
		face = v.angle()
	player.face_angle(face)
	if moving:
		player.loop_anim("Walk", spd / 110.0)
	else:
		player.loop_anim("Idle", 1.0)

	for m in _active_group():
		if moving and String(m["id"]) == "flame-wheel":
			# Rastro de fuego de Rueda Fuego: llamas y chispas tras el jugador mientras corre.
			for k in range(2):
				pfx.trail("flame", "fire", player.position + Vector2(randf_range(-6.0, 6.0), -8.0), v)
			pfx.trail("ember", "fire", player.position + Vector2(0.0, -14.0), v)
		_tick_move(m, delta)


func _hurt_player(amount: float, atk_type: String = "", pure: bool = false) -> void:
	if player.invuln > 0.0 or player.dead:
		return
	var eff: String = ""
	if atk_type != "":
		var tk: float = _types_mult(atk_type, player.types, true)
		amount *= tk * _weather_mult(atk_type)
		eff = _eff_label(tk)
	var close: float = 1.0
	for gm in _active_group():
		if String(gm["kind"]) == "melee":
			close = 0.75        # cuerpo a cuerpo: recibes un 25% menos
	var d: float = maxf(1.0, amount * (1.0 - _reduction()) * close)
	if pure:
		d = maxf(1.0, amount)
	player.hp -= d
	player.invuln = 0.45
	Aud.sfx("hurt")
	if bool(SV.setting("vibration")):
		Input.vibrate_handheld(40)
	player.flash = 0.6
	shake = 5.0
	var tcol := Color("#ff6b7a")
	if eff == "super":
		tcol = Color("#ff3048")
	elif eff == "weak":
		tcol = Color("#c9a0a8")
	add_text(player.position + Vector2(0.0, -player.body_h - 4.0), "-" + str(roundi(d)), tcol, 24 if eff == "super" else 18)
	# Banda Focus: aguanta el golpe con 1 de vida (una vez cada 60 s).
	if player.hp <= 0.0 and _has_item("focussash") and run_time - sash_t > 60.0:
		sash_t = run_time
		player.hp = 1.0
		player.invuln = 1.2
		add_text(player.position + Vector2(0.0, -player.body_h - 20.0), L.t("¡Banda Focus!"), Color("#ff9a3d"), 24)
		_ring(player.position, 6.0, 70.0, Color("#ff9a3d"), 0.5)
	if player.hp <= 0.0 and arena != null and String(ainfo.get("phase", "")) == "fight":
		player.hp = 1.0
		player.invuln = 4.0
		ainfo["phase"] = "lost"
		ainfo["why"] = "lose"
		return
	if player.hp <= 0.0:
		player.hp = 0.0
		player.dead = true
		player.play("Faint", 1.0, true)   # desmayo en camara lenta antes de la pantalla final
		player.flash = 0.0
		Engine.time_scale = DEATH_SLOW
		player.active = false
		_clear_orbit_orbs()
		for e in enemies:
			e.active = false


# ---------------------------------------------------------------
# Ejecucion de movimientos (combat.js)
# ---------------------------------------------------------------
func _reach(m: Dictionary) -> float:
	var k: String = String(m["kind"])
	if k == "melee":
		return _f(m, "radius") + 30.0
	if k == "beam":
		return _f(m, "radius") + 20.0
	if k == "boomerang":
		return _f(m, "radius") + 40.0
	if k == "chain":
		return 280.0
	if k == "meteor":
		return 340.0
	if k == "dash":
		return _f(m, "radius") + 60.0
	if k == "cone":
		return _f(m, "speed") * _f(m, "life") + 30.0
	return 520.0


func _cut_by_move(m: Dictionary, kind: String) -> void:
	if arena != null:
		return
	if ["melee", "aura", "nova", "dash", "buff"].has(kind):
		_cut_grass(player.position, minf(150.0, maxf(40.0, _f(m, "radius") * 0.85)))
		return
	var dirv: Vector2 = Vector2.from_angle(player.aim)
	var reach: float = minf(260.0, _reach(m))
	var t := 20.0
	while t <= reach:
		_cut_grass(player.position + dirv * t, 38.0)
		t += 44.0


func _tick_move(m: Dictionary, delta: float) -> void:
	var kind: String = String(m["kind"])
	if kind == "orbit":
		_orbit(m, delta)
		return
	m["t"] = _f(m, "t") - delta
	if _f(m, "t") > 0.0:
		return
	# Los ataques con blanco esperan a tenerlo a tiro.
	if TARGETED.has(kind):
		if target == null or player.position.distance_to(target.position) > _reach(m):
			m["t"] = 0.05
			return
	var cd: float = maxf(0.05, _f(m, "cd") * _cd_mul())
	m["t"] = cd
	if _has_item("lifeorb") and kind != "trail":
		player.hp = maxf(1.0, player.hp - maxf(1.0, player.max_hp * 0.01))
	if m.has("iframes"):
		player.invuln = maxf(player.invuln, float(m["iframes"]))
	if kind != "trail":
		player.attack_face = 0.35
		player.play_attack(String(ANIM_FOR.get(kind, "Shoot")), maxf(0.12, cd))
	Aud.shot(kind, String(m.get("type", "normal")))
	_cut_by_move(m, kind)
	match kind:
		"projectile":
			_fire_projectiles(m)
		"melee":
			_melee(m)
		"beam":
			_beam(m)
		"nova":
			_nova(m)
		"aura":
			_aura(m)
		"buff":
			_buff(m)
		"boomerang":
			_boomerang(m)
		"chain":
			_chain(m)
		"mine":
			_mines(m)
		"meteor":
			_meteors(m)
		"turret":
			_turret(m)
		"dash":
			_dash(m)
		"trail":
			_trail_patch(m)
		"cone":
			_cone(m)


func _make_bullet(m: Dictionary, pos: Vector2, vel: Vector2, life: float, pierce: int) -> Bullet:
	var b := Bullet.new()
	b.position = pos
	b.ppos = pos
	b.vel = vel
	b.dmg = _f(m, "dmg") * _atk()
	b.r = _f(m, "size", 6.0)
	b.life = life
	b.pierce = pierce
	b.color = _col(m)
	b.homing = _f(m, "homing")
	b.burn = int(_f(m, "burn"))
	b.poison = int(_f(m, "poison"))
	b.slow = _f(m, "slow")
	b.knock = _f(m, "knock")
	b.mtype = String(m["type"])
	var vv: Dictionary = VFX.for_move(String(m["id"]), String(m["type"]))
	b.shape = String(vv["proj"])
	b.pal = String(vv["pal"])
	b.trail = String(vv.get("trail", ""))
	fx.add_child(b)
	bullets.append(b)
	return b


func _fire_projectiles(m: Dictionary) -> void:
	var n: int = maxi(1, int(_f(m, "count", 1.0)))
	var spread: float = _f(m, "spread")
	for i in range(n):
		var off: float = 0.0
		if n > 1:
			off = (float(i) / float(n - 1) - 0.5) * spread * float(n)
		var a: float = player.aim + off + randf_range(-0.03, 0.03)
		var d: Vector2 = Vector2.from_angle(a)
		_make_bullet(m, player.position + d * 3.0, d * _f(m, "speed"), _f(m, "life", 1.4), int(_f(m, "pierce")))
	pfx.spark(player.position + Vector2(0.0, -LIFT) + Vector2.from_angle(player.aim) * player.radius, _col(m), Vector2.from_angle(player.aim), 3)


func _nova(m: Dictionary) -> void:
	var n: int = maxi(3, int(_f(m, "count", 8.0)))
	for i in range(n):
		var a: float = float(i) / float(n) * TAU + randf_range(-0.06, 0.06)
		var d: Vector2 = Vector2.from_angle(a)
		_make_bullet(m, player.position + d * 3.0, d * _f(m, "speed"), _f(m, "life", 1.2), int(_f(m, "pierce")))
	_ring(player.position, player.radius, player.radius * 4.0, _col(m), 0.3)


func _cone(m: Dictionary) -> void:
	var n: int = maxi(2, int(_f(m, "count", 5.0)))
	var arc: float = _f(m, "arc", 0.9)
	for i in range(n):
		var a: float = player.aim + (float(i) / float(n - 1) - 0.5) * arc + randf_range(-0.05, 0.05)
		var sp: float = _f(m, "speed") * randf_range(0.85, 1.1)
		var d: Vector2 = Vector2.from_angle(a)
		_make_bullet(m, player.position + d * 4.0, d * sp, _f(m, "life", 0.5) * randf_range(0.85, 1.05), int(_f(m, "pierce")))


func _boomerang(m: Dictionary) -> void:
	var n: int = maxi(1, int(_f(m, "count", 1.0)))
	var spread: float = _f(m, "spread", 0.5)
	var out: float = _f(m, "radius") / maxf(1.0, _f(m, "speed"))
	for i in range(n):
		var off: float = 0.0
		if n > 1:
			off = (float(i) / float(n - 1) - 0.5) * spread * float(minf(float(n), 3.0))
		var d: Vector2 = Vector2.from_angle(player.aim + off)
		var b: Bullet = _make_bullet(m, player.position, d * _f(m, "speed"), out * 4.0 + 1.5, 999)
		b.boom = out
		b.bsp = _f(m, "speed") * 1.1


func _in_arc(from: Vector2, p: Vector2, aim: float, half: float) -> bool:
	var a: float = (p - from).angle()
	return absf(fposmod(a - aim + PI * 3.0, TAU) - PI) <= half


func _melee(m: Dictionary) -> void:
	var rad: float = _f(m, "radius")
	var arc: float = _f(m, "arc", 1.6)
	var half: float = minf(arc, TAU) * 0.5
	pfx.slash(player.position + Vector2(0.0, -LIFT * 0.5), player.aim, rad, arc, VFX.for_move(String(m["id"]), String(m["type"])))
	for e in enemies:
		if e.dead:
			continue
		if e.position.distance_to(player.position) > rad + e.radius * 0.5:
			continue
		if not _in_arc(player.position, e.position, player.aim, half):
			continue
		_hit_move(e, _f(m, "dmg") * _atk(), e.position - player.position, m)


func _beam(m: Dictionary) -> void:
	var ln: float = _f(m, "radius")
	var w: float = _f(m, "width", 30.0)
	var d: Vector2 = Vector2.from_angle(player.aim)
	pfx.beam(player.position + Vector2(0.0, -LIFT), player.aim, ln, w, VFX.for_move(String(m["id"]), String(m["type"])))
	shake = maxf(shake, 1.5)
	for e in enemies:
		if e.dead:
			continue
		var rel: Vector2 = e.position - player.position
		var along: float = rel.dot(d)
		if along < -e.radius or along > ln + e.radius:
			continue
		var side: float = absf(-rel.x * d.y + rel.y * d.x)
		if side <= w * 0.5 + e.radius:
			_hit_move(e, _f(m, "dmg") * _atk(), d, m)


func _aura(m: Dictionary) -> void:
	var rad: float = _f(m, "radius")
	_ring(player.position, rad * 0.5, rad, _col(m), 0.28, 2.0)
	var vis: Dictionary = VFX.for_move(String(m["id"]), String(m["type"]))
	if vis.has("aura"):
		for i in range(5):
			var a: float = randf() * TAU
			var r: float = rad * randf_range(0.45, 1.0)
			var pos: Vector2 = player.position + Vector2(cos(a) * r, sin(a) * r * 0.8 - LIFT * 0.5)
			var v := Vector2(-sin(a) * 70.0, cos(a) * 55.0)
			if vis.has("inward"):
				v = Vector2(-cos(a) * r * 2.2, -sin(a) * r * 1.8)
			elif vis.has("rise"):
				v = Vector2(randf_range(-10.0, 10.0), -55.0)
			pfx.sp(String(vis["aura"]), String(vis["pal"]), pos, {"v": v, "life": 0.42, "spin": randf_range(-6.0, 6.0) if VFX.spins(String(vis["aura"])) else 0.0})
	for e in enemies:
		if e.dead:
			continue
		if e.position.distance_to(player.position) <= rad + e.radius * 0.5:
			_hit_move(e, _f(m, "dmg") * _atk(), e.position - player.position, m)


func _buff(m: Dictionary) -> void:
	var stat: String = String(m["stat"])
	if player.buffs.has(stat):
		var b: Dictionary = player.buffs[stat]
		b["amount"] = _f(m, "amount")
		b["n"] = mini(int(_f(m, "stacks")), int(b["n"]) + 1)
		b["t"] = _f(m, "dur")
	_ring(player.position, player.radius * 2.4, player.radius * 1.1, _col(m), 0.35, 2.5)
	var bv: Dictionary = VFX.for_move(String(m["id"]), String(m["type"]))
	for i in range(3):
		pfx.sp(String(bv.get("buff", "arrow")), String(bv["pal"]), player.position + Vector2(randf_range(-player.radius * 1.4, player.radius * 1.4), -randf_range(0.0, player.body_h * 0.8)), {"v": Vector2(0.0, -70.0), "life": 0.6})


func _chain(m: Dictionary) -> void:
	var cur: Node2D = null
	if target != null and not target.dead and player.position.distance_to(target.position) <= _reach(m):
		cur = target
	else:
		cur = _nearest_enemy(player.position, _reach(m))
	if cur == null:
		return
	var from: Vector2 = player.position + Vector2(0.0, -LIFT)
	var k: float = 1.0
	var done := {}
	var n: int = maxi(1, int(_f(m, "count", 1.0)))
	var jump: float = _f(m, "radius", 140.0)
	for i in range(n):
		if cur == null:
			break
		done[cur.get_instance_id()] = true
		var to: Vector2 = cur.position + Vector2(0.0, -cur.body_h * 0.5)
		pfx.beam(from, (to - from).angle(), (to - from).length(), 10.0, VFX.for_move(String(m["id"]), String(m["type"])))
		var hex: float = 1.0
		if m.has("hex") and (cur.burn > 0 or cur.poison > 0 or cur.slow > 0.0):
			hex = _f(m, "hex")
		_hit_move(cur, _f(m, "dmg") * _atk() * k * hex, to - from, m)
		k *= 0.85
		from = to
		var best: Node2D = null
		var bd: float = jump * jump
		for e in enemies:
			if e.dead or done.has(e.get_instance_id()):
				continue
			var d2: float = cur.position.distance_squared_to(e.position)
			if d2 < bd:
				bd = d2
				best = e
		cur = best
	shake = maxf(shake, 1.0)


func _new_field(kind: String, m: Dictionary, pos: Vector2) -> Field:
	var f := Field.new()
	f.kind = kind
	f.move = m
	f.color = _col(m)
	f.vis = VFX.for_move(String(m["id"]), String(m["type"]))
	f.position = pos
	f.dmg = _f(m, "dmg") * _atk()
	if kind == "turret":
		world.add_child(f)
	else:
		gfx.add_child(f)
	fields.append(f)
	return f


func _trim_fields(kind: String, keep: int) -> void:
	var mine: Array = []
	for f in fields:
		if f.kind == kind and not f.gone:
			mine.append(f)
	var extra: int = mine.size() - keep
	for i in range(maxi(0, extra)):
		mine[i].gone = true


func _mines(m: Dictionary) -> void:
	var n: int = maxi(1, int(_f(m, "count", 1.0)))
	for i in range(n):
		var a: float = randf() * TAU
		var d: float = 0.0
		if n > 1:
			d = randf_range(18.0, 46.0)
		var f: Field = _new_field("mine", m, player.position + Vector2(cos(a) * d, sin(a) * d * 0.8))
		f.arm = 0.35
		f.life = _f(m, "dur", 7.0)
		f.r = _f(m, "radius")
	_trim_fields("mine", 4 + n * 2)


func _meteors(m: Dictionary) -> void:
	var n: int = maxi(1, int(_f(m, "count", 1.0)))
	var near: Array = []
	for e in enemies:
		if not e.dead and e.position.distance_to(player.position) <= _reach(m):
			near.append(e)
	near.shuffle()
	for i in range(n):
		var pos: Vector2
		if i < near.size():
			pos = near[i].position + Vector2(randf_range(-8.0, 8.0), randf_range(-6.0, 6.0))
		else:
			pos = player.position + Vector2(randf_range(-140.0, 140.0), randf_range(-110.0, 110.0))
		var f: Field = _new_field("meteor", m, pos)
		f.t = -float(i) * 0.09
		f.fall = 0.5
		f.r = _f(m, "radius")


func _turret(m: Dictionary) -> void:
	var a: float = player.aim + PI + randf_range(-0.6, 0.6)
	var f: Field = _new_field("turret", m, player.position + Vector2(cos(a) * 26.0, sin(a) * 20.0))
	f.life = _f(m, "dur", 6.0)
	f.shot_t = 0.3
	_trim_fields("turret", maxi(1, int(_f(m, "count", 1.0))))
	_ring(player.position, 4.0, 30.0, _col(m), 0.3)


func _dash(m: Dictionary) -> void:
	var d: Vector2 = Vector2.from_angle(player.aim)
	var start: Vector2 = player.position
	var ln: float = _f(m, "radius")
	var w: float = _f(m, "width", 34.0)
	var dest: Vector2 = start + d * ln
	var dv: Dictionary = VFX.for_move(String(m["id"]), String(m["type"]))
	for s in range(0, int(ln) + 1, 22):
		pfx.sp(String(dv.get("proj", "streak")), String(dv["pal"]), start + d * float(s) + Vector2(0.0, -LIFT * 0.6), {"life": 0.22, "angle": player.aim})
	pfx.slash(dest + Vector2(0.0, -LIFT * 0.5), player.aim, 34.0, 2.2, dv)
	player.position = dest
	player.invuln = maxf(player.invuln, _f(m, "iframes", 0.3))
	for e in enemies:
		if e.dead:
			continue
		var cp: Vector2 = Geometry2D.get_closest_point_to_segment(e.position, start, dest)
		var rr: float = w * 0.5 + e.radius
		if cp.distance_squared_to(e.position) <= rr * rr:
			_hit_move(e, _f(m, "dmg") * _atk(), d, m)
	shake = maxf(shake, 3.0)


func _trail_patch(m: Dictionary) -> void:
	var rad: float = _f(m, "radius")
	# Parado no deja uno nuevo encima del anterior.
	if player.last_patch != null and is_instance_valid(player.last_patch):
		var last: Field = player.last_patch
		if last.position.distance_squared_to(player.position) < pow(rad * 0.9, 2.0) and last.t < 1.0:
			return
	var f: Field = _new_field("patch", m, player.position)
	f.life = _f(m, "dur", 3.0)
	f.r = rad
	f.tick = 0.0
	player.last_patch = f
	_trim_fields("patch", 18)


func _orbit(m: Dictionary, delta: float) -> void:
	var want: int = maxi(1, int(_f(m, "count", 1.0)))
	var mid: String = String(m["id"])
	var mine: Array = []
	for ob in bullets:
		if ob.orb and ob.mid == mid:
			mine.append(ob)
	var relayout: bool = mine.size() != want
	var base_a: float = run_time * _f(m, "speed")
	if mine.size() > 0:
		base_a = mine[0].oa
	while mine.size() > want:
		var ex = mine.pop_back()
		ex.queue_free()
		bullets.erase(ex)
	for i in range(mine.size(), want):
		var nb := Bullet.new()
		nb.orb = true
		nb.mid = mid
		var ov: Dictionary = VFX.for_move(mid, String(m["type"]))
		nb.shape = String(ov["proj"])
		nb.pal = String(ov["pal"])
		nb.oa = float(i) / float(want) * TAU
		nb.life = 1.0e9
		nb.pierce = 999999
		nb.position = player.position
		fx.add_child(nb)
		bullets.append(nb)
		mine.append(nb)
	for i in range(mine.size()):
		var ob = mine[i]
		ob.dmg = _f(m, "dmg") * _atk()
		ob.orad = _f(m, "radius")
		ob.ospeed = _f(m, "speed")
		ob.r = _f(m, "size", 8.0)
		ob.color = _col(m)
		ob.rehit = maxf(0.12, _f(m, "cd"))
		ob.knock = _f(m, "knock")
		ob.burn = int(_f(m, "burn"))
		ob.poison = int(_f(m, "poison"))
		ob.slow = _f(m, "slow")
		ob.mtype = String(m["type"])
		if relayout:
			ob.oa = base_a + float(i) / float(mine.size()) * TAU
	player.orb_cast_t -= delta
	if player.orb_cast_t <= 0.0:
		player.orb_cast_t = 1.6
		player.play_attack("Shoot", 1.6)


# Tabla de tipos suavizada (types.js): x1.6 / x0.6 / x0.3, tope [0.3, 2.4]. Al jugador: debilidad x1.3 (tope 1.6).
func _types_mult(atk: String, defs: Array, for_player: bool = false) -> float:
	if not TD.CHART.has(atk):
		return 1.0
	var row: Dictionary = TD.CHART[atk]
	var m: float = 1.0
	for t in defs:
		if row.has(t):
			var v: float = float(row[t])
			if v > 1.0:
				m *= 1.3 if for_player else 1.6   # el jugador no es castigado por su tipo favorito
			elif v > 0.0:
				m *= 0.6
			else:
				m *= 0.3
	return clampf(m, 0.3, 1.6 if for_player else 2.4)


func _eff_label(k: float) -> String:
	if k > 1.05:
		return "super"
	if k < 0.95:
		return "weak"
	return ""


func _type_mult(mtype: String, e) -> float:
	return _types_mult(mtype, e.types) * _weather_mult(mtype)


func _hit_move(e, dmg: float, dir: Vector2, m: Dictionary) -> void:
	_hit_enemy(e, dmg, _col(m), dir, _f(m, "knock"), String(m["type"]),
		int(_f(m, "burn")), int(_f(m, "poison")), _f(m, "slow"))


func _hit_enemy(e, dmg: float, col: Color, dir: Vector2, knock: float, mtype: String, burn: int, poison: int, slow: float) -> void:
	var eff: String = _eff_label(_types_mult(mtype, e.types))
	var d_final: float = dmg * _type_mult(mtype, e)
	if float(perks["crit"]) > 0.0 and randf() < float(perks["crit"]):
		d_final *= 1.5
		add_text(e.position + Vector2(0.0, -e.body_h - 26.0), L.t("¡Crítico!"), Color("#ffb347"), 16)
	if _has_item("shellbell"):
		bell_heal = minf(4.0, bell_heal + d_final * 0.04)
	_damage_enemy(e, d_final, col, dir, knock, eff)
	if e.dead:
		return
	if burn > 0:
		e.apply_burn(burn)
	if poison > 0:
		e.apply_poison(poison)
	if slow > 0.0:
		e.apply_slow(slow)


func _ring(pos: Vector2, r0: float, r1: float, color: Color, life: float, width: float = 3.0) -> void:
	pfx.ring(pos + Vector2(0.0, -LIFT * 0.5), r0, r1, color, life, width)


# ---------------------------------------------------------------
# Campos persistentes: minas, meteoros, torretas, charcos
# ---------------------------------------------------------------
func _blast(f: Field, r: float, k: float) -> void:
	var m: Dictionary = f.move
	for e in enemies:
		if e.dead:
			continue
		if e.position.distance_to(f.position) <= r + e.radius * 0.5:
			_hit_move(e, f.dmg * k, e.position - f.position, m)


func _update_fields(delta: float) -> void:
	for i in range(fields.size() - 1, -1, -1):
		var f: Field = fields[i]
		f.t += delta
		if f.gone or (f.life > 0.0 and f.t >= f.life and f.kind != "mine"):
			f.queue_free()
			fields.remove_at(i)
			continue
		var m: Dictionary = f.move
		if f.kind == "mine":
			var trig: bool = false
			if f.t >= f.arm:
				for e in enemies:
					if not e.dead and e.position.distance_to(f.position) <= 14.0 + e.radius * 0.5:
						trig = true
						break
			if trig or f.t >= f.life:
				_ring(f.position, 4.0, f.r, f.color, 0.3)
				pfx.burst(f.position + Vector2(0.0, -6.0), f.color, 10, 150.0)
				shake = maxf(shake, 2.0)
				_blast(f, f.r, 1.0 if trig else 0.5)
				f.queue_free()
				fields.remove_at(i)
		elif f.kind == "meteor":
			if f.t >= f.fall:
				_ring(f.position, 4.0, f.r, f.color, 0.35)
				pfx.burst(f.position + Vector2(0.0, -6.0), f.color, 12, 170.0)
				shake = maxf(shake, 4.0)
				_blast(f, f.r, 1.0)
				f.queue_free()
				fields.remove_at(i)
		elif f.kind == "turret":
			f.shot_t -= delta
			if f.shot_t <= 0.0:
				var tg: Node2D = _nearest_enemy(f.position, _f(m, "range", 300.0))
				f.shot_t = 0.15
				if tg != null:
					f.shot_t = _f(m, "rate", 0.6)
					var d: Vector2 = (tg.position - f.position).normalized()
					var b: Bullet = _make_bullet(m, f.position, d * _f(m, "speed", 300.0), 1.4, int(_f(m, "pierce")))
					b.dmg = f.dmg
					b.r = _f(m, "size", 6.0)
					f.kick = 0.12
			if f.kick > 0.0:
				f.kick -= delta
		elif f.kind == "patch":
			f.tick -= delta
			if f.tick <= 0.0:
				f.tick = 0.5
				_blast(f, f.r, 1.0)
			if f.vis.has("aura") and randf() < delta * 3.0:
				var ap: Vector2 = f.position + Vector2(randf_range(-f.r, f.r) * 0.6, -4.0)
				pfx.sp(String(f.vis["aura"]), String(f.vis["pal"]), ap, {"v": Vector2(0.0, -40.0), "life": 0.4})


# Enemigos: datos, reparto de la run, oleadas, jefes, eventos y comportamientos
# (enemies.js, spawner.js, enemy.js, hazards.js, events.js)
# ---------------------------------------------------------------
static var _dex_list: Array = []
static var _dex_by: Dictionary = {}
static var _smeta: Dictionary = {}


func _load_data() -> void:
	SV.ensure()
	_dex_list = SV.dex_list
	_dex_by = SV.dex_by
	_smeta = SV.smeta


func _sm(dex: int) -> Dictionary:
	return _smeta[str(dex)]


# Hash determinista (util.js) con enteros de 32 bits.
func _hash(x: int, y: int, seed_v: int) -> float:
	var h: int = ((x & 0xFFFFFFFF) * 374761393) & 0xFFFFFFFF
	h = h ^ (((y & 0xFFFFFFFF) * 668265263) & 0xFFFFFFFF)
	h = h ^ (((seed_v & 0xFFFFFFFF) * 2246822519) & 0xFFFFFFFF)
	h = ((h ^ (h >> 13)) * 1274126177) & 0xFFFFFFFF
	h = h ^ (h >> 16)
	return float(h & 0xFFFFFFFF) / 4294967296.0


func _pick_n(arr: Array, n: int) -> Array:
	var c: Array = arr.duplicate()
	c.shuffle()
	return c.slice(0, mini(n, c.size()))


func _has_t(types: Array, xs: Array) -> bool:
	for x in xs:
		if types.has(x):
			return true
	return false


func _base_hp(p: Dictionary) -> float:
	return (float(p["hp"]) - 70.0) / 0.45


func _base_spd(p: Dictionary) -> float:
	return (float(p["spd"]) - 78.0) / 0.42


static var _beh_cache: Dictionary = {}


func _behavior_of(p: Dictionary) -> String:
	var dex: int = int(p["dex"])
	if _beh_cache.has(dex):
		return String(_beh_cache[dex])
	var r: String = _behavior_calc(p)
	_beh_cache[dex] = r
	return r


func _behavior_calc(p: Dictionary) -> String:
	var dex: int = int(p["dex"])
	var t: Array = p["types"]
	var h: float = _hash(dex, 7, 11)
	if HEAL_SET.has(dex):
		return "healer"
	if SHIELD_SET.has(dex):
		return "shielder"
	if BOMB_SET.has(dex):
		return "bomber"
	if SUMMON_MAP.has(dex) and _smeta.has(str(SUMMON_MAP[dex])):
		return "summoner"
	if _has_t(t, ["bug"]) and h >= 0.6 and h < 0.78:
		return "summoner"
	if _has_t(t, ["electric", "psychic", "dragon", "ice"]) and h < 0.18:
		return "beamer"
	if _has_t(t, ["fire", "ground", "poison"]) and h < 0.18:
		return "zoner"
	if _has_t(t, ["water", "grass", "bug", "fairy"]) and h >= 0.18 and h < 0.32:
		return "fan"
	if _has_t(t, ["fighting", "ground", "normal", "rock"]) and h >= 0.42 and h < 0.56:
		return "jumper"
	if _has_t(t, ["psychic", "electric", "ghost", "fairy"]) and h < 0.4:
		return "ranged"
	if _has_t(t, ["fire", "water", "poison", "ice"]) and h < 0.22:
		return "ranged"
	if _has_t(t, ["fighting", "normal", "ground", "rock", "dragon", "steel", "dark"]) and h < 0.4:
		return "charger"
	if _base_hp(p) > 95.0 and _base_spd(p) < 50.0:
		return "tank"
	return "chase"


func _def_for(p: Dictionary, tier: Dictionary, ti: int) -> Dictionary:
	var hp_k: float = clampf(_base_hp(p) / 65.0, 0.7, 1.6)
	var spd_k: float = clampf(0.75 + _base_spd(p) / 260.0, 0.75, 1.3)
	var b: String = _behavior_of(p)
	var tank: bool = b == "tank"
	var d := {
		"dex": int(p["dex"]), "name": String(p["name"]), "behavior": b,
		"hp": roundf(float(tier["hp"]) * hp_k * (1.5 if tank else 1.0)),
		"spd": roundf(float(tier["spd"]) * spd_k * (0.7 if tank else 1.0)),
		"dmg": roundf(float(tier["dmg"]) * (1.2 if tank else 1.0)),
		"xp": maxf(3.0, roundf(float(tier["xp"]) * (1.3 if tank else 1.0))),
	}
	var cds := {"ranged": 2.2 - float(ti) * 0.15, "fan": 3.2 - float(ti) * 0.15, "beamer": 4.4 - float(ti) * 0.2,
		"zoner": 4.6 - float(ti) * 0.2, "healer": 3.5, "summoner": 7.0}
	if cds.has(b):
		d["shotDmg"] = roundf(float(tier["dmg"]) * (0.7 if b == "fan" else 0.8))
		d["shotCd"] = snappedf(float(cds[b]), 0.01)
		var rg: float = 190.0
		if b == "beamer":
			rg = 260.0
		elif b == "healer" or b == "summoner":
			rg = 230.0
		d["range"] = rg + float(ti) * 6.0
	if b == "summoner":
		d["minion"] = int(SUMMON_MAP.get(int(p["dex"]), int(p["dex"])))
	if b == "fan":
		d["fanN"] = 3 if ti < 2 else 5
	if b == "zoner":
		d["zones"] = 1 if ti < 2 else (2 if ti < 4 else 3)
	if b == "bomber":
		d["spd"] = roundf(float(d["spd"]) * 1.25)
		d["hp"] = roundf(float(d["hp"]) * 0.8)
	return d


static var _cand_cache: Dictionary = {}


func _candidates(ti: int) -> Array:
	if _cand_cache.has(ti):
		return _cand_cache[ti]
	var tier: Dictionary = TIERS[ti]
	var lo: float = float(tier["bst"][0])
	var hi: float = float(tier["bst"][1])
	var out: Array = []
	for p in _dex_list:
		if int(p["rarity"]) < 5 and float(p["bst"]) >= lo and float(p["bst"]) <= hi and _smeta.has(str(int(p["dex"]))):
			out.append(p)
	_cand_cache[ti] = out
	return out


func _cast_for(ti: int) -> Array:
	var tier: Dictionary = TIERS[ti]
	var all: Array = _candidates(ti)
	var kinds: Array = []
	for k in SUPPORT_B:
		for p in all:
			if _behavior_of(p) == k:
				kinds.append(k)
				break
	var pick: Array = []
	if not kinds.is_empty():
		var sk: String = String(kinds[randi() % kinds.size()])
		var pool_s: Array = []
		for p in all:
			if _behavior_of(p) == sk:
				pool_s.append(p)
		pick = _pick_n(pool_s, 1)
	var need: int = int(tier["cast"])
	if int(tier["from"]) > 0:
		var pool_x: Array = []
		for p in all:
			var bb: String = _behavior_of(p)
			if not PLAIN_B.has(bb) and not SUPPORT_B.has(bb):
				pool_x.append(p)
		pick.append_array(_pick_n(pool_x, 1))
	var rest: Array = []
	for p in all:
		if pick.has(p):
			continue
		if int(tier["from"]) == 0 and not PLAIN_B.has(_behavior_of(p)):
			continue
		rest.append(p)
	pick.append_array(_pick_n(rest, need - pick.size()))
	return pick


func _roll_run() -> void:
	cast_run = []
	for ti in range(TIERS.size()):
		var list: Array = []
		for p in _cast_for(ti):
			list.append(_def_for(p, TIERS[ti], ti))
		cast_run.append({"from": int(TIERS[ti]["from"]), "list": list})
	# En cada tramo, el mas rapido de los normales pasa a ser el corredor.
	for tier in cast_run:
		var best: Dictionary = {}
		for d in tier["list"]:
			var bb: String = String(d["behavior"])
			if bb == "chase" or bb == "charger" or bb == "tank":
				if best.is_empty() or float(d["spd"]) > float(best["spd"]):
					best = d
		if not best.is_empty():
			best["behavior"] = "runner"
			best["spd"] = roundf(float(best["spd"]) * 1.6)
			best["hp"] = roundf(float(best["hp"]) * 0.7)
	boss_run = []
	var used := {}
	for slot in BOSS_SLOTS:
		var pool: Array = []
		for p in _dex_list:
			var dx: int = int(p["dex"])
			if bool(p.get("leg", false)) or not _smeta.has(str(dx)) or used.has(dx):
				continue
			if float(p["bst"]) >= float(slot["bst"][0]) and float(p["bst"]) <= float(slot["bst"][1]):
				pool.append(p)
		if pool.is_empty():
			for p in _dex_list:
				var dx2: int = int(p["dex"])
				if not bool(p.get("leg", false)) and _smeta.has(str(dx2)) and not used.has(dx2) and float(p["bst"]) >= 580.0:
					pool.append(p)
		var bp: Dictionary = pool[randi() % pool.size()]
		used[int(bp["dex"])] = true
		var bb2: String = "chase"
		if _behavior_of(bp) == "ranged":
			bb2 = "ranged"
		elif _base_spd(bp) > 90.0:
			bb2 = "charger"
		boss_run.append({
			"at": float(slot["at"]), "dex": int(bp["dex"]), "name": String(bp["name"]),
			"hp": roundf(float(slot["hp"]) * 1.35), "spd": roundf(clampf(40.0 + _base_spd(bp) * 0.5, 40.0, 100.0)),
			"dmg": roundf(float(slot["dmg"]) * 1.2), "xp": float(slot["xp"]), "behavior": bb2,
			"shotDmg": roundf(float(slot["dmg"]) * 0.55), "shotCd": 1.1, "range": 260.0,
		})


func _tier_at(t: float) -> int:
	var ti: int = 0
	for i in range(TIERS.size()):
		if t >= float(TIERS[i]["from"]):
			ti = i
	return ti


func _bag_at(t: float) -> Array:
	if event_id == "horde" and not horde_defs.is_empty():
		return horde_defs
	var bag: Array = []
	for tier in cast_run:
		if t < float(tier["from"]):
			continue
		var w: int = 3 if t - float(tier["from"]) > 260.0 else 10
		for d in tier["list"]:
			for i in range(w):
				bag.append(d)
	if bag.is_empty():
		return cast_run[0]["list"]
	return bag


func _hp_k(t: float) -> float:
	return 3.3 + minf(1.7, t / 210.0)


func _scale_at(t: float) -> Dictionary:
	return {"hp": 1.0 + t / 95.0, "dmg": 1.0 + t / 420.0, "spd": 1.0 + minf(0.35, t / 1400.0)}


func _boss_scale_k(dex: int) -> float:
	var idle: Dictionary = _sm(dex)["a"]["Idle"] if _sm(dex)["a"].has("Idle") else _sm(dex)["a"]["Walk"]
	var h: float = float(idle["ay"]) * 2.0
	return clampf(roundf(110.0 / h * 2.0) / 2.0, 1.0, 2.0)


func _say(text: String, secs: float = 2.6) -> void:
	banner_text = L.t(text)
	banner_t = secs


func _make_enemy(def: Dictionary, pos: Vector2, sc: Dictionary, boss: bool = false) -> Enemy:
	var dex: int = int(def["dex"])
	var p: Dictionary = _dex_by[dex]
	var sm: Dictionary = _sm(dex)
	var e := Enemy.new()
	var scl: float = _boss_scale_k(dex) if boss else 1.0
	e.setup(dex, sm, flash_shader, scl, false)
	e.def = def
	e.boss = boss
	e.behavior = String(def["behavior"])
	e.enemy_name = L.t(String(p["name"]))
	var ty: Array = p["types"]
	e.types = ty if not ty.is_empty() else ["normal"]
	e.atk_type = String(e.types[0])
	e.flying = boss or bool(sm.get("hv", 0))
	e.max_hp = roundf(float(def["hp"]) * float(sc["hp"]))
	e.hp = e.max_hp
	e.spd = float(def["spd"]) * float(sc["spd"])
	e.dmg = float(def["dmg"]) * float(sc["dmg"])
	e.xp_val = float(def["xp"])
	e.sc = sc
	if def.has("shotCd"):
		e.shot_cd = randf_range(0.3, float(def["shotCd"]))
	e.skill_cd = randf_range(1.0, 4.0)
	e.bob = randf() * TAU
	e.position = pos
	world.add_child(e)
	enemies.append(e)
	return e


func _apply_fov() -> void:
	var pct: int = clampi(int(SV.d["settings"].get("fov", 165)), 100, 200)
	cam_zoom = float(pct) / 100.0
	if cam != null:
		cam.zoom = Vector2(cam_zoom, cam_zoom)


func _ring_point(angle: float) -> Vector2:
	var d: float = get_viewport_rect().size.length() * 0.5 / cam_zoom + randf_range(10.0, 70.0)
	return player.position + Vector2(cos(angle) * d, sin(angle) * d * 0.9)


func _spawn_one(angle: float = -999.0, near: bool = false) -> Enemy:
	var bag: Array = _bag_at(run_time)
	var def: Dictionary = bag[randi() % bag.size()]
	var a: float = angle if angle > -900.0 else randf() * TAU
	var pos: Vector2 = _ring_point(a)
	if near:
		pos = player.position + Vector2.from_angle(a) * randf_range(380.0, 520.0)
	pos = _free_spot(pos, 14.0)
	var base: Dictionary = _scale_at(run_time)
	var sc := {"hp": float(base["hp"]) * _hp_k(run_time), "dmg": base["dmg"], "spd": base["spd"]}
	var e: Enemy = _make_enemy(def, pos, sc)
	e.dmg *= DMG_K
	e.xp_val = roundf(e.xp_val * XP_K)
	if enemies.size() >= int(ENEMY_CAP * 0.85):
		e.max_hp = roundf(e.max_hp * 1.6)
		e.hp = e.max_hp
		e.dmg *= 1.25
		e.xp_val = roundf(e.xp_val * 1.6)
	if bool(_sm(e.dex).get("sh", 0)) and randf() < SHINY_RATE:
		e.make_shiny()
		Aud.sfx("shiny")
		_say(L.t("¡Un %s shiny anda cerca!") % e.enemy_name, 3.4)
	if event_id == "gold":
		e.make_golden()
	return e


func _spawn_boss(b: Dictionary) -> void:
	var t: float = run_time
	var sc := {"hp": 1.0 + t / 600.0, "dmg": 1.0 + t / 600.0, "spd": 1.0}
	var e: Enemy = _make_enemy(b, _ring_point(randf() * TAU), sc, true)
	if bool(_sm(e.dex).get("sh", 0)) and randf() < SHINY_RATE:
		e.make_shiny()
	Aud.sfx("boss")
	_say(L.t("¡%s%s salvaje apareció!") % [e.enemy_name, " shiny" if e.shiny else ""], 3.2)
	shake = 14.0


func _boss_alive() -> bool:
	for e in enemies:
		if e.boss and not e.dead:
			return true
	return false


func _update_spawner(delta: float) -> void:
	# Enemigos por segundo (spawner.js): sube con el tiempo de la run.
	var t: float = run_time
	banner_t = maxf(0.0, banner_t - delta)
	# Jefes
	if boss_idx < boss_run.size() and t >= float(boss_run[boss_idx]["at"]):
		_spawn_boss(boss_run[boss_idx])
		boss_idx += 1
	var fight: bool = _boss_alive()
	if enemies.size() < ENEMY_CAP:
		var rate: float = (1.6 + t * 0.028 + pow(t / 60.0, 1.6) * 0.5) * 0.17
		spawn_acc += rate * (0.25 if fight else 1.0) * delta
		while spawn_acc >= 1.0:
			spawn_acc -= 1.0
			if enemies.size() < ENEMY_CAP:
				_spawn_one()
	# Marea: una avalancha desde un lado concreto.
	if not fight:
		surge_t -= delta
	if surge_t <= 0.0:
		surge_t = randf_range(38.0, 56.0)
		var base_a: float = randf() * TAU
		var n: int = mini(ENEMY_CAP - enemies.size(), roundi(float(14 + int(t / 22.0)) * 0.28))
		for i in range(maxi(0, n)):
			_spawn_one(base_a + randf_range(-0.55, 0.55))
		Aud.sfx("surge")
		_say(L.t("¡Marea de Pokémon!"), 2.2)
	_update_events(delta)
	# Precarga de lo que va a salir en el proximo minuto.
	preload_t -= delta
	if preload_t <= 0.0:
		preload_t = 10.0
		_preload_upcoming(t + 60.0)


func _preload_upcoming(until: float) -> void:
	for tier in cast_run:
		if float(tier["from"]) <= until:
			for d in tier["list"]:
				_preload_dex(int(d["dex"]))
	for b in boss_run:
		if float(b["at"]) <= until:
			_preload_dex(int(b["dex"]))


func _preload_dex(dex: int) -> void:
	for a in ANIMS:
		var path: String = "res://assets/pokemon/%d/%s.png" % [dex, a]
		if ResourceLoader.exists(path) and not ResourceLoader.has_cached(path):
			ResourceLoader.load_threaded_request(path)


# ---------------------------------------------------------------
# Eventos (events.js): hordas de un tipo, hora dorada, duendes del tesoro
# ---------------------------------------------------------------
func _update_events(delta: float) -> void:
	if event_id != "":
		event_t += delta
		if event_t >= 30.0:
			event_id = ""
			horde_defs = []
	if run_time > 0.0 and not _boss_alive():
		thief_t -= delta
		if thief_t <= 0.0 and thieves < 2:
			_spawn_thief()
			thieves += 1
			thief_t = randf_range(240.0, 360.0)
		if event_id == "":
			next_event_t -= delta
			if next_event_t <= 0.0:
				next_event_t = randf_range(240.0, 300.0)
				var ids: Array = ["horde", "gold"]
				ids.erase(last_event)
				_start_event(String(ids[randi() % ids.size()]))


func _start_event(id: String) -> void:
	last_event = id
	if id == "horde":
		var ti: int = _tier_at(run_time)
		var no_horde := ["bomber", "healer", "shielder", "summoner"]
		var by_type := {}
		for p in _candidates(ti):
			if no_horde.has(_behavior_of(p)):
				continue
			for ty in p["types"]:
				if not by_type.has(ty):
					by_type[ty] = []
				by_type[ty].append(p)
		var ok: Array = []
		for ty in by_type:
			if by_type[ty].size() >= 3:
				ok.append(ty)
		if ok.is_empty():
			_start_event("gold")
			return
		var type: String = String(ok[randi() % ok.size()])
		horde_defs = []
		for p in _pick_n(by_type[type], 4):
			horde_defs.append(_def_for(p, TIERS[ti], ti))
		event_id = "horde"
		event_t = 0.0
		for i in range(6):
			_spawn_one(randf() * TAU)
		_say(L.t("¡Horda de tipo %s!") % L.t(String(MD.TYPE_NAME[type])), 3.0)
	else:
		event_id = "gold"
		event_t = 0.0
		for e in enemies:
			e.make_golden()
		_say(L.t("¡Hora dorada! Doble de experiencia"), 3.0)


func _spawn_thief() -> void:
	var gold: bool = randf() < 0.25
	var dex: int = 1000 if gold else 52
	if not _dex_by.has(dex) or not _smeta.has(str(dex)):
		return
	var def := {"dex": dex, "name": String(_dex_by[dex]["name"]), "behavior": "thief",
		"hp": roundf(60.0 * (1.0 + run_time / 95.0) * (1.5 if gold else 1.0)), "spd": 92.0, "dmg": 0.0, "xp": 10.0,
		"loot": "ticket10" if gold else "coins"}
	var a: float = randf() * TAU
	var pos: Vector2 = player.position + Vector2(cos(a) * randf_range(230.0, 300.0), sin(a) * randf_range(230.0, 300.0) * 0.8)
	var e: Enemy = _make_enemy(def, pos, {"hp": 1.0, "spd": 1.0, "dmg": 1.0})
	e.life = 15.0
	e.golden = true
	_ring(pos, 4.0, 40.0, Color("#ffd23f"), 0.5)
	if gold:
		_say(L.t("¡Un %s con un ticket ×10! ¡Atrápalo antes de que huya!") % e.enemy_name, 3.2)
	else:
		_say(L.t("¡Un %s cargado de monedas! ¡Atrápalo antes de que huya!") % e.enemy_name, 3.2)


# ---------------------------------------------------------------
# Comportamiento de los enemigos (enemy.js)
# ---------------------------------------------------------------
func _update_enemies(delta: float) -> void:
	var kn_decay: float = pow(0.0015, delta)
	for e in enemies:
		if e.dead:
			continue
		e.touch_cd = maxf(0.0, e.touch_cd - delta)
		# Estados alterados.
		if e.slow_t > 0.0:
			e.slow_t -= delta
			if e.slow_t <= 0.0:
				e.slow = 0.0
		if e.burn > 0:
			e.burn_t -= delta
			e.burn_tick -= delta
			if e.burn_tick <= 0.0:
				e.burn_tick = 0.5
				_damage_enemy(e, 1.6 * float(e.burn) * (1.0 + float(player.level) * 0.06), Color("#ff9a4d"))
			if e.burn_t <= 0.0:
				e.burn = 0
		if e.dead:
			continue
		if e.poison > 0:
			e.poison_t -= delta
			e.poison_tick -= delta
			if e.poison_tick <= 0.0:
				e.poison_tick = 0.6
				_damage_enemy(e, e.max_hp * 0.012 * float(e.poison) + 1.0, Color("#d47cf0"))
			if e.poison_t <= 0.0:
				e.poison = 0
		if e.dead:
			continue
		var tint := Color.WHITE
		if e.burn > 0:
			tint = Color(1.0, 0.75, 0.55)
		elif e.poison > 0:
			tint = Color(0.85, 0.65, 1.0)
		elif e.slow > 0.0:
			tint = Color(0.7, 0.85, 1.0)
		e.sprite.modulate = tint
		_enemy_step(e, delta, kn_decay)
	# Separacion suave para que no se apilen en un solo punto.
	var n: int = enemies.size()
	for i in range(n):
		var a = enemies[i]
		if a.dead or a.jump != null:
			continue
		for j in range(i + 1, n):
			var b = enemies[j]
			if b.dead or b.jump != null:
				continue
			var diff: Vector2 = b.position - a.position
			var min_d: float = (a.radius + b.radius) * 0.7
			var dd: float = diff.length()
			if dd < min_d and dd > 0.001:
				var push: Vector2 = diff / dd * (min_d - dd) * 0.5
				a.position -= push
				b.position += push


func _enemy_step(e: Enemy, delta: float, kn_decay: float) -> void:
	var to: Vector2 = player.position - e.position
	var dist: float = to.length()
	var dirv: Vector2 = Vector2.ZERO
	if dist > 0.001:
		dirv = to / dist
	var spd: float = e.spd * (1.0 - e.slow) * _weather_speed(e.types)
	if not e.flying:
		spd *= _enemy_terrain(e, delta)
	if e.life > 0.0 and e.behavior == "thief":
		e.life -= delta
		if e.life <= 0.0:
			_ring(e.position, 4.0, 30.0, Color("#ffd23f"), 0.3)
			e.dead = true
			e.fade = 0.2
			return
	# Duende del tesoro: huye de ti en zigzag.
	if e.behavior == "thief":
		e.zig += delta
		var ang: float = (-dirv).angle() + sin(e.zig * 2.2) * 0.7
		var kk: float = 1.0 if dist < 300.0 else 0.35
		e.position += (Vector2.from_angle(ang) * spd * kk + e.knock) * delta
		e.position = _collide(e.position, e.radius * 0.5)
		e.knock *= kn_decay
		e.face_angle(ang)
		e.loop_anim("Walk", 1.4)
		return
	if e.behavior == "runner":
		# Va a donde vas a estar.
		var lead: float = clampf(dist / maxf(60.0, spd), 0.0, 1.4)
		var tgt: Vector2 = player.position + player_vel * lead
		var d2: Vector2 = tgt - e.position
		if d2.length() > 0.001:
			dirv = d2.normalized()
	# Personalidades: escudo, salto, explosion.
	if e.shield_lock > 0.0:
		e.shield_lock -= delta
	if e.shield_t > 0.0:
		e.shield_t -= delta
		if e.shield_t <= 0.0:
			e.shield = 0.0
	if e.jump != null:
		_update_jump(e, delta)
		return
	if e.behavior == "bomber" and e.phase == "fuse":
		e.pt -= delta
		e.flash = 0.05 if int(e.pt * 10.0) % 2 == 1 else 0.0
		if e.pt <= 0.0:
			_kill_enemy(e)
		e.loop_anim("Idle", 1.0)
		return
	if e.behavior == "bomber" and dist < e.radius + player.radius + 26.0:
		e.phase = "fuse"
		e.pt = 1.0
		_hazard_zone(e.position, 62.0, 1.0, e.dmg * 1.4, e.atk_type, Color("#ff7b3d"))
		return
	if e.behavior == "shielder" or e.behavior == "jumper":
		e.skill_cd -= delta
		if e.skill_cd <= 0.0:
			if e.behavior == "shielder":
				e.skill_cd = 8.0
				_cast_shields(e)
			elif dist < 250.0:
				e.skill_cd = randf_range(5.0, 7.0)
				_start_jump(e)
				return
			else:
				e.skill_cd = 0.5
	var v: Vector2 = dirv * spd
	var abase: String = "Walk"
	if e.boss:
		var r: Array = _boss_move(e, delta, dist, dirv, spd)
		v = r[0]
		abase = String(r[1])
	elif e.behavior == "charger":
		e.pt -= delta
		if e.phase == "walk":
			if dist < 200.0 and e.pt <= 0.0:
				e.phase = "aim"
				e.pt = 0.55
				e.play("Charge", 1.6)
		elif e.phase == "aim":
			v = Vector2.ZERO
			abase = "Idle"
			if e.pt <= 0.0:
				e.phase = "dash"
				e.pt = 0.42
				e.dash_dir = dirv
				e.play("Attack", 1.4)
				_ring(e.position, e.radius, e.radius * 2.4, Color("#ff6b6b"), 0.25)
		elif e.phase == "dash":
			v = e.dash_dir * spd * 3.4
			if e.pt <= 0.0:
				e.phase = "walk"
				e.pt = 1.1
	elif KEEP_DIST.has(e.behavior):
		var rng: float = float(e.def.get("range", 200.0))
		var keep: float = rng * 0.82
		if dist < keep * 0.75:
			v = -dirv * spd * 0.8
		elif dist < keep:
			v *= 0.1
			abase = "Idle"
		e.shot_cd -= delta
		if e.shot_cd <= 0.0 and dist < rng:
			e.shot_cd = float(e.def.get("shotCd", 2.0))
			_enemy_special(e, dirv)
	e.position += (v + e.knock) * delta
	if not e.flying and e.jump == null:
		e.position = _collide(e.position, e.radius * 0.5)
	e.knock *= kn_decay
	var moving: bool = v.length() > 2.0
	var face: float = to.angle()
	if e.phase == "dash":
		face = e.dash_dir.angle()
	elif moving:
		face = v.angle()
	e.face_angle(face)
	e.loop_anim(abase if moving else "Idle", maxf(0.6, spd / 70.0) if moving else 1.0)
	# Contacto con el jugador (combat.js): cada 0,55 s por enemigo.
	var rr: float = e.radius + player.radius
	if dist <= rr and e.touch_cd <= 0.0 and e.behavior != "thief":
		e.touch_cd = 0.55
		e.strike(to.angle())
		_hurt_player(e.dmg, e.atk_type)
		e.knock = -dirv * 150.0
		if _has_item("rockyhelmet"):
			_damage_enemy(e, 15.0 + float(player.level) * 4.0, Color("#9aa6b5"), -dirv, 80.0)


func _shot_dmg(e: Enemy) -> float:
	var base_dmg: float = maxf(0.001, float(e.def.get("dmg", 1.0)))
	return float(e.def.get("shotDmg", 10.0)) * (e.dmg / base_dmg)


func _enemy_shoot(e: Enemy, ang: float, spread: float, n: int, k: float) -> void:
	for i in range(n):
		var a: float = ang
		if n > 1:
			a = ang + (float(i) / float(n - 1) - 0.5) * spread
		var b := EBullet.new()
		b.position = e.position
		b.vel = Vector2.from_angle(a) * 190.0
		b.dmg = _shot_dmg(e) * k
		b.mtype = e.atk_type
		b.color = Color.html(String(MD.TYPE_COLOR.get(e.atk_type, "#ff7a9e")))
		fx.add_child(b)
		ebullets.append(b)
	e.play("Shoot", 1.0)
	_ring(e.position + Vector2(0.0, -LIFT), 4.0, 14.0, Color("#ff7a9e"), 0.2)


func _enemy_special(e: Enemy, dirv: Vector2) -> void:
	var col := Color.html(String(MD.TYPE_COLOR.get(e.atk_type, "#ff7a9e")))
	var ang: float = dirv.angle()
	var b: String = e.behavior
	if b == "fan":
		var n: int = int(e.def.get("fanN", 5))
		_enemy_shoot(e, ang, 0.6 if n == 3 else 0.9, n, 0.65)
	elif b == "beamer":
		_hazard_beam(e.position, ang, 360.0, 22.0, 1.0, _shot_dmg(e) * 1.05, e.atk_type, col)
		e.play("Charge", 1.2)
	elif b == "zoner":
		var n2: int = randi_range(1, int(e.def.get("zones", 3)))
		for i in range(n2):
			var off := Vector2.ZERO
			if i > 0:
				off = Vector2(randf_range(-70.0, 70.0), randf_range(-55.0, 55.0))
			_hazard_zone(player.position + off, 44.0, 1.2, _shot_dmg(e) * 0.95, e.atk_type, col)
		e.play("Shoot", 1.0)
	elif b == "healer":
		_heal_around(e)
	elif b == "summoner":
		_summon(e)
	else:
		_enemy_shoot(e, ang, 0.0, 1, 1.0)


func _heal_around(e: Enemy) -> void:
	# 7% de la vida, mas cuanto mas fuerte pegas (con tope x2,5).
	var pw: float = maxf(1.0, _atk() / maxf(0.001, base_atk))
	var k: float = 0.07 * minf(2.5, pow(pw, 0.35))
	# Balance: con mas de 4 curanderos vivos la curacion baja un 10 %.
	var healers := 0
	for h in enemies:
		if not h.dead and h.behavior == "healer":
			healers += 1
	if healers > 4:
		k *= 0.9
	for o in enemies:
		if o.dead or o.hp >= o.max_hp:
			continue
		if o.position.distance_to(e.position) <= 150.0:
			o.hp = minf(o.max_hp, o.hp + o.max_hp * k)
			o.queue_redraw()
	e.play("Charge", 1.0)
	_ring(e.position, 8.0, 150.0, Color("#5fe08a"), 0.5)


func _cast_shields(e: Enemy) -> void:
	var near: Array = []
	for o in enemies:
		if not o.dead and o.position.distance_to(e.position) <= 160.0:
			near.append(o)
	near.sort_custom(func(a, b): return a.position.distance_squared_to(e.position) < b.position.distance_squared_to(e.position))
	# Balance: escudo del 30 % (antes 35 %) durante 7 s, y un mismo Pokemon no recibe otro
	# hasta 14 s despues (nada de escudos infinitos). Maximo 5 por lanzamiento.
	var given := 0
	for i in range(near.size()):
		if given >= 5:
			break
		var o2 = near[i]
		if o2.shield > 0.0 or o2.shield_lock > 0.0:
			continue
		o2.shield = o2.max_hp * 0.30
		o2.shield_t = 7.0
		o2.shield_lock = 14.0
		given += 1
	e.play("Charge", 1.0)
	_ring(e.position, 8.0, 160.0, Color("#7fc8ff"), 0.5)


func _summon(e: Enemy) -> void:
	var alive: Array = []
	for m in e.minions:
		if is_instance_valid(m) and not m.dead:
			alive.append(m)
	e.minions = alive
	# Balance: cada invocacion saca 4, con un maximo de 20 subditos vivos en todo el mapa
	# (y 8 por invocador).
	var total_minions := 0
	for q in enemies:
		if q.is_minion and not q.dead:
			total_minions += 1
	if e.minions.size() >= 8 or total_minions >= 20 or enemies.size() > ENEMY_CAP + 15:
		return
	var dex: int = int(e.def.get("minion", e.dex))
	if not _dex_by.has(dex) or not _smeta.has(str(dex)):
		dex = e.dex
	var def := {"dex": dex, "name": String(_dex_by[dex]["name"]), "hp": roundf(float(e.def["hp"]) * 0.35),
		"spd": roundf(float(e.def["spd"]) * 1.1), "dmg": roundf(float(e.def["dmg"]) * 0.6),
		"xp": maxf(1.0, roundf(float(e.def["xp"]) * 0.25)), "behavior": "chase"}
	for i in range(mini(4, 20 - total_minions)):
		var a: float = randf() * TAU
		var m2: Enemy = _make_enemy(def, e.position + Vector2(cos(a) * 30.0, sin(a) * 22.0), e.sc)
		m2.is_minion = true
		e.minions.append(m2)
	e.play("Charge", 1.0)
	_ring(e.position, 8.0, 50.0, Color("#c47bff"), 0.4)


func _start_jump(e: Enemy) -> void:
	e.jump = {"sx": e.position.x, "sy": e.position.y, "tx": player.position.x, "ty": player.position.y, "t": -0.45, "dur": 0.6}
	e.play("Charge", 1.4)
	_hazard_zone(player.position, 50.0, 1.05, e.dmg * 1.2, e.atk_type, Color.html(String(MD.TYPE_COLOR.get(e.atk_type, "#ff7a9e"))))


func _update_jump(e: Enemy, delta: float) -> void:
	var j: Dictionary = e.jump
	j["t"] = float(j["t"]) + delta
	if float(j["t"]) < 0.0:
		e.loop_anim("Idle", 1.0)
		return
	var k: float = minf(1.0, float(j["t"]) / float(j["dur"]))
	var s := Vector2(float(j["sx"]), float(j["sy"]))
	var tg := Vector2(float(j["tx"]), float(j["ty"]))
	e.position = s.lerp(tg, k)
	e.lift_extra = sin(k * PI) * 46.0
	e.face_angle((tg - s).angle())
	if k >= 1.0:
		e.jump = null
		e.lift_extra = 0.0
		e.play("Attack", 1.4)


func _kill_enemy(e: Enemy) -> void:
	if e.dead:
		return
	e.hp = 1.0
	_damage_enemy(e, 1.0, Color.WHITE)


# --- jefes: 4 ataques (Pisoton + Embestida o Salto, y 2 de lejos segun tipo) ---
func _boss_init(e: Enemy) -> void:
	var t: Array = e.types
	var melee := ["slam", "dash" if _hash(e.dex, 3, 7) < 0.5 else "leap"]
	var pref: String = "volley"
	if _has_t(t, ["fire", "ground", "poison", "rock", "grass"]):
		pref = "rain"
	elif _has_t(t, ["electric", "psychic", "dragon", "ice", "steel"]):
		pref = "beam"
	elif _has_t(t, ["fairy", "ghost", "water", "flying"]):
		pref = "nova"
	var others: Array = ["rain", "beam", "nova", "volley"]
	others.erase(pref)
	var ranged: Array = [pref, others[int(_hash(e.dex, 5, 9) * 3.0) % 3]]
	var far: bool = e.behavior == "ranged"
	e.ai = {"melee": melee, "ranged": ranged, "far_like": 0.65 if far else 0.35, "mode": "far" if far else "close",
		"mode_t": randf_range(6.0, 8.0), "cd": 1.6, "cast": null, "fury": false, "side": 1.0 if randf() < 0.5 else -1.0}


func _boss_enrage(e: Enemy) -> void:
	e.ai["fury"] = true
	e.spd *= 1.15
	if not e.judge:
		_say(L.t("¡%s se ha enfurecido!") % e.enemy_name, 2.4)
	_ring(e.position, e.radius, e.radius * 5.0, Color("#ff4a4a"), 0.6)
	shake = 8.0


func _boss_move(e: Enemy, delta: float, dist: float, dirv: Vector2, spd: float) -> Array:
	if e.ai.is_empty():
		_boss_init(e)
	var ai: Dictionary = e.ai
	if not bool(ai["fury"]) and e.hp < e.max_hp * 0.5:
		_boss_enrage(e)
	var k: float = 1.25 if bool(ai["fury"]) else 1.0
	if ai["cast"] != null:
		return _boss_cast(e, delta)
	ai["mode_t"] = float(ai["mode_t"]) - delta
	ai["cd"] = float(ai["cd"]) - delta * k
	if float(ai["mode_t"]) <= 0.0:
		ai["mode"] = "close" if String(ai["mode"]) == "far" else "far"
		var fav: bool = (String(ai["mode"]) == "far") == (float(ai["far_like"]) > 0.5)
		ai["mode_t"] = randf_range(7.0, 9.0) if fav else randf_range(4.0, 5.0)
		ai["side"] = -float(ai["side"])
	var v: Vector2 = dirv * spd * k * 1.1
	if String(ai["mode"]) == "far":
		if dist < 170.0:
			v = -dirv * spd
		elif dist < 300.0:
			v = Vector2(-dirv.y, dirv.x) * spd * 0.55 * float(ai["side"])
	if float(ai["cd"]) <= 0.0:
		var id: String = ""
		if String(ai["mode"]) == "close":
			var ok: Array = []
			for m in ai["melee"]:
				if (m == "slam" and dist < 125.0) or (m != "slam" and dist < 320.0):
					ok.append(m)
			if not ok.is_empty() and randf() < 0.8:
				id = String(ok[randi() % ok.size()])
			elif dist < 480.0:
				id = String(ai["ranged"][randi() % 2])
		else:
			if dist < 115.0:
				id = "slam"
			elif dist < 430.0:
				id = String(ai["ranged"][randi() % 2])
		if id != "":
			_boss_start(e, id)
	return [v, "Walk"]


func _boss_start(e: Enemy, id: String) -> void:
	var ai: Dictionary = e.ai
	var f: float = 0.8 if bool(ai["fury"]) else 1.0
	var type: String = e.atk_type
	var col := Color.html(String(MD.TYPE_COLOR.get(type, "#ff7a9e")))
	var ang: float = (player.position - e.position).angle()
	var c := {"id": id, "t": 0.0, "wind": 0.6 * f, "after": 0.35, "ang": ang, "go": false, "fired": false, "len": 0.0, "dur": 0.0}
	ai["cast"] = c
	if id == "slam":
		c["wind"] = 0.85 * f
		_hazard_zone(e.position, 96.0 + e.radius, float(c["wind"]), e.dmg * 1.3, type, col)
		e.play("Charge", 1.2)
	elif id == "dash":
		c["wind"] = 0.75 * f
		c["len"] = 330.0
		c["dur"] = 0.32
		_hazard_beam(e.position, ang, 330.0 + e.radius, e.radius * 2.0 + 16.0, float(c["wind"]) + 0.32, e.dmg * 1.2, type, col)
		e.play("Charge", 1.3)
	elif id == "leap":
		e.jump = {"sx": e.position.x, "sy": e.position.y, "tx": player.position.x, "ty": player.position.y, "t": -0.5 * f, "dur": 0.65}
		_hazard_zone(player.position, 82.0, 0.5 * f + 0.65, e.dmg * 1.25, type, col)
		e.play("Charge", 1.4)
		ai["cast"] = null
		ai["cd"] = randf_range(1.4, 2.0) + 0.6
	elif id == "rain":
		var n: int = 6 if bool(ai["fury"]) else 4
		for i in range(n):
			var a: float = randf() * TAU if i > 0 else 0.0
			var d: float = randf_range(40.0, 120.0) if i > 0 else 0.0
			_hazard_zone(player.position + Vector2(cos(a) * d, sin(a) * d * 0.8), 50.0, 1.05 + float(i) * 0.12, _shot_dmg(e) * 1.15, type, col)
		c["wind"] = 0.5
		e.play("Shoot", 1.0)
	elif id == "beam":
		var nb: int = 5 if bool(ai["fury"]) else 3
		var sp: float = 0.42 if bool(ai["fury"]) else 0.5
		for i in range(nb):
			_hazard_beam(e.position, ang + (float(i) - float(nb - 1) / 2.0) * sp, 400.0, 26.0, 1.0, _shot_dmg(e) * 1.2, type, col)
		c["wind"] = 1.0
		c["after"] = 0.25
		e.play("Charge", 1.1)
	elif id == "volley" or id == "nova":
		c["wind"] = (0.7 if id == "nova" else 0.5) * f
		e.play("Charge", 1.4)
		_ring(e.position, e.radius, e.radius * 2.4, col, float(c["wind"]))


func _boss_cast(e: Enemy, delta: float) -> Array:
	var ai: Dictionary = e.ai
	var c: Dictionary = ai["cast"]
	c["t"] = float(c["t"]) + delta
	var id: String = String(c["id"])
	if id == "dash" and float(c["t"]) >= float(c["wind"]):
		if not bool(c["go"]):
			c["go"] = true
			e.play("Attack", 1.6)
		if float(c["t"]) >= float(c["wind"]) + float(c["dur"]):
			return _boss_end(e)
		var sp: float = float(c["len"]) / float(c["dur"])
		return [Vector2.from_angle(float(c["ang"])) * sp, "Walk"]
	if float(c["t"]) >= float(c["wind"]) and not bool(c["fired"]):
		c["fired"] = true
		var a0: float = (player.position - e.position).angle()
		var fury: bool = bool(ai["fury"])
		if id == "volley":
			_enemy_shoot(e, a0, 1.1, 9 if fury else 7, 0.8)
		elif id == "nova":
			var n: int = 18 if fury else 14
			_enemy_shoot(e, a0, TAU * float(n - 1) / float(n), n, 0.7)
		elif id == "slam":
			e.play("Attack", 1.4)
	if float(c["t"]) >= float(c["wind"]) + float(c["after"]):
		return _boss_end(e)
	return [Vector2.ZERO, "Idle"]


func _boss_end(e: Enemy) -> Array:
	var ai: Dictionary = e.ai
	ai["cast"] = null
	ai["cd"] = randf_range(1.3, 2.0)
	if bool(ai["fury"]) and randf() < 0.35:
		ai["cd"] = 0.3
	return [Vector2.ZERO, "Idle"]


# --- ataques con aviso en el suelo (hazards.js) y disparos enemigos ---
func _hazard_zone(pos: Vector2, r: float, delay: float, dmg: float, type: String, col: Color) -> Hazard:
	var h := Hazard.new()
	h.kind = "zone"
	h.position = pos
	h.r = r
	h.delay = delay
	h.dmg = dmg
	h.mtype = type
	h.color = col
	gfx.add_child(h)
	hazards.append(h)
	return h


func _hazard_beam(pos: Vector2, angle: float, length: float, width: float, delay: float, dmg: float, type: String, col: Color) -> Hazard:
	var h := Hazard.new()
	h.kind = "beam"
	h.position = pos
	h.angle = angle
	h.length = length
	h.width = width
	h.delay = delay
	h.dmg = dmg
	h.mtype = type
	h.color = col
	gfx.add_child(h)
	hazards.append(h)
	return h


func _hazard_inside(h: Hazard) -> bool:
	var pr: float = player.radius
	if h.kind == "zone":
		return player.position.distance_squared_to(h.position) < pow(h.r + pr * 0.6, 2.0)
	var d: Vector2 = Vector2.from_angle(h.angle)
	var rel: Vector2 = player.position - h.position
	var along: float = rel.dot(d)
	if along < -pr or along > h.length + pr:
		return false
	return absf(-rel.x * d.y + rel.y * d.x) <= h.width * 0.5 + pr * 0.6


func _update_hazards(delta: float) -> void:
	trap_slow_t = maxf(0.0, trap_slow_t - delta)
	for i in range(hazards.size() - 1, -1, -1):
		var h: Hazard = hazards[i]
		h.t += delta
		if not h.hit and h.t >= h.delay:
			h.hit = true
			if h.vis == "pillar":
				var pf := Fx.new()
				pf.kind = "beam"
				pf.color = h.color
				pf.position = h.position
				pf.ang = -PI / 2.0
				pf.length = 420.0
				pf.width = h.r * 1.1
				pf.life = 0.4
				fx.add_child(pf)
				_ring(h.position, 4.0, h.r * 1.3, Color("#fff3c8"), 0.4)
				Aud.sfx("judge")
				shake = maxf(shake, 3.0)
			elif h.kind == "zone":
				_ring(h.position, 4.0, h.r, h.color, 0.35)
				if h.r > 60.0:
					shake = maxf(shake, 4.0)
			else:
				var f := Fx.new()
				f.kind = "beam"
				f.color = h.color
				f.position = h.position
				f.ang = h.angle
				f.length = h.length
				f.width = h.width
				f.life = 0.3
				fx.add_child(f)
			if not player.dead and _hazard_inside(h):
				player.invuln = 0.0
				if h.pct > 0.0:
					_hurt_player(maxf(h.dmg, player.max_hp * h.pct), "", h.pure)
				else:
					_hurt_player(h.dmg, h.mtype)
				if h.slows:
					trap_slow_t = 2.0
		if h.hit and h.t >= h.delay + 0.3:
			h.queue_free()
			hazards.remove_at(i)


func _update_ebullets(delta: float) -> void:
	for i in range(ebullets.size() - 1, -1, -1):
		var b: EBullet = ebullets[i]
		b.age += delta
		var eprev: Vector2 = b.position
		b.position += b.vel * delta
		var remove: bool = b.age >= 2.4 or _wall_hit(eprev, b.position)
		if not remove:
			var rr: float = 7.0 + player.radius
			if b.position.distance_squared_to(player.position) < rr * rr:
				_hurt_player(b.dmg, b.mtype)
				remove = true
		if remove:
			b.queue_free()
			ebullets.remove_at(i)


func _nearest_enemy(from: Vector2, reach: float) -> Node2D:
	var best: Node2D = null
	var best_d2: float = reach * reach
	for e in enemies:
		if e.dead:
			continue
		var d2: float = from.distance_squared_to(e.position)
		if d2 <= best_d2:
			best_d2 = d2
			best = e
	return best


func _damage_enemy(e, amount: float, col: Color = Color.WHITE, dir: Vector2 = Vector2.ZERO, knock: float = 0.0, eff: String = "") -> void:
	if e.dead:
		return
	var d: float = maxf(1.0, roundf(amount))
	jd.note_dmg(d, e)
	_cut_grass(e.position, 34.0)
	# Escudo: absorbe primero.
	if e.shield > 0.0:
		var ab: float = minf(e.shield, d)
		e.shield -= ab
		if ab >= d:
			add_text(e.position + Vector2(0.0, -e.body_h - 4.0), str(roundi(d)), Color("#9fd8ff"))
			e.flash = 0.5
			return
		d -= ab
	var tc: Color = col.lerp(Color.WHITE, 0.55)
	var ts: int = 18
	if e.boss:
		ts = 24
	if eff == "super":
		tc = Color("#ffe14d")
		ts = 26
	elif eff == "weak":
		tc = Color("#a3abb8")
	add_text(e.position + Vector2(0.0, -e.body_h - 4.0), str(roundi(d)), tc, ts)
	if knock > 0.0 and dir != Vector2.ZERO and not e.boss:
		e.knock += dir.normalized() * knock
	Aud.sfx("hit")
	if e.hurt_by(d):
		kills += 1
		var lg: int = e.dex if (e.legend and not e.judge) else 0
		PG.event("kill", {"types": e.types, "boss": e.boss and not e.judge, "legend": lg})
		Aud.sfx("bossDown" if e.boss else "faint")
		_drop(e)


# ---------------------------------------------------------------
# Mundo: trozos infinitos con arboles, rocas, charcos, cofres, altares,
# fuentes y trampas (generados al vuelo, siempre igual para una misma partida)
# ---------------------------------------------------------------
func _chunk_of(pos: Vector2) -> Vector2i:
	return Vector2i(floori(pos.x / CHUNK), floori(pos.y / CHUNK))


func _gen_chunk(cx: int, cy: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = absi((cx * 73856093) ^ (cy * 19349663) ^ (world_seed * 83492791)) + 1
	var props: Array = []
	var placed: Array = []
	var grass_items: Array = []
	var bx: int = cx * 16
	var by: int = cy * 16
	for j in range(16):
		for i in range(16):
			var tx: int = bx + i
			var ty: int = by + j
			if ground.terrain(tx, ty) != 0:
				continue
			var dist0: float = Vector2(float(tx) + 0.5, float(ty) + 0.5).length()
			if dist0 < 8.0:
				continue
			var open: bool = ground.open_at(tx, ty)
			var h: float = ARENA.hsh(tx, ty, world_seed + 404)
			var grove: bool = ARENA.fbm(float(tx) / 10.0, float(ty) / 10.0, world_seed + 505) > 0.62
			var wp := Vector2((float(tx) + 0.5) * ground.TS + rng.randf_range(-8.0, 8.0), (float(ty) + 0.5) * ground.TS + rng.randf_range(-6.0, 6.0))
			if open and h < (0.045 if grove else 0.004):
				_add_prop(props, placed, "tree", wp, 15.0, rng)
			elif open and h > 0.994:
				_add_prop(props, placed, "rock", wp, 18.0, rng)
			elif ARENA.fbm(float(tx) / 5.0, float(ty) / 5.0, world_seed + 707) > 0.66 and ARENA.hsh(tx, ty, world_seed + 808) < 0.7:
				grass_items.append(Vector3(wp.x, wp.y + 14.0, rng.randf() * TAU))
	# Especiales (en sitios abiertos, lejos del inicio y de cualquier otro objeto)
	if rng.randf() < 0.22:
		_place_special("chest", 16.0, 7.0, props, placed, rng, cx, cy)
	if rng.randf() < 0.08:
		_place_special("spring", 20.0, 10.0, props, placed, rng, cx, cy)
	if rng.randf() < 0.08:
		_place_special("altar", 18.0, 10.0, props, placed, rng, cx, cy)
	if rng.randf() < 0.3:
		_place_special("trap", 16.0, 13.0, props, placed, rng, cx, cy)
	ground.add_grass(Vector2i(cx, cy), grass_items)
	return {"props": props}


func _place_special(kind: String, r: float, min_tiles: float, props: Array, placed: Array, rng: RandomNumberGenerator, cx: int, cy: int) -> void:
	for attempt in range(10):
		var tx: int = cx * 16 + rng.randi_range(1, 14)
		var ty: int = cy * 16 + rng.randi_range(1, 14)
		if Vector2(float(tx) + 0.5, float(ty) + 0.5).length() < min_tiles:
			continue
		if not ground.open_at(tx, ty):
			continue
		var pos := Vector2((float(tx) + 0.5) * ground.TS, (float(ty) + 0.5) * ground.TS + 10.0)
		if _add_prop(props, placed, kind, pos, r, rng):
			return


func _add_prop(props: Array, placed: Array, kind: String, pos: Vector2, r: float, rng: RandomNumberGenerator) -> bool:
	for pl in placed:
		if pos.distance_to(pl[0]) < float(pl[1]) + r + 10.0:
			return false
	var p := Prop.new()
	p.kind = kind
	p.r = r
	p.solid = kind == "tree" or kind == "rock"
	p.v = rng.randf()
	p.position = pos
	if kind == "trap":
		p.sub = ["poison", "ice", "fire"][rng.randi() % 3]
	if kind == "altar":
		var pw: Dictionary = POWERS[rng.randi() % POWERS.size()]
		p.power = String(pw["id"])
		p.color = Color.html(String(pw["color"]))
	world.add_child(p)
	props.append(p)
	placed.append([pos, r])
	return true


func _free_chunk(key: Vector2i) -> void:
	var ch: Dictionary = chunks[key]
	for p in ch["props"]:
		if is_instance_valid(p):
			p.queue_free()
	chunks.erase(key)


func _update_biome() -> void:
	var b: int = int(run_time / 240.0)
	if b == biome_idx:
		return
	biome_idx = b
	ground.set_biome(b)
	Aud.sfx("biome")
	_say("— " + L.t(ground.biome_name(ground.biome)) + " —", 3.0)
	_ring(player.position, 10.0, 520.0, Color.WHITE, 0.7)
	player_lava_t = 1.5
	for key in chunks:
		for p in chunks[key]["props"]:
			if is_instance_valid(p):
				p.queue_redraw()


func _cut_grass(pos: Vector2, r: float) -> void:
	var cut: Array = ground.cut_grass(pos, r)
	if cut.is_empty():
		return
	Aud.sfx("grass")
	var pal: Dictionary = ground.pal(ground.biome)
	var gcol: Color = (pal["grass"] as Array)[1]
	for i in range(mini(cut.size(), 6)):
		var f := Fx.new()
		f.kind = "burst"
		f.color = gcol
		f.position = cut[i] + Vector2(0.0, -6.0)
		f.r1 = 16.0
		f.life = 0.25
		fx.add_child(f)
	for gp in cut:
		var rr: float = randf()
		if rr < 0.04:
			_spawn_orb(gp, "heal", 0.0)
		elif rr < 0.09:
			_spawn_orb(gp, "coin", 1.0)


func _update_world(delta: float) -> void:
	power_t = maxf(0.0, power_t - delta)
	if power_t <= 0.0:
		power_kind = ""
	var c: Vector2i = _chunk_of(player.position)
	ground.center = player.position
	if c != player_chunk:
		player_chunk = c
		ground.set_center(c)
		for dx in range(-2, 3):
			for dy in range(-2, 3):
				var key := Vector2i(c.x + dx, c.y + dy)
				if not chunks.has(key) and not gen_q.has(key):
					gen_q.append(key)
		gen_q.sort_custom(func(a, b): return absi(a.x - c.x) + absi(a.y - c.y) < absi(b.x - c.x) + absi(b.y - c.y))
		for key in chunks.keys():
			if absi(key.x - c.x) > 3 or absi(key.y - c.y) > 3:
				_free_chunk(key)
	# Los trozos nuevos se crean de uno en uno (sin tirones); al empezar, todos de golpe.
	while not gen_q.is_empty():
		var nk: Vector2i = gen_q.pop_front()
		if not chunks.has(nk):
			chunks[nk] = _gen_chunk(nk.x, nk.y)
		if delta > 0.0:
			break
	_update_props(delta)


func _props_near(pos: Vector2) -> Array:
	var out: Array = []
	var c: Vector2i = _chunk_of(pos)
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			var ch = chunks.get(Vector2i(c.x + dx, c.y + dy))
			if ch != null:
				out.append_array(ch["props"])
	return out


func _collide(pos: Vector2, rad: float) -> Vector2:
	if arena != null:
		return arena.collide(pos, rad)
	pos = ground.collide(pos, rad)
	var c: Vector2i = _chunk_of(pos)
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			var ch = chunks.get(Vector2i(c.x + dx, c.y + dy))
			if ch == null:
				continue
			for p in ch["props"]:
				if not p.solid:
					continue
				var d: Vector2 = pos - p.position
				var md: float = p.r + rad
				var dd: float = d.length_squared()
				if dd < md * md:
					if dd < 0.0001:
						d = Vector2(1.0, 0.0)
						dd = 1.0
					pos = p.position + d.normalized() * md
	return pos


# Las paredes (tierra/roca del mapa y de las arenas) detienen los proyectiles.
func _wall_hit(a: Vector2, b: Vector2) -> bool:
	for t in [0.0, 0.5, 1.0]:
		var p: Vector2 = a.lerp(b, t)
		var q: Vector2 = arena.collide(p, 2.0) if arena != null else ground.collide(p, 2.0)
		if q.distance_squared_to(p) > 0.01:
			return true
	return false


func _liquid_at(pos: Vector2) -> String:
	if arena != null:
		return arena.liquid_at(pos)
	return ground.liquid_at(pos)


func _blocked(pos: Vector2, rad: float) -> bool:
	if _collide(pos, rad) != pos:
		return true
	return _liquid_at(pos) == "lava"


func _free_spot(pos: Vector2, rad: float) -> Vector2:
	if not _blocked(pos, rad):
		return pos
	for i in range(10):
		var q: Vector2 = pos + Vector2.from_angle(randf() * TAU) * randf_range(40.0, 170.0)
		if not _blocked(q, rad):
			return q
	return pos


func _player_terrain(delta: float) -> float:
	var liq: String = _liquid_at(player.position)
	if liq == "water":
		if _has_t(player.types, ["water", "flying"]):
			return 1.0
		return 0.72
	if liq == "lava":
		if _has_t(player.types, ["fire", "flying"]):
			return 1.0
		player_lava_t -= delta
		if player_lava_t <= 0.0:
			player_lava_t = 0.5
			player.invuln = 0.0
			_hurt_player(maxf(3.0, player.max_hp * 0.035), "")
		return 0.85
	if liq == "swamp":
		return 1.0 if _has_t(player.types, ["poison", "water", "flying"]) else 0.7
	if liq == "ice":
		return 1.0 if _has_t(player.types, ["ice", "flying"]) else 0.85
	if liq == "poison":
		if _has_t(player.types, ["poison", "steel", "flying"]):
			return 1.0
		player_lava_t -= delta
		if player_lava_t <= 0.0:
			player_lava_t = 0.6
			player.invuln = 0.0
			_hurt_player(maxf(2.0, player.max_hp * 0.025), "")
		return 0.8
	if liq == "spark":
		if _has_t(player.types, ["electric", "ground", "flying"]):
			return 1.0
		player_lava_t -= delta
		if player_lava_t <= 0.0:
			player_lava_t = 0.8
			player.invuln = 0.0
			_hurt_player(maxf(3.0, player.max_hp * 0.03), "")
		return 0.9
	return 1.0


func _enemy_terrain(e: Enemy, delta: float) -> float:
	if e.legend:
		return 1.0
	if _liquid_at(e.position) == "swamp":
		return 1.0 if _has_t(e.types, ["poison", "water"]) else 0.55
	var liq: String = _liquid_at(e.position)
	if liq == "water":
		if _has_t(e.types, ["water", "flying"]):
			return 1.0
		return 0.55
	if liq == "lava":
		if _has_t(e.types, ["fire"]):
			return 1.0
		e.lava_t -= delta
		if e.lava_t <= 0.0:
			e.lava_t = 0.6
			_damage_enemy(e, 6.0 + e.max_hp * 0.04, Color("#ff7b3d"))
		return 0.8
	return 1.0


func _pw(id: String) -> bool:
	return power_kind == id


func _power_text() -> String:
	if power_kind == "":
		return ""
	for p in POWERS:
		if String(p["id"]) == power_kind:
			return "%s %ds" % [L.t(String(p["name"])), ceili(power_t)]
	return ""


func _update_props(delta: float) -> void:
	var pp: Vector2 = player.position
	for p in _props_near(pp):
		if not is_instance_valid(p):
			continue
		var d: float = p.position.distance_to(pp)
		if p.kind == "chest" and not p.used and d < p.r + player.radius + 14.0:
			p.used = true
			_open_chest(p)
		elif p.kind == "spring" and not p.used and d < 52.0:
			var amt: float = minf(player.max_hp * 0.07 * delta, p.charge)
			if player.hp < player.max_hp and amt > 0.0:
				player.hp = minf(player.max_hp, player.hp + amt)
				p.charge -= amt
				p.queue_redraw()
				if p.charge <= 0.0:
					p.used = true
		elif p.kind == "altar" and not p.used and d < 50.0:
			p.used = true
			_use_altar(p)
		elif p.kind == "trap":
			p.cd = maxf(0.0, p.cd - delta)
			if p.cd <= 0.0 and d < 26.0:
				p.cd = 999.0
				_trigger_trap(p)
				var tt: Tween = p.create_tween()
				tt.tween_property(p, "modulate:a", 0.0, 0.35)
				tt.tween_callback(p.queue_free)
				_forget_prop(p)


func _trigger_trap(p: Prop) -> void:
	# Igual que interact.js: 3 tipos (veneno / pegajosa / fuego), radio 74.
	var pos: Vector2 = p.position
	var lvl: int = player.level
	var col: Color = Color("#c86bdc")
	if p.sub == "ice":
		col = Color("#8bd94a")
	elif p.sub == "fire":
		col = Color("#ff7b3d")
	_ring(pos, 6.0, 74.0, col, 0.5)
	for e in enemies:
		if e.dead or e.position.distance_to(pos) > 74.0:
			continue
		if p.sub == "poison":
			e.apply_poison(5)
			_damage_enemy(e, 14.0 + lvl * 3.0, Color("#d47cf0"))
		elif p.sub == "ice":
			e.apply_slow(0.65, 4.5)
			_damage_enemy(e, 4.0, Color("#8bd94a"))
		else:
			_damage_enemy(e, 90.0 + lvl * 18.0, col, (e.position - pos).normalized(), 220.0)
	if not player.dead and player.position.distance_to(pos) < 74.0 * 0.7:
		player.invuln = 0.0
		if p.sub == "poison":
			_hurt_player(player.max_hp * 0.1, "poison")
		elif p.sub == "ice":
			trap_slow_t = 3.5
			add_text(player.position + Vector2(0.0, -34.0), L.t("¡Pegajoso!"), Color("#8bd94a"), 20)
		else:
			_hurt_player(player.max_hp * 0.2, "fire")


func _forget_prop(p: Prop) -> void:
	for key in chunks:
		(chunks[key]["props"] as Array).erase(p)


func _open_chest(p: Prop) -> void:
	run_chests += 1
	PG.event("chest")
	Aud.sfx("chest")
	p.queue_redraw()
	_ring(p.position, 6.0, 60.0, Color("#ffd23f"), 0.45)
	var r: float = randf()
	var pos: Vector2 = p.position
	if r < 0.40:
		for i in range(10):
			_spawn_orb(pos, "coin", 5.0)
		if randf() < 0.1:
			_spawn_orb(pos, "ticket", float(1 + randi() % 3))
			if randf() < 0.15:
				_spawn_orb(pos, "ticket10", 1.0)
		add_text(pos + Vector2(0.0, -30.0), L.t("¡Monedas!"), Color("#ffd23f"), 22)
	elif r < 0.72:
		_spawn_orb(pos, "heal", 0.0)
		var per: float = ceilf(float(_xp_for(player.level)) * 0.12 / 5.0)
		for i in range(5):
			_spawn_orb(pos, "xpBig", per)
		add_text(pos + Vector2(0.0, -30.0), L.t("¡Cofre de experiencia!"), Color("#7fe0ff"), 22)
	elif item == "" or r < 0.88:
		_spawn_orb(pos, "item", 0.0)
		add_text(pos + Vector2(0.0, -30.0), L.t("¡Un objeto!"), Color("#ff8ad8"), 22)
	else:
		_spawn_orb(pos, "magnet", 0.0)
		_spawn_orb(pos, "bomb", 0.0)
	var t: Tween = p.create_tween()
	t.tween_property(p, "modulate:a", 0.0, 0.5)
	t.tween_callback(p.queue_free)
	_forget_prop(p)


func _use_altar(p: Prop) -> void:
	for pw in POWERS:
		if String(pw["id"]) == p.power:
			power_kind = p.power
			power_t = 25.0
			_say(L.t("Altar: %s. %s (25 s)") % [L.t(String(pw["name"])), L.t(String(pw["desc"]))], 3.0)
			Aud.sfx("legend")
	_ring(p.position, 6.0, 90.0, p.color, 0.6)
	p.queue_redraw()


func _cleanup_enemies() -> void:
	for i in range(enemies.size() - 1, -1, -1):
		if enemies[i].dead:
			enemies.remove_at(i)


# ---------------------------------------------------------------
# Proyectiles y orbes giratorios
# ---------------------------------------------------------------
func _bullet_hit(b, e) -> void:
	var dir: Vector2 = b.vel
	if dir == Vector2.ZERO:
		dir = e.position - player.position
	_hit_enemy(e, b.dmg, b.color, dir, b.knock, b.mtype, b.burn, b.poison, b.slow)


func _update_bullets(delta: float) -> void:
	for i in range(bullets.size() - 1, -1, -1):
		var b = bullets[i]
		b.age += delta
		if arena == null:
			_cut_grass(b.position, 20.0)
		if b.orb:
			b.oa += b.ospeed * delta
			b.position = player.position + Vector2(cos(b.oa) * b.orad, sin(b.oa) * b.orad * 0.7)
			for e in enemies:
				if e.dead:
					continue
				var rr: float = e.radius + b.r
				if e.position.distance_squared_to(b.position) > rr * rr:
					continue
				var key: int = e.get_instance_id()
				var last: float = float(b.hit_log.get(key, -99.0))
				if run_time - last < b.rehit:
					continue
				b.hit_log[key] = run_time
				_bullet_hit(b, e)
			if b.hit_log.size() > 300:
				b.hit_log.clear()
			continue
		var remove: bool = b.age >= b.life
		if not remove and b.boom > 0.0:
			if not b.back and b.age >= b.boom:
				b.back = true
				b.hits.clear()
			if b.back:
				var to: Vector2 = player.position - b.position
				var dd: float = to.length()
				b.vel = b.vel.lerp(to / maxf(dd, 0.001) * b.bsp, 1.0 - exp(-7.0 * delta))
				if dd < player.radius + 8.0:
					remove = true
		if not remove and b.homing > 0.0:
			var tg: Node2D = _nearest_enemy(b.position, 340.0)
			if tg != null:
				var sp: float = b.vel.length()
				var want: Vector2 = (tg.position + Vector2(0.0, -tg.body_h * 0.5) - b.position).normalized() * sp
				b.vel = b.vel.lerp(want, 1.0 - exp(-b.homing * delta))
		if b.trail != "":
			b.trail_t -= delta
			if b.trail_t <= 0.0:
				b.trail_t = 0.04
				pfx.trail(b.trail, b.pal, b.position + Vector2(0.0, -18.0), b.vel)
		if not remove:
			b.ppos = b.position
			b.position += b.vel * delta
			if b.position.distance_squared_to(player.position) > 2000.0 * 2000.0:
				remove = true
			elif _wall_hit(b.ppos, b.position):
				if b.boom > 0.0 and not b.back:
					b.back = true
					b.hits.clear()
					b.position = b.ppos
				else:
					remove = true
		if not remove:
			for e in enemies:
				if e.dead or b.hits.has(e):
					continue
				var rr2: float = e.radius + b.r
				var cp: Vector2 = Geometry2D.get_closest_point_to_segment(e.position, b.ppos, b.position)
				if cp.distance_squared_to(e.position) > rr2 * rr2:
					continue
				b.hits.append(e)
				_bullet_hit(b, e)
				if b.pierce > 0:
					b.pierce -= 1
				else:
					remove = true
					break
		if remove:
			b.queue_free()
			bullets.remove_at(i)


# ---------------------------------------------------------------
# Experiencia, orbes y cartas de nivel
# ---------------------------------------------------------------
func _xp_for(level: int) -> int:
	var l: float = float(level)
	return int(floor((8.0 + l * 6.0 + pow(l, 1.75) * 1.6) * 4.0))


func _gain_xp(amount: float) -> void:
	player.xp += amount * _xp_mul()
	while player.xp >= player.xp_next:
		player.xp -= player.xp_next
		player.level += 1
		player.xp_next = float(_xp_for(player.level))
		pending_levels += 1


func _spawn_orb(pos: Vector2, kind: String, value: float):
	var o := Orb.new()
	o.kind = kind
	o.value = value
	o.position = pos
	o.vel = Vector2.from_angle(randf() * TAU) * randf_range(10.0, 46.0)
	fx.add_child(o)
	orbs.append(o)
	if orbs.size() > ORB_CAP:
		# Demasiados: el orbe de XP mas viejo se cobra al instante.
		for i in range(orbs.size()):
			var old = orbs[i]
			if old.kind == "xp" or old.kind == "xpBig":
				_gain_xp(old.value)
				old.queue_free()
				orbs.remove_at(i)
				break
	return o


func _drop(e) -> void:
	if e.legend:
		_legend_down(e)
		return
	if e.boss and not e.judge:
		run_bosses += 1
	if e.judge:
		jd.boss_down()
		progress_event("judgeKill")
	if e.behavior == "thief":
		if String(e.def.get("loot", "coins")) == "ticket10":
			for k in range(6):
				_spawn_orb(e.position, "coin", 5.0)
			_spawn_orb(e.position, "ticket10", 1.0)
		else:
			for k in range(20):
				_spawn_orb(e.position, "coin", 5.0)
		_say(L.t("¡Botín recuperado!"), 1.6)
		return
	if e.boss:
		var n: int = 14
		var per: float = ceilf(e.xp_val / float(n))
		for k in range(n):
			var ang: float = randf() * TAU
			_spawn_orb(e.position + Vector2.from_angle(ang) * randf_range(10.0, 70.0), "xpBig", per)
		if not e.judge:
			_spawn_orb(e.position + Vector2(24.0, 0.0), "heal", 0.0)
			_spawn_orb(e.position + Vector2(-24.0, 0.0), "magnet", 0.0)
			if randf() < 1.0 / 3.0:
				_spawn_orb(e.position + Vector2(0.0, -20.0), "ticket10", 1.0)
			for k in range(10):
				_spawn_orb(e.position + Vector2(randf_range(-40.0, 40.0), randf_range(-30.0, 30.0)), "coin", 5.0)
			_spawn_orb(e.position + Vector2(-26.0, -10.0), "item", 0.0)
		_say(L.t("¡%s derrotado!") % e.enemy_name, 2.6)
		shake = 10.0
		return
	var kind := "xp"
	if e.xp_val >= XP_ENEMY:
		kind = "xpBig"
	_spawn_orb(e.position, kind, e.xp_val)
	if randf() < 1.0 / 400.0:
		_spawn_orb(e.position + Vector2(10.0, 0.0), "ticket", 1.0)
	var r: float = randf()
	var off: Vector2 = Vector2.from_angle(randf() * TAU) * 14.0
	if r < 0.012:
		_spawn_orb(e.position + off, "heal", 0.0)
	elif r < 0.020:
		_spawn_orb(e.position + off, "magnet", 0.0)
	elif r < 0.026:
		_spawn_orb(e.position + off, "bomb", 0.0)
	elif r < 0.041:
		_spawn_orb(e.position + off, "item", 0.0)


func _update_orbs(delta: float) -> void:
	var mag_r: float = _magnet()
	var pr: Vector2 = player.position
	for i in range(orbs.size() - 1, -1, -1):
		var o = orbs[i]
		var to: Vector2 = pr - o.position
		var d: float = to.length()
		if d < 15.0:
			var kind: String = o.kind
			var val: float = o.value
			o.queue_free()
			orbs.remove_at(i)
			_collect(kind, val)
			continue
		if o.pulled or d < mag_r:
			var pull: float = 240.0 + 1400.0 / maxf(d, 1.0)
			var tv: Vector2 = to / maxf(d, 0.001) * pull
			o.vel = o.vel.lerp(tv, 1.0 - exp(-7.0 * delta))
		else:
			o.vel *= pow(0.02, delta)
		o.position += o.vel * delta


func _collect(kind: String, value: float) -> void:
	if kind == "xp" or kind == "xpBig":
		_gain_xp(value)
		Aud.xp()
	elif kind == "heal":
		Aud.sfx("heal")
		player.hp = minf(player.max_hp, player.hp + player.max_hp * 0.3)
		add_text(player.position + Vector2(0.0, -player.body_h - 4.0), L.t("+PS"), Color("#5fe08a"))
	elif kind == "magnet":
		for o in orbs:
			if o.kind == "xp" or o.kind == "xpBig":
				o.pulled = true
		add_text(player.position + Vector2(0.0, -player.body_h - 4.0), L.t("IMAN!"), Color("#7fe0ff"))
	elif kind == "coin":
		coins += int(value)
		Aud.sfx("coin")
	elif kind == "ticket10":
		tickets10 += int(value)
		Aud.sfx("shinyGet")
		add_text(player.position + Vector2(0.0, -player.body_h - 4.0), L.t("+%d ×10 tickets") % int(value), Color("#c47bff"))
	elif kind == "ticket":
		tickets += int(value)
		Aud.sfx("shinyGet")
		add_text(player.position + Vector2(0.0, -player.body_h - 4.0), L.t("+%d tickets") % int(value), Color("#ffd23f"))
	elif kind == "item":
		_offer_item()
	elif kind == "bomb":
		Aud.sfx("ball")
		shake = 12.0
		for e in enemies.duplicate():
			if not e.dead and e.position.distance_to(player.position) < 520.0:
				_damage_enemy(e, 80.0, Color("#ff7b3d"))
		add_text(player.position + Vector2(0.0, -player.body_h - 4.0), L.t("BOOM!"), Color("#ff7b3d"))


# Construye las cartas candidatas (levelup.js) y devuelve tres.
func _offer() -> Array:
	var pool: Array = []
	var waiting := {}

	# --- movimientos nuevos ---
	if _slot_list().size() < MAX_MOVES:
		var owned := {}
		var buffs := 0
		for m in player.moves:
			owned[String(m["id"])] = true
			if String(m["kind"]) == "buff":
				buffs += 1
		var cand: Array = []
		for id in MD.ORDER:
			var d: Dictionary = MD.MOVES[id]
			var ty: String = String(d["type"])
			if ty != "normal" and not player.types.has(ty):
				continue
			if owned.has(id) or banned.has(id):
				continue
			if buffs >= 2 and String(d["kind"]) == "buff":
				continue
			cand.append(id)
		cand.shuffle()
		for i in range(mini(6, cand.size())):
			var nid: String = String(cand[i])
			var nd: Dictionary = MD.MOVES[nid]
			pool.append({"cat": "new", "id": nid, "key": "new:" + nid, "w": 10.0, "title": String(nd["name"]),
				"desc": String(nd["desc"]), "icon": "move:" + nid, "tag": String(MD.TYPE_NAME[String(nd["type"])]),
				"color": Color.html(String(MD.TYPE_COLOR[String(nd["type"])]))})

	# --- evoluciones: movimiento al maximo + su condicion cumplida ---
	for m in player.moves:
		var ev: Dictionary = _evo_info(m)
		if ev.is_empty():
			continue
		if not bool(ev["ready"]):
			waiting[String(ev["needs"])] = m
			continue
		pool.append({"cat": "evo", "id": String(m["id"]), "key": "evo:" + String(m["id"]), "w": 40.0,
			"title": "%s > %s" % [L.t(String(m["name"])), L.t(String(ev["name"]))], "desc": String(ev["text"]),
			"icon": "evo:" + String(m["id"]), "tag": "EVOLUCIÓN", "color": Color("#ffd23f")})

	# --- mejoras de movimientos que ya tienes ---
	for m in player.moves:
		if int(m["lvl"]) >= _max_lvl(m):
			continue
		var ladder: Array = MD.LADDERS[String(m["kind"])]
		pool.append({"cat": "up", "id": String(m["id"]), "key": "up:" + String(m["id"]), "w": 8.0,
			"title": String(m["name"]), "icon": "move:" + String(m["id"]), "desc": String(ladder[int(m["lvl"]) - 1]["t"]),
			"tag": L.t("Nv.%d > %d") % [int(m["lvl"]), int(m["lvl"]) + 1], "color": _col(m)})

	# --- estadisticas (las que desbloquean una evolucion salen siempre) ---
	var cand_s: Array = []
	for sid in STAT_IDS:
		if waiting.has(sid):
			continue
		if _lv(sid) >= int(STATS[sid]["max"]):
			continue
		cand_s.append(sid)
	cand_s.shuffle()
	var picks_s: Array = cand_s.slice(0, 5)
	for sid in waiting:
		picks_s.append(sid)
	for sid in picks_s:
		var sd: Dictionary = STATS[sid]
		var evo_for: bool = waiting.has(sid)
		var w: float = 7.0
		if evo_for:
			w = 14.0
		elif _slot_list().size() < MAX_MOVES:
			w = 4.0
		var tag := "Mejora"
		var colr := Color("#8fa3c4")
		if evo_for:
			tag = L.t("Evoluciona ") + L.t(String(waiting[sid]["name"]))
			colr = Color("#ffd23f")
		pool.append({"cat": "stat", "id": String(sid), "key": "stat:" + String(sid), "w": w,
			"title": String(sd["title"]), "desc": String(sd["desc"]), "icon": String(STAT_ICON.get(sid, "star")), "tag": tag, "color": colr})

	# --- elegir tres ---
	var picked: Array = []
	for i in range(pool.size()):
		if String(pool[i]["cat"]) == "evo":
			picked.append(pool[i])
			pool.remove_at(i)
			break
	while picked.size() < 3 and not pool.is_empty():
		var total := 0.0
		for c in pool:
			total += float(c["w"])
		var roll: float = randf() * total
		var idx := pool.size() - 1
		for k in range(pool.size()):
			roll -= float(pool[k]["w"])
			if roll <= 0.0:
				idx = k
				break
		picked.append(pool[idx])
		pool.remove_at(idx)
	return picked


# ---------------------------------------------------------------
# Vinculos: fusiona movimientos en un solo hueco (player.js)
# ---------------------------------------------------------------
const BOND_MAX := 4


# Atajos de Mejoras: cada movimiento con hueco fijo se coloca en ese numero; si aun
# no hay tantos, va al mas cercano y el resto rellena los libres en orden de aprendizaje.
func _arrange(keep: Dictionary = {}) -> void:
	var bl: Array = SV.bind_list(SV.run_dex)
	var want_of := {}
	for i in range(4):
		if String(bl[i]) != "":
			want_of[String(bl[i])] = i
	var sl: Array = _slot_list()
	var n: int = sl.size()
	if want_of.is_empty() or n < 2:
		return
	var cur_m: Dictionary = keep
	if cur_m.is_empty() and player.slot < n:
		cur_m = sl[player.slot][0]
	var wants: Array = []
	for g in sl:
		var k := 99
		for m in g:
			if want_of.has(String(m["id"])):
				k = mini(k, int(want_of[String(m["id"])]))
		wants.append(k)
	var order: Array = []
	for gi in range(n):
		if int(wants[gi]) < 99:
			order.append(gi)
	order.sort_custom(func(a, b): return int(wants[a]) < int(wants[b]))
	var out: Array = []
	out.resize(n)
	out.fill(-1)
	for gi in order:
		var p: int = mini(int(wants[gi]), n - 1)
		while p >= 0 and int(out[p]) != -1:
			p -= 1
		if p < 0:
			p = 0
			while int(out[p]) != -1:
				p += 1
		out[p] = gi
	for gi in range(n):
		if not out.has(gi):
			out[out.find(-1)] = gi
	var flat: Array = []
	var new_slot := 0
	for pos in range(n):
		var g: Array = sl[int(out[pos])]
		if not cur_m.is_empty() and g.has(cur_m):
			new_slot = pos
		for m in g:
			flat.append(m)
	player.moves = flat
	player.slot = new_slot


func _slot_list() -> Array:
	var out: Array = []
	var grp: Array = []
	var added := false
	for m in player.moves:
		if bond_ids.has(String(m["id"])):
			if not added:
				added = true
				out.append(grp)
			grp.append(m)
		else:
			out.append([m])
	return out


func _active_group() -> Array:
	var sl: Array = _slot_list()
	return sl[clampi(player.slot, 0, sl.size() - 1)]


func _bond_options() -> Dictionary:
	var loose: Array = []
	for m in player.moves:
		if not bond_ids.has(String(m["id"])):
			loose.append(m)
	if bond_ids.size() >= 2 and bond_ids.size() < BOND_MAX:
		return {"mode": "add", "loose": loose} if not loose.is_empty() else {}
	if bond_ids.is_empty() and loose.size() >= 2:
		return {"mode": "pair", "loose": loose}
	return {}


func _offer_bond(quiet: bool = false) -> void:
	if bonds <= 0 or player.dead or choosing or arena != null:
		return
	var opt: Dictionary = _bond_options()
	if opt.is_empty():
		if not quiet:
			_say(L.t("Guardas el vínculo: aprende otro movimiento para usarlo"), 3.0)
		return
	var mode: String = String(opt["mode"])
	var names: Array = []
	for m in player.moves:
		if bond_ids.has(String(m["id"])):
			names.append(L.t(String(m["name"])))
	var gname: String = " + ".join(names)
	var picks: Array = []
	for m in opt["loose"]:
		if bond_first != "" and String(m["id"]) == bond_first:
			continue
		var d: String = String(m["desc"])
		if mode == "add":
			d = L.t("Se lanzará a la vez que %s.") % gname
		elif bond_first != "":
			d = L.t("Se lanzará a la vez que %s. Queda un hueco libre.") % _move_name(bond_first)
		picks.append({"cat": "bond", "id": String(m["id"]), "key": "bond:" + String(m["id"]), "w": 1.0,
			"title": String(m["name"]), "desc": d, "icon": "move:" + String(m["id"]),
			"tag": L.t("Nv.%d") % int(m["lvl"]), "color": _col(m)})
	var heading: String = L.t("Elige el primer movimiento que vas a unir")
	if mode == "add":
		heading = L.t("Elige qué movimiento se une a %s") % gname
	elif bond_first != "":
		heading = L.t("¿Con cuál unes %s?") % _move_name(bond_first)
	choosing = true
	Aud.sfx("levelup")
	cards.show_cards(picks, heading, L.t("¡Vínculo!"), false)


func _move_name(id: String) -> String:
	for m in player.moves:
		if String(m["id"]) == id:
			return L.t(String(m["name"]))
	return id


func _bond_pick(id: String) -> void:
	var opt: Dictionary = _bond_options()
	cards.hide_cards()
	choosing = false
	if opt.is_empty():
		bond_first = ""
		return
	if String(opt["mode"]) == "pair" and bond_first == "":
		bond_first = id
		Aud.sfx("select")
		_offer_bond(true)
		return
	var cur_m: Dictionary = _active_group()[0]
	if bond_first != "":
		bond_ids = [bond_first, id]
	else:
		bond_ids.append(id)
	bond_first = ""
	bonds = maxi(0, bonds - 1)
	var sl: Array = _slot_list()
	var target := 0
	for i in range(sl.size()):
		for m in sl[i]:
			if String(m["id"]) == id:
				target = i
	if _has_item("choiceband"):
		for i in range(sl.size()):
			for m in sl[i]:
				if String(m["id"]) == String(cur_m["id"]):
					target = i
	_clear_orbit_orbs()
	player.slot = target
	Aud.sfx("legend")
	_ring(player.position, 8.0, 130.0, Color("#ff8ad8"), 0.8)
	_say(L.t("¡Vínculo! %d movimientos a la vez") % bond_ids.size(), 2.6)


func _open_cards() -> void:
	var picks: Array = _offer()
	if picks.is_empty():
		pending_levels = 0
		return
	choosing = true
	Aud.sfx("levelup")
	cards.rerolls = rerolls
	cards.bans = bans
	cards.show_cards(picks, L.t("Nivel %d - elige una mejora") % player.level)


func _on_card_chosen(idx: int) -> void:
	var opts: Array = cards.items
	if idx < 0 or idx >= opts.size():
		return
	var c: Dictionary = opts[idx]
	var id: String = String(c["id"])
	var cat: String = String(c["cat"])
	if cat == "itemtake" or cat == "itemkeep":
		if cat == "itemtake":
			item = id
			PG.event("item", {"id": id})
			add_text(player.position + Vector2(0.0, -player.body_h - 8.0), _item_name(), Color("#ff8ad8"), 22)
		cards.hide_cards()
		choosing = false
		return
	if cat == "bond":
		_bond_pick(id)
		return
	if cat == "new":
		var nm: Dictionary = _new_move(id, 1)
		var cur_g: Array = _active_group()
		var cur_first: Dictionary = cur_g[0]
		player.moves.append(nm)
		_arrange(cur_first)
		if cur_g.size() < 2:
			var nsl: Array = _slot_list()
			for gi in range(nsl.size()):
				if String(nsl[gi][0]["id"]) == id:
					_set_active(gi)
	elif cat == "evo" or cat == "up":
		for m in player.moves:
			if String(m["id"]) == id:
				if cat == "evo":
					_evolve(m)
				else:
					_level_up_move(m)
				break
	else:
		stat_lv[id] = _lv(id) + 1
		if id == "hp":
			player.max_hp += 20.0
			player.hp = minf(player.max_hp, player.hp + 20.0)
		elif id == "heal":
			player.hp = minf(player.max_hp, player.hp + player.max_hp * 0.45)
	Aud.sfx("confirm")
	pending_levels = maxi(0, pending_levels - 1)
	cards.hide_cards()
	choosing = false


# ---------------------------------------------------------------
# Objetos (items.js): uno por run
# ---------------------------------------------------------------
func _offer_item() -> void:
	var pool: Array = []
	for it in TD.ITEMS:
		if String(it["id"]) != item:
			pool.append(it)
	var nw: Dictionary = pool[randi() % pool.size()]
	var picks: Array = []
	picks.append({"cat": "itemtake", "id": String(nw["id"]), "key": "it:" + String(nw["id"]), "w": 1.0,
		"title": String(nw["name"]), "desc": String(nw["desc"]), "icon": String(nw["id"]), "tag": "Objeto nuevo", "color": Color("#ff8ad8")})
	if item != "":
		var cur_desc: String = ""
		for it in TD.ITEMS:
			if String(it["id"]) == item:
				cur_desc = String(it["desc"])
		picks.append({"cat": "itemkeep", "id": item, "key": "keep", "w": 1.0,
			"title": _item_name(), "desc": cur_desc, "icon": item, "tag": "Quedarte con el tuyo", "color": Color("#8fa3c4")})
	choosing = true
	cards.show_cards(picks, L.t("Solo puedes llevar uno: elige con cuál quedarte"), L.t("Has encontrado un objeto"), false)


# ---------------------------------------------------------------
# Clima (weather.js): evento raro, cambia el dano segun el tipo
# ---------------------------------------------------------------
func _wx_level() -> float:
	if wx_kind == "":
		return 0.0
	return clampf(minf(wx_t / 3.0, (wx_dur - wx_t) / 3.0), 0.0, 1.0)


func _weather_mult(type: String) -> float:
	if wx_kind == "":
		return 1.0
	var d: Dictionary = TD.WEATHER[wx_kind]
	var mm: Dictionary = d["mult"]
	if mm.has(type):
		return 1.0 + (float(mm[type]) - 1.0) * _wx_level()
	return 1.0


func _weather_hurts(types: Array) -> bool:
	if wx_kind == "":
		return false
	var safe: Array = TD.WEATHER[wx_kind]["safe"]
	if safe.is_empty():
		return false
	for t in types:
		if safe.has(t):
			return false
	return true


func _weather_speed(types: Array) -> float:
	if wx_kind != "" and bool(TD.WEATHER[wx_kind]["slow"]) and not types.has("ice"):
		return 1.0 - 0.1 * _wx_level()
	return 1.0


func _weather_text() -> String:
	if wx_kind == "" or _wx_level() <= 0.0:
		return ""
	return "%s  %ds" % [L.t(String(TD.WEATHER[wx_kind]["name"])), ceili(wx_dur - wx_t)]


func _weather_banner() -> String:
	if wx_kind == "" or wx_banner <= 0.0:
		return ""
	var d: Dictionary = TD.WEATHER[wx_kind]
	return "%s: %s" % [L.t(String(d["name"])), L.t(String(d["hint"]))]


# ---------------------------------------------------------------
# Grietas y arenas legendarias (rift.js)
# ---------------------------------------------------------------
func _update_rift(delta: float) -> void:
	if rift != null:
		if not is_instance_valid(rift) or rift.ttl <= 0.0:
			if is_instance_valid(rift):
				rift.queue_free()
			rift = null
			_rift_drop_arena()
		elif rift.t > 1.0 and player.position.distance_to(rift.position) < 42.0 and not player.dead:
			_arena_begin()
			return
	rift_check -= delta
	if rift_check > 0.0:
		return
	rift_check = RIFT_EVERY
	if rift != null or run_time >= RIFT_END or _boss_alive():
		return
	var chance: float = minf(1.0, 0.2 + 0.2 * float(rift_miss))
	if randf() < chance:
		rift_miss = 0
		_open_rift()
	else:
		rift_miss += 1


func _legend_pool() -> Array:
	var out: Array = []
	for p in _dex_list:
		if bool(p.get("leg", false)) and _smeta.has(str(int(p["dex"]))):
			out.append(p)
	return out


func _pick_legend() -> Dictionary:
	var pool: Array = _legend_pool()
	if pool.is_empty():
		return {}
	var seen: Dictionary = SV.d.get("legends", {})
	var tot := 0.0
	for p in pool:
		tot += 1.0 if seen.has(str(int(p["dex"]))) else 4.0
	var roll: float = randf() * tot
	for p in pool:
		roll -= 1.0 if seen.has(str(int(p["dex"]))) else 4.0
		if roll <= 0.0:
			return p
	return pool[pool.size() - 1]


func _open_rift(force_dex: int = -1) -> void:
	var p: Dictionary = _dex_by[force_dex] if force_dex > 0 else _pick_legend()
	if p.is_empty():
		return
	var pos: Vector2 = player.position + Vector2.from_angle(randf() * TAU) * randf_range(380.0, 560.0)
	for i in range(14):
		if not _blocked(pos, 30.0):
			break
		pos = player.position + Vector2.from_angle(randf() * TAU) * randf_range(380.0, 560.0)
	var tys: Array = p["types"]
	var ty: String = String(tys[randi() % tys.size()])
	if not ARENA.THEMES.has(ty):
		ty = "normal"
	var dex: int = int(p["dex"])
	rift = ARENA.Portal.new()
	rift.position = pos
	world.add_child(rift)
	var ar: Node2D = ARENA.new()
	ar.setup(ty, randi() % 100000)
	ar.start_bake()
	rift_info = {"dex": dex, "type": ty, "shiny": bool(_sm(dex).get("sh", 0)) and randf() < 1.0 / 512.0, "arena": ar}
	Aud.sfx("rift")
	hud.rift_notice = 0.0   # cartel grande como en el original (4,5 s)


func _rift_drop_arena() -> void:
	var ar = rift_info.get("arena")
	if ar != null and is_instance_valid(ar):
		ar.dispose()
	rift_info = {}


func _exit_tree() -> void:
	Engine.time_scale = 1.0
	_rift_drop_arena()


func _update_rift_hud() -> void:
	hud.rift_ttl = -1.0
	hud.legend_frac = -1.0
	if arena != null:
		hud.arena_left = maxf(0.0, ARENA_LIMIT - float(ainfo.get("t", 0.0))) if String(ainfo.get("phase", "")) == "fight" else -1.0
		var b = ainfo.get("boss")
		if b != null and is_instance_valid(b):
			hud.legend_name = b.enemy_name
			hud.legend_frac = clampf(b.hp / maxf(b.max_hp, 1.0), 0.0, 1.0)
		return
	if rift != null and is_instance_valid(rift):
		var to: Vector2 = rift.position - player.position
		var vp: Vector2 = get_viewport_rect().size
		hud.rift_ttl = rift.ttl
		hud.rift_dir = to.normalized()
		hud.rift_scr = get_viewport().get_canvas_transform() * (rift.position + Vector2(0.0, -40.0))
		hud.rift_m = roundi(to.length() / ground.TS)
		hud.rift_off = hud.rift_scr.x < 0.0 or hud.rift_scr.x > vp.x or hud.rift_scr.y < 0.0 or hud.rift_scr.y > vp.y


func _free_list(arr: Array) -> void:
	for x in arr:
		if is_instance_valid(x):
			x.queue_free()
	arr.clear()


func _legend_def(dex: int) -> Dictionary:
	var p: Dictionary = _dex_by[dex]
	var t: float = run_time
	var ranged: bool = _has_t(p["types"], ["psychic", "electric", "ghost", "fairy", "fire", "water", "ice", "dragon"])
	return {"dex": dex, "name": String(p["name"]), "hp": 3200.0 + 9.0 * t,
		"spd": clampf(48.0 + (float(p["spd"]) - 78.0) * 0.6, 48.0, 105.0),
		"dmg": 36.0 + t / 20.0, "xp": 500.0 + 1.2 * t,
		"behavior": "ranged" if ranged else "charger", "shotDmg": 18.0 + t / 40.0, "shotCd": 0.9, "range": 300.0}


func _arena_begin() -> void:
	var dex: int = int(rift_info["dex"])
	var ty: String = String(rift_info["type"])
	var new_arena: Node2D = rift_info["arena"]
	ainfo = {"phase": "fight", "t": 0.0, "back": player.position, "dex": dex, "type": ty,
		"shiny": bool(rift_info["shiny"]), "stash_e": enemies.duplicate(), "stash_o": orbs.duplicate(), "end": 0.0, "boss": null}
	for e in enemies:
		e.visible = false
	for o in orbs:
		if is_instance_valid(o):
			o.visible = false
	enemies.clear()
	orbs.clear()
	_free_list(bullets)
	_free_list(fields)
	_free_list(hazards)
	_free_list(ebullets)
	if is_instance_valid(rift):
		rift.queue_free()
	rift = null
	rift_info = {}
	ground.visible = false
	arena = new_arena
	arena.position = ARENA_POS
	arena.z_index = -2
	add_child(arena)
	arena.build(world)
	player.position = ARENA_POS + Vector2(0.0, 3.0 * ARENA.TS)
	player_vel = Vector2.ZERO
	var def: Dictionary = _legend_def(dex)
	var e: Enemy = _make_enemy(def, ARENA_POS + Vector2(0.0, -3.5 * ARENA.TS), {"hp": 1.0, "dmg": 1.0, "spd": 1.0}, true)
	e.legend = true
	e.flying = false
	if bool(ainfo["shiny"]):
		e.make_shiny()
	ainfo["boss"] = e
	var wk: String = String(arena.th.get("weather", ""))
	if wk != "" and TD.WEATHER.has(wk):
		_start_weather(wk, 135.0)
	else:
		wx_kind = ""
		wx.clear()
	Aud.sfx("legend")
	_say(L.t("¡%s te desafía!") % e.enemy_name, 3.0)
	shake = 10.0


func _update_arena(delta: float) -> void:
	var ph: String = String(ainfo.get("phase", ""))
	if ph == "fight":
		ainfo["t"] = float(ainfo["t"]) + delta
		var b = ainfo["boss"]
		if b == null or not is_instance_valid(b) or b.dead:
			return
		if float(ainfo["t"]) >= ARENA_LIMIT:
			ainfo["phase"] = "lost"
			ainfo["why"] = "time"
	elif ph == "lost":
		_arena_end(false, String(ainfo.get("why", "")) == "time")
	elif ph == "won":
		ainfo["end"] = float(ainfo["end"]) - delta
		if float(ainfo["end"]) <= 0.0:
			_arena_end(true)


func progress_event(ev: String, _d = null) -> void:
	if ev == "judge":
		PG.check()


# Viaje a la arena de la Sentencia (judgment.gd): igual que entrar a una grieta.
func _jd_port(new_arena: Node2D) -> void:
	ainfo = {"phase": "cine", "back": player.position, "stash_e": enemies.duplicate(), "stash_o": orbs.duplicate()}
	for e in enemies:
		e.visible = false
	for o in orbs:
		if is_instance_valid(o):
			o.visible = false
	enemies.clear()
	orbs.clear()
	_free_list(bullets)
	_free_list(fields)
	_free_list(hazards)
	_free_list(ebullets)
	if is_instance_valid(rift):
		rift.queue_free()
	rift = null
	_rift_drop_arena()
	ground.visible = false
	arena = new_arena
	arena.position = ARENA_POS
	arena.z_index = -2
	add_child(arena)
	arena.build(world)
	wx_kind = ""
	wx.clear()


func _legend_down(e) -> void:
	if arena == null or String(ainfo.get("phase", "")) != "fight":
		return
	ainfo["phase"] = "won"
	ainfo["end"] = 5.0
	var pos: Vector2 = e.position
	var dex: int = int(ainfo["dex"])
	var lg: Dictionary = SV.d.get("legends", {})
	lg[str(dex)] = int(lg.get(str(dex), 0)) + 1
	SV.d["legends"] = lg
	var ar: Dictionary = SV.d.get("arenas", {})
	ar[String(ainfo["type"])] = int(ar.get(String(ainfo["type"]), 0)) + 1
	SV.d["arenas"] = ar
	if bool(ainfo["shiny"]):
		var ls: Dictionary = SV.d.get("lshiny", {})
		ls[str(dex)] = true
		SV.d["lshiny"] = ls
		Aud.sfx("shiny")
	var st: Dictionary = SV.d["stats"]
	st["rifts"] = int(st.get("rifts", 0)) + 1
	SV.save()
	PG.event("rift", {"type": String(ainfo["type"])})
	var n := 14
	var per: float = ceilf(e.xp_val / float(n))
	var made: Array = []
	for k in range(n):
		made.append(_spawn_orb(pos, "xpBig", per))
	made.append(_spawn_orb(pos + Vector2(24.0, 0.0), "item", 0.0))
	made.append(_spawn_orb(pos + Vector2(-24.0, 0.0), "ticket", 3.0))
	if randf() < 0.5:
		made.append(_spawn_orb(pos + Vector2(0.0, 24.0), "ticket10", 1.0))
	for k in range(10):
		made.append(_spawn_orb(pos, "coin", 10.0))
	made.append(_spawn_orb(pos + Vector2(0.0, -24.0), "heal", 0.0))
	for o in made:
		if o != null and is_instance_valid(o):
			o.pulled = true
	bonds += 1
	Aud.sfx("bossDown")
	_say(L.t("¡Legendario derrotado!"), 3.0)
	shake = 12.0


func _arena_end(won: bool, timeout: bool = false) -> void:
	if arena == null:
		return
	var back: Vector2 = ainfo["back"]
	_free_list(bullets)
	_free_list(fields)
	_free_list(hazards)
	_free_list(ebullets)
	for e in enemies:
		if is_instance_valid(e):
			e.queue_free()
	enemies.clear()
	_free_list(orbs)
	arena.clear_props()
	arena.queue_free()
	arena = null
	ground.visible = true
	wx_kind = ""
	wx.clear()
	for e in ainfo["stash_e"]:
		if is_instance_valid(e) and not e.dead:
			e.visible = true
			enemies.append(e)
	for o in ainfo["stash_o"]:
		if is_instance_valid(o):
			o.visible = true
			orbs.append(o)
	player.position = _free_spot(back, 14.0)
	player_vel = Vector2.ZERO
	player.invuln = 1.5
	if not won:
		player.hp = maxf(player.hp, player.max_hp * 0.3)
		_say(L.t("Se acabó el tiempo") if timeout else L.t("El legendario te superó…"), 3.0)
	ainfo = {}
	if won and bonds > 0 and _bond_options().is_empty():
		_say(L.t("Guardas el vínculo: aprende otro movimiento para usarlo"), 3.0)
	rift_check = RIFT_EVERY
	rift_miss = 0
	_update_world(0.0)
	shake = 0.0


func _start_weather(kind: String, dur: float) -> void:
	wx_kind = kind
	wx_t = 0.0
	wx_dur = dur
	wx_banner = 3.4
	wx.setup(TD.WEATHER[kind])


func _update_weather(delta: float) -> void:
	wx_banner = maxf(0.0, wx_banner - delta)
	if wx_kind != "":
		wx_t += delta
		if wx_t >= wx_dur:
			wx_kind = ""
			wx.clear()
	elif run_time > 120.0 and arena == null:
		wx_check -= delta
		if wx_check <= 0.0:
			wx_check = 60.0
			if randf() < 0.18:
				var w: Dictionary = TD.BIOME_W[mini(biome_idx, 2)]
				var total: float = 0.0
				for k in w:
					total += float(w[k])
				var roll: float = randf() * total
				var pick: String = "rain"
				for k in w:
					roll -= float(w[k])
					if roll <= 0.0:
						pick = String(k)
						break
				_start_weather(pick, roundf(randf_range(55.0, 75.0)))
	# Arena y nieve: te van quitando un poco de vida (nunca te dejan KO).
	wx_chip -= delta
	if wx_chip <= 0.0:
		wx_chip = 2.0
		if wx_kind != "" and _wx_level() > 0.5:
			var wc := Color.html(String(TD.WEATHER[wx_kind]["color"]))
			if _weather_hurts(player.types):
				var d: float = maxf(1.0, player.max_hp * 0.012)
				if player.hp > d + 1.0:
					player.hp -= d
					add_text(player.position + Vector2(0.0, -player.body_h - 4.0), "-" + str(roundi(d)), wc)
			for e in enemies:
				if e.dead or not _weather_hurts(e.types):
					continue
				if e.hurt_by(e.max_hp * 0.02 + 1.0):
					kills += 1
					_drop(e)


func add_text(pos: Vector2, text: String, color: Color, size: int = 18) -> void:
	if not dmg_on and (text.is_valid_int() or (text.begins_with("-") and text.substr(1).is_valid_int())):
		return
	var f := Floater.new()
	f.text = L.t(text)
	f.size = size
	f.color = color
	f.position = pos
	fx.add_child(f)


# ---------------------------------------------------------------
# Actor: sprite + animacion + sombra + destello (jugador y enemigos)
# ---------------------------------------------------------------
class Actor extends Node2D:
	const SPR_K := 1.12   # jugador y Pokemon salvajes un 12 % mas grandes (solo el dibujo; el area de choque no cambia)
	const PX := 2.0               # unidades de mundo por pixel de arte

	var dex := 0
	var smeta: Dictionary = {}
	var meta: Dictionary = {}     # animacion -> geometria
	var shiny := false
	var scl := 1.0
	var sprite := Sprite2D.new()
	var mat := ShaderMaterial.new()
	var textures := {}
	var anim := "Idle"
	var base := "Idle"
	var once := false
	var hold := false
	var frame := 0
	var t := 0.0
	var anim_speed := 1.0
	var dir := 0                  # fila: 0 Down,1 DownRight,2 Right,3 UpRight,4 Up,5 UpLeft,6 Left,7 DownLeft
	var radius := 12.0
	var body_h := 40.0
	var shadow_rx := 16.0
	static var flash_k := 1.0
	var flash := 0.0
	var fade := -1.0
	var active := true
	var hover := false
	var bob := 0.0
	var lift_extra := 0.0
	var dirty := true

	func setup(d: int, sm: Dictionary, shader: Shader, s: float = 1.0, shn: bool = false) -> void:
		dex = d
		smeta = sm
		meta = sm["a"]
		scl = s
		shiny = shn
		hover = bool(sm.get("hv", 0))
		mat.shader = shader
		sprite.material = mat
		sprite.centered = false
		sprite.region_enabled = true
		sprite.scale = Vector2(PX * scl * SPR_K, PX * scl * SPR_K)
		add_child(sprite)
		var idle: Dictionary = meta["Idle"] if meta.has("Idle") else meta["Walk"]
		radius = clampf(float(idle["w"]) * 0.22, 5.0, 26.0) * PX * scl
		body_h = float(idle["ay"]) * PX * scl * SPR_K
		var sizes := [5.0, 8.0, 12.0]
		shadow_rx = float(sizes[clampi(int(sm.get("s", 1)), 0, 2)]) * PX * scl * SPR_K
		if not meta.has("Idle"):
			anim = "Walk"
			base = "Walk"
		_apply()
		queue_redraw()

	func set_shiny() -> void:
		shiny = true
		textures.clear()
		dirty = true
		_apply()

	func _am(a: String) -> Dictionary:
		if shiny and smeta.has("sa") and (smeta["sa"] as Dictionary).has(a):
			return smeta["sa"][a]
		return meta[a]

	func _tex_path(a: String, shn: bool) -> String:
		if shn:
			return "res://assets/pokemon/%d/s/%s.png" % [dex, a]
		return "res://assets/pokemon/%d/%s.png" % [dex, a]

	func _tex(a: String) -> Texture2D:
		if not textures.has(a):
			var tx: Texture2D = null
			if shiny:
				var ps: String = _tex_path(a, true)
				if ResourceLoader.exists(ps):
					tx = load(ps)
			if tx == null:
				var p: String = _tex_path(a, false)
				if ResourceLoader.exists(p):
					tx = load(p)
			textures[a] = tx
		return textures[a]

	func has_anim(a: String) -> bool:
		return meta.has(a) and _tex(a) != null

	func face_angle(a: float) -> void:
		var nd: int = posmod(int(floor((PI / 2.0 - a) / (PI / 4.0) + 0.5)), 8)
		if nd != dir:
			dir = nd
			dirty = true

	func _start(a: String) -> void:
		anim = a
		frame = 0
		t = 0.0
		dirty = true

	func loop_anim(a: String, spd: float) -> void:
		if not has_anim(a):
			a = "Idle" if has_anim("Idle") else "Walk"
		base = a
		if not once and anim != a:
			_start(a)
		if not once:
			anim_speed = spd

	func progress() -> float:
		var am: Dictionary = _am(anim)
		var total := 0.0
		var before := 0.0
		var i := 0
		for dd in am["d"]:
			if i < frame:
				before += float(dd)
			total += float(dd)
			i += 1
		if total <= 0.0:
			return 1.0
		return (before + t) / total

	# Reproduce una animacion una vez y vuelve a la base (hold: se queda en el ultimo fotograma).
	func play(a: String, spd: float = 1.0, hld: bool = false) -> void:
		if not has_anim(a):
			return
		if once and not hold and progress() < 0.65 and not hld:
			return
		_start(a)
		once = true
		hold = hld
		anim_speed = spd

	func play_attack(a: String, cd: float) -> void:
		if not has_anim(a):
			return
		if once and progress() < 0.65:
			return
		var am: Dictionary = _am(a)
		var total := 0.0
		for dd in am["d"]:
			total += float(dd)
		var dur: float = total / 60.0
		_start(a)
		once = true
		hold = false
		anim_speed = maxf(1.0, dur / (maxf(0.12, cd) * 0.9))

	func tick_anim(delta: float) -> void:
		var am: Dictionary = _am(anim)
		var before_f: int = frame
		t += delta * 60.0 * anim_speed
		var guard := 0
		while t >= float(am["d"][frame]) and guard < 16:
			guard += 1
			t -= float(am["d"][frame])
			frame += 1
			if frame >= int(am["n"]):
				if hold:
					frame = int(am["n"]) - 1
					t = 0.0
					break
				elif once:
					once = false
					anim = base
					frame = 0
					t = 0.0
					anim_speed = 1.0
					am = _am(anim)
				else:
					frame = 0
		if frame != before_f or guard > 0:
			dirty = true
		_apply()

	func _apply() -> void:
		var py: float = -(lift_extra + (sin(bob) * 3.0 if hover else 0.0) + (6.0 if hover else 0.0))
		sprite.position.y = py
		if not dirty:
			return
		dirty = false
		var am: Dictionary = _am(anim)
		var tx: Texture2D = _tex(anim)
		if tx == null:
			tx = _tex(base) if _tex(base) != null else null
			if tx == null and meta.has("Idle"):
				tx = _tex("Idle")
		sprite.texture = tx
		sprite.visible = tx != null
		sprite.offset = Vector2(-float(am["ax"]), -float(am["ay"]))
		sprite.region_rect = Rect2(frame * float(am["w"]), minf(dir, float(am.get("r", 8)) - 1.0) * float(am["h"]), float(am["w"]), float(am["h"]))

	func _process(delta: float) -> void:
		bob += delta * 6.0
		if fade >= 0.0:
			fade -= delta
			modulate.a = clampf(fade / 0.5, 0.0, 1.0)
			if once or hold:
				tick_anim(delta)
			if fade <= 0.0:
				queue_free()
			return
		if flash > 0.0:
			flash = maxf(0.0, flash - delta * 8.0)
			mat.set_shader_parameter("flash", flash * flash_k)
		if active and not meta.is_empty():
			tick_anim(delta)
		elif hover or lift_extra != 0.0:
			_apply()

	func _draw() -> void:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.42))
		draw_circle(Vector2.ZERO, shadow_rx, Color(0, 0, 0, 0.34))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


class Player extends Actor:
	var hp := 1.0
	var max_hp := 1.0
	var spd := 100.0
	var atk := 1.0
	var types: Array = []
	var invuln := 0.0
	var dead := false
	var aim := PI / 2.0
	var attack_face := 0.0
	var level := 1
	var xp := 0.0
	var xp_next := 62.0
	var moves: Array = []
	var slot := 0
	var orb_cast_t := 0.0
	var last_patch = null
	var buffs := {
		"atk": {"n": 0, "amount": 0.0, "t": 0.0},
		"spd": {"n": 0, "amount": 0.0, "t": 0.0},
		"def": {"n": 0, "amount": 0.0, "t": 0.0},
		"regen": {"n": 0, "amount": 0.0, "t": 0.0},
	}


class Enemy extends Actor:
	var judge := false
	var hp := 10.0
	var max_hp := 10.0
	var spd := 50.0
	var dmg := 5.0
	var touch_cd := 0.0
	var dead := false
	var knock := Vector2.ZERO
	var enemy_name := ""
	var xp_val := 20.0
	var types: Array = ["normal"]
	var atk_type := "normal"
	var burn := 0
	var burn_t := 0.0
	var burn_tick := 0.0
	var poison := 0
	var poison_t := 0.0
	var poison_tick := 0.0
	var slow := 0.0
	var slow_t := 0.0
	var def: Dictionary = {}
	var boss := false
	var legend := false
	var behavior := "chase"
	var flying := false
	var sc: Dictionary = {}
	var shot_cd := 1.0
	var skill_cd := 2.0
	var shield := 0.0
	var shield_t := 0.0
	var shield_lock := 0.0   # tras un escudo no se le puede poner otro hasta que pase
	var is_minion := false
	var minions: Array = []
	var jump = null
	var phase := "walk"
	var pt := 0.0
	var dash_dir := Vector2.RIGHT
	var zig := 0.0
	var life := -1.0
	var golden := false
	var ai: Dictionary = {}
	var lava_t := 0.0

	func apply_burn(n: int) -> void:
		burn = mini(8, burn + n)
		burn_t = 3.0

	func apply_poison(n: int) -> void:
		poison = mini(8, poison + n)
		poison_t = 4.0

	func apply_slow(f: float, dur: float = 1.2) -> void:
		slow = maxf(slow, f)
		slow_t = maxf(slow_t, dur)

	func make_shiny() -> void:
		set_shiny()
		max_hp *= 2.0
		hp = max_hp
		xp_val *= 5.0

	func make_golden() -> void:
		if golden:
			return
		golden = true
		xp_val *= 2.0
		queue_redraw()

	func strike(angle: float) -> void:
		face_angle(angle)
		play("Attack", 1.3)

	# Devuelve true si este golpe lo derrota.
	func hurt_by(amount: float) -> bool:
		hp -= amount
		flash = 1.0
		queue_redraw()
		if hp <= 0.0:
			hp = 0.0
			dead = true
			fade = 0.9
			play("Faint", 1.0, true)
			return true
		return false

	func _draw() -> void:
		super._draw()
		if dead:
			return
		if golden:
			draw_arc(Vector2(0.0, -body_h * 0.5), radius + 4.0, 0.0, TAU, 20, Color(1.0, 0.82, 0.25, 0.7), 2.0)
		if shield > 0.0:
			draw_arc(Vector2(0.0, -body_h * 0.5), maxf(radius, body_h * 0.5) + 3.0, 0.0, TAU, 24, Color(0.5, 0.8, 1.0, 0.85), 2.5)
		if boss:
			var bw := 90.0
			var by: float = -body_h - 14.0
			draw_rect(Rect2(-bw * 0.5, by, bw, 6.0), Color(0, 0, 0, 0.65))
			draw_rect(Rect2(-bw * 0.5, by, bw * clampf(hp / max_hp, 0.0, 1.0), 6.0), Color("#ffd23f"))
		elif hp < max_hp:
			var w := 30.0
			var y := -body_h - 12.0
			draw_rect(Rect2(-w * 0.5, y, w, 4.0), Color(0, 0, 0, 0.6))
			draw_rect(Rect2(-w * 0.5, y, w * clampf(hp / max_hp, 0.0, 1.0), 4.0), Color("#ff6b7a"))
		if behavior == "healer" or behavior == "shielder" or behavior == "summoner":
			var ic: Color = Color("#5fe08a") if behavior == "healer" else (Color("#7fc8ff") if behavior == "shielder" else Color("#c47bff"))
			draw_circle(Vector2(0.0, -body_h - (22.0 if boss else 20.0)), 4.0, ic)


# Aviso en el suelo (hazards.js): zona circular o rayo; hace dano al cumplirse el retraso.
class Hazard extends Node2D:
	var kind := "zone"
	var r := 40.0
	var angle := 0.0
	var length := 300.0
	var width := 20.0
	var delay := 1.0
	var dmg := 10.0
	var mtype := "normal"
	var color := Color("#ff7a9e")
	var t := 0.0
	var hit := false
	var slows := false
	var pct := 0.0
	var pure := false
	var vis := ""

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		if hit:
			return
		var k: float = clampf(t / maxf(0.01, delay), 0.0, 1.0)
		var warn := Color(color.r, color.g, color.b, 0.16 + 0.22 * k)
		var edge := Color(color.r, color.g, color.b, 0.75)
		if kind == "zone":
			draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.8))
			draw_circle(Vector2.ZERO, r, warn)
			draw_arc(Vector2.ZERO, r, 0.0, TAU, 40, edge, 2.0)
			draw_circle(Vector2.ZERO, r * k, Color(color.r, color.g, color.b, 0.3))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		else:
			var d := Vector2.from_angle(angle)
			var n := Vector2(-d.y, d.x) * width * 0.5
			var p1: Vector2 = d * length
			draw_colored_polygon(PackedVector2Array([n, p1 + n, p1 - n, -n]), warn)
			draw_line(n, p1 + n, edge, 2.0)
			draw_line(-n, p1 - n, edge, 2.0)
			var q: Vector2 = d * length * k
			draw_colored_polygon(PackedVector2Array([n, q + n, q - n, -n]), Color(color.r, color.g, color.b, 0.3))


# Disparo enemigo
class EBullet extends Node2D:
	var vel := Vector2.ZERO
	var dmg := 5.0
	var mtype := "normal"
	var color := Color("#ff7a9e")
	var age := 0.0

	func _init() -> void:
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	func _process(_d: float) -> void:
		queue_redraw()

	func _draw() -> void:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.42))
		draw_circle(Vector2.ZERO, 6.0, Color(0, 0, 0, 0.3))
		draw_circle(Vector2.ZERO, 9.0, Color(1.0, 0.235, 0.314, 0.35))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		var v: Dictionary = VFX.for_type(mtype)
		var sh: String = String(v["proj"])
		var ang := 0.0
		if VFX.is_dir(sh):
			ang = vel.angle()
		elif VFX.spins(sh):
			ang = age * 9.0
		VFX.draw(self, sh, String(v["pal"]), Vector2(0.0, -18.0), ang, 1.0, int(age * 12.0), 1.0)
		return
		draw_circle(Vector2(0.0, -18.0), 8.0, Color(color.r, color.g, color.b, 0.35))
		draw_circle(Vector2(0.0, -18.0), 5.0, color)
		draw_circle(Vector2(-1.0, -19.0), 2.0, Color(1, 1, 1, 0.85))


# --- dibujo ---
class WTex:
	const SC := 2.4   # objetos del mundo (cofres, altares, fuentes...) un 20 % mas pequenos
	static var cache := {}

	static func get_t(n: String) -> Texture2D:
		if not cache.has(n):
			var p: String = "res://assets/world/%s.png" % n
			cache[n] = load(p) if ResourceLoader.exists(p) else null
		return cache[n]


class Decor extends Node2D:
	var items: Array = []
	var done := false

	func _process(_d: float) -> void:
		if not done:
			done = true
			queue_redraw()
		set_process(false)

	func _draw() -> void:
		for it in items:
			var tx: Texture2D = WTex.get_t(String(it[0]))
			if tx == null:
				continue
			var p: Vector2 = it[1]
			var sz := Vector2(tx.get_width(), tx.get_height()) * WTex.SC
			draw_texture_rect(tx, Rect2(p - sz * 0.5, sz), false)


class Pool extends Node2D:
	var kind := "water"
	var variant := 0
	var tex: Texture2D = null
	var img: Image = null
	var r := 100.0
	var tw := 0
	var th := 0

	func setup(k: String, v: int) -> void:
		kind = k
		variant = v
		tex = WTex.get_t("pool_%s_%d" % [k, v])
		if tex != null:
			img = tex.get_image()
			tw = tex.get_width()
			th = tex.get_height()
			r = float(maxi(tw, th)) * WTex.SC * 0.5
		else:
			r = 100.0

	func contains(p: Vector2) -> bool:
		var d: Vector2 = p - position
		if tex == null or img == null:
			var kx: float = d.x / r
			var ky: float = d.y / (r * 0.8)
			return kx * kx + ky * ky < 1.0
		var x: int = int(floor(d.x / WTex.SC + float(tw) * 0.5))
		var y: int = int(floor(d.y / WTex.SC + float(th) * 0.5))
		if x < 0 or y < 0 or x >= tw or y >= th:
			return false
		return img.get_pixel(x, y).a > 0.5

	func _draw() -> void:
		if tex != null:
			draw_texture_rect(tex, Rect2(-Vector2(tw, th) * WTex.SC * 0.5, Vector2(tw, th) * WTex.SC), false)
			return
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.8))
		draw_circle(Vector2.ZERO, r, Color("#d9531e") if kind == "lava" else Color("#2e7bbf"))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


class Prop extends Node2D:
	static var tw: Node2D
	var kind := "tree"
	var r := 15.0
	var solid := false
	var used := false
	var v := 0.5
	var power := ""
	var sub := ""
	var color := Color.WHITE
	var charge := 0.0
	var cd := 0.0
	var t := 0.0

	func _ready() -> void:
		t = v * 10.0
		if kind == "spring":
			charge = 120.0
		set_process(kind == "spring" or kind == "altar" or kind == "chest" or kind == "trap")

	var _trap_off := false

	func _process(delta: float) -> void:
		t += delta
		if kind == "trap":
			# las trampas se quedan quietas: solo se redibujan al activarse o recargarse
			if (cd > 0.0) != _trap_off:
				_trap_off = cd > 0.0
				queue_redraw()
			return
		queue_redraw()

	func _spr(n: String, anchor: String = "feet", lift: float = 0.0, a: float = 1.0) -> bool:
		var tx: Texture2D = WTex.get_t(n)
		if tx == null:
			return false
		var sz := Vector2(tx.get_width(), tx.get_height()) * WTex.SC
		var off := Vector2(-sz.x * 0.5, -sz.y + WTex.SC)
		if anchor == "center":
			off = -sz * 0.5
		off.y -= lift
		draw_texture_rect(tx, Rect2(off, sz), false, Color(1, 1, 1, a))
		return true

	func _draw() -> void:
		var shadow := true
		if kind == "trap" or kind == "spring" or kind == "pebble" or kind == "tuft" or kind == "wall":
			shadow = false
		if shadow:
			draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.42))
			draw_circle(Vector2.ZERO, r * 1.35, Color(0, 0, 0, 0.28))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		if kind == "tree" or kind == "rock":
			var key: String = ("tree%d" % mini(2, int(v * 3.0))) if kind == "tree" else ("rock%d" % (1 if v > 0.8 else 0))
			var tx: Texture2D = tw.prop_tex(key) if tw != null else null
			if tx != null:
				var sz := Vector2(tx.get_width(), tx.get_height()) * 2.4
				draw_texture_rect(tx, Rect2(Vector2(-sz.x * 0.5, -sz.y + 5.0), sz), false)
				return
		elif kind == "chest":
			if _spr("chest_open" if used else "chest_closed"):
				if not used:
					draw_circle(Vector2(0.0, -58.0 - 3.0 * sin(t * 3.0)), 3.0, Color(1.0, 0.9, 0.4, 0.8))
				return
		elif kind == "altar":
			if used:
				# Estatua gastada: la misma estatua, apagada y derretida (oscura, achatada, con charco).
				var mt: Texture2D = WTex.get_t("altar_" + power)
				if mt != null:
					draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.42))
					draw_circle(Vector2(0.0, 2.0), r * 1.9, Color(0.05, 0.04, 0.05, 0.55))
					draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
					var msz := Vector2(mt.get_width(), mt.get_height()) * WTex.SC
					var mrect := Rect2(Vector2(-msz.x * 0.58, -msz.y * 0.74 + WTex.SC), Vector2(msz.x * 1.16, msz.y * 0.74))
					draw_texture_rect(mt, mrect, false, Color(0.30, 0.28, 0.30, 1.0))
					# gotas fundidas
					draw_circle(Vector2(-msz.x * 0.22, -msz.y * 0.30), 3.0, Color(0.12, 0.10, 0.12, 0.9))
					draw_circle(Vector2(msz.x * 0.18, -msz.y * 0.18), 2.5, Color(0.12, 0.10, 0.12, 0.9))
					return
			var nm: String = "used" if used else power
			if _spr("altar_" + nm):
				if not used:
					var pulse: float = 0.5 + 0.5 * sin(t * 3.0)
					draw_circle(Vector2(0.0, -58.0), 14.0 + 3.0 * pulse, Color(color.r, color.g, color.b, 0.16 + 0.12 * pulse))
				return
		elif kind == "spring":
			if _spr("spring_off" if used else "spring_on", "center"):
				if not used:
					for i in range(3):
						var yy: float = -fposmod(t * 22.0 + float(i) * 14.0, 40.0)
						draw_circle(Vector2(float(i - 1) * 12.0, yy), 2.4, Color(0.8, 1.0, 0.9, 0.75))
				return
		elif kind == "trap":
			_draw_trap_tile()
			return
		_old_draw()

	# Trampa como una baldosa plana pegada al suelo; cada tipo con su color y dibujo.
	func _draw_trap_tile() -> void:
		var u := 4.6   # 1 "pixel" de arte; la baldosa son 8x8 pixeles (~37 px)
		var off: bool = cd > 0.0
		var base: Color
		var edge: Color
		var hi: Color
		match sub:
			"poison":
				base = Color("#3b2152")
				edge = Color("#241033")
				hi = Color("#b06bff")
			"ice":
				base = Color("#86cfe8")
				edge = Color("#4f9cc0")
				hi = Color("#f2fcff")
			_:
				base = Color("#5c1f0d")
				edge = Color("#2a0c05")
				hi = Color("#ff9a2e")
		if off:
			base = base.lerp(Color(0.25, 0.25, 0.25), 0.7)
			edge = edge.lerp(Color(0.2, 0.2, 0.2), 0.7)
			hi = hi.lerp(Color(0.45, 0.45, 0.45), 0.8)
		var o := Vector2(-4.0 * u, -4.0 * u)
		draw_rect(Rect2(o, Vector2(8.0 * u, 8.0 * u)), edge)
		draw_rect(Rect2(o + Vector2(u, u), Vector2(6.0 * u, 6.0 * u)), base)
		var cells: Array
		match sub:
			"poison":   # burbujas
				cells = [Vector2(2, 2), Vector2(5, 3), Vector2(3, 5), Vector2(5, 6), Vector2(2, 4)]
			"ice":      # cristal en cruz diagonal
				cells = [Vector2(2, 2), Vector2(3, 3), Vector2(4, 4), Vector2(5, 5), Vector2(5, 2), Vector2(4, 3), Vector2(3, 4), Vector2(2, 5)]
			_:          # grietas de lava
				cells = [Vector2(2, 3), Vector2(3, 3), Vector2(3, 4), Vector2(4, 4), Vector2(4, 5), Vector2(5, 5), Vector2(5, 2), Vector2(4, 2)]
		for c in cells:
			var sz: float = u * (0.9 if sub == "poison" else 1.0)
			draw_rect(Rect2(o + (c as Vector2) * u, Vector2(sz, sz)), hi)
		if sub == "fire" and not off:
			draw_rect(Rect2(o + Vector2(3.0 * u, 3.0 * u), Vector2(2.0 * u, 2.0 * u)), Color("#ffe27a"))

	func _old_draw() -> void:
		if kind == "tree":
			var g: Color = Color("#2f7a3e").lerp(Color("#3f9a4c"), v)
			draw_rect(Rect2(-4.0, -22.0, 8.0, 22.0), Color("#6b4a2e"))
			draw_circle(Vector2(0.0, -40.0), 19.0, g)
		elif kind == "rock":
			draw_circle(Vector2(0.0, -10.0), r, Color("#7d8591"))
		elif kind == "chest":
			draw_rect(Rect2(-14.0, -22.0, 28.0, 22.0), Color("#8a5a2b"))
		elif kind == "spring":
			draw_circle(Vector2.ZERO, 25.0, Color("#5fe0a8"))
		elif kind == "altar":
			draw_rect(Rect2(-12.0, -30.0, 24.0, 30.0), Color("#8a8c94"))
		elif kind == "trap":
			draw_circle(Vector2.ZERO, 16.0, Color("#6a6a6a"))


# ---------------------------------------------------------------
# Proyectil / orbe giratorio / bumeran: vuela en el plano del suelo y se
# dibuja elevado con sombra
# ---------------------------------------------------------------
class Bullet extends Node2D:
	const LIFT := 18.0
	var vel := Vector2.ZERO
	var ppos := Vector2.ZERO
	var dmg := 10.0
	var r := 6.0
	var life := 1.4
	var age := 0.0
	var pierce := 0
	var color := Color.WHITE
	var hits: Array = []
	var homing := 0.0
	var burn := 0
	var poison := 0
	var slow := 0.0
	var knock := 0.0
	var mtype := "normal"
	var boom := 0.0
	var bsp := 0.0
	var back := false
	var orb := false
	var mid := ""
	var oa := 0.0
	var orad := 60.0
	var ospeed := 2.0
	var rehit := 0.3
	var hit_log := {}
	var shape := ""
	var pal := "normal"
	var trail := ""
	var trail_t := 0.0

	func _init() -> void:
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	func _process(_d: float) -> void:
		queue_redraw()

	func _draw() -> void:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.42))
		draw_circle(Vector2.ZERO, r * 0.9, Color(0, 0, 0, 0.3))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		if shape != "":
			var ang := 0.0
			if VFX.is_dir(shape):
				ang = (oa + PI / 2.0) if orb else vel.angle()
			elif VFX.spins(shape):
				ang = age * 9.0
			var al: float = 1.0 if orb else minf(1.0, (life - age) * 4.0)
			VFX.draw(self, shape, pal, Vector2(0.0, -LIFT), ang, 1.5 if r >= 8.0 else 1.0, int(age * 12.0), al)
			return
		draw_circle(Vector2(0.0, -LIFT), r * 1.4, Color(color.r, color.g, color.b, 0.35))
		draw_circle(Vector2(0.0, -LIFT), r, color)
		draw_circle(Vector2(0.0, -LIFT), r * 0.5, Color(1, 1, 1, 0.9))


# ---------------------------------------------------------------
# Efectos breves: anillos, arcos de golpe, rayos, lineas, destellos
# ---------------------------------------------------------------
class Fx extends Node2D:
	var kind := "ring"
	var color := Color.WHITE
	var age := 0.0
	var life := 0.25
	var r0 := 0.0
	var r1 := 40.0
	var ang := 0.0
	var arc := 1.0
	var length := 0.0
	var width := 10.0
	var p2 := Vector2.ZERO

	func _process(delta: float) -> void:
		age += delta
		if age >= life:
			queue_free()
		else:
			queue_redraw()

	func _draw() -> void:
		var k: float = clampf(age / life, 0.0, 1.0)
		var a: float = 1.0 - k
		var c := Color(color.r, color.g, color.b, a * 0.85)
		var up := Vector2(0.0, -LIFT * 0.5)
		if kind == "ring":
			draw_set_transform(up, 0.0, Vector2(1.0, 0.7))
			draw_arc(Vector2.ZERO, lerpf(r0, r1, k), 0.0, TAU, 40, c, 3.0)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		elif kind == "arc":
			var pts := PackedVector2Array()
			pts.append(up)
			var n := 14
			for i in range(n + 1):
				var t: float = float(i) / float(n)
				var aa: float = ang + (t - 0.5) * arc
				pts.append(up + Vector2.from_angle(aa) * r1 * (0.55 + 0.45 * minf(1.0, k * 3.0 + 0.3)))
			if arc >= TAU - 0.05:
				draw_circle(up, r1 * (0.55 + 0.45 * minf(1.0, k * 3.0 + 0.3)), Color(color.r, color.g, color.b, a * 0.45))
				draw_arc(up, r1, 0.0, TAU, 36, c, 4.0)
			else:
				draw_colored_polygon(pts, Color(color.r, color.g, color.b, a * 0.45))
				draw_arc(up, r1, ang - arc * 0.5, ang + arc * 0.5, 18, c, 4.0)
		elif kind == "beam":
			var d: Vector2 = Vector2.from_angle(ang)
			var start: Vector2 = Vector2(0.0, -LIFT)
			draw_line(start, start + d * length, Color(color.r, color.g, color.b, a * 0.5), width * (1.0 - k * 0.5))
			draw_line(start, start + d * length, Color(1, 1, 1, a * 0.9), width * 0.35 * (1.0 - k * 0.5))
		elif kind == "line":
			draw_line(Vector2.ZERO, p2, Color(color.r, color.g, color.b, a * 0.8), width)
			draw_line(Vector2.ZERO, p2, Color(1, 1, 1, a), width * 0.4)
		elif kind == "burst":
			draw_circle(up, r1 * (1.0 - k * 0.6), Color(color.r, color.g, color.b, a * 0.5))


# ---------------------------------------------------------------
# Campos persistentes: minas, meteoros, torretas, charcos
# ---------------------------------------------------------------
class Field extends Node2D:
	var kind := "mine"
	var color := Color.WHITE
	var move: Dictionary = {}
	var vis: Dictionary = {}
	var t := 0.0
	var life := 3.0
	var arm := 0.35
	var fall := 0.5
	var r := 40.0
	var dmg := 0.0
	var shot_t := 0.3
	var tick := 0.0
	var kick := 0.0
	var gone := false

	func _process(_delta: float) -> void:
		queue_redraw()

	func _spr(pos: Vector2, ang: float, scl: float, frame: int, al: float) -> void:
		if vis.is_empty():
			return
		VFX.draw(self, String(vis["proj"]), String(vis["pal"]), pos, ang, scl, frame, al)

	func _dashed(rx: float, ry: float, col: Color) -> void:
		var n := 24
		for i in range(n):
			if i % 2 == 0:
				var a0: float = TAU * float(i) / float(n)
				var a1: float = TAU * float(i + 1) / float(n)
				draw_line(Vector2(cos(a0) * rx, sin(a0) * ry), Vector2(cos(a1) * rx, sin(a1) * ry), col, 1.5)

	func _draw() -> void:
		var now: float = Time.get_ticks_msec() / 1000.0
		if kind == "patch":
			var a: float = clampf(minf((life - t) * 2.0, t * 6.0), 0.0, 1.0)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.62))
			draw_circle(Vector2.ZERO, r, Color(color.r, color.g, color.b, 0.32 * a))
			draw_arc(Vector2.ZERO, r * 0.8, 0.0, TAU, 28, Color(color.r, color.g, color.b, 0.5 * a), 1.5)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		elif kind == "mine":
			var armed: bool = t >= arm
			var blink: bool = armed and sin(now * 8.0 + position.x) > 0.3
			draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.62))
			draw_circle(Vector2.ZERO, r * 0.45, Color(color.r, color.g, color.b, 0.18))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			_spr(Vector2(0.0, -4.0), 0.0, 1.0, 0, 1.0 if blink else 0.75)
		elif kind == "meteor":
			var k: float = clampf(t / fall, 0.0, 1.0)
			var sc: float = 0.3 + k * 0.7
			draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.6))
			draw_circle(Vector2.ZERO, r * sc, Color(0, 0, 0, 0.2 + k * 0.3))
			_dashed(r, r, Color(color.r, color.g, color.b, 0.6))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			if t > 0.0:
				_spr(Vector2((1.0 - k) * 40.0, -(1.0 - k) * 170.0 - 6.0), atan2(170.0, -40.0), 1.5, int(now * 12.0), 1.0)
		elif kind == "turret":
			var fade: float = clampf(minf((life - t) * 2.0, t * 5.0), 0.0, 1.0)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.42))
			draw_circle(Vector2.ZERO, 11.0, Color(0, 0, 0, 0.3))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			var bob: float = sin(now * 4.0 + position.x) * 2.0 - (2.0 if kick > 0.0 else 0.0)
			_spr(Vector2(0.0, -16.0 + bob), 0.0, 1.5, int(now * 8.0), fade)


# ---------------------------------------------------------------
# Barra de movimientos (abajo a la derecha): tocalos para cambiar
# ---------------------------------------------------------------
class Slots extends Node2D:
	signal picked(idx: int)
	const SZ := 76.0
	var info: Array = []
	var active := 0
	var enabled := true

	func _rects() -> Array:
		var vp: Vector2 = get_viewport_rect().size
		var n: int = info.size()
		var total: float = SZ * float(n) + 8.0 * float(maxi(0, n - 1))
		var x0: float = (vp.x - total) * 0.5
		var y0: float = vp.y - SZ - 12.0 - DSP.insets(get_tree()).w
		var out: Array = []
		for i in range(n):
			out.append(Rect2(x0 + float(i) * (SZ + 8.0), y0, SZ, SZ))
		return out

	func _process(_delta: float) -> void:
		queue_redraw()

	func _input(event: InputEvent) -> void:
		if not enabled:
			return
		if event is InputEventScreenTouch and event.pressed:
			var rs: Array = _rects()
			for i in range(rs.size()):
				if rs[i].has_point(event.position):
					get_viewport().set_input_as_handled()
					picked.emit(i)
					return

	func _draw() -> void:
		var font := ThemeDB.fallback_font
		var rs: Array = _rects()
		for i in range(rs.size()):
			var r: Rect2 = rs[i]
			var it: Dictionary = info[i]
			var col: Color = it["color"]
			var is_act: bool = i == active
			var border: Color = Color("#ffd33d") if is_act else Color(col.r, col.g, col.b, 0.6)
			draw_rect(r.grow(3.0 if is_act else 1.0), border)
			draw_rect(r, Color(0.08, 0.12, 0.2, 0.9))
			IC.draw_in(self, String(it.get("icon", "star")), r.position + Vector2(SZ * 0.5, 29.0), 32.0)
			if bool(it["evo"]):
				IC.draw_in(self, "star", r.position + Vector2(SZ - 12.0, 12.0), 12.0)
			if int(it.get("n", 1)) > 1:
				draw_rect(Rect2(r.position.x + SZ - 30.0, r.position.y + 2.0, 28.0, 14.0), Color("#ff8ad8"))
				draw_string(font, r.position + Vector2(SZ - 30.0, 13.0), "x%d" % int(it["n"]), HORIZONTAL_ALIGNMENT_CENTER, 28.0, 12, Color("#2a0f24"))
			draw_string(font, r.position + Vector2(5.0, 15.0), str(i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, Color("#8fa8cc"))
			var nm_t: String = L.t(String(it["name"]))
			var nm_fs: int = 11
			while nm_fs > 7 and font.get_string_size(nm_t, HORIZONTAL_ALIGNMENT_LEFT, -1.0, nm_fs).x > SZ - 4.0:
				nm_fs -= 1
			draw_string(font, r.position + Vector2(2.0, 55.0), nm_t, HORIZONTAL_ALIGNMENT_CENTER, SZ - 4.0, nm_fs, Color.WHITE)
			var mx: int = int(it["max"])
			var lv: int = int(it["lvl"])
			var pw: float = (SZ - 12.0) / float(maxi(1, mx))
			for p in range(mx):
				var pc := Color(1, 1, 1, 0.2)
				if p < lv:
					pc = Color("#ffd33d")
				draw_rect(Rect2(r.position.x + 6.0 + float(p) * pw, r.position.y + 60.0, pw - 1.5, 4.0), pc)
			draw_rect(Rect2(r.position.x, r.position.y + SZ - 6.0, SZ * float(it["frac"]), 6.0), Color(col.r, col.g, col.b, 0.8))


# ---------------------------------------------------------------
# Orbe de experiencia / objeto que suelta un enemigo
# ---------------------------------------------------------------
class Orb extends Node2D:
	var kind := "xp"
	var value := 20.0
	var vel := Vector2.ZERO
	var pulled := false

	func _draw() -> void:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.42))
		draw_circle(Vector2.ZERO, 6.0, Color(0, 0, 0, 0.3))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		var c := Vector2(0.0, -9.0)
		if kind == "xp":
			draw_circle(c, 8.0, Color(0.16, 0.56, 0.82, 0.35))
			draw_circle(c, 4.5, Color("#7fe0ff"))
			draw_circle(c + Vector2(-1.2, -1.4), 1.6, Color(1, 1, 1, 0.9))
		elif kind == "xpBig":
			draw_circle(c + Vector2(0.0, -4.0), 15.0, Color(1.0, 0.82, 0.25, 0.22))
			var ctx: Texture2D = WTex.get_t("xp_big")
			if ctx != null:
				var csz := Vector2(ctx.get_width(), ctx.get_height()) * 2.4
				draw_texture_rect(ctx, Rect2(c + Vector2(-csz.x * 0.5, -csz.y * 0.5 - 4.0), csz), false)
			else:
				draw_circle(c, 7.0, Color("#ffd95e"))
		else:
			var icn := "coin"
			var glow := Color("#ffd23f")
			if kind == "ticket":
				icn = "ticket"
				glow = Color("#ffd23f")
			elif kind == "ticket10":
				icn = "ticket10"
				glow = Color("#c47bff")
			elif kind == "magnet":
				icn = "magnet"
				glow = Color("#7fe0ff")
			elif kind == "bomb":
				icn = "bomb"
				glow = Color("#ff7b3d")
			elif kind == "item":
				icn = "star"
				glow = Color("#ff8ad8")
			elif kind != "coin":
				icn = "berry"
				glow = Color("#5fe08a")
			draw_circle(c + Vector2(0.0, -4.0), 15.0, Color(glow.r, glow.g, glow.b, 0.22))
			IC.draw_in(self, icn, c + Vector2(0.0, -4.0), 20.0)



# ---------------------------------------------------------------
# Cartas de subida de nivel (tactil, mando y teclado)
# ---------------------------------------------------------------
class Cards extends Node2D:
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

	func _btn_rects() -> Array:
		var vp: Vector2 = get_viewport_rect().size
		return [Rect2(vp.x * 0.5 - 250.0, vp.y - 100.0, 230.0, 50.0), Rect2(vp.x * 0.5 + 20.0, vp.y - 100.0, 230.0, 50.0)]

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
		queue_redraw()

	func hide_cards() -> void:
		open = false
		queue_redraw()

	func _rects() -> Array:
		var vp: Vector2 = get_viewport_rect().size
		var n: int = items.size()
		var gap := 20.0
		var w: float = minf(300.0, (vp.x - 80.0 - gap * float(n - 1)) / float(maxi(n, 1)))
		var h := 294.0
		var total: float = w * float(n) + gap * float(n - 1)
		var x0: float = (vp.x - total) * 0.5
		var y0: float = vp.y * 0.5 - 106.0
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
		var vp: Vector2 = get_viewport_rect().size
		draw_rect(Rect2(Vector2.ZERO, vp), Color(0, 0, 0, 0.6))
		draw_string(font, Vector2(0.0, vp.y * 0.5 - 150.0), L.t(headline), HORIZONTAL_ALIGNMENT_CENTER, vp.x, 40, Color("#ffd33d"))
		draw_string(font, Vector2(0.0, vp.y * 0.5 - 118.0), L.t(title), HORIZONTAL_ALIGNMENT_CENTER, vp.x, 20, Color.WHITE)
		var rs: Array = _rects()
		for i in range(rs.size()):
			var r: Rect2 = rs[i]
			var it: Dictionary = items[i]
			var tag_col: Color = it["color"]
			var chosen_now: bool = i == sel
			var border: Color = tag_col
			if chosen_now:
				border = Color("#ffd33d")
			draw_rect(r.grow(4.0 if chosen_now else 1.5), border)
			draw_rect(r, Color("#1b2a44"))
			draw_rect(Rect2(r.position, Vector2(r.size.x, 32.0)), Color(tag_col.r, tag_col.g, tag_col.b, 0.35))
			draw_string(font, r.position + Vector2(10.0, 22.0), L.t(String(it["tag"])), HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 40.0, 16, Color.WHITE)
			draw_string(font, r.position + Vector2(r.size.x - 24.0, 22.0), str(i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18, Color("#8fa8cc"))
			var ic_c: Vector2 = r.position + Vector2(r.size.x * 0.5, 72.0)
			var ic_bg := Rect2(ic_c - Vector2(34.0, 34.0), Vector2(68.0, 68.0))
			draw_rect(ic_bg, Color(tag_col.r, tag_col.g, tag_col.b, 0.22))
			draw_rect(ic_bg, Color(tag_col.r, tag_col.g, tag_col.b, 0.7), false, 2.0)
			IC.draw_in(self, String(it.get("icon", "star")), ic_c, 52.0)
			draw_multiline_string(font, r.position + Vector2(12.0, 134.0), L.t(String(it["title"])), HORIZONTAL_ALIGNMENT_CENTER, r.size.x - 24.0, 24, 2, Color.WHITE)
			draw_multiline_string(font, r.position + Vector2(16.0, 196.0), L.t(String(it["desc"])), HORIZONTAL_ALIGNMENT_CENTER, r.size.x - 32.0, 18, 5, Color("#c8d6ee"))
		if extras:
			var brs: Array = _btn_rects()
			if rerolls > 0:
				draw_rect(brs[0], Color("#1b2a44"))
				draw_rect(brs[0], Color("#7fe0ff"), false, 2.0)
				draw_string(font, brs[0].position + Vector2(0.0, 32.0), L.t("Cambiar (%d)  [R]") % rerolls, HORIZONTAL_ALIGNMENT_CENTER, brs[0].size.x, 20, Color.WHITE)
			if bans > 0:
				draw_rect(brs[1], Color("#5a1f2a") if ban_mode else Color("#1b2a44"))
				draw_rect(brs[1], Color("#ff6b7a"), false, 2.0)
				draw_string(font, brs[1].position + Vector2(0.0, 32.0), L.t("Vetar (%d)  [B]") % bans, HORIZONTAL_ALIGNMENT_CENTER, brs[1].size.x, 20, Color.WHITE)
			if ban_mode:
				draw_string(font, Vector2(0.0, vp.y * 0.5 + 214.0), L.t("Elige un movimiento nuevo para vetarlo"), HORIZONTAL_ALIGNMENT_CENTER, vp.x, 22, Color("#ff9aa5"))
		draw_string(font, Vector2(0.0, vp.y - 24.0), L.t("Toca una carta  |  Mando: izq/der + A  |  Teclado: 1 2 3"), HORIZONTAL_ALIGNMENT_CENTER, vp.x, 18, Color("#8fa8cc"))


# ---------------------------------------------------------------
# Numero de dano flotante
# ---------------------------------------------------------------
class Floater extends Node2D:
	var text := ""
	var color := Color.WHITE
	var life := 0.7
	var age := 0.0
	var size := 18

	func _process(delta: float) -> void:
		age += delta
		position.y -= 38.0 * delta
		if age >= life:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		var k: float = clampf(age / life, 0.0, 1.0)
		var a: float = clampf(1.0 - k * k, 0.0, 1.0)
		var font := ThemeDB.fallback_font
		draw_string_outline(font, Vector2(-30.0, 0.0), L.t(text), HORIZONTAL_ALIGNMENT_CENTER, 60.0, size, 4, Color(0, 0, 0, a))
		draw_string(font, Vector2(-30.0, 0.0), L.t(text), HORIZONTAL_ALIGNMENT_CENTER, 60.0, size, Color(color.r, color.g, color.b, a))



# ---------------------------------------------------------------
# Suelo: cuadricula que sigue a la camara (provisional, hasta tener mapa)
# ---------------------------------------------------------------
class Ground extends Node2D:
	const TILE := 192.0
	var center := Vector2.ZERO

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		var half: Vector2 = get_viewport_rect().size * 0.5 + Vector2(TILE, TILE)
		var x0: int = int(floor((center.x - half.x) / TILE))
		var x1: int = int(ceil((center.x + half.x) / TILE))
		var y0: int = int(floor((center.y - half.y) / TILE))
		var y1: int = int(ceil((center.y + half.y) / TILE))
		var tx: Texture2D = WTex.get_t("ground_grass")
		for ix in range(x0, x1 + 1):
			for iy in range(y0, y1 + 1):
				if tx != null:
					draw_texture_rect(tx, Rect2(ix * TILE, iy * TILE, TILE, TILE), false)
				else:
					var c := Color("#1f3d2e")
					if posmod(ix + iy, 2) == 1:
						c = Color("#244632")
					draw_rect(Rect2(ix * TILE, iy * TILE, TILE, TILE), c)



# ---------------------------------------------------------------
# HUD: vida, tiempo, derrotados, pantalla de derrota
# ---------------------------------------------------------------
# ---------------------------------------------------------------
# Minimapa circular (exclusivo del port Android). Terreno detallado que se desplaza
# con el jugador y niebla de exploracion: lo que ya recorriste queda dibujado (mas
# apagado), lo que no, oculto. Iconos: cofres/altares/fuentes cercanos o ya vistos,
# trampas ocultas solo muy cerca, enemigos solo a corta distancia; grietas y jefes
# siempre, como flecha en el borde.
# ---------------------------------------------------------------
class Minimap extends Node2D:
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
	func _fog_update(i0: Vector2i) -> void:
		for oy in range(-SIGHT, SIGHT + 1):
			for ox in range(-SIGHT, SIGHT + 1):
				if ox * ox + oy * oy <= SIGHT * SIGHT:
					explored[Vector2i(i0.x + ox, i0.y + oy)] = true
		var half: int = N / 2
		for r in range(N):
			for c in range(N):
				var tx: int = i0.x - half + c
				var ty: int = i0.y - half + r
				var ox: int = tx - i0.x
				var oy: int = ty - i0.y
				var a := 0.94
				if ox * ox + oy * oy <= SIGHT * SIGHT:
					a = 0.0
				elif explored.has(Vector2i(tx, ty)):
					a = 0.5
				fog.set_pixel(c, r, Color(0.03, 0.05, 0.11, a))
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
			_fog_update(i0)
			_acc = 1.0
		_acc += delta
		if _acc >= 0.04:   # 25 veces por segundo bastan para el minimapa
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
			for p in m.chunks[key]["props"]:
				if not is_instance_valid(p) or p.used:
					continue
				var k: String = p.kind
				if k != "chest" and k != "altar" and k != "spring" and k != "trap":
					continue
				var d: float = p.position.distance_to(ppos)
				var q: Vector2 = _pt(p.position)
				if not _inside(q, 6.0):
					continue
				if k == "trap":
					if d > trap_r or p.cd > 900.0:
						continue
					var tc := Color("#a35cff") if p.sub == "poison" else (Color("#5fd8ff") if p.sub == "ice" else Color("#ff8a2b"))
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


class Hud extends Node2D:
	var hp := 1.0
	var max_hp := 1.0
	var run_time := 0.0
	var kills := 0
	var dead := false
	var show_end := false
	var poke_name := ""
	var level := 1
	var xp := 0.0
	var xp_next := 1.0
	var buff_text := ""
	var power_id := ""
	var item_name := ""
	var item_id := ""
	var weather_text := ""
	var banner := ""
	var coins := 0
	var tickets := 0
	var tickets10 := 0
	var paused := false
	var show_fps := false
	var rift_dir := Vector2.ZERO
	var rift_ttl := -1.0
	var rift_off := false
	var rift_scr := Vector2.ZERO
	var rift_m := 0
	var arena_left := -1.0
	var legend_name := ""
	var legend_frac := -1.0
	var arena_won := false
	var toast: Dictionary = {}
	var toast_t := 0.0

	var _acc := 0.0

	var rift_notice := -1.0
	var death_t := 0.0

	func _process(delta: float) -> void:
		if rift_notice >= 0.0:
			rift_notice += delta
			if rift_notice >= 4.5:
				rift_notice = -1.0
		_acc += delta
		if _acc >= 0.033:   # el HUD se redibuja 30 veces por segundo (texto y barras)
			_acc = 0.0
			queue_redraw()

	# Poderes activos (mejoras de altar, buffs) y objeto: en el centro, bajo el reloj.
	func _chip(font: Font, vp: Vector2, y: float, txt: String, col: Color, icon: Texture2D, icon_name: String) -> void:
		var tw: float = font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 20).x
		var iw: float = 34.0 if (icon != null or icon_name != "") else 0.0
		var w: float = tw + iw + 26.0
		var x0: float = (vp.x - w) * 0.5
		draw_rect(Rect2(x0, y - 24.0, w, 38.0), Color(0.03, 0.06, 0.16, 0.62))
		draw_rect(Rect2(x0, y - 24.0, w, 38.0), Color(col.r, col.g, col.b, 0.8), false, 2.0)
		var tx: float = x0 + 13.0
		if icon != null:
			var h: float = 30.0
			var sw: float = float(icon.get_width()) * h / float(icon.get_height())
			draw_texture_rect(icon, Rect2(Vector2(tx + 14.0 - sw * 0.5, y - 20.0), Vector2(sw, h)), false)
			tx += iw
		elif icon_name != "":
			IC.draw_in(self, icon_name, Vector2(tx + 14.0, y - 5.0), 26.0)
			tx += iw
		draw_string(font, Vector2(tx, y + 2.0), txt, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 20, col)

	func draw_powers(font: Font, vp: Vector2) -> void:
		var y: float = 140.0
		if buff_text != "":
			_chip(font, vp, y, L.t(buff_text), Color("#ffd33d"), WTex.get_t("altar_" + power_id) if power_id != "" else null, "")
			y += 46.0
		if item_name != "":
			_chip(font, vp, y, L.t(item_name), Color("#ff8ad8"), null, item_id)

	func draw_rift_notice(font: Font, vp: Vector2) -> void:
		if rift_notice < 0.0:
			return
		var a: float = minf(1.0, minf(rift_notice * 4.0, (4.5 - rift_notice) * 2.0))
		var pop: float = 1.0 + maxf(0.0, 0.25 - rift_notice) * 1.6
		var t1: String = L.t("¡SE HA ABIERTO UNA GRIETA!")
		var t2: String = L.t("Sigue la flecha morada: dentro te espera un legendario")
		var w1: float = font.get_string_size(t1, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 26).x
		var w2: float = font.get_string_size(t2, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 16).x
		var bw: float = minf(vp.x - 24.0, maxf(w1, w2) + 48.0)
		draw_set_transform(Vector2(vp.x * 0.5, vp.y * 0.2), 0.0, Vector2(pop, pop))
		var r := Rect2(-bw * 0.5, -34.0, bw, 68.0)
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.102, 0.043, 0.2, 0.88 * a)
		sb.border_color = Color(0.706, 0.541, 1.0, a)
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(10)
		draw_style_box(sb, r)
		draw_string(font, Vector2(-bw * 0.5, -4.0), t1, HORIZONTAL_ALIGNMENT_CENTER, bw, 26, Color(0.886, 0.816, 1.0, a))
		draw_string(font, Vector2(-bw * 0.5, 22.0), t2, HORIZONTAL_ALIGNMENT_CENTER, bw, 16, Color(0.788, 0.69, 1.0, a))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	func draw_rift(font: Font, vp: Vector2) -> void:
		if rift_ttl >= 0.0:
			var beat: float = 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.001 * 7.0)
			var tcol: Color = Color("#e2d0ff")
			var fcol: Color = Color("#e2d0ff") if beat > 0.5 else Color("#a06bff")
			if rift_off:
				# Borde de pantalla: halo que late + flecha grande + "GRIETA · N m · S s"
				var M := 52.0
				var e := Vector2(clampf(rift_scr.x, M, vp.x - M), clampf(rift_scr.y, M + 70.0, vp.y - M - 80.0))
				if e.x > vp.x - 150.0 and e.y < 150.0:
					e.y = 150.0   # no tapar el boton de pausa
				var a: float = (rift_scr - e).angle()
				draw_circle(e, 30.0 + beat * 8.0, Color(0.706, 0.541, 1.0, 0.18 + beat * 0.22))
				var big := PackedVector2Array([e + Vector2.from_angle(a) * 45.0, e + Vector2.from_angle(a + 2.45) * 22.0, e + Vector2.from_angle(a - 2.45) * 22.0])
				draw_colored_polygon(big, Color("#1a0b33"))
				draw_colored_polygon(PackedVector2Array([e + Vector2.from_angle(a) * 40.0, e + Vector2.from_angle(a + 2.45) * 20.0, e + Vector2.from_angle(a - 2.45) * 20.0]), fcol)
				var label: String = "%s %d m · %d s" % [L.t("GRIETA ·"), rift_m, ceili(rift_ttl)]
				var ca: float = cos(a)
				var ha := HORIZONTAL_ALIGNMENT_RIGHT if ca > 0.3 else (HORIZONTAL_ALIGNMENT_LEFT if ca < -0.3 else HORIZONTAL_ALIGNMENT_CENTER)
				var lp: Vector2 = e + Vector2(-ca * 34.0, -sin(a) * 30.0 + 4.0)
				var lw: float = 240.0
				var lx: float = lp.x - (lw if ha == HORIZONTAL_ALIGNMENT_RIGHT else (0.0 if ha == HORIZONTAL_ALIGNMENT_LEFT else lw * 0.5))
				draw_string_outline(font, Vector2(lx, lp.y), label, ha, lw, 16, 5, Color(0, 0, 0, 0.85))
				draw_string(font, Vector2(lx, lp.y), label, ha, lw, 16, tcol)
			else:
				# Encima de la grieta: flecha que bota con la cuenta atras
				var by: float = rift_scr.y - 46.0 - absf(sin(Time.get_ticks_msec() * 0.001 * 4.0)) * 10.0
				var p := Vector2(rift_scr.x, by)
				var tri := PackedVector2Array([p + Vector2(-17.0, -14.0), p + Vector2(17.0, -14.0), p + Vector2(0.0, 11.0)])
				draw_colored_polygon(tri, Color("#1a0b33"))
				draw_colored_polygon(PackedVector2Array([p + Vector2(-14.0, -12.0), p + Vector2(14.0, -12.0), p + Vector2(0.0, 8.0)]), fcol)
				var l2: String = "%s %d s" % [L.t("GRIETA ·"), ceili(rift_ttl)]
				draw_string_outline(font, p + Vector2(-100.0, -22.0), l2, HORIZONTAL_ALIGNMENT_CENTER, 200.0, 15, 5, Color(0, 0, 0, 0.85))
				draw_string(font, p + Vector2(-100.0, -22.0), l2, HORIZONTAL_ALIGNMENT_CENTER, 200.0, 15, tcol)
		if legend_frac >= 0.0:
			var w: float = minf(440.0, vp.x - 360.0)
			var x0: float = vp.x * 0.5 - w * 0.5
			draw_rect(Rect2(x0 - 2.0, vp.y - 148.0, w + 4.0, 22.0), Color(0, 0, 0, 0.6))
			draw_rect(Rect2(x0, vp.y - 146.0, w * clampf(legend_frac, 0.0, 1.0), 18.0), Color("#b06bff"))
			draw_string(font, Vector2(x0, vp.y - 154.0), legend_name, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18, Color("#e6d4ff"))
			if arena_left >= 0.0:
				draw_string(font, Vector2(x0, vp.y - 154.0), "%02d:%02d" % [int(arena_left) / 60, int(arena_left) % 60], HORIZONTAL_ALIGNMENT_RIGHT, w, 18, Color("#ffd33d") if arena_left > 20.0 else Color("#ff6b7a"))

	func pause_rects() -> Array:
		var vp: Vector2 = get_viewport_rect().size
		var ins: Vector4 = DSP.insets(get_tree())
		return [Rect2(vp.x - 70.0 - ins.z, 70.0, 54.0, 46.0), Rect2(vp.x * 0.5 - 160.0, vp.y * 0.5, 320.0, 58.0), Rect2(vp.x * 0.5 - 160.0, vp.y * 0.5 + 76.0, 320.0, 58.0)]

	func draw_toast(font: Font, vp: Vector2) -> void:
		if toast_t <= 0.0 or toast.is_empty():
			return
		var a: float = clampf(minf(toast_t, 2.8 - toast_t + 0.001) * 4.0, 0.0, 1.0)
		var txt: String = String(toast["text"])
		var sub: String = String(toast.get("sub", ""))
		var tw: float = font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x
		if sub != "":
			tw = maxf(tw, font.get_string_size(sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x)
		var w: float = minf(tw + 100.0, vp.x - 40.0)
		var h: float = 64.0 if sub == "" else 82.0
		var x0: float = vp.x * 0.5 - w * 0.5
		var y0: float = 64.0
		var out := StyleBoxFlat.new()
		out.bg_color = Color(0.043, 0.094, 0.22, a)
		out.set_corner_radius_all(15)
		draw_style_box(out, Rect2(x0 - 3.0, y0 - 3.0, w + 6.0, h + 6.0))
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.145, 0.28, 0.6, a)
		sb.border_color = Color(1.0, 0.82, 0.25, a)
		sb.set_border_width_all(3)
		sb.set_corner_radius_all(12)
		draw_style_box(sb, Rect2(x0, y0, w, h))
		var ic: String = "medal%d" % clampi(int(toast.get("tier", 2)), 1, 3)
		IC.draw_in(self, ic, Vector2(x0 + 36.0, y0 + h * 0.5), 36.0, Color(1, 1, 1, a))
		var ty: float = y0 + (h * 0.5 + 8.0 if sub == "" else 34.0)
		draw_string(font, Vector2(x0 + 66.0, ty), txt, HORIZONTAL_ALIGNMENT_LEFT, w - 76.0, 22, Color(1.0, 0.82, 0.25, a))
		if sub != "":
			draw_string(font, Vector2(x0 + 66.0, y0 + 60.0), sub, HORIZONTAL_ALIGNMENT_LEFT, w - 76.0, 16, Color(0.72, 0.8, 0.94, a))

	func _draw() -> void:
		var font := ThemeDB.fallback_font
		var vp: Vector2 = get_viewport_rect().size
		var ins: Vector4 = DSP.insets(get_tree())
		draw_toast(font, vp)
		if show_fps:
			draw_string(font, Vector2(vp.x - 130.0 - ins.z, vp.y - 12.0 - ins.w), "%d FPS" % int(Engine.get_frames_per_second()), HORIZONTAL_ALIGNMENT_RIGHT, 118.0, 20, Color(1, 1, 1, 0.85))
		var frac: float = clampf(hp / max_hp, 0.0, 1.0)
		var col := Color("#5fe08a")
		if frac <= 0.25:
			col = Color("#ff6b7a")
		elif frac <= 0.5:
			col = Color("#ffd33d")
		draw_rect(Rect2(0.0, 0.0, vp.x, 8.0), Color(0, 0, 0, 0.55))
		draw_rect(Rect2(0.0, 0.0, vp.x * clampf(xp / xp_next, 0.0, 1.0), 8.0), Color("#7fe0ff"))
		draw_rect(Rect2(16.0 + ins.x, 16.0 + ins.y, 240.0, 18.0), Color(0, 0, 0, 0.55))
		draw_rect(Rect2(18.0 + ins.x, 18.0 + ins.y, 236.0 * frac, 14.0), col)
		draw_string(font, Vector2(16.0 + ins.x, 54.0 + ins.y), L.t("%s  PS %d/%d") % [poke_name, ceili(hp), ceili(max_hp)], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18, Color.WHITE)
		draw_string(font, Vector2(16.0 + ins.x, 76.0 + ins.y), L.t("Nv. %d") % level, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18, Color("#7fe0ff"))
		draw_powers(font, vp)
		if weather_text != "":
			draw_string(font, Vector2(0.0, 62.0), L.t(weather_text), HORIZONTAL_ALIGNMENT_CENTER, vp.x, 18, Color("#cfe2ff"))
		if banner != "":
			draw_string(font, Vector2(0.0, 92.0), L.t(banner), HORIZONTAL_ALIGNMENT_CENTER, vp.x, 20, Color("#ffffff"))
		draw_rift(font, vp)
		draw_rift_notice(font, vp)
		var tw: float = font.get_string_size(str(tickets), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18).x
		var t10w: float = font.get_string_size(str(tickets10), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18).x
		var rx: float = vp.x - 16.0 - ins.z
		draw_string(font, Vector2(rx - t10w, 62.0), str(tickets10), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18, Color("#c47bff"))
		IC.draw_in(self, "ticket10", Vector2(rx - t10w - 16.0, 56.0), 24.0)
		rx -= t10w + 40.0
		draw_string(font, Vector2(rx - tw, 62.0), str(tickets), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18, Color("#ffd23f"))
		IC.draw_in(self, "ticket", Vector2(rx - tw - 16.0, 56.0), 24.0)
		rx -= tw + 40.0
		var cw: float = font.get_string_size(str(coins), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18).x
		draw_string(font, Vector2(rx - cw, 62.0), str(coins), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18, Color("#ffd23f"))
		IC.draw_in(self, "coin", Vector2(rx - cw - 16.0, 56.0), 24.0)
		var pr: Array = pause_rects()
		draw_rect(pr[0], Color(0, 0, 0, 0.45))
		draw_rect(pr[0], Color.WHITE, false, 2.0)
		draw_rect(Rect2(pr[0].position + Vector2(16.0, 12.0), Vector2(8.0, 22.0)), Color.WHITE)
		draw_rect(Rect2(pr[0].position + Vector2(30.0, 12.0), Vector2(8.0, 22.0)), Color.WHITE)
		var clock: String = "%02d:%02d" % [floori(run_time / 60.0), int(run_time) % 60]
		draw_string(font, Vector2(0.0, 36.0), L.t(clock), HORIZONTAL_ALIGNMENT_CENTER, vp.x, 28, Color.WHITE)
		draw_string(font, Vector2(vp.x - 236.0 - ins.z, 36.0), L.t("Derrotados: %d") % kills, HORIZONTAL_ALIGNMENT_RIGHT, 220.0, 20, Color.WHITE)
		if dead:
			# Camara lenta: primero se ve caer al Pokemon; despues oscurece y aparece GAME OVER.
			var fade: float = clampf((death_t - 0.3) / 0.35, 0.0, 1.0)
			draw_rect(Rect2(Vector2.ZERO, vp), Color(0, 0, 0, 0.55 * fade))
			if fade > 0.0:
				var ga: float = fade
				draw_string_outline(font, Vector2(0.0, vp.y * 0.36), "GAME OVER", HORIZONTAL_ALIGNMENT_CENTER, vp.x, 72, 10, Color(0, 0, 0, ga))
				draw_string(font, Vector2(0.0, vp.y * 0.36), "GAME OVER", HORIZONTAL_ALIGNMENT_CENTER, vp.x, 72, Color(1.0, 0.36, 0.42, ga))
				draw_string(font, Vector2(0.0, vp.y * 0.45 + 10.0), L.t("Has caído..."), HORIZONTAL_ALIGNMENT_CENTER, vp.x, 40, Color(1, 1, 1, ga))
				draw_string(font, Vector2(0.0, vp.y * 0.45 + 50.0), L.t("Aguantaste %s y derrotaste %d") % [clock, kills], HORIZONTAL_ALIGNMENT_CENTER, vp.x, 22, Color(1, 1, 1, ga))
		if dead:
			if show_end:
				draw_string(font, Vector2(0.0, vp.y * 0.45 + 96.0), L.t("Pulsa una tecla, un botón o toca la pantalla para volver al menú"), HORIZONTAL_ALIGNMENT_CENTER, vp.x, 20, Color("#ffd33d"))


# ---------------------------------------------------------------
# Clima: tinte suave y pocas particulas (weather.js)
# ---------------------------------------------------------------
class WeatherFx extends Node2D:
	var kind := ""
	var level := 0.0
	var def: Dictionary = {}
	var parts: Array = []

	func setup(d: Dictionary) -> void:
		def = d
		parts.clear()

	func clear() -> void:
		def = {}
		parts.clear()
		queue_redraw()

	func _new_part(vp: Vector2, anywhere: bool) -> Dictionary:
		var y: float = randf() * vp.y if anywhere else -10.0
		if kind == "rain":
			return {"x": randf() * (vp.x + 200.0), "y": y, "vx": -120.0, "vy": 720.0, "t": 0.0, "life": 9.0}
		if kind == "snow":
			return {"x": randf() * vp.x, "y": y, "vx": randf_range(-20.0, 20.0), "vy": randf_range(40.0, 80.0), "t": 0.0, "life": 20.0}
		if kind == "sand":
			return {"x": randf() * vp.x if anywhere else vp.x + 20.0, "y": randf() * vp.y, "vx": randf_range(-520.0, -380.0), "vy": randf_range(20.0, 60.0), "t": 0.0, "life": 9.0}
		return {"x": randf() * vp.x, "y": randf() * vp.y if anywhere else vp.y + 5.0, "vx": randf_range(-8.0, 8.0), "vy": -randf_range(15.0, 30.0), "t": 0.0, "life": 12.0}

	func _process(delta: float) -> void:
		if kind == "" or level <= 0.0 or def.is_empty():
			if not parts.is_empty():
				parts.clear()
				queue_redraw()
			return
		var vp: Vector2 = get_viewport_rect().size
		var want: int = int(float(def["parts"]) * level * (vp.x / 1280.0))
		while parts.size() < want:
			parts.append(_new_part(vp, true))
		if parts.size() > want + 4:
			parts.resize(want)
		for i in range(parts.size()):
			var p: Dictionary = parts[i]
			p["x"] = float(p["x"]) + float(p["vx"]) * delta
			p["y"] = float(p["y"]) + float(p["vy"]) * delta
			p["t"] = float(p["t"]) + delta
			if float(p["y"]) > vp.y + 20.0 or float(p["x"]) < -40.0 or float(p["x"]) > vp.x + 40.0 or float(p["y"]) < -40.0 or float(p["t"]) > float(p["life"]):
				parts[i] = _new_part(vp, false)
		queue_redraw()

	func _draw() -> void:
		if kind == "" or level <= 0.0 or def.is_empty():
			return
		var vp: Vector2 = get_viewport_rect().size
		var t: Array = def["tint"]
		draw_rect(Rect2(Vector2.ZERO, vp), Color(float(t[0]), float(t[1]), float(t[2]), float(t[3]) * level))
		var s: float = maxf(2.0, roundf(vp.x / 640.0))
		for p in parts:
			var pos := Vector2(float(p["x"]), float(p["y"]))
			if kind == "rain":
				draw_line(pos, pos + Vector2(-s * 1.2, -s * 5.0), Color(0.81, 0.89, 1.0, 0.5 * level), s * 0.5)
			elif kind == "snow":
				draw_rect(Rect2(pos, Vector2(s, s)), Color(1, 1, 1, 0.7 * level))
			elif kind == "sand":
				draw_rect(Rect2(pos, Vector2(s * 3.0, s * 0.5)), Color(0.91, 0.81, 0.56, 0.4 * level))
			else:
				draw_rect(Rect2(pos, Vector2(s, s)), Color(1.0, 0.95, 0.69, 0.45 * level))


# ---------------------------------------------------------------
# Joystick tactil flotante: aparece donde pones el dedo
# ---------------------------------------------------------------
class Stick extends Node2D:
	var radius := 90.0
	var axis := Vector2.ZERO
	var fixed := false          # joystick fijo (siempre visible abajo a la izquierda)
	var _id := -1
	var _origin := Vector2.ZERO
	var _pos := Vector2.ZERO

	func _home() -> Vector2:
		var vp: Vector2 = get_viewport_rect().size
		var ins: Vector4 = DSP.insets(get_tree())
		return Vector2(radius + 56.0 + ins.x, vp.y - radius - 56.0 - ins.w)

	func _process(_d: float) -> void:
		if fixed:
			queue_redraw()
		elif _id == -1 and visible:
			pass

	func _input(event: InputEvent) -> void:
		if event is InputEventScreenTouch:
			if event.pressed and _id == -1:
				if fixed:
					var h: Vector2 = _home()
					if event.position.distance_to(h) > radius * 1.8:
						return
					_id = event.index
					_origin = h
					var v0: Vector2 = event.position - h
					if v0.length() > radius:
						v0 = v0.normalized() * radius
					_pos = h + v0
					axis = v0 / radius
				else:
					_id = event.index
					_origin = event.position
					_pos = event.position
			elif not event.pressed and event.index == _id:
				_id = -1
				axis = Vector2.ZERO
			queue_redraw()
		elif event is InputEventScreenDrag and event.index == _id:
			var v: Vector2 = event.position - _origin
			if v.length() > radius:
				v = v.normalized() * radius
			_pos = _origin + v
			axis = v / radius
			queue_redraw()

	func _draw() -> void:
		if _id == -1:
			if fixed:
				var h: Vector2 = _home()
				draw_arc(h, radius, 0.0, TAU, 48, Color(1, 1, 1, 0.2), 3.0)
				draw_circle(h, 28.0, Color(1, 1, 1, 0.18))
			return
		draw_arc(_origin, radius, 0.0, TAU, 48, Color(1, 1, 1, 0.35), 3.0)
		draw_circle(_pos, 28.0, Color(1, 1, 1, 0.45))
