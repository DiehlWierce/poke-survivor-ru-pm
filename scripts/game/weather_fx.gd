# Clima: tinte suave y pocas particulas (weather.js)
extends Node2D

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
