class_name Prof
extends RefCounted
# Mini-profiler estático por sistemas (microsegundos). Solo mide con Prof.on (lo activa keys_only.gd en consola
# o con --keys-only); apagado cuesta un solo if. end_frame() lo llama keys_only al final del fotograma.

const S_WORLD := 0
const S_SPAWN := 1
const S_ENEMIES := 2
const S_HAZ_EB := 3
const S_FIELDS := 4
const S_BULLETS := 5
const S_ORBS := 6
const S_CLEAN := 7
const S_PLAYER := 8
const S_HUD := 9
const S_CHUNK := 10
const S_FX := 11
const S_TOTAL := 12
const S_ACTOR := 13
const NAMES: Array[String] = ["мир", "спавн", "враги", "опасн+вр_снаряды", "поля", "снаряды", "орбы", "очистка", "игрок", "худ", "куски", "эффекты", "всего", "актёры_визуал"]

# _draw() по классам: GDScript-рисование выполняется внутри TIME_PROCESS, но вне кругов S_* выше — именно оно и пряталось в «скрипты» >> «всего».
const D_ENEMY := 0
const D_BULLET := 1
const D_EBULLET := 2
const D_HAZARD := 3
const D_FX := 4
const D_FIELD := 5
const D_ORB := 6
const D_FLOATER := 7
const D_GROUND := 8
const D_DECOR := 9
const D_POOL := 10
const D_PROP := 11
const D_PFX := 12
const D_CHUNK := 13
const D_GRASS := 14
const D_HUD := 15
const D_MINIMAP := 16
const D_SLOTS := 17
const D_STICK := 18
const D_NAMES: Array[String] = ["враги", "пули", "вр_пули", "опасности", "fx", "поля", "орбы", "цифры", "земля", "декор", "лужи", "пропы", "частицы", "куски_пола", "трава", "худ", "миникарта", "слоты", "стик"]

static var on := false
static var cur := PackedInt64Array()
static var last := PackedInt64Array()
static var sum := PackedInt64Array()
static var mx := PackedInt64Array()
static var frames := 0
static var n_enemies := 0
static var n_bullets := 0
static var n_ebullets := 0
static var n_orbs := 0
static var n_fx := 0
static var perf_lv := 0          # Rendimiento activo (main.apply_perf)
static var n_bullets_cut := 0    # disparos propios quitados por el tope de Rendimiento en este juego
# trozos de suelo (los escribe tileworld.gd)
static var ch_vis_missing := 0   # trozos visibles sin textura ahora mismo
static var ch_vis_total := 0     # observaciones acumuladas durante la partida
static var ch_vis_n := 0
static var ch_n := 0
static var ch_n_max := 0
static var ch_sync_n := 0        # docrutas sincronas (esperar una tarea o hornear en el principal)
static var ch_sync_us := 0
static var ch_sync_max := 0
static var ch_sync_last := 0     # us gastados en docrutas en el ultimo fotograma
static var bk_workers := 0       # tareas a la vez (0 = horneado sincrono)
static var bk_task_n := 0
static var bk_task_us := 0
static var bk_pauses := 0
static var pfx_us := 0
static var pfx_max := 0
static var pfx_n := 0
static var pfx_parts_max := 0
static var pfx_sprites_max := 0
# _draw по классам: за период / за последний кадр
static var d_sum := PackedInt64Array()
static var d_cnt := PackedInt64Array()
static var d_max := PackedInt64Array()
static var d_cur := PackedInt64Array()
static var d_last := PackedInt64Array()
# данные для журнала событий: забег идёт / пики за забег
static var run_active := false
static var peak_enemies := 0
static var peak_bullets := 0
static var peak_orbs := 0
static var peak_fx := 0
static var peak_draw := 0
static var peak_nodes := 0


static func _init_arrays() -> void:
	if cur.size() != NAMES.size():
		cur.resize(NAMES.size())
		last.resize(NAMES.size())
		sum.resize(NAMES.size())
		mx.resize(NAMES.size())


# Suma now-t0 a la sección i y devuelve now (para encadenar)
static func lap(i: int, t0: int) -> int:
	var t := Time.get_ticks_usec()
	if cur.size() != NAMES.size():
		_init_arrays()
	cur[i] += t - t0
	return t


static func _init_d() -> void:
	var n: int = D_NAMES.size()
	d_sum.resize(n)
	d_cnt.resize(n)
	d_max.resize(n)
	d_cur.resize(n)
	d_last.resize(n)


static func dbegin() -> int:
	return Time.get_ticks_usec() if on else 0


