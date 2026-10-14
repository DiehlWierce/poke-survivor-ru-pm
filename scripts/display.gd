extends RefCounted
# Tamano de pantalla (zoom de la vista) y boton "atras" de Android.

const SV = preload("res://scripts/save_data.gd")
const MIN_PCT := 60
const MAX_PCT := 140


static func pct() -> int:
	SV.ensure()
	return clampi(int(SV.d["settings"].get("view", 100)), MIN_PCT, MAX_PCT)


static func apply(tree: SceneTree) -> void:
	tree.root.content_scale_factor = float(pct()) / 100.0
	# El boton atras de Android lo gestiona el juego (no cierra la app).
	tree.quit_on_go_back = false


static func set_pct(tree: SceneTree, v: int) -> void:
	SV.ensure()
	SV.d["settings"]["view"] = clampi(v, MIN_PCT, MAX_PCT)
	SV.save()
	apply(tree)


static func info(tree: SceneTree) -> String:
	var win: Vector2i = DisplayServer.window_get_size()
	var vp: Vector2 = tree.root.get_visible_rect().size
	return "%d×%d  →  %d×%d" % [win.x, win.y, int(vp.x), int(vp.y)]


# Margenes seguros (notch, esquinas redondeadas, barra de gestos) en unidades de la vista:
# x = izquierda, y = arriba, z = derecha, w = abajo. En escritorio/ventana valen 0.
static var force := Vector4.ZERO   # solo para pruebas


static func insets(tree: SceneTree) -> Vector4:
	if force != Vector4.ZERO:
		return force
	var win: Vector2i = DisplayServer.window_get_size()
	var scr: Vector2i = DisplayServer.screen_get_size()
	if win.x <= 0 or win.y <= 0 or absi(win.x - scr.x) > 8 or absi(win.y - scr.y) > 8:
		return Vector4.ZERO
	var sa: Rect2i = DisplayServer.get_display_safe_area()
	if sa.size.x <= 0 or sa.size.y <= 0:
		return Vector4.ZERO
	var vp: Vector2 = tree.root.get_visible_rect().size
	var k: float = vp.x / float(win.x)
	var l: float = clampf(float(sa.position.x) * k, 0.0, 120.0)
	var t: float = clampf(float(sa.position.y) * k, 0.0, 80.0)
	var r: float = clampf(float(scr.x - sa.end.x) * k, 0.0, 120.0)
	var b: float = clampf(float(scr.y - sa.end.y) * k, 0.0, 60.0)
	return Vector4(l, t, r, b)
