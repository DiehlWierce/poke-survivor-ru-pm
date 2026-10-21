# Завеса перехода в грету: если арена ещё допекается (медленная приставка), экран сразу темнеет и показывает
# «Загрузка…» с бегущими точками — видно, что игра не зависла. Когда арена готова, завеса растворяется и удаляется.
extends Node2D

var text := ""
var a := 0.0          # текущая непрозрачность
var want := 1.0       # к чему идём: 1 — показать, 0 — убрать
var t := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(delta: float) -> void:
	t += delta
	a = move_toward(a, want, delta / (0.12 if want > a else 0.3))
	if want <= 0.0 and a <= 0.0:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var vp: Vector2 = get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, vp), Color(0.05, 0.02, 0.1, a))
	if a < 0.6:
		return
	var font := ThemeDB.fallback_font
	var fs: int = int(clampf(vp.y / 18.0, 16.0, 40.0))
	var col := Color(1, 1, 1, (a - 0.6) / 0.4)
	draw_string(font, Vector2(0.0, vp.y * 0.5), text, HORIZONTAL_ALIGNMENT_CENTER, vp.x, fs, col)
	# бегущие точки: кадр за кадром меняются, даже если работа тяжёлая
	for i in range(3):
		var ph: float = fmod(t * 2.0 + float(i) * 0.33, 1.0)
		var r: float = 3.0 + 3.0 * sin(ph * PI)
		draw_circle(Vector2(vp.x * 0.5 + float(i - 1) * 22.0, vp.y * 0.5 + fs * 0.9), r, Color(0.75, 0.55, 1.0, col.a))
