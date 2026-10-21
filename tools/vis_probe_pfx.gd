extends "res://scripts/pfx.gd"
# Зонд для tools/vischeck.gd: тот же pfx.gd, но считает каждый запрошенный эффект (по источнику вызова),
# отброшенные лимитами и те, что ни разу не попали в _draw() за свою жизнь. Ставится вместо скрипта pfx на лету.
# Только для проверки: get_stack() работает в отладочной сборке (редактор/CLI godot).

const ABIL := {"_melee": 1, "_beam": 1, "_aura": 1, "_buff": 1, "_chain": 1, "_dash": 1, "_nova": 1, "_fire_projectiles": 1,
	"_cone": 1, "_turret": 1, "_mines": 1, "_meteors": 1, "_update_fields": 1, "_trail_patch": 1, "_set_active": 1, "_evolve": 1}

var view := Rect2()          # прямоугольник камеры в мировых координатах (ставит vischeck каждый кадр)
var stats := {}              # ctx -> {req, drop, undrawn, offscreen, draws, frames}
var tracked: Array = []      # [entry, ctx, frame0, onscreen]
var phase_tag := ""         # фаза сценария vischeck (префикс ключа статистики)
var ghost_frames := 0        # кадров, когда массивы пусты, а на экране ещё висит старый рисунок
var _drawn_nonempty := false
var _frame := 0
var _empty_n := 0


func _ctx() -> String:
	for f in get_stack():
		var fn: String = String(f["function"])
		var src: String = String(f["source"])
		if src.ends_with("zmove.gd"):
			return "zmove"
		if src.ends_with("dynamax.gd"):
			return "dynamax"
		if src.ends_with("judgment.gd"):
			return "judgment"
		if ABIL.has(fn):
			return "ability"
		if fn == "_update_enemies" or fn == "_cc_fx":
			return "status"
		if fn == "_damage_enemy" or fn == "_hit_enemy" or fn == "_bullet_hit":
			return "hit"
	return "other"


func _st(ctx: String) -> Dictionary:
	if not stats.has(ctx):
		stats[ctx] = {"req": 0, "drop": 0, "undrawn": 0, "offscreen": 0, "draws": 0, "frames": 0}
	return stats[ctx]


func _track(arr: Array, n0: int, kind: String, pos: Vector2) -> void:
	var ctx: String = phase_tag + "|" + kind + ":" + _ctx()
	var s: Dictionary = _st(ctx)
	s["req"] += 1
	if arr.size() <= n0:
		s["drop"] += 1
		return
	var e: Dictionary = arr[arr.size() - 1]
	e["_d"] = 0
	tracked.append([e, ctx, _frame, view.has_point(pos)])


func sp(shape: String, pal: String, pos: Vector2, o: Dictionary = {}) -> void:
	var n0 := sprs.size()
	super.sp(shape, pal, pos, o)
	_track(sprs, n0, "sprite", pos)


func ring(pos: Vector2, r0: float, r1: float, color: Color, life: float = 0.3, width: float = 3.0) -> void:
	var n0 := rings.size()
	super.ring(pos, r0, r1, color, life, width)
	_track(rings, n0, "ring", pos)


func slash(pos: Vector2, angle: float, radius: float, arc: float, vis: Dictionary) -> void:
	var n0 := slashes.size()
	super.slash(pos, angle, radius, arc, vis)
	_track(slashes, n0, "slash", pos)


func beam(pos: Vector2, angle: float, length: float, width: float, vis: Dictionary) -> void:
	var n0 := beams.size()
	super.beam(pos, angle, length, width, vis)
	_track(beams, n0, "beam", pos)


func px(pos: Vector2, color: Color, vel: Vector2 = Vector2.ZERO, life: float = 0.4, size: float = 1.0, grav: float = 0.0, drag: float = 0.9, force: bool = false) -> void:
	var n0 := parts.size()
	super.px(pos, color, vel, life, size, grav, drag, force)
	var kind := "pxforce" if force else "px"
	# частицы не отслеживаются поштучно (их тысячи): только запрошено/отброшено
	var ctx: String = phase_tag + "|" + kind + ":" + _ctx()
	var s: Dictionary = _st(ctx)
	s["req"] += 1
	if parts.size() <= n0:
		s["drop"] += 1


func _process(delta: float) -> void:
	_frame += 1
	super._process(delta)
	for i in range(tracked.size() - 1, -1, -1):
		var tr: Array = tracked[i]
		var e: Dictionary = tr[0]
		if float(e["t"]) >= float(e["life"]):
			var s: Dictionary = _st(String(tr[1]))
			if not bool(tr[3]):
				s["offscreen"] += 1
			elif int(e["_d"]) == 0:
				s["undrawn"] += 1
			s["draws"] += int(e["_d"])
			s["frames"] += maxi(1, _frame - int(tr[2]))
			tracked.remove_at(i)
	# «призрак»: эффектов нет уже второй кадр подряд, а последний рисунок ещё с эффектами (не стёрт)
	if parts.is_empty() and sprs.is_empty() and rings.is_empty() and slashes.is_empty() and beams.is_empty() and _drawn_nonempty:
		_empty_n += 1
		if _empty_n >= 2:
			ghost_frames += 1
	else:
		_empty_n = 0


func clear() -> void:
	super.clear()
	tracked.clear()   # смена сцены/забега: незавершённые не считаются


func _draw() -> void:
	super._draw()
	_drawn_nonempty = not (parts.is_empty() and sprs.is_empty() and rings.is_empty() and slashes.is_empty() and beams.is_empty())
	for arr in [sprs, rings, slashes, beams]:
		for e in arr:
			if e.has("_d"):
				e["_d"] = int(e["_d"]) + 1
