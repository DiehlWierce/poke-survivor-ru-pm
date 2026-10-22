# HUD: vida, tiempo, derrotados, pantalla de derrota
extends Node2D
const SV = preload("res://scripts/save_data.gd")
const L = preload("res://scripts/lang.gd")
const IC = preload("res://scripts/icons.gd")
const DSP = preload("res://scripts/display.gd")
const ZM = preload("res://scripts/zmove.gd")
const DYN = preload("res://scripts/dynamax.gd")
const MD = preload("res://scripts/moves_data.gd")
const WTex = preload("res://scripts/game/wtex.gd")
const TXS = preload("res://scripts/textscale.gd")
const MAIN = preload("res://scripts/main.gd")
const Actor = MAIN.Actor
const TOWER_FLOORS = MAIN.TOWER_FLOORS

var hp := 1.0
var max_hp := 1.0
var run_time := 0.0
var kills := 0
var dead := false
var z_dim := 0.0
var z_state := ""
var z_t := 0.0
var z_name := ""
var z_type := ""
var z_btn := 0
var z_cd := 0.0
var dyn_cd := 0.0
var adapt_pct := 0
var dyn_left := -1.0
var dyn_flash := 99.0
var dyn_type := "normal"
var dyn_btn := 0
var rift_den := false
var ab_name := ""
var down := false
var down_left := 0.0
var pbar := 1.0
var show_end := false
var poke_name := ""
var level := 1
var xp := 0.0
var xp_next := 1.0
var buff_text := ""
var power_id := ""
var item_name := ""
var item_id := ""
var item2_name := ""
var item2_id := ""
var weather_text := ""
var banner := ""
var coins := 0
var tickets := 0
var tickets10 := 0
var paused := false
var show_fps := false
var show_stats := false
var revives := 0
var stats: Array = []
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
var thieves_hud: Array = []
var thief_notice := -1.0
var thief_name := ""
var thief_gold := false
var death_t := 0.0

# --- Disposicion en cache (se recalcula en size_changed y al cambiar el equipo, no en cada _draw) ---
var _vp := Vector2(1280.0, 720.0)
var _ins := Vector4.ZERO
var _team_n := -1
var mini_pos := Vector2(8.0, 92.0)   # minimapa: esquina izquierda bajo la barra de vida
var mini_scale := 1.0                # 0.8 si la vista es baja (< 500)
var stats_y := 300.0                 # panel de estadisticas, bajo el minimapa
var _rz := Rect2()                   # boton Z
var _rd := Rect2()                   # boton Dynamax
var _rt := Rect2()                   # boton de cambio de equipo
var _rp := Rect2()                   # boton de pausa
var _y_chip := 140.0                 # fila de los poderes/objeto (baja si el cartel de arriba es largo)
var _y_dyn := 58.0                   # barra de tiempo de Dynamax
var _y_down := 58.0                  # cartel "Espectando"
var _side_l := 270.0                 # ancho que ocupan a la izquierda la vida y el nombre (el texto central no lo pisa)

func _ready() -> void:
	_relayout()
	get_viewport().size_changed.connect(_relayout)

# Columna derecha, de arriba abajo: pausa, lista de equipo, [Dynamax, Z], cambio de equipo, huecos.
# Si Dynamax no cabe encima de Z (vista baja a 140 %), se pone a su izquierda; si Z tampoco cabe,
# los dos van en una fila junto al boton de equipo, encima de la barra de movimientos.
func _relayout() -> void:
	_vp = get_viewport_rect().size
	_ins = DSP.insets(get_tree())
	_team_n = team.size()
	var vp: Vector2 = _vp
	var tight: bool = vp.y - _ins.y - _ins.w < 500.0
	mini_scale = 0.8 if tight else 1.0
	mini_pos = Vector2(8.0 + _ins.x, 92.0 + _ins.y)
	stats_y = mini_pos.y + 200.0 * mini_scale + 8.0
	_rp = Rect2(vp.x - 70.0 - _ins.z, 70.0 + _ins.y, 54.0, 46.0)
	var b: float = vp.y - _ins.w
	var col_top: float = _rp.end.y + 2.0
	if _team_n > 0:
		col_top = 126.0 + _ins.y + 52.0 * float(_team_n - 1) + 46.0 + 2.0
	var zx: float = vp.x - 126.0 - _ins.z
	_rt = Rect2(vp.x - 150.0 - _ins.z, b - 214.0, 120.0, 120.0)
	if b - 442.0 >= col_top:
		_rz = Rect2(zx, b - 330.0, 100.0, 100.0)
		_rd = Rect2(zx, b - 442.0, 100.0, 100.0)
	elif b - 330.0 >= col_top:
		_rz = Rect2(zx, b - 330.0, 100.0, 100.0)
		_rd = Rect2(zx - 112.0, b - 330.0, 100.0, 100.0)
	else:
		if _team_n >= 2:
			zx = _rt.position.x - 112.0
		_rt.position.y = maxf(_rt.position.y, col_top)   # sin pisar la lista de equipo si la vista es muy baja
		var ry: float = maxf(b - 204.0, col_top)
		_rz = Rect2(zx, ry, 100.0, 100.0)
		_rd = Rect2(zx - 112.0, ry, 100.0, 100.0)
	# lo que queda a ambos lados del texto central: vida/nombre a la izquierda y contadores a la derecha
	_side_l = 270.0 + _ins.x
	queue_redraw()

func team_btn_rect() -> Rect2:
	return _rt

func _process(delta: float) -> void:
	if rift_notice >= 0.0:
		rift_notice += delta
		if rift_notice >= 4.5:
			rift_notice = -1.0
	if thief_notice >= 0.0:
		thief_notice += delta
		if thief_notice >= 4.0:
			thief_notice = -1.0
	_page_t += delta
	_acc += delta
	if _acc >= (0.066 if Actor.lite else 0.033):   # el HUD se redibuja 30 veces por segundo (15 en consola)
		_acc = 0.0
		queue_redraw()

# Poderes activos (mejoras de altar, buffs) y objeto: en el centro, bajo el reloj.
func _chip(font: Font, vp: Vector2, y: float, txt: String, col: Color, icon: Texture2D, icon_name: String) -> void:
	var iw: float = 34.0 if (icon != null or icon_name != "") else 0.0
	var bd: Vector2 = _band(y - 24.0, y + 14.0)
	var fit: Array = _fit_txt(font, txt, 20, maxf(60.0, bd.y - bd.x - iw - 26.0), 12)
	txt = String(fit[0])
	var fsz: int = int(fit[1])
	var tw: float = font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1.0, fsz).x
	var w: float = tw + iw + 26.0
	var x0: float = clampf((vp.x - w) * 0.5, bd.x, maxf(bd.x, bd.y - w))
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
	draw_string(font, Vector2(tx, y + 2.0), txt, HORIZONTAL_ALIGNMENT_LEFT, -1.0, fsz, col)

# Texto que cabe en `avail` px: se encoge hasta fs_min y, si aun asi no cabe, se recorta con "…". Devuelve [texto, tamano].
func _fit_txt(font: Font, txt: String, fs: int, avail: float, fs_min: int) -> Array:
	var f: int = fs
	var w: float = font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1.0, f).x
	if w > avail:
		f = maxi(fs_min, int(floor(float(fs) * avail / w)))
		w = font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1.0, f).x
	var base: String = txt
	while w > avail and base.length() > 1:
		base = base.substr(0, base.length() - 1)
		w = font.get_string_size(base + "…", HORIZONTAL_ALIGNMENT_LEFT, -1.0, f).x
	return [base if base == txt else base.strip_edges() + "…", f]

# Hueco horizontal libre (izquierda, derecha) para una fila entre y0 e y1: descuenta lo que ocupan ahi la vida y el
# nombre, el nivel, el minimapa, los contadores, la pausa y la lista del equipo (se rellena al principio de cada _draw).
var _obst: Array = []

