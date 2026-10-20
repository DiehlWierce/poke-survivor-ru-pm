extends Node2D
const DSP = preload("res://scripts/display.gd")

var radius := 90.0
var axis := Vector2.ZERO
var fixed := false          # joystick fijo (siempre visible abajo a la izquierda)
var _id := -1
var _origin := Vector2.ZERO
var _pos := Vector2.ZERO
var _vp := Vector2(1280.0, 720.0)
var _ins := Vector4.ZERO
var _rad := 90.0     # radio efectivo: el fijo se encoge si en una vista baja taparia el minimapa

func _ready() -> void:
	_relayout()
	get_viewport().size_changed.connect(_relayout)

func _relayout() -> void:
	_vp = get_viewport_rect().size
	_ins = DSP.insets(get_tree())
	_rad = radius
	if fixed:
		var mini_bottom: float = 98.0 + _ins.y + (160.0 if _vp.y - _ins.y - _ins.w < 500.0 else 200.0)
		_rad = clampf((_vp.y - _ins.w - 56.0 - mini_bottom) * 0.5, 56.0, radius)
	queue_redraw()

func _home() -> Vector2:
	return Vector2(_rad + 56.0 + _ins.x, _vp.y - _rad - 56.0 - _ins.w)

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
				if event.position.distance_to(h) > _rad * 1.8:
					return
				_id = event.index
				_origin = h
				var v0: Vector2 = event.position - h
				if v0.length() > _rad:
					v0 = v0.normalized() * _rad
				_pos = h + v0
				axis = v0 / _rad
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
		if v.length() > _rad:
			v = v.normalized() * _rad
		_pos = _origin + v
		axis = v / _rad
		queue_redraw()

func _draw() -> void:
	if _id == -1:
		if fixed:
			var h: Vector2 = _home()
			draw_arc(h, _rad, 0.0, TAU, 48, Color(1, 1, 1, 0.2), 3.0)
			draw_circle(h, 28.0, Color(1, 1, 1, 0.18))
		return
	draw_arc(_origin, _rad, 0.0, TAU, 48, Color(1, 1, 1, 0.35), 3.0)
	draw_circle(_pos, 28.0, Color(1, 1, 1, 0.45))
