extends RefCounted


const SV = preload("res://scripts/save_data.gd")
const TL = preload("res://scripts/lang.gd")
const NAMES: = ["Xbox", "PlayStation", "Nintendo"]

const ACTIONS: = ["prev", "next", "pause", "confirm", "cancel", "reroll", "ban", "swap", "zmove", "dynamax"]
const LABELS: = {
	"prev": "Movimiento anterior", 
	"next": "Movimiento siguiente", 
	"pause": "Pausa", 
	"confirm": "Aceptar / elegir", 
	"cancel": "Atrás / cancelar", 
	"reroll": "Relanzar cartas", 
	"ban": "Vetar carta", 
	"swap": "Cambiar Pokémon (Modo Equipo)", 
	"zmove": "Movimiento Z", 
	"dynamax": "Dynamax", 
}
const BTN_NAMES: = {
	0: ["A", "Cross", "B"], 1: ["B", "Circle", "A"], 2: ["X", "Square", "Y"], 3: ["Y", "Triangle", "X"], 
	4: ["View", "Share", "-"], 5: ["Guide", "PS", "Home"], 6: ["Menu", "Options", "+"], 
	7: ["LS", "L3", "LS"], 8: ["RS", "R3", "RS"], 9: ["LB", "L1", "L"], 10: ["RB", "R1", "R"], 
	11: ["Cruceta arriba", "Cruceta arriba", "Cruceta arriba"], 12: ["Cruceta abajo", "Cruceta abajo", "Cruceta abajo"], 
	13: ["Cruceta izquierda", "Cruceta izquierda", "Cruceta izquierda"], 14: ["Cruceta derecha", "Cruceta derecha", "Cruceta derecha"], 
	15: ["Share", "Mic", "Capture"], 20: ["Touchpad", "Touchpad", "Touchpad"], 
}


static func layout() -> int:
	SV.ensure()
	return clampi(int(SV.d["settings"].get("pad", 0)), 0, 2)


static func defaults(lay: int = -1) -> Dictionary:
	if lay < 0:
		lay = layout()
	var ok: = JOY_BUTTON_B if lay == 2 else JOY_BUTTON_A
	var no: = JOY_BUTTON_A if lay == 2 else JOY_BUTTON_B
	return {"prev": JOY_BUTTON_LEFT_SHOULDER, "next": JOY_BUTTON_RIGHT_SHOULDER, "pause": JOY_BUTTON_START, 
		"confirm": ok, "cancel": no, "reroll": JOY_BUTTON_Y, "ban": JOY_BUTTON_X, "swap": JOY_BUTTON_RIGHT_STICK, "zmove": JOY_BUTTON_LEFT_STICK, "dynamax": JOY_BUTTON_BACK}


static func btn(action: String) -> int:
	SV.ensure()
	var m = SV.d["settings"].get("padmap", {})
	if m is Dictionary and m.has(action):
		return int(m[action])
	return int(defaults()[action])


static func is_mapped(b: int) -> bool:
	for a in ACTIONS:
		if btn(a) == b:
			return true
	return false



static func set_btn(action: String, b: int) -> void :
	SV.ensure()
	var cur: = {}
	for a in ACTIONS:
		cur[a] = btn(a)
	var old: int = int(cur[action])
	for a in ACTIONS:
		if a != action and int(cur[a]) == b:
			cur[a] = old
	cur[action] = b
	SV.d["settings"]["padmap"] = cur
	SV.save()
	apply()


static func reset(lay: int = -1) -> void :
	SV.ensure()
	if lay >= 0:
		SV.d["settings"]["pad"] = lay
	SV.d["settings"]["padmap"] = defaults()
	SV.save()
	apply()


static func confirm_btn() -> int:
	return btn("confirm")


static func cancel_btn() -> int:
	return btn("cancel")


static func btn_name(b: int) -> String:
	var l: = layout()
	if BTN_NAMES.has(b):
		return TL.t(String(BTN_NAMES[b][l]))
	return TL.t("Botón %d") % b


static func confirm_name() -> String:
	return btn_name(confirm_btn())


static func cancel_name() -> String:
	return btn_name(cancel_btn())


static func is_cancel(event: InputEvent) -> bool:
	if event is InputEventJoypadButton and event.pressed:
		return event.button_index == cancel_btn() or (event.button_index == JOY_BUTTON_BACK and not is_mapped(JOY_BUTTON_BACK))
	if event is InputEventKey and event.pressed and not event.echo:
		return event.keycode == KEY_ESCAPE or event.keycode == KEY_BACKSPACE
	return false


static func _set_joy(action: String, buttons: Array) -> void :
	if not InputMap.has_action(action):
		return
	for ev in InputMap.action_get_events(action):
		if ev is InputEventJoypadButton:
			InputMap.action_erase_event(action, ev)
	for b in buttons:
		var e: = InputEventJoypadButton.new()
		e.button_index = b
		InputMap.action_add_event(action, e)



static func apply() -> void :
	_set_joy("ui_accept", [confirm_btn()])
	_set_joy("ui_cancel", [cancel_btn()])







const STICK_ON: = 0.6
const STICK_OFF: = 0.35
const STICK_DELAY: = 0.42
const STICK_REPEAT: = 0.16
static var _sdir: = Vector2i.ZERO
static var _snext: = 0.0


static func stick_event(event: InputEvent) -> bool:
	if not (event is InputEventJoypadMotion) or not (event.axis == JOY_AXIS_LEFT_X or event.axis == JOY_AXIS_LEFT_Y):
		return false
	var x: float = Input.get_joy_axis(event.device, JOY_AXIS_LEFT_X)
	var y: float = Input.get_joy_axis(event.device, JOY_AXIS_LEFT_Y)
	var d: = Vector2i.ZERO
	var thr: float = STICK_ON if _sdir == Vector2i.ZERO else STICK_OFF
	if maxf(absf(x), absf(y)) >= thr:

		if absf(x) > absf(y):
			d = Vector2i(1 if x > 0.0 else -1, 0)
		else:
			d = Vector2i(0, 1 if y > 0.0 else -1)
	if d != _sdir:
		_sdir = d
		if d != Vector2i.ZERO:
			_stick_fire(d)
			_snext = Time.get_ticks_msec() / 1000.0 + STICK_DELAY
	return true


static func stick_tick() -> void :
	if _sdir == Vector2i.ZERO:
		return
	var now: float = Time.get_ticks_msec() / 1000.0
	if now >= _snext:
		_snext = now + STICK_REPEAT
		_stick_fire(_sdir)


static func stick_reset() -> void :
	_sdir = Vector2i.ZERO


static func _stick_fire(d: Vector2i) -> void :
	var act: = "ui_down" if d.y > 0 else ("ui_up" if d.y < 0 else ("ui_right" if d.x > 0 else "ui_left"))
	var e: = InputEventAction.new()
	e.action = act
	e.pressed = true
	e.strength = 1.0
	Input.parse_input_event(e)
	var r: = InputEventAction.new()
	r.action = act
	r.pressed = false
	Input.parse_input_event(r)