func _band(y0: float, y1: float) -> Vector2:
	var xl: float = 8.0 + _ins.x
	var xr: float = _vp.x - 8.0 - _ins.z
	for o in _obst:
		var r: Rect2 = o
		if r.position.y < y1 and r.end.y > y0:
			if r.get_center().x < _vp.x * 0.5:
				xl = maxf(xl, r.end.x + 8.0)
			else:
				xr = minf(xr, r.position.x - 8.0)
	return Vector2(xl, xr)

# Etiqueta con contorno que se queda dentro de la zona util: anclada por la izquierda, la derecha o el centro en ax.
func _pin_label(font: Font, txt: String, fs: int, ax: float, y: float, ha: int, col: Color) -> void:
	var fit: Array = _fit_txt(font, txt, fs, _vp.x - _ins.x - _ins.z - 16.0, 10)
	var t: String = String(fit[0])
	var f: int = int(fit[1])
	var w: float = font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1.0, f).x
	var x0: float = ax - (w if ha == HORIZONTAL_ALIGNMENT_RIGHT else (0.0 if ha == HORIZONTAL_ALIGNMENT_LEFT else w * 0.5))
	x0 = clampf(x0, _ins.x + 8.0, _vp.x - _ins.z - 8.0 - w)
	var yy: float = clampf(y, _ins.y + float(f) + 4.0, _vp.y - _ins.w - 8.0)
	draw_string_outline(font, Vector2(x0, yy), t, HORIZONTAL_ALIGNMENT_LEFT, -1.0, f, 5, Color(0, 0, 0, 0.85))
	draw_string(font, Vector2(x0, yy), t, HORIZONTAL_ALIGNMENT_LEFT, -1.0, f, col)

func draw_powers(font: Font, vp: Vector2) -> void:
	var y: float = _y_chip
	if buff_text != "":
		_chip(font, vp, y, L.t(buff_text), Color("#ffd33d"), WTex.get_t("altar_" + power_id) if power_id != "" else null, "")
		y += 46.0
	if item_name != "":
		_chip(font, vp, y, L.t(item_name), Color("#ff8ad8"), null, item_id)
		y += 46.0
	if item2_name != "":
		_chip(font, vp, y, L.t(item2_name), Color("#ffd23f"), null, item2_id)
		y += 46.0
	if item3_name != "":
		_chip(font, vp, y, L.t(item3_name), Color("#8fe3b0"), null, item3_id)

func draw_thief_notice(font: Font, vp: Vector2) -> void:
	if thief_notice < 0.0:
		return
	var a: float = minf(1.0, minf(thief_notice * 4.0, (4.0 - thief_notice) * 2.0))
	var pop: float = 1.0 + maxf(0.0, 0.25 - thief_notice) * 1.6
	var t1: String = L.t("¡%s merodea cerca!") % thief_name
	var t2: String = L.t("Sigue la flecha dorada: ¡trae un ticket ×10!") if thief_gold else L.t("Sigue la flecha dorada: ¡va cargado de monedas!")
	# el cartel "salta" hasta x1,4: se limita para que ni asi se salga, y el texto se encoge si hace falta
	var cap: float = (vp.x - _ins.x - _ins.z - 24.0) / 1.4
	var fit1: Array = _fit_txt(font, t1, 26, cap - 32.0, 12)
	var fit2: Array = _fit_txt(font, t2, 16, cap - 32.0, 10)
	t1 = String(fit1[0])
	t2 = String(fit2[0])
	var w1: float = font.get_string_size(t1, HORIZONTAL_ALIGNMENT_LEFT, -1.0, int(fit1[1])).x
	var w2: float = font.get_string_size(t2, HORIZONTAL_ALIGNMENT_LEFT, -1.0, int(fit2[1])).x
	var bw: float = minf(cap, maxf(w1, w2) + 48.0)
	draw_set_transform(Vector2((_ins.x + vp.x - _ins.z) * 0.5, maxf(vp.y * 0.2, 136.0 + _ins.y)), 0.0, Vector2(pop, pop))   # bajo la fila de nivel aunque la vista sea baja
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.2, 0.14, 0.02, 0.88 * a)
	sb.border_color = Color(1.0, 0.82, 0.25, a)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(10)
	draw_style_box(sb, Rect2(-bw * 0.5, -34.0, bw, 68.0))
	draw_string(font, Vector2(-bw * 0.5, -4.0), t1, HORIZONTAL_ALIGNMENT_CENTER, bw, int(fit1[1]), Color(1.0, 0.92, 0.55, a))
	draw_string(font, Vector2(-bw * 0.5, 22.0), t2, HORIZONTAL_ALIGNMENT_CENTER, bw, int(fit2[1]), Color(1.0, 0.85, 0.45, a))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

# Brujula hacia los duendes del tesoro: flecha en el borde (o sobre su cabeza si ya los ves) con distancia y tiempo.
func draw_thieves(font: Font, vp: Vector2) -> void:
	var beat: float = 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.001 * 7.0)
	var gcol: Color = Color("#ffd23f") if beat > 0.5 else Color("#fff0a0")
	for th in thieves_hud:
		var sp: Vector2 = th["sp"]
		var off: bool = sp.x < 0.0 or sp.x > vp.x or sp.y < 0.0 or sp.y > vp.y
		var label: String = "%s · %d m · %d s" % [String(th["name"]), int(th["m"]), ceili(float(th["life"]))]
		if off:
			var M := 52.0
			var e := Vector2(clampf(sp.x, M, vp.x - M), clampf(sp.y, M + 70.0, vp.y - M - 80.0))
			if e.x > vp.x - 150.0 and e.y < 150.0:
				e.y = 150.0
			var a: float = (sp - e).angle()
			draw_circle(e, 30.0 + beat * 8.0, Color(1.0, 0.82, 0.25, 0.16 + beat * 0.22))
			draw_colored_polygon(PackedVector2Array([e + Vector2.from_angle(a) * 45.0, e + Vector2.from_angle(a + 2.45) * 22.0, e + Vector2.from_angle(a - 2.45) * 22.0]), Color("#3a2606"))
			draw_colored_polygon(PackedVector2Array([e + Vector2.from_angle(a) * 40.0, e + Vector2.from_angle(a + 2.45) * 20.0, e + Vector2.from_angle(a - 2.45) * 20.0]), gcol)
			var ca: float = cos(a)
			var ha := HORIZONTAL_ALIGNMENT_RIGHT if ca > 0.3 else (HORIZONTAL_ALIGNMENT_LEFT if ca < -0.3 else HORIZONTAL_ALIGNMENT_CENTER)
			var lp: Vector2 = e + Vector2(-ca * 34.0, -sin(a) * 30.0 + 4.0)
			_pin_label(font, label, 16, lp.x, lp.y, ha, Color("#ffe27a"))
		else:
			var by: float = maxf(sp.y - 60.0 - absf(sin(Time.get_ticks_msec() * 0.001 * 4.0)) * 10.0, _ins.y + 104.0)   # la etiqueta no sale por arriba ni pisa el reloj
			var p := Vector2(sp.x, by)
			draw_colored_polygon(PackedVector2Array([p + Vector2(-17.0, -14.0), p + Vector2(17.0, -14.0), p + Vector2(0.0, 11.0)]), Color("#3a2606"))
			draw_colored_polygon(PackedVector2Array([p + Vector2(-14.0, -12.0), p + Vector2(14.0, -12.0), p + Vector2(0.0, 8.0)]), gcol)
			_pin_label(font, label, 15, p.x, p.y - 22.0, HORIZONTAL_ALIGNMENT_CENTER, Color("#ffe27a"))

