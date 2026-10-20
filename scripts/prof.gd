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
const NAMES: Array[String] = ["мир", "спавн", "враги", "опасн+вр_снаряды", "поля", "снаряды", "орбы", "очистка", "игрок", "худ", "куски", "эффекты", "всего"]

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
# trozos de suelo (los escribe tileworld.gd; acumulados de toda la partida, no se reinician con reset_period)
static var ch_vis_missing := 0   # trozos visibles temporalmente sin textura, sumados por fotograma
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
static var bk_rollbacks := 0


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


static func end_frame() -> void:
	if cur.size() != NAMES.size():
		_init_arrays()
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
	return "счётчики: врагов=%d снарядов=%d вражьих_снарядов=%d орбов=%d эффектов=%d | %s" % [n_enemies, n_bullets, n_ebullets, n_orbs, n_fx, line_chunks()]


static func line_chunks() -> String:
	return "куски=%d(макс %d) видимых_без_текстуры=%d докруток=%d(%.1f мс, макс %.1f) воркеров=%d задача_ср=%.1f мс откатов=%d" % [ch_n, ch_n_max, ch_vis_missing, ch_sync_n, float(ch_sync_us) / 1000.0, float(ch_sync_max) / 1000.0, bk_workers, float(bk_task_us) / 1000.0 / maxf(1.0, float(bk_task_n)), bk_rollbacks]
