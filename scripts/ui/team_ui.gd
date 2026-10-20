# Cambio de Pokemon del Modo Equipo con la pantalla tactil: boton grande + fichas del equipo.
extends Node2D

signal swap_requested(slot: int)   # main lo conecta a _swap_team
var m: Node = null

func _btn_rect() -> Rect2:
	return m.hud.team_btn_rect()   # el Hud lo coloca junto con Z y Dynamax (columna derecha)

func _live() -> bool:
	return m != null and not m.player.dead and not m.paused and not m.choosing and m.arena_ok_for_ui()

func _input(event: InputEvent) -> void:
	if not (event is InputEventScreenTouch and event.pressed) or not _live():
		return
	var p: Vector2 = event.position
	var trs: Array = m.hud.team_rects()
	for i in range(trs.size()):
		if (trs[i] as Rect2).has_point(p):
			get_viewport().set_input_as_handled()
			swap_requested.emit(i)
			return
	if _btn_rect().has_point(p):
		get_viewport().set_input_as_handled()
		swap_requested.emit(m._team_next())

func _process(_d: float) -> void:
	queue_redraw()

func _draw() -> void:
	if m == null or m.team.size() < 2 or m.player.dead:
		return
	var r: Rect2 = _btn_rect()
	var c: Vector2 = r.get_center()
	var ready: bool = m.swap_cd <= 0.0 and m._team_next() >= 0
	var a: float = 0.85 if ready else 0.4
	draw_circle(c, 52.0, Color(0.08, 0.12, 0.25, 0.6 * a))
	draw_arc(c, 52.0, 0.0, TAU, 48, Color(1.0, 0.82, 0.25, a), 4.0)
	# dos flechas circulares
	draw_arc(c, 24.0, -2.6, 0.2, 20, Color(1, 1, 1, a), 5.0)
	draw_arc(c, 24.0, 0.54, 3.34, 20, Color(1, 1, 1, a), 5.0)
	draw_colored_polygon(PackedVector2Array([c + Vector2(30.0, -6.0), c + Vector2(18.0, -6.0), c + Vector2(24.0, 6.0)]), Color(1, 1, 1, a))
	draw_colored_polygon(PackedVector2Array([c + Vector2(-30.0, 6.0), c + Vector2(-18.0, 6.0), c + Vector2(-24.0, -6.0)]), Color(1, 1, 1, a))
	var nx: int = m._team_next()
	if nx >= 0:
		var font := ThemeDB.fallback_font
		draw_string(font, c + Vector2(-70.0, 74.0), String(m.team[nx]["name"]), HORIZONTAL_ALIGNMENT_CENTER, 140.0, 16, Color(1, 1, 1, a))
	if m.swap_cd > 0.0:
		draw_arc(c, 60.0, -PI / 2.0, -PI / 2.0 + TAU * (m.swap_cd / 3.0), 32, Color(1, 0.4, 0.4, 0.9), 4.0)