func draw_rift_notice(font: Font, vp: Vector2) -> void:
	if rift_notice < 0.0:
		return
	var a: float = minf(1.0, minf(rift_notice * 4.0, (4.5 - rift_notice) * 2.0))
	var pop: float = 1.0 + maxf(0.0, 0.25 - rift_notice) * 1.6
	var t1: String = L.t("¡SE HA ABIERTO UNA GRIETA!")
	var t2: String = L.t("Sigue la flecha morada: dentro te espera un legendario")
	if rift_den:
		t1 = L.t("¡SE HA ABIERTO UNA GUARIDA DYNAMAX!")
		t2 = L.t("Sigue la flecha roja: dentro te espera un Pokémon gigante")
	# el cartel "salta" hasta x1,4: se limita para que ni asi se salga, y el texto se encoge si hace falta
	var cap: float = (vp.x - _ins.x - _ins.z - 24.0) / 1.4
	var fit1: Array = _fit_txt(font, t1, 26, cap - 32.0, 12)
	var fit2: Array = _fit_txt(font, t2, 16, cap - 32.0, 10)
	t1 = String(fit1[0])
	t2 = String(fit2[0])
	var w1: float = font.get_string_size(t1, HORIZONTAL_ALIGNMENT_LEFT, -1.0, int(fit1[1])).x
	var w2: float = font.get_string_size(t2, HORIZONTAL_ALIGNMENT_LEFT, -1.0, int(fit2[1])).x
	var bw: float = minf(cap, maxf(w1, w2) + 48.0)
	draw_set_transform(Vector2((_ins.x + vp.x - _ins.z) * 0.5, maxf(vp.y * 0.2, 136.0 + _ins.y)), 0.0, Vector2(pop, pop))   # bajo la fila de nivel aunque la vista sea baja
	var r := Rect2(-bw * 0.5, -34.0, bw, 68.0)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.102, 0.043, 0.2, 0.88 * a)
	sb.border_color = Color(1.0, 0.24, 0.43, a) if rift_den else Color(0.706, 0.541, 1.0, a)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(10)
	draw_style_box(sb, r)
	draw_string(font, Vector2(-bw * 0.5, -4.0), t1, HORIZONTAL_ALIGNMENT_CENTER, bw, int(fit1[1]), Color(0.886, 0.816, 1.0, a))
	draw_string(font, Vector2(-bw * 0.5, 22.0), t2, HORIZONTAL_ALIGNMENT_CENTER, bw, int(fit2[1]), Color(0.788, 0.69, 1.0, a))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func draw_rift(font: Font, vp: Vector2) -> void:
	if rift_ttl >= 0.0:
		var beat: float = 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.001 * 7.0)
		var tcol: Color = Color("#e2d0ff")
		var fcol: Color = Color("#e2d0ff") if beat > 0.5 else Color("#a06bff")
		var lbl: String = L.t("GRIETA ·")
		if rift_den:
			tcol = Color("#ffd0d6")
			fcol = Color("#ffd0d6") if beat > 0.5 else Color("#ff3d6e")
			lbl = L.t("GUARIDA ·")
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
			var label: String = "%s %d m · %d s" % [lbl, rift_m, ceili(rift_ttl)]
			var ca: float = cos(a)
			var ha := HORIZONTAL_ALIGNMENT_RIGHT if ca > 0.3 else (HORIZONTAL_ALIGNMENT_LEFT if ca < -0.3 else HORIZONTAL_ALIGNMENT_CENTER)
			var lp: Vector2 = e + Vector2(-ca * 34.0, -sin(a) * 30.0 + 4.0)
			_pin_label(font, label, 16, lp.x, lp.y, ha, tcol)
		else:
			# Encima de la grieta: flecha que bota con la cuenta atras
			var by: float = maxf(rift_scr.y - 46.0 - absf(sin(Time.get_ticks_msec() * 0.001 * 4.0)) * 10.0, _ins.y + 104.0)
			var p := Vector2(rift_scr.x, by)
			var tri := PackedVector2Array([p + Vector2(-17.0, -14.0), p + Vector2(17.0, -14.0), p + Vector2(0.0, 11.0)])
			draw_colored_polygon(tri, Color("#1a0b33"))
			draw_colored_polygon(PackedVector2Array([p + Vector2(-14.0, -12.0), p + Vector2(14.0, -12.0), p + Vector2(0.0, 8.0)]), fcol)
			var l2: String = "%s %d s" % [lbl, ceili(rift_ttl)]
			_pin_label(font, l2, 15, p.x, p.y - 22.0, HORIZONTAL_ALIGNMENT_CENTER, tcol)
	if legend_frac >= 0.0:
		var w: float = minf(440.0, vp.x - 360.0)
		var x0: float = vp.x * 0.5 - w * 0.5
		draw_rect(Rect2(x0 - 2.0, vp.y - 148.0, w + 4.0, 22.0), Color(0, 0, 0, 0.6))
		draw_rect(Rect2(x0, vp.y - 146.0, w * clampf(legend_frac, 0.0, 1.0), 18.0), Color("#b06bff"))
		var lg: Array = _fit_txt(font, legend_name, 18, w - 70.0, 11)
		draw_string(font, Vector2(x0, vp.y - 154.0), String(lg[0]), HORIZONTAL_ALIGNMENT_LEFT, -1.0, int(lg[1]), Color("#e6d4ff"))
		if arena_left >= 0.0:
			_ds(font, Vector2(x0, vp.y - 154.0), "%02d:%02d" % [int(arena_left) / 60, int(arena_left) % 60], HORIZONTAL_ALIGNMENT_RIGHT, w, 18, Color("#ffd33d") if arena_left > 20.0 else Color("#ff6b7a"))

var team: Array = []:
	set(v):
		team = v
		if v.size() != _team_n and is_inside_tree():
			_relayout()   # la columna derecha depende de cuantos miembros hay
var swap_cd := 0.0
var limit := 0.0
var rifts_n := 0
var timeup := false
var end_big := ""
var end_l1 := ""
var end_l2 := ""
var tower_floor := 0
var tower_t := 0.0
var tower_risk := 0
var reap_pct := -1.0

func team_rects() -> Array:
	var out: Array = []
	for i in range(team.size()):
		out.append(Rect2(_vp.x - 190.0 - _ins.z, 126.0 + _ins.y + float(i) * 52.0, 174.0, 46.0))
	return out

func draw_team(font: Font) -> void:
	var rs: Array = team_rects()
	for i in range(team.size()):
		var t: Dictionary = team[i]
		var r: Rect2 = rs[i]
		var cur: bool = bool(t["cur"])
		draw_rect(r, Color(0.08, 0.12, 0.25, 0.72) if not cur else Color(0.2, 0.32, 0.62, 0.85))
		draw_rect(r, Color("#ffd23f") if cur else Color(1, 1, 1, 0.45), false, 2.0)
		var dead: bool = bool(t["dead"])
		_ds(font, r.position + Vector2(8.0, 20.0), String(t["name"]), HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 16.0, 16, Color(0.6, 0.6, 0.65) if dead else Color.WHITE)
		var f: float = clampf(float(t["frac"]), 0.0, 1.0)
		draw_rect(Rect2(r.position + Vector2(8.0, 29.0), Vector2(r.size.x - 16.0, 9.0)), Color(0, 0, 0, 0.6))
		var c2 := Color("#5fe08a") if f > 0.5 else (Color("#ffd33d") if f > 0.25 else Color("#ff6b7a"))
		draw_rect(Rect2(r.position + Vector2(9.0, 30.0), Vector2((r.size.x - 18.0) * f, 7.0)), c2)
		if not cur and swap_cd > 0.0 and not dead:
			draw_rect(r, Color(0, 0, 0, 0.35))

func _ease_out(x: float) -> float:
	return 1.0 - pow(1.0 - x, 3.0)

func _ease_back(x: float) -> float:
	var c1: float = 1.70158
	var c3: float = c1 + 1.0
	return 1.0 + c3 * pow(x - 1.0, 3.0) + c1 * pow(x - 1.0, 2.0)

func _bounce(x: float) -> float:
	var n1 := 7.5625
	var d1 := 2.75
	if x < 1.0 / d1:
		return n1 * x * x
	elif x < 2.0 / d1:
		x -= 1.5 / d1
		return n1 * x * x + 0.75
	elif x < 2.5 / d1:
		x -= 2.25 / d1
		return n1 * x * x + 0.9375
	x -= 2.625 / d1
	return n1 * x * x + 0.984375

func z_rect() -> Rect2:
	return _rz

func dyn_rect() -> Rect2:
	return _rd

