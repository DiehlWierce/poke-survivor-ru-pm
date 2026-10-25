extends RefCounted
# Tamano de pantalla (zoom de la vista) y boton "atras" de Android.

const SV = preload("res://scripts/save_data.gd")
const MIN_PCT := 60
const MAX_PCT := 140


static func pct() -> int:
	SV.ensure()
	return clampi(int(SV.d["settings"].get("view", 100)), MIN_PCT, MAX_PCT)


static func apply(tree: SceneTree) -> void :
	SV.ensure()
	if not SV.save_blocked and not SV.recovered_from_backup and int(SV.d["settings"].get("view_v", 0)) < 2:
		SV.d["settings"]["view_v"] = 2
		SV.d["settings"]["view"] = 100
		SV.save()
	tree.root.content_scale_factor = 1.0 if menu_mode else float(pct()) / 100.0

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


# Zona util en unidades de la vista: el rect visible (ya escalado por el % de vista y el "expand")
# menos los margenes seguros y un margen extra `pad`. A 140 % en 720x480 es ~914x609, y en una
# pantalla 16:9 solo ~914x514, asi que los paneles no pueden asumir 1280x720.
static func area(tree: SceneTree, pad: float = 0.0) -> Rect2:
	var vp: Vector2 = tree.root.get_visible_rect().size
	var ins: Vector4 = insets(tree)
	var r := Rect2(Vector2(ins.x + pad, ins.y + pad), Vector2(vp.x - ins.x - ins.z - 2.0 * pad, vp.y - ins.y - ins.w - 2.0 * pad))
	r.size = r.size.max(Vector2(160, 120))
	return r


# Coloca un contenedor a pantalla completa (p. ej. un CenterContainer) dentro de la zona segura.
static func fit_to_safe(tree: SceneTree, c: Control) -> void:
	var ins: Vector4 = insets(tree)
	c.anchor_left = 0.0
	c.anchor_top = 0.0
	c.anchor_right = 1.0
	c.anchor_bottom = 1.0
	c.offset_left = ins.x
	c.offset_top = ins.y
	c.offset_right = -ins.z
	c.offset_bottom = -ins.w


# Ajusta el tamano minimo de un ScrollContainer al de su contenido, pero sin pasar de la zona util:
# si no cabe, aparece la barra y con el mando el foco desplaza solo (follow_focus). `chrome` es lo
# que rodea al scroll (margenes del panel). Devuelve true si hace falta desplazar en vertical.
static func fit_scroll(tree: SceneTree, sc: ScrollContainer, content: Control, chrome: Vector2 = Vector2.ZERO, pad: float = 8.0) -> bool:
	var avail: Vector2 = area(tree, pad).size - chrome
	var need: Vector2 = content.get_combined_minimum_size()
	var bar: float = sc.get_v_scroll_bar().get_combined_minimum_size().x
	var vscroll: bool = need.y > avail.y
	sc.follow_focus = true
	sc.custom_minimum_size = Vector2(minf(need.x + (bar if vscroll else 0.0), avail.x), minf(need.y, avail.y))
	return vscroll


# Numero de columnas de una cuadricula de tarjetas segun el ancho disponible: tantas como quepan con `min_w` de ancho
# por tarjeta y `gap` entre ellas (minimo 1, maximo `max_cols`).
static func cols(avail_w: float, min_w: float, gap: float, max_cols: int = 4) -> int:
	for c in range(max_cols, 1, -1):
		if float(c) * min_w + float(c - 1) * gap <= avail_w:
			return c
	return 1

# Modo de ventana y resolucion (solo PC; en la consola PortMaster / handheld la pantalla es siempre completa).
const WIN_RES := [Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1920, 1080), Vector2i(2560, 1440)]


static func is_desktop() -> bool:
	if OS.has_feature("handheld") or "--keys-only" in OS.get_cmdline_user_args():
		return false
	return OS.has_feature("pc") and not OS.has_feature("android")


static func win_mode() -> int:
	SV.ensure()
	return clampi(int(SV.d["settings"].get("win_mode", 0)), 0, 1)


static func win_res() -> int:
	SV.ensure()
	return clampi(int(SV.d["settings"].get("win_res", 0)), 0, WIN_RES.size() - 1)


static func apply_window() -> void:
	if not is_desktop():
		return
	if win_mode() == 1:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	var want: Vector2i = WIN_RES[win_res()]
	var scr: Rect2i = DisplayServer.screen_get_usable_rect()
	# si no cabe en la pantalla se ajusta, y se centra
	var sz := Vector2i(mini(want.x, scr.size.x), mini(want.y, scr.size.y))
	DisplayServer.window_set_size(sz)
	DisplayServer.window_set_position(scr.position + (scr.size - sz) / 2)


static func set_window(mode: int, res: int) -> void:
	SV.ensure()
	SV.d["settings"]["win_mode"] = clampi(mode, 0, 1)
	SV.d["settings"]["win_res"] = clampi(res, 0, WIN_RES.size() - 1)
	SV.save()
	apply_window()


static var menu_mode := false
