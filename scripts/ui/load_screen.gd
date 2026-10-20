# Pantalla de carga: fondo oscuro, texto y barra de progreso
extends Node2D

var text := ""
var prog := 0.0

func set_prog(v: float) -> void:
	if absf(v - prog) >= 0.005 or v >= 1.0:
		prog = v
		queue_redraw()

func _draw() -> void:
	var vp: Vector2 = get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, vp), Color("#0c1220"))
	var font := ThemeDB.fallback_font
	var fs: int = int(clampf(vp.y / 15.0, 18.0, 44.0))
	draw_string(font, Vector2(0.0, vp.y * 0.5 - fs * 0.4), text, HORIZONTAL_ALIGNMENT_CENTER, vp.x, fs, Color.WHITE)
	var bw: float = minf(vp.x * 0.6, 460.0)
	var bh: float = maxf(8.0, vp.y / 50.0)
	var r := Rect2((vp.x - bw) * 0.5, vp.y * 0.5 + fs * 0.6, bw, bh)
	draw_rect(r.grow(2.0), Color("#8fa8cc"))
	draw_rect(r, Color("#16233a"))
	draw_rect(Rect2(r.position, Vector2(r.size.x * clampf(prog, 0.0, 1.0), r.size.y)), Color("#ffd33d"))