# Dynamax: boton (listo / bloqueado por nivel), barra de tiempo, borde rojo y cartel "DYNAMAX" al activarse.
func draw_dyn(font: Font, vp: Vector2) -> void:
	var tcol: Color = Color("#ff3d6e")
	var beat: float = 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.001 * 6.0)
	if dyn_left >= 0.0:
		var a: float = 0.1 + 0.06 * beat
		var th: float = 26.0
		draw_rect(Rect2(0, 0, vp.x, th), Color(1.0, 0.1, 0.3, a))
		draw_rect(Rect2(0, vp.y - th, vp.x, th), Color(1.0, 0.1, 0.3, a))
		draw_rect(Rect2(0, 0, th, vp.y), Color(1.0, 0.1, 0.3, a))
		draw_rect(Rect2(vp.x - th, 0, th, vp.y), Color(1.0, 0.1, 0.3, a))
		var bd: Vector2 = _band(_y_dyn - 16.0, _y_dyn + 26.0)
		var w: float = minf(360.0, bd.y - bd.x - 8.0)
		var x0: float = clampf(vp.x * 0.5 - w * 0.5, bd.x + 4.0, maxf(bd.x + 4.0, bd.y - 4.0 - w))
		var fr: float = clampf(dyn_left / DYN.DUR, 0.0, 1.0)
		draw_rect(Rect2(x0 - 2.0, _y_dyn + 4.0, w + 4.0, 20.0), Color(0, 0, 0, 0.65))
		draw_rect(Rect2(x0, _y_dyn + 6.0, w * fr, 16.0), tcol if fr > 0.25 else Color("#ffb347"))
		draw_string(font, Vector2(x0, _y_dyn), "DYNAMAX  %d s" % ceili(dyn_left), HORIZONTAL_ALIGNMENT_CENTER, w, 16, Color.WHITE)
	if dyn_flash < 2.7:
		var fl: float = clampf(1.0 - dyn_flash / 0.25, 0.0, 1.0)
		if fl > 0.0:
			draw_rect(Rect2(Vector2.ZERO, vp), Color(1.0, 0.6, 0.7, 0.45 * fl))
		var al: float = clampf((2.7 - dyn_flash) / 0.5, 0.0, 1.0)
		var fs: int = 84
		var word := "DYNAMAX"
		var widths: Array = []
		var tw: float = 0.0
		for ch in word:
			var cw: float = font.get_string_size(String(ch), HORIZONTAL_ALIGNMENT_LEFT, -1.0, fs).x + 3.0
			widths.append(cw)
			tw += cw
		var x0: float = vp.x * 0.5 - tw * 0.5
		var by: float = vp.y * 0.3
		var shine: float = (dyn_flash - 0.9) / 0.9 * (tw + 160.0) - 80.0
		var cx: float = x0
		for i in range(word.length()):
			var loc: float = dyn_flash - 0.35 - float(i) * 0.08
			var cwid: float = float(widths[i])
			if loc >= 0.0:
				var k: float = clampf(loc / 0.55, 0.0, 1.0)
				var drop: float = (1.0 - _bounce(k)) * 190.0
				var sc: float = 1.0 + 0.35 * maxf(0.0, 1.0 - loc / 0.25)
				var wave: float = sin(dyn_flash * 5.0 - float(i) * 0.7) * 5.0 * clampf((dyn_flash - 1.2) / 0.3, 0.0, 1.0)
				var ox: float = cx + cwid * 0.5
				var oy: float = by - drop + wave
				draw_set_transform(Vector2(ox, oy), 0.0, Vector2(sc, sc))
				var base: Color = Color("#ff2f63").lerp(Color("#ffd6e0"), clampf(float(i) / 6.0 + 0.15 * sin(dyn_flash * 6.0 - float(i)), 0.0, 1.0))
				var pos := Vector2(-cwid * 0.5, 0.0)
				_dso(font, pos + Vector2(0.0, 6.0), String(word[i]), HORIZONTAL_ALIGNMENT_LEFT, -1.0, fs, 16, Color(0.22, 0.0, 0.1, 0.92 * al))
				_ds(font, pos + Vector2(3.0, 9.0), String(word[i]), HORIZONTAL_ALIGNMENT_LEFT, -1.0, fs, Color(0.55, 0.0, 0.2, 0.9 * al))
				_ds(font, pos + Vector2(0.0, 6.0), String(word[i]), HORIZONTAL_ALIGNMENT_LEFT, -1.0, fs, Color(base.r, base.g, base.b, al))
				var sh: float = clampf(1.0 - absf(cx + cwid * 0.5 - shine) / 55.0, 0.0, 1.0)
				if sh > 0.0:
					_ds(font, pos + Vector2(0.0, 6.0), String(word[i]), HORIZONTAL_ALIGNMENT_LEFT, -1.0, fs, Color(1.0, 1.0, 1.0, sh * 0.9 * al))
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
				# chispas al aterrizar
				if loc < 0.45:
					var burst: float = 1.0 - loc / 0.45
					for q in range(5):
						var ang: float = float(q) * 1.256 + float(i)
						draw_circle(Vector2(ox, by - 28.0) + Vector2.from_angle(ang) * (loc * 260.0), 3.0 * burst + 1.0, Color(1.0, 0.85, 0.9, burst * al))
			cx += cwid
	draw_poi(font, vp)
	if dyn_btn > 0:
		var r: Rect2 = dyn_rect()
		var c: Vector2 = r.position + r.size * 0.5
		var ready: bool = dyn_btn == 2
		if ready:
			draw_circle(c, 52.0 + beat * 6.0, Color(tcol.r, tcol.g, tcol.b, 0.25 + beat * 0.25))
		draw_circle(c, 46.0, Color(0.14, 0.03, 0.07, 0.88))
		draw_arc(c, 46.0, 0.0, TAU, 40, tcol if ready else Color(0.5, 0.52, 0.58), 4.0)
		_ds(font, Vector2(c.x - 44.0, c.y + (2.0 if dyn_btn == 3 else 11.0)), "MAX", HORIZONTAL_ALIGNMENT_CENTER, 88.0, 28 if dyn_btn == 3 else 32, Color.WHITE if ready else Color(0.6, 0.62, 0.68))
		if dyn_btn == 3:
			_ds(font, Vector2(c.x - 44.0, c.y + 26.0), "%d:%02d" % [int(dyn_cd) / 60, int(dyn_cd) % 60], HORIZONTAL_ALIGNMENT_CENTER, 88.0, 18, Color(0.85, 0.88, 0.95))
		elif not ready:
			_ds(font, Vector2(c.x - 50.0, c.y + 70.0), L.t("Nv. %d") % DYN.MIN_LEVEL, HORIZONTAL_ALIGNMENT_CENTER, 100.0, 16, Color(0.75, 0.78, 0.85))

