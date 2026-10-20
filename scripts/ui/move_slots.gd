# Barra de movimientos (abajo a la derecha): tocalos para cambiar
extends Node2D
const L = preload("res://scripts/lang.gd")
const IC = preload("res://scripts/icons.gd")
const DSP = preload("res://scripts/display.gd")
const Actor = preload("res://scripts/main.gd").Actor

signal picked(idx: int)
const SZ := 76.0
var info: Array = []
var active := 0
var enabled := true
var _vp := Vector2(1280.0, 720.0)   # tamano de la vista y margen inferior en cache (se refrescan en size_changed)
var _inw := 0.0

func _ready() -> void:
	_relayout()
	get_viewport().size_changed.connect(_relayout)

func _relayout() -> void:
	_vp = get_viewport_rect().size
	_inw = DSP.insets(get_tree()).w

func _rects() -> Array:
	var vp: Vector2 = _vp
	var n: int = info.size()
	# Si no caben todos a 76 px (vista pequena), los huecos se estrechan un poco.
	var gap := 8.0
	var total: float = SZ * float(n) + gap * float(maxi(0, n - 1))
	if total > vp.x - 16.0 and n > 1:
		gap = maxf(2.0, (vp.x - 16.0 - SZ * float(n)) / float(n - 1))
		total = SZ * float(n) + gap * float(n - 1)
	var x0: float = (vp.x - total) * 0.5
	var y0: float = vp.y - SZ - 12.0 - _inw
	var out: Array = []
	for i in range(n):
		out.append(Rect2(x0 + float(i) * (SZ + gap), y0, SZ, SZ))
	return out

func _process(_delta: float) -> void:
	if not Actor.lite or (Actor.tick % 3) == 0:   # consola: 10 veces por segundo bastan
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
		while nm_fs > 8 and font.get_string_size(nm_t, HORIZONTAL_ALIGNMENT_LEFT, -1.0, nm_fs).x > SZ - 4.0:
			nm_fs -= 1
		if font.get_string_size(nm_t, HORIZONTAL_ALIGNMENT_LEFT, -1.0, nm_fs).x > SZ - 4.0:
			var nb: String = nm_t   # ni a 8 px cabe: se recorta con "…"
			while nb.length() > 1 and font.get_string_size(nb + "…", HORIZONTAL_ALIGNMENT_LEFT, -1.0, nm_fs).x > SZ - 4.0:
				nb = nb.substr(0, nb.length() - 1)
			nm_t = nb.strip_edges() + "…"
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