static func dend(i: int, t0: int) -> void:
	if t0 == 0:
		return
	if d_sum.size() != D_NAMES.size():
		_init_d()
	var d: int = Time.get_ticks_usec() - t0
	d_sum[i] += d
	d_cnt[i] += 1
	d_cur[i] += d
	if d > d_max[i]:
		d_max[i] = d


static func end_frame() -> void:
	if cur.size() != NAMES.size():
		_init_arrays()
	if d_sum.size() != D_NAMES.size():
		_init_d()
	for j in range(D_NAMES.size()):
		d_last[j] = d_cur[j]
		d_cur[j] = 0
	for i in range(NAMES.size()):
		var v: int = cur[i]
		sum[i] += v
		if v > mx[i]:
			mx[i] = v
		last[i] = v
		cur[i] = 0
	frames += 1


static func reset_period() -> void:
	_init_arrays()
	for i in range(NAMES.size()):
		sum[i] = 0
		mx[i] = 0
	frames = 0
	if d_sum.size() != D_NAMES.size():
		_init_d()
	for j in range(D_NAMES.size()):
		d_sum[j] = 0
		d_cnt[j] = 0
		d_max[j] = 0
	pfx_us = 0
	pfx_max = 0
	pfx_n = 0
	pfx_parts_max = 0
	pfx_sprites_max = 0


static func add_pfx_time(us: int, parts_n: int, sprites_n: int) -> void:
	pfx_us += us
	pfx_max = maxi(pfx_max, us)
	pfx_n += 1
	pfx_parts_max = maxi(pfx_parts_max, parts_n)
	pfx_sprites_max = maxi(pfx_sprites_max, sprites_n)


static func _fmt(a: PackedInt64Array, div: float) -> String:
	_init_arrays()
	var s := ""
	for i in range(NAMES.size()):
		if a[i] > 0 or i == S_TOTAL:
			s += "%s=%.1f " % [NAMES[i], float(a[i]) / div / 1000.0]
	return s.strip_edges()


static func line_avg() -> String:
	return _fmt(sum, float(maxi(1, frames)))


static func line_max() -> String:
	return _fmt(mx, 1.0)


# Fotograma anterior ya cerrado (end_frame lo copia en last)
static func line_cur() -> String:
	return _fmt(last, 1.0)


static func line_counts() -> String:
	var pfx_avg: float = float(pfx_us) / 1000.0 / maxf(1.0, float(pfx_n))
	return "счётчики: perf=%d врагов=%d снарядов=%d(срезано %d) вражьих_снарядов=%d орбов=%d эффектов=%d | PFX=%.2f/%.2f мс частей=%d спрайтов=%d | %s" % [perf_lv, n_enemies, n_bullets, n_bullets_cut, n_ebullets, n_orbs, n_fx, pfx_avg, float(pfx_max) / 1000.0, pfx_parts_max, pfx_sprites_max, line_chunks()]


static func line_chunks() -> String:
	return "куски=%d(макс %d) пустых_видимых=%d/накоплено%d докруток=%d(%.1f мс, макс %.1f) задач=%d задача_ср=%.1f мс пауз_запекания=%d" % [ch_n, ch_n_max, ch_vis_missing, ch_vis_total, ch_sync_n, float(ch_sync_us) / 1000.0, float(ch_sync_max) / 1000.0, bk_workers, float(bk_task_us) / 1000.0 / maxf(1.0, float(bk_task_n)), bk_pauses]


# Время _draw по классам за период: мс/кадр | вызовов/кадр | макс. мс одного вызова
static func line_draw() -> String:
	if d_sum.size() != D_NAMES.size():
		_init_d()
	var f: float = float(maxi(1, frames))
	var s := ""
	var tot := 0.0
	for i in range(D_NAMES.size()):
		if d_cnt[i] > 0:
			s += "%s=%.1f|%d|%.1f " % [D_NAMES[i], float(d_sum[i]) / f / 1000.0, int(round(float(d_cnt[i]) / f)), float(d_max[i]) / 1000.0]
			tot += float(d_sum[i]) / f / 1000.0
	return "рисование_gd(мс/кадр|вызовов/кадр|макс): %s | сумма=%.1f мс" % [s.strip_edges(), tot]


# То же для последнего закрытого кадра (для строки рывка)
static func line_draw_cur() -> String:
	if d_last.size() != D_NAMES.size():
		return ""
	var s := ""
	for i in range(D_NAMES.size()):
		if d_last[i] > 0:
			s += "%s=%.1f " % [D_NAMES[i], float(d_last[i]) / 1000.0]
	return s.strip_edges()