func draw_z(font: Font, vp: Vector2) -> void:
	var tcol: Color = Color.html(String(MD.TYPE_COLOR.get(z_type, "#ffffff")))
	if z_dim > 0.0:
		draw_rect(Rect2(Vector2.ZERO, vp), Color(0.0, 0.0, 0.04, z_dim))
	if z_state == "cine":
		var T: float = ZM.CINE_T
		var cy: float = vp.y * 0.42
		var open: float = _ease_out(clampf((z_t - 0.05) / 0.3, 0.0, 1.0))
		var fade: float = clampf((T - z_t) / 0.3, 0.0, 1.0)
		var al: float = open * fade
		# Rayos giratorios detras del cartel
		var rl: float = vp.x * 0.9
		for i in range(16):
			var ra: float = float(i) * TAU / 16.0 + z_t * 0.5
			var w: float = 0.075
			draw_colored_polygon(PackedVector2Array([Vector2(vp.x * 0.5, cy), Vector2(vp.x * 0.5, cy) + Vector2.from_angle(ra - w) * rl, Vector2(vp.x * 0.5, cy) + Vector2.from_angle(ra + w) * rl]), Color(tcol.r, tcol.g, tcol.b, 0.16 * al))
		# Cartel que se abre
		var hh: float = 66.0 * open
		draw_rect(Rect2(0.0, cy - hh, vp.x, hh * 2.0), Color(tcol.r * 0.22, tcol.g * 0.22, tcol.b * 0.22, 0.8 * fade))
		draw_rect(Rect2(0.0, cy - hh - 3.0, vp.x, 5.0), Color(minf(1.0, tcol.r + 0.3), minf(1.0, tcol.g + 0.3), minf(1.0, tcol.b + 0.3), fade))
		draw_rect(Rect2(0.0, cy + hh - 2.0, vp.x, 5.0), Color(minf(1.0, tcol.r + 0.3), minf(1.0, tcol.g + 0.3), minf(1.0, tcol.b + 0.3), fade))
		# Lineas de velocidad
		for i in range(22):
			var h1: float = fmod(float(i) * 0.6180339 + 0.13, 1.0)
			var h2: float = fmod(float(i) * 0.7548776 + 0.29, 1.0)
			var yy: float = cy - 120.0 + h1 * 240.0
			var xx: float = fposmod(h2 * vp.x - z_t * (900.0 + h1 * 700.0), vp.x + 300.0) - 150.0
			draw_rect(Rect2(xx, yy, 90.0 + h2 * 120.0, 2.0), Color(1, 1, 1, 0.28 * al))
		# Cristal Z que aparece sobre el cartel y late
		var cr_p: float = 1.0 + 0.08 * sin(z_t * 9.0)
		var cr_c := Vector2(vp.x * 0.5, cy - 112.0 * open)
		draw_circle(cr_c, 58.0 * cr_p, Color(tcol.r, tcol.g, tcol.b, 0.22 * al))
		draw_circle(cr_c, 38.0 * cr_p, Color(1, 1, 1, 0.16 * al))
		IC.draw_in(self, "zc:" + z_type, cr_c, 24.0 * 5.0 * cr_p * open, Color(1, 1, 1, al))
		# Subtitulo con letras que se separan
		var sub: String = L.t("MOVIMIENTO Z")
		var sp: float = lerpf(1.0, 14.0, _ease_out(clampf((z_t - 0.1) / 0.6, 0.0, 1.0)))
		var sx: float = vp.x * 0.5 - (font.get_string_size(sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x + sp * float(sub.length() - 1)) * 0.5
		for i in range(sub.length()):
			var ch: String = sub.substr(i, 1)
			_ds(font, Vector2(sx, cy - 28.0), ch, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(1, 1, 1, 0.85 * al))
			sx += font.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x + sp
		# Nombre: cada letra cae con un golpe y rebote
		var fs: int = 60 if vp.x >= 900.0 else 40
		var tw: float = font.get_string_size(z_name, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var x0: float = vp.x * 0.5 - tw * 0.5
		var sweep: float = vp.x * clampf((z_t - 1.0) / 0.75, 0.0, 1.0) * 1.3 - vp.x * 0.15
		var cx: float = x0
		var n: int = z_name.length()
		for i in range(n):
			var ch: String = z_name.substr(i, 1)
			var cw: float = font.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			var ts: float = 0.35 + float(i) * (0.5 / float(maxi(n, 1)))
			var pr: float = clampf((z_t - ts) / 0.26, 0.0, 1.0)
			if pr > 0.0:
				var scl: float = lerpf(3.4, 1.0, _ease_back(pr))
				var ca: float = clampf(pr * 5.0, 0.0, 1.0) * fade
				var shk: Vector2 = Vector2.ZERO
				if pr < 1.0 or z_t < ts + 0.4:
					shk = Vector2(sin(z_t * 90.0 + float(i)) * 3.0, cos(z_t * 70.0 + float(i) * 2.0) * 3.0) * clampf(1.0 - (z_t - ts) / 0.4, 0.0, 1.0)
				var pos: Vector2 = Vector2(cx + cw * 0.5, cy + 22.0) + shk
				draw_set_transform(pos, 0.0, Vector2(scl, scl))
				var shine: float = clampf(1.0 - absf((cx + cw * 0.5) - sweep) / 110.0, 0.0, 1.0)
				var base: Color = Color(minf(1.0, tcol.r * 0.45 + 0.55), minf(1.0, tcol.g * 0.45 + 0.55), minf(1.0, tcol.b * 0.45 + 0.55), ca)
				var fc: Color = base.lerp(Color(1, 1, 1, ca), shine)
				for o in [Vector2(-3, 0), Vector2(3, 0), Vector2(0, -3), Vector2(0, 3)]:
					_ds(font, Vector2( - cw * 0.5, 0.0) + o, ch, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(tcol.r, tcol.g, tcol.b, 0.55 * ca))
				_ds(font, Vector2( - cw * 0.5 + 3.0, 4.0), ch, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0, 0, 0, 0.7 * ca))
				_ds(font, Vector2( - cw * 0.5, 0.0), ch, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, fc)
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			cx += cw
		# Destello blanco con el primer golpe
		var fl: float = clampf(1.0 - absf(z_t - 0.38) / 0.12, 0.0, 1.0)
		if fl > 0.0:
			draw_rect(Rect2(Vector2.ZERO, vp), Color(1, 1, 1, 0.5 * fl))
	if z_btn > 0:
		var r: Rect2 = z_rect()
		var c: Vector2 = r.position + r.size * 0.5
		var ready: bool = z_btn == 2
		var beat: float = 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.001 * 6.0)
		if ready:
			draw_circle(c, 52.0 + beat * 6.0, Color(tcol.r, tcol.g, tcol.b, 0.25 + beat * 0.25))
		draw_circle(c, 46.0, Color(0.05, 0.07, 0.14, 0.85))
		draw_arc(c, 46.0, 0.0, TAU, 40, tcol if ready else Color(0.5, 0.52, 0.58), 4.0)
		var zc: Color = Color.WHITE if ready else Color(0.6, 0.62, 0.68)
		IC.draw_in(self, "zc:" + z_type, c + Vector2(0.0, -2.0 - (beat * 2.0 if ready else 0.0)), 64.0, zc)
		if z_btn == 3:
			_ds(font, Vector2(c.x - 50.0, c.y + 70.0), "%d:%02d" % [int(z_cd) / 60, int(z_cd) % 60], HORIZONTAL_ALIGNMENT_CENTER, 100.0, 16, Color(0.75, 0.78, 0.85))
		elif not ready:
			_ds(font, Vector2(c.x - 50.0, c.y + 70.0), L.t("Nv. %d") % ZM.MIN_LEVEL, HORIZONTAL_ALIGNMENT_CENTER, 100.0, 16, Color(0.75, 0.78, 0.85))

func pause_rects() -> Array:
	var vp: Vector2 = _vp
	return [_rp, Rect2(vp.x * 0.5 - 160.0, vp.y * 0.5, 320.0, 58.0), Rect2(vp.x * 0.5 - 160.0, vp.y * 0.5 + 76.0, 320.0, 58.0)]

func draw_toast(font: Font, vp: Vector2) -> void:
	if toast_t <= 0.0 or toast.is_empty():
		return
	var a: float = clampf(minf(toast_t, 2.8 - toast_t + 0.001) * 4.0, 0.0, 1.0)
	var txt: String = String(toast["text"])
	var sub: String = String(toast.get("sub", ""))
	var cap: float = vp.x - _ins.x - _ins.z - 40.0
	var f1: Array = _fit_txt(font, txt, 22, cap - 76.0, 12)
	txt = String(f1[0])
	var tw: float = font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, int(f1[1])).x
	var f2: Array = [sub, 16]
	if sub != "":
		f2 = _fit_txt(font, sub, 16, cap - 76.0, 10)
		sub = String(f2[0])
		tw = maxf(tw, font.get_string_size(sub, HORIZONTAL_ALIGNMENT_LEFT, -1, int(f2[1])).x)
	var w: float = minf(tw + 100.0, cap)
	var h: float = 64.0 if sub == "" else 82.0
	var x0: float = (_ins.x + vp.x - _ins.z) * 0.5 - w * 0.5
	var y0: float = 64.0 + _ins.y
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
	draw_string(font, Vector2(x0 + 66.0, ty), txt, HORIZONTAL_ALIGNMENT_LEFT, w - 76.0, int(f1[1]), Color(1.0, 0.82, 0.25, a))
	if sub != "":
		draw_string(font, Vector2(x0 + 66.0, y0 + 60.0), sub, HORIZONTAL_ALIGNMENT_LEFT, w - 76.0, int(f2[1]), Color(0.72, 0.8, 0.94, a))

# Linea de texto centrada en el hueco libre de su fila: si cabe centrada en la pantalla se queda ahi; si no, se
# desplaza al hueco y, si aun asi no cabe, se encoge (hasta 11 px) y al final se recorta con "…".
func _cline(font: Font, y: float, txt: String, fs: int, col: Color) -> void:
	var bd: Vector2 = _band(y - float(fs) * 0.8, y + float(fs) * 0.3)
	var fit: Array = _fit_txt(font, txt, fs, maxf(60.0, bd.y - bd.x), 11)
	var t: String = String(fit[0])
	var f: int = int(fit[1])
	var w: float = font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1.0, f).x
	var x0: float = clampf(_vp.x * 0.5 - w * 0.5, bd.x, maxf(bd.x, bd.y - w))
	draw_string(font, Vector2(x0, y), t, HORIZONTAL_ALIGNMENT_LEFT, -1.0, f, col)

func _draw() -> void:
	var _pt := Prof.dbegin()
	_draw_body()
	Prof.dend(Prof.D_HUD, _pt)

func _draw_body() -> void:
	var font := ThemeDB.fallback_font
	if team.size() != _team_n:
		_relayout()
	var vp: Vector2 = _vp
	var ins: Vector4 = _ins
	var oy: float = ins.y
	# --- Medidas de lo que rodea a las filas centrales: cada fila de texto central se coloca en el hueco libre ---
	var hp_txt: String = L.t("%s  PS %d/%d") % [poke_name, ceili(hp), ceili(max_hp)]
	var name_w: float = font.get_string_size(hp_txt, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18).x
	var lvl_end: float = 16.0 + ins.x + font.get_string_size(L.t("Nv. %d") % level, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18).x
	if revives > 0:
		lvl_end = maxf(lvl_end, 70.0 + ins.x + 22.0 * float(revives - 1) + 9.0)
	if ab_name != "":
		lvl_end = maxf(lvl_end, 132.0 + ins.x + font.get_string_size(ab_name, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 15).x)
	var tw: float = font.get_string_size(str(tickets), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18).x
	var t10w: float = font.get_string_size(str(tickets10), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18).x
	var cw: float = font.get_string_size(str(coins), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18).x
	var cnt_left: float = vp.x - 16.0 - ins.z - (t10w + 40.0) - (tw + 40.0) - cw - 28.0   # borde izquierdo de los contadores
	var kills_txt: String = L.t("Derrotados: %d") % kills
	var kills_fs: int = 20
	var kfit: Array = _fit_txt(font, kills_txt, 20, 220.0, 12)
	kills_txt = String(kfit[0])
	kills_fs = int(kfit[1])
	var kw: float = font.get_string_size(kills_txt, HORIZONTAL_ALIGNMENT_LEFT, -1.0, kills_fs).x
	_obst = [
		Rect2(16.0 + ins.x, 16.0 + oy, 240.0, 18.0),
		Rect2(16.0 + ins.x, 40.0 + oy, name_w, 20.0),
		Rect2(16.0 + ins.x, 62.0 + oy, lvl_end - 16.0 - ins.x, 18.0),
		Rect2(vp.x - 16.0 - ins.z - kw, 14.0 + oy, kw, 28.0),
		Rect2(cnt_left, 42.0 + oy, vp.x - 16.0 - ins.z - cnt_left, 28.0),
		_rp,
		Rect2(mini_pos, Vector2(200.0, 200.0) * mini_scale),
	]
	for tr in team_rects():
		_obst.append(tr)
	# pila de filas centrales bajo el reloj: cada fila presente baja a la siguiente
	var cy: float = 58.0 + oy
	var y_l2: float = cy
	if limit > 0.0 or tower_floor > 0 or adapt_pct > 0:
		cy += 24.0
	var y_wx: float = cy
	if weather_text != "":
		cy += 24.0
	_y_dyn = cy
	if dyn_left >= 0.0:
		cy += 30.0
	var y_down: float = cy - 2.0
	if down:
		cy += 74.0
	var y_ban: float = maxf(cy + 8.0, 92.0 + oy)
	_y_chip = 140.0 + oy
	if banner != "":
		_y_chip = maxf(_y_chip, y_ban + 48.0)
	draw_z(font, vp)
	draw_dyn(font, vp)
	if show_fps:
		_ds(font, Vector2(vp.x - 130.0 - ins.z, vp.y - 12.0 - ins.w), "%d FPS" % int(Engine.get_frames_per_second()), HORIZONTAL_ALIGNMENT_RIGHT, 118.0, 20, Color(1, 1, 1, 0.85))
	var frac: float = clampf(hp / max_hp, 0.0, 1.0)
	var col := Color("#5fe08a")
	if frac <= 0.25:
		col = Color("#ff6b7a")
	elif frac <= 0.5:
		col = Color("#ffd33d")
	draw_rect(Rect2(0.0, 0.0, vp.x, 8.0), Color(0, 0, 0, 0.55))
	draw_rect(Rect2(0.0, 0.0, vp.x * clampf(xp / xp_next, 0.0, 1.0), 8.0), Color("#7fe0ff"))
	draw_rect(Rect2(16.0 + ins.x, 16.0 + oy, 240.0, 18.0), Color(0, 0, 0, 0.55))
	draw_rect(Rect2(18.0 + ins.x, 18.0 + oy, 236.0 * frac, 14.0), col)
	draw_string(font, Vector2(16.0 + ins.x, 54.0 + oy), hp_txt, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18, Color.WHITE)
	draw_string(font, Vector2(16.0 + ins.x, 76.0 + oy), L.t("Nv. %d") % level, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18, Color("#7fe0ff"))
	if ab_name != "":
		draw_string(font, Vector2(132.0 + ins.x, 76.0 + oy), ab_name, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 15, Color("#ffd98a"))
	if down:
		var bd: Vector2 = _band(y_down - 4.0, y_down + 66.0)
		var d1: Array = _fit_txt(font, L.t("Espectando: reviveras en %d s") % ceili(down_left), 20, bd.y - bd.x - 24.0, 11)
		var d2: Array = _fit_txt(font, L.t("Vida de tu compañero"), 16, bd.y - bd.x - 24.0, 10)
		var dw: float = maxf(font.get_string_size(String(d1[0]), HORIZONTAL_ALIGNMENT_LEFT, -1.0, int(d1[1])).x, font.get_string_size(String(d2[0]), HORIZONTAL_ALIGNMENT_LEFT, -1.0, int(d2[1])).x)
		var bw: float = minf(maxf(300.0, dw + 24.0), bd.y - bd.x - 8.0)
		var bx: float = clampf(vp.x * 0.5 - bw * 0.5, bd.x + 4.0, maxf(bd.x + 4.0, bd.y - 4.0 - bw))
		var by: float = y_down
		draw_rect(Rect2(bx - 4.0, by - 4.0, bw + 8.0, 70.0), Color(0, 0, 0, 0.5))
		draw_string(font, Vector2(bx, by + 16.0), String(d1[0]), HORIZONTAL_ALIGNMENT_CENTER, bw, int(d1[1]), Color("#ffd2d8"))
		draw_rect(Rect2(bx, by + 28.0, bw, 14.0), Color(0, 0, 0, 0.6))
		draw_rect(Rect2(bx + 1.0, by + 29.0, (bw - 2.0) * pbar, 12.0), Color("#9ad0ff"))
		draw_string(font, Vector2(bx, by + 60.0), String(d2[0]), HORIZONTAL_ALIGNMENT_CENTER, bw, int(d2[1]), Color("#cfe6ff"))
	if show_stats and not stats.is_empty():
		# bajo el minimapa; si no cabe encima de la barra de huecos, sube lo justo (minimo pegado al minimapa).
		# El ancho sale del texto mas largo de cada columna (en otros idiomas "Regeneracion" no cabe en 90 px).
		var sh: float = 18.0 * float(stats.size()) + 6.0
		var sy: float = minf(stats_y, maxf(mini_pos.y + 200.0 * mini_scale + 4.0, vp.y - 88.0 - ins.w - 6.0 - sh))
		var sx: float = 16.0 + ins.x
		var lw_max := 0.0
		var vw_max := 0.0
		for row in stats:
			lw_max = maxf(lw_max, font.get_string_size(String(row[0]), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14).x)
			vw_max = maxf(vw_max, font.get_string_size(String(row[1]), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14).x)
		var pw: float = maxf(150.0, lw_max + vw_max + 24.0)
		draw_rect(Rect2(sx - 4.0, sy - 2.0, pw, sh), Color(0, 0, 0, 0.32))
		for row in stats:
			draw_string(font, Vector2(sx, sy + 13.0), String(row[0]), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, Color(1, 1, 1, 0.75))
			draw_string(font, Vector2(sx, sy + 13.0), String(row[1]), HORIZONTAL_ALIGNMENT_RIGHT, pw - 12.0, 14, Color("#ffe58a"))
			sy += 18.0
	for ri in range(revives):
		IC.draw_in(self, "revive", Vector2(70.0 + ins.x + float(ri) * 22.0, 71.0 + oy), 18.0)
	draw_powers(font, vp)
	draw_items(font, ins)
	if not team.is_empty():
		draw_team(font)
	if weather_text != "":
		_cline(font, y_wx, L.t(weather_text), 18, Color("#cfe2ff"))
	if banner != "":
		_cline(font, y_ban, L.t(banner), 20, Color("#ffffff"))
	draw_fusion(font, vp)
	draw_rift(font, vp)
	draw_rift_notice(font, vp)
	draw_thief_notice(font, vp)
	draw_thieves(font, vp)
	draw_toast(font, vp)
	var rx: float = vp.x - 16.0 - ins.z
	draw_string(font, Vector2(rx - t10w, 62.0 + oy), str(tickets10), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18, Color("#c47bff"))
	IC.draw_in(self, "ticket10", Vector2(rx - t10w - 16.0, 56.0 + oy), 24.0)
	rx -= t10w + 40.0
	draw_string(font, Vector2(rx - tw, 62.0 + oy), str(tickets), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18, Color("#ffd23f"))
	IC.draw_in(self, "ticket", Vector2(rx - tw - 16.0, 56.0 + oy), 24.0)
	rx -= tw + 40.0
	draw_string(font, Vector2(rx - cw, 62.0 + oy), str(coins), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18, Color("#ffd23f"))
	IC.draw_in(self, "coin", Vector2(rx - cw - 16.0, 56.0 + oy), 24.0)
	var pr: Array = pause_rects()
	draw_rect(pr[0], Color(0, 0, 0, 0.45))
	draw_rect(pr[0], Color.WHITE, false, 2.0)
	draw_rect(Rect2(pr[0].position + Vector2(16.0, 12.0), Vector2(8.0, 22.0)), Color.WHITE)
	draw_rect(Rect2(pr[0].position + Vector2(30.0, 12.0), Vector2(8.0, 22.0)), Color.WHITE)
	var clock: String = "%02d:%02d" % [floori(run_time / 60.0), int(run_time) % 60]
	if limit > 0.0:
		var left: float = maxf(0.0, limit - run_time)
		var lc: String = "%02d:%02d" % [floori(left / 60.0), int(left) % 60]
		draw_string(font, Vector2(0.0, 36.0 + oy), lc, HORIZONTAL_ALIGNMENT_CENTER, vp.x, 28, Color("#ff6b7a") if left < 30.0 else Color.WHITE)
		if ch_mode:
			var chy := 134.0
			for ln in ch_lines:
				var okc: bool = bool(ln[3])
				var txt: String = String(ln[0])
				if okc:
					txt += "  ✓"
				elif bool(ln[4]):
					var cs: int = int(minf(float(ln[1]), float(ln[2])))
					txt += "  %d:%02d/%d:%02d" % [cs / 60, cs % 60, int(ln[2]) / 60, int(ln[2]) % 60]
				elif float(ln[2]) > 1.0 and float(ln[2]) <= 100000.0:
					txt += "  %d/%d" % [int(minf(float(ln[1]), float(ln[2]))), int(ln[2])]
				var tw2: float = font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 16).x
				var px: float = vp.x - 16.0 - ins.z - tw2
				_dso(font, Vector2(px, chy), txt, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 16, 5, Color(0, 0, 0, 0.85))
				_ds(font, Vector2(px, chy), txt, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 16, Color("#8fe39b") if okc else Color.WHITE)
				chy += 20.0
		else:
			_cline(font, y_l2, L.t("Grietas ganadas: %d") % rifts_n, 18, Color("#c9a6ff"))
	else:
		draw_string(font, Vector2(0.0, 36.0 + oy), L.t(clock), HORIZONTAL_ALIGNMENT_CENTER, vp.x, 28, Color.WHITE)
	if adapt_pct > 0 and tower_floor <= 0 and limit <= 0.0:
		var ac: Color = Color("#8fe39b") if adapt_pct < 100 else (Color("#ffd23f") if adapt_pct == 100 else Color("#ff9a5a"))
		_cline(font, y_l2, L.t("Reto: %d%%") % adapt_pct, 16, ac)
	if tower_floor > 0:
		var sub: String = L.t("Piso %d / %d") % [tower_floor, TOWER_FLOORS]
		if tower_t >= 0.0:
			sub += "  ·  " + L.t("Jefe en %ds") % int(ceil(tower_t))
		else:
			sub += "  ·  " + L.t("¡Jefe!")
		if tower_risk > 0:
			sub += "  ·  " + L.t("Pactos: %d") % tower_risk
		if reap_pct >= 0.0:
			sub += "  ·  " + L.t("Sed de victoria +%s%%") % ("%.1f" % reap_pct)
		_cline(font, y_l2, sub, 18, Color("#ffd23f"))
	draw_string(font, Vector2(vp.x - 16.0 - ins.z - 220.0, 36.0 + oy), kills_txt, HORIZONTAL_ALIGNMENT_RIGHT, 220.0, kills_fs, Color.WHITE)
	if dead:
		# Camara lenta: primero se ve caer al Pokemon; despues oscurece y aparece GAME OVER.
		var fade: float = clampf((death_t - 0.3) / 0.35, 0.0, 1.0)
		draw_rect(Rect2(Vector2.ZERO, vp), Color(0, 0, 0, 0.55 * fade))
		if fade > 0.0:
			var ga: float = fade
			var big: String = (end_big if end_big != "" else L.t("¡TIEMPO!")) if timeup else "GAME OVER"
			var bigc: Color = Color(1.0, 0.82, 0.25, ga) if timeup else Color(1.0, 0.36, 0.42, ga)
			_dso(font, Vector2(0.0, vp.y * 0.36), big, HORIZONTAL_ALIGNMENT_CENTER, vp.x, 72, 10, Color(0, 0, 0, ga))
			_ds(font, Vector2(0.0, vp.y * 0.36), big, HORIZONTAL_ALIGNMENT_CENTER, vp.x, 72, bigc)
			if timeup:
				_ds(font, Vector2(0.0, vp.y * 0.45 + 10.0), end_l1 if end_l1 != "" else L.t("Grietas ganadas: %d") % rifts_n, HORIZONTAL_ALIGNMENT_CENTER, vp.x, 40, Color(1, 1, 1, ga))
				_ds(font, Vector2(0.0, vp.y * 0.45 + 50.0), end_l2 if end_l2 != "" else L.t("Derrotaste %d Pokémon") % kills, HORIZONTAL_ALIGNMENT_CENTER, vp.x, 22, Color(1, 1, 1, ga))
			else:
				_ds(font, Vector2(0.0, vp.y * 0.45 + 10.0), L.t("Has fallado el reto...") if ch_mode else L.t("Has caído..."), HORIZONTAL_ALIGNMENT_CENTER, vp.x, 40, Color(1, 1, 1, ga))
				_ds(font, Vector2(0.0, vp.y * 0.45 + 50.0), L.t("Aguantaste %s y derrotaste %d") % [clock, kills], HORIZONTAL_ALIGNMENT_CENTER, vp.x, 22, Color(1, 1, 1, ga))
	if dead:
		if show_end:
			_ds(font, Vector2(0.0, vp.y * 0.45 + 96.0), L.t("Pulsa una tecla, un botón o toca la pantalla para volver al menú"), HORIZONTAL_ALIGNMENT_CENTER, vp.x, 20, Color("#ffd33d"))

func _ds(f: Font, p: Vector2, t: String, a: int, w: float, sz: int, c: Color) -> void :
	draw_string(f, p, t, a, w, roundi(float(sz) * TXS.k()), c)

func _dso(f: Font, p: Vector2, t: String, a: int, w: float, sz: int, o: int, c: Color) -> void :
	draw_string_outline(f, p, t, a, w, roundi(float(sz) * TXS.k()), o, c)

var act_txt := ""

var poi_marks: Array = []

var items_hud: Array = []

var _page_t := 0.0

var item3_name := ""

var item3_id := ""

var fusion_t := 0.0

var fusion_name := ""

var balls := 0

func draw_items(font: Font, ins: Vector4) -> void :
	if items_hud.is_empty():
		return
	var per := 4
	var pages: int = (items_hud.size() + per - 1) / per
	var page: int = int(_page_t / 4.0) % pages
	var x0: float = 16.0 + ins.x
	var y0: float = 300.0 + ins.y + ((18.0 * stats.size() + 14.0) if (show_stats and not stats.is_empty()) else 0.0)
	var rows: int = mini(per, items_hud.size() - page * per)
	draw_rect(Rect2(x0 - 4.0, y0 - 4.0, 226.0, 34.0 * float(rows) + 8.0 + (14.0 if pages > 1 else 0.0)), Color(0.03, 0.06, 0.16, 0.5))
	for i in range(rows):
		var e: Dictionary = items_hud[page * per + i]
		var cy: float = y0 + float(i) * 34.0 + 14.0
		IC.draw_in(self, String(e["icon"]), Vector2(x0 + 14.0, cy), 26.0)
		var txt: String = L.t(String(e["name"]))
		var right := ""
		var rcol := Color("#ffe58a")
		if float(e["cd"]) >= 0.0:
			if float(e["cd"]) <= 0.0:
				right = L.t("Listo")
				rcol = Color("#7dffb0")
			else:
				right = "%ds" % ceili(float(e["cd"]))
				var act: bool = bool(e.get("act", false))
				rcol = Color("#8fe0ff") if act else Color("#ff9a7a")
				var k: float = clampf(float(e["cd"]) / maxf(1.0, float(e["cdmax"])), 0.0, 1.0)
				draw_rect(Rect2(x0 + 32.0, cy + 10.0, 176.0, 3.0), Color(0, 0, 0, 0.5))
				draw_rect(Rect2(x0 + 32.0, cy + 10.0, 176.0 * (k if act else 1.0 - k), 3.0), rcol)
		elif int(e["lv"]) > 0:
			right = L.t("Nv. %d") % int(e["lv"])
		_ds(font, Vector2(x0 + 32.0, cy + 4.0), txt, HORIZONTAL_ALIGNMENT_LEFT, 128.0, 14, Color(1, 1, 1, 0.9))
		_ds(font, Vector2(x0 + 32.0, cy + 4.0), right, HORIZONTAL_ALIGNMENT_RIGHT, 176.0, 14, rcol)
	if pages > 1:
		_ds(font, Vector2(x0, y0 + 34.0 * float(rows) + 8.0), "%d/%d" % [page + 1, pages], HORIZONTAL_ALIGNMENT_RIGHT, 218.0, 12, Color(1, 1, 1, 0.6))

func draw_fusion(f: Font, vp: Vector2) -> void :
	if fusion_t <= 0.0:
		return
	var tt: float = 2.8 - fusion_t
	var fin: float = clampf(tt / 0.35, 0.0, 1.0)
	var fout: float = clampf(fusion_t / 0.6, 0.0, 1.0)
	var al: float = fin * fout
	var cy: float = vp.y * 0.38

	draw_rect(Rect2(0.0, cy - 70.0 * fin, vp.x, 140.0 * fin), Color(0.05, 0.0, 0.1, 0.55 * al))
	draw_rect(Rect2(0.0, cy - 72.0 * fin, vp.x, 3.0), Color(1.0, 0.85, 1.0, 0.9 * al))
	draw_rect(Rect2(0.0, cy + 70.0 * fin, vp.x, 3.0), Color(1.0, 0.85, 1.0, 0.9 * al))
	var sx: float = fmod(tt * 1400.0, vp.x + 400.0) - 200.0
	draw_rect(Rect2(sx, cy - 70.0, 90.0, 140.0), Color(1.0, 1.0, 1.0, 0.18 * al))

	var txt := "F U S I O N !"
	var sz: int = roundi(clampf(vp.x / 11.0, 34.0, 96.0) * (1.0 + 0.25 * (1.0 - fin)) * TXS.k())
	var wob: float = 1.0 + 0.04 * sin(tt * 14.0)
	var fs: int = roundi(float(sz) * wob)
	var pos := Vector2(0.0, cy + float(fs) * 0.33)
	draw_string_outline(f, pos + Vector2(0.0, 5.0), txt, HORIZONTAL_ALIGNMENT_CENTER, vp.x, fs, 14, Color(0.25, 0.0, 0.35, al))
	draw_string_outline(f, pos, txt, HORIZONTAL_ALIGNMENT_CENTER, vp.x, fs, 10, Color(1.0, 0.45, 0.85, al))
	draw_string(f, pos, txt, HORIZONTAL_ALIGNMENT_CENTER, vp.x, fs, Color(1.0, 0.97, 0.8, al))
	if fusion_name != "":
		draw_string_outline(f, Vector2(0.0, cy + 62.0), fusion_name, HORIZONTAL_ALIGNMENT_CENTER, vp.x, roundi(26.0 * TXS.k()), 6, Color(0.1, 0.0, 0.2, al))
		draw_string(f, Vector2(0.0, cy + 62.0), fusion_name, HORIZONTAL_ALIGNMENT_CENTER, vp.x, roundi(26.0 * TXS.k()), Color(1.0, 0.9, 0.5, al))

var ch_lines: Array = []

var ch_mode := false

func act_rect() -> Rect2:
	var vp: Vector2 = get_viewport_rect().size
	var ins: Vector4 = DSP.insets(get_tree())

	var left: bool = int(SV.d["settings"].get("act_side", 0)) == 1
	var ax: float = (26.0 + ins.x) if left else (vp.x - 126.0 - ins.z)
	return Rect2(ax, vp.y * 0.5 - 50.0, 100.0, 100.0)

func draw_poi(font: Font, vp: Vector2) -> void :
	for mk in poi_marks:
		var sp: Vector2 = mk["sp"]
		var col: Color = mk["col"]
		var on: bool = Rect2(Vector2(30, 70), vp - Vector2(60, 140)).has_point(sp)
		if on:
			_ds(font, sp + Vector2(-120, -28), String(mk["txt"]), HORIZONTAL_ALIGNMENT_CENTER, 240.0, 18, col)
		else:
			var c: Vector2 = vp * 0.5
			var dir: Vector2 = (sp - c).normalized()
			var q: Vector2 = Vector2(clampf(sp.x, 40.0, vp.x - 40.0), clampf(sp.y, 90.0, vp.y - 90.0))
			draw_circle(q, 18.0, Color(0, 0, 0, 0.6))
			draw_colored_polygon(PackedVector2Array([q + dir * 14.0, q + dir.rotated(2.5) * 12.0, q + dir.rotated(-2.5) * 12.0]), col)
	if act_txt != "":
		var r: Rect2 = act_rect()
		var c2: Vector2 = r.position + r.size * 0.5
		var beat: float = 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.006)
		draw_circle(c2, 52.0 + beat * 5.0, Color(1, 0.85, 0.3, 0.22 + 0.2 * beat))
		draw_circle(c2, 46.0, Color(0.1, 0.07, 0.02, 0.9))
		draw_arc(c2, 46.0, 0.0, TAU, 40, Color("#ffd23f"), 4.0)
		_ds(font, Vector2(c2.x - 44.0, c2.y + 10.0), act_txt, HORIZONTAL_ALIGNMENT_CENTER, 88.0, 26, Color.WHITE)
