extends SceneTree
# Матрица режимов: один забег main.tscn с ботом, который ходит (бродит, длинные пробежки через куски, возвраты),
# сам выбирает карточки (уровни, слияния, связи, предметы, отдых Башни), заходит в разломы, дерётся с боссами.
# Ищет зависания и поломки; ошибки скриптов ловит обёртка tools/mode_matrix.sh по stderr Godot.
#   godot --headless --path . --fixed-fps 30 --script res://tools/mode_matrix.gd -- --keys-only \
#         --mode rush --dex 4 --seed 3 --secs 600 [--god 1] [--ts 1] [--verbose]
# --fixed-fps 30: каждое обновление = 1/30 с игрового времени, сколько бы оно ни шло на самом деле — headless гонит быстрее
# реального времени (это и есть «ускорение»), а логика видит обычный шаг. --ts N дополнительно ставит Engine.time_scale (крупнее шаг).
# В конце строка MATRIX_RESULT {...}: ok, проблемы (issues), счётчики. Работает и на ветке main (без loading_done и т.п.).
# Режимы: normal daily rush party type team coop rifts tower.

const FPS := 30.0
const HITCH_MS := 100.0

var m: Node
var MODE := _arg_s("--mode", "normal")
var DEX := _arg_i("--dex", 4)
var SEED := _arg_i("--seed", 1)
var SECS := _arg_f("--secs", 600.0)       # игровых секунд забега
var GOD := _arg_i("--god", 1) == 1        # не даём умереть (лечим при <30%), чтобы дойти до поздних этапов; смерти считаются
var TS := _arg_f("--ts", 1.0)
var META := _arg_s("--meta", "zero")   # zero | mid | max — профиль мета-прогресса (временный, в памяти)
var VERBOSE := "--verbose" in OS.get_cmdline_user_args()
var PROBE := "--probe" in OS.get_cmdline_user_args()
var rng := RandomNumberGenerator.new()

var issues: Array = []          # [{kind, t, info}]
var issue_kinds := {}
var frame := 0
var loaded_frame := -1
var load_frames := 0
var last_us := 0
var hitches: Array = []         # [t, ms]
var worst_ms := 0.0
var wall_t0 := 0

# бот
var seg := ""
var seg_t := 0.0
var target := Vector2.ZERO
var dir := Vector2.RIGHT
var trail: Array = []           # позиции раз в 5 с для возвратов
var stuck_t := 0.0
var last_pos := Vector2.ZERO
var dist_total := 0.0
var max_from_origin := 0.0
var cards_open_frames := 0
var cards_picked := 0
var z_used := 0
var dyn_used := 0
var rift_entered := 0
var near_deaths := 0

# сторожа
var last_rt := 0.0
var rt_still := 0
var no_enemy_t := 0.0
var no_boss_t := 0.0
var boss_ref = null
var boss_best_hp := 0.0
var boss_hp_still_t := 0.0
var boss_alive_t := 0.0
var bosses_seen := 0
var boss_spawn_times: Array = []
var arena_t := 0.0
var tw_floor_t := 0.0
var tw_floor_last := 1
var biome_seen: Array = []
var biome_bad_t := 0.0
var blank_frames := 0
var blank_run := 0
var blank_run_max := 0
var paused_frames := 0
var cine_frames := 0
var last_kills := 0
var kills_still_t := 0.0
var ended := ""


static func _arg_s(n: String, d: String) -> String:
	var a := OS.get_cmdline_user_args()
	var i := a.find(n)
	return String(a[i + 1]) if i >= 0 and i + 1 < a.size() else d


static func _arg_i(n: String, d: int) -> int:
	return int(_arg_s(n, str(d)))


static func _arg_f(n: String, d: float) -> float:
	return float(_arg_s(n, str(d)))


func _g(o: Object, k: String, d = null):
	if o == null or not (k in o):
		return d
	return o.get(k)


func _initialize() -> void:
	rng.seed = SEED * 7907 + DEX
	seed(SEED)
	var MS = load("res://scripts/main.gd")
	if "bench_seed_override" in MS:
		MS.bench_seed_override = SEED
	var SVl = load("res://scripts/save_data.gd")
	# Сохранение игрока не читаем и не пишем никогда: профиль собирается в памяти из default_data(),
	# save_blocked не даёт SV.save() ничего записать (а обёртка ещё и подменяет HOME на временный).
	SVl.load_dex()
	SVl.loaded = true
	SVl.d = SVl.default_data()
	if "save_blocked" in SVl:
		SVl.save_blocked = true
	_apply_meta(SVl)
	SVl.run_mode = MODE
	SVl.run_dex = DEX
	SVl.party_dex = DEX
	SVl.run_mods = []
	SVl.run_type = _type_of(SVl, DEX)
	if MODE == "team":
		SVl.d["team"] = [DEX]   # остальные двое — из owned (team_list)
	if "daily_seed_override" in SVl:
		SVl.daily_seed_override = 20260000 + SEED * 37 + DEX   # ежедневный: разный «случайный» покемон по сиду
	Engine.time_scale = TS
	m = load("res://scenes/main.tscn").instantiate()
	root.add_child(m)
	last_us = Time.get_ticks_usec()
	wall_t0 = last_us
	print("MATRIX_START mode=%s dex=%d seed=%d meta=%s secs=%.0f god=%s ts=%.1f" % [MODE, DEX, SEED, META, SECS, GOD, TS])


# Мета-прогресс: zero — свежее сохранение (ничего не куплено/открыто); mid — средняя прокачка после ~20 забегов;
# max — всё куплено до предела, открыты Z-движения всех типов и Динамакс, все стартёры, реликвии Башни, сотни забегов.
func _apply_meta(SVl) -> void:
	var d: Dictionary = SVl.d
	var k: float = {"zero": 0.0, "mid": 0.5, "max": 1.0}.get(META, 0.0)
	d["selected"] = DEX
	if not d["owned"].has(str(DEX)):
		d["owned"][str(DEX)] = {"shiny": false}
	if k <= 0.0:
		return
	var pup := {}
	for u in SVl.UPGRADES:
		pup[String(u["id"])] = int(floorf(float(u["max"]) * k))
	d["pup"][str(DEX)] = pup
	var st: Dictionary = d["stats"]
	var runs: int = 20 if k < 1.0 else 300
	st["runs"] = runs
	st["kills"] = runs * 400
	st["bosses"] = runs * 2
	st["best_time"] = 600 if k < 1.0 else 1800
	st["best_level"] = 25 if k < 1.0 else 60
	for s in SVl.STARTERS_D.STARTERS:
		d["owned"][str(int(s["dex"]))] = {"shiny": k >= 1.0}
	if k >= 1.0:
		d["shiny_on"] = true
		d["owned"][str(DEX)]["shiny"] = true
		st["dens"] = 5
		for ty in ["normal", "fire", "water", "grass", "electric", "ice", "fighting", "poison", "ground", "flying", "psychic", "bug", "rock", "ghost", "dragon", "dark", "steel", "fairy"]:
			st["tk_" + ty] = 999
		var tm: Array = SVl.tm_pool(DEX)
		if not tm.is_empty():
			d["ptm"][str(DEX)] = String(tm[rng.randi() % tm.size()])
		var cl := {}
		for f in range(1, 26):
			cl[str(f)] = true
		d["tower"] = {"claimed": cl, "best": 25}
	else:
		var ty0: String = _type_of(SVl, DEX)
		st["tk_" + ty0] = 999   # Z-движение своего типа открыто


func _type_of(SVl, dex: int) -> String:
	if SVl.dex_by.has(dex):
		return String((SVl.dex_by[dex]["types"] as Array)[0])
	return "fire"


func _issue(kind: String, info: String) -> void:
	var t: float = float(_g(m, "run_time", 0.0))
	issue_kinds[kind] = int(issue_kinds.get(kind, 0)) + 1
	if int(issue_kinds[kind]) <= 3:
		issues.append({"kind": kind, "t": snappedf(t, 0.1), "info": info})
		print("ISSUE %s t=%.1f %s" % [kind, t, info])


func _state() -> String:
	var p = _g(m, "player")
	var cards = _g(m, "cards")
	return "choosing=%s cards_open=%s items=%d paused=%s dead=%s down=%s arena=%s arena_down=%s z=%s jdcine=%s enemies=%d boss_alive=%s rush_i=%s rush_rest=%s tw_floor=%s tw_phase=%s biome=%s fade=%s" % [
		_g(m, "choosing"), _g(cards, "open"), (_g(cards, "items", []) as Array).size(), _g(m, "paused"), _g(p, "dead"), _g(m, "down"),
		_g(m, "arena") != null, _g(m, "arena_down"), _g(m, "z_state"), (m.jd.cinematic() if _g(m, "jd") != null else false),
		(_g(m, "enemies", []) as Array).size(), m._boss_alive(), _g(m, "rush_i"), _g(m, "rush_rest"), _g(m, "tw_floor"), _g(m, "tw_phase"),
		_g(m, "biome_idx"), _g(_g(m, "ground"), "fade_t")]


func _process(delta: float) -> bool:
	var now := Time.get_ticks_usec()
	var ms: float = (now - last_us) / 1000.0
	last_us = now
	frame += 1
	var loaded: bool = bool(_g(m, "loading_done", true)) and _g(m, "player") != null and _g(m, "hud") != null
	if not loaded:
		load_frames += 1
		if load_frames > 6000:
			_issue("LOAD_STALL", "загрузка не закончилась за 6000 кадров")
			return _finish("load")
		return false
	if loaded_frame < 0:
		loaded_frame = frame
		last_pos = m.player.position
		print("MATRIX_LOADED frames=%d dex=%d mode=%s types=%s" % [load_frames, int(load("res://scripts/save_data.gd").run_dex), _g(m, "mode"), m.player.types])
		return false
	var rt: float = float(m.run_time)
	# кадр дольше 100 мс (после 2 с игры: прогрев загрузки не считаем)
	if frame - loaded_frame > 60 and ms > HITCH_MS:
		hitches.append([snappedf(rt, 0.1), snappedf(ms, 0.1)])
		if hitches.size() <= 5:
			print("HITCH t=%.1f %.1f мс %s" % [rt, ms, _state()])
	if frame - loaded_frame > 60:
		worst_ms = maxf(worst_ms, ms)
	if m.player.dead:
		if GOD and not bool(_g(m, "timeup", false)):
			_issue("PLAYER_DEAD_GOD", "игрок умер несмотря на бота: " + _state())
		return _finish("dead" if not bool(_g(m, "timeup", false)) else "timeup")
	_bot(delta)
	_watch(delta, rt)
	if rt >= SECS:
		return _finish("secs")
	if (Time.get_ticks_usec() - wall_t0) / 1e6 > maxf(900.0, SECS * 1.5):
		_issue("WALL_TIMEOUT", "слишком долго по реальному времени " + _state())
		return _finish("wall")
	return false


# ---------------- бот ----------------
func _press(v: Vector2) -> void:
	for a in ["move_left", "move_right", "move_up", "move_down"]:
		Input.action_release(a)
	if v.length() < 0.05:
		return
	v = v.normalized()
	if v.x < 0.0:
		Input.action_press("move_left", -v.x)
	elif v.x > 0.0:
		Input.action_press("move_right", v.x)
	if v.y < 0.0:
		Input.action_press("move_up", -v.y)
	elif v.y > 0.0:
		Input.action_press("move_down", v.y)


func _new_seg(pp: Vector2) -> void:
	var r := rng.randf()
	var fighty: bool = MODE == "rush" or MODE == "tower" or m._boss_alive()
	if fighty and r < 0.7:
		seg = "fight"
		seg_t = rng.randf_range(4.0, 10.0)
	elif r < 0.35:
		seg = "fight"
		seg_t = rng.randf_range(3.0, 8.0)
	elif r < 0.65:
		seg = "wander"
		target = pp + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(200.0, 900.0)
		seg_t = 6.0
	elif r < 0.88:
		seg = "long"   # длинная пробежка через несколько кусков
		dir = Vector2.from_angle(rng.randf() * TAU)
		seg_t = rng.randf_range(8.0, 20.0)
	else:
		seg = "back"   # возврат туда, где были 30-60 с назад (старые куски должны снова появиться)
		target = trail[maxi(0, trail.size() - 1 - rng.randi_range(6, 12))] if trail.size() > 3 else Vector2.ZERO
		seg_t = 15.0


func _nearest(pp: Vector2, boss_only: bool):
	var best = null
	var bd := 1e18
	for e in m.enemies:
		if e.dead or (boss_only and not e.boss):
			continue
		var d2: float = pp.distance_squared_to(e.position)
		if d2 < bd:
			bd = d2
			best = e
	return best


func _bot(delta: float) -> void:
	var p = m.player
	if GOD:
		if p.hp < p.max_hp * 0.5:
			near_deaths += 1
			p.hp = p.max_hp
		if int(_g(m, "revives", 0)) < 50:   # смертельный удар одним попаданием: срабатывает обычное «воскрешение» игры
			m.revives = 99
	if bool(_g(m, "paused", false)) and not bool(_g(m, "settings_open", false)):
		paused_frames += 1
		m.paused = false
	var cards = _g(m, "cards")
	if cards != null and bool(_g(cards, "open", false)):
		cards_open_frames += 1
		if cards_open_frames % 9 == 4:   # «читает» ~0.3 с, потом выбирает
			var items: Array = _g(cards, "items", [])
			if items.size() > 0:
				cards._pick(rng.randi() % items.size())
				cards_picked += 1
		_press(Vector2.ZERO)
		return
	cards_open_frames = 0
	if not bool(_g(m, "choosing", false)) and rng.randf() < 0.003:
		if "z_req" in m and m.has_method("_z_can") and m._z_can():
			m.z_req = true
			z_used += 1
		elif "dyn_req" in m and m.has_method("_dyn_can") and m._dyn_can():
			m.dyn_req = true
			dyn_used += 1
	_slot_ai(delta)
	var pp: Vector2 = p.position
	if frame % 150 == 0:
		trail.append(pp)
	seg_t -= delta
	# разлом: заходим, если открыт и не идёт бой с боссом
	var rift = _g(m, "rift")
	if rift != null and is_instance_valid(rift) and _g(m, "arena") == null and not m._boss_alive() and seg != "rift" and rng.randf() < 0.02:
		seg = "rift"
		seg_t = 25.0
	if seg_t <= 0.0 or seg == "":
		_new_seg(pp)
	# Сбор: после босса (и иногда в обычном бою) идём к ближайшему орбу опыта/предмету/лечению, как игрок
	if not m._boss_alive() and seg != "rift" and seg != "collect" and frame % 15 == 0 and (MODE == "rush" or rng.randf() < 0.15):
		var o = _nearest_orb(pp, 900.0)
		if o != null:
			seg = "collect"
			seg_t = 6.0
	# Бой с боссом: игрок держится рядом (иначе босс просто ходит за ним кругами), кроме короткого выхода из застревания
	if m._boss_alive() and seg != "fight" and seg != "rift" and not (seg == "long" and seg_t < 5.0 and stuck_escape):
		seg = "fight"
		seg_t = rng.randf_range(6.0, 12.0)
	var v := Vector2.ZERO
	match seg:
		"fight":
			var e = _nearest(pp, m._boss_alive())
			if e == null:
				e = _nearest(pp, false)
			if e == null:
				v = Vector2.from_angle(frame * 0.01)
			else:
				var to: Vector2 = e.position - pp
				var dd := to.length()
				var want: float = _want_dist()
				var tang: Vector2 = to.orthogonal().normalized() * (1.0 if (SEED & 1) == 0 else -1.0)
				if dd > want + 60.0:
					v = to.normalized() + tang * 0.3
				elif dd < want - 60.0:
					v = -to.normalized() + tang * 0.5
				else:
					v = tang
		"wander", "back":
			v = target - pp
			if v.length() < 40.0:
				seg_t = 0.0
		"long":
			v = dir
		"collect":
			var o = _nearest_orb(pp, 900.0)
			if o == null:
				seg_t = 0.0
			else:
				v = o.position - pp
		"rift":
			if rift == null or not is_instance_valid(rift):
				seg_t = 0.0
			else:
				v = rift.global_position - pp
	# застрял (стена/вода): новый отрезок
	var moved := pp.distance_to(last_pos)
	dist_total += moved
	max_from_origin = maxf(max_from_origin, pp.length())
	if v.length() > 0.1 and moved < 0.3:
		stuck_t += delta
		if stuck_t > 1.5:
			stuck_t = 0.0
			stuck_escape = true
			seg = "long"
			dir = Vector2.from_angle(rng.randf() * TAU)
			seg_t = rng.randf_range(2.0, 5.0)
	else:
		stuck_t = 0.0
	if seg != "long":
		stuck_escape = false
	last_pos = pp
	_press(v)


# Как игрок: переключает активный слот (стреляет только активная группа). Слот из одних «buff» не наносит урона —
# с него уходим сразу; иначе раз в 6-12 с (и чаще, если босс не получает урона) выбираем другой атакующий слот.
var stuck_escape := false
func _nearest_orb(pp: Vector2, r: float):
	var best = null
	var bd := r * r
	for o in _g(m, "orbs", []):
		if not is_instance_valid(o) or String(_g(o, "kind", "")) == "coin":
			continue
		var d2: float = pp.distance_squared_to(o.position)
		if d2 < bd:
			bd = d2
			best = o
	return best


# Дистанция боя по активным движениям: ближние (удар, рывок, конус, орбита, аура, вспышка, след, мина) — вплотную.
func _want_dist() -> float:
	var MDl = load("res://scripts/moves_data.gd")
	for mv in m._active_group():
		var k: String = String(MDl.MOVES.get(String(mv["id"]), {}).get("kind", ""))
		if k in ["melee", "dash", "cone", "orbit", "aura", "nova", "trail", "mine"]:
			return 80.0
	return 190.0


var slot_t := 0.0
var slot_switches := 0
func _slot_ai(delta: float) -> void:
	if not m.has_method("_slot_list"):
		return
	var sl: Array = m._slot_list()
	if sl.size() < 2:
		return
	var MDl = load("res://scripts/moves_data.gd")
	var atk: Array = []
	for i in range(sl.size()):
		for mv in sl[i]:
			var md: Dictionary = MDl.MOVES.get(String(mv["id"]), {})
			if String(md.get("kind", "")) != "buff":
				atk.append(i)
				break
	if atk.is_empty():
		return
	slot_t -= delta
	var cur: int = int(m.player.slot)
	if not atk.has(cur) or slot_t <= 0.0 or (boss_hp_still_t > 6.0 and slot_t < 4.0):
		var nxt: int = atk[rng.randi() % atk.size()]
		if nxt != cur:
			m._set_active(nxt)
			slot_switches += 1
		slot_t = rng.randf_range(6.0, 12.0)


# ---------------- сторожа ----------------
func _watch(delta: float, rt: float) -> void:
	var choosing: bool = bool(_g(m, "choosing", false))
	var cine: bool = str(_g(m, "z_state", "")) == "cine" or (m.jd.cinematic() if _g(m, "jd") != null else false)
	if cine:
		cine_frames += 1
	# 1) игровое время стоит
	if rt <= last_rt + 1e-6:
		rt_still += 1
		if rt_still == int(FPS * 20):
			_issue("TIME_STALL", "run_time не идёт 20 с: " + _state())
	else:
		rt_still = 0
	last_rt = rt
	# 2) карточки висят
	if cards_open_frames > int(FPS * 10) and cards_open_frames % int(FPS * 10) == 1:
		_issue("CARDS_STUCK", "карточки открыты >10 с: " + _state())
	if choosing and _g(m.cards, "open", true) == false:
		no_enemy_t += 0.0
		if rt_still > int(FPS * 5) and rt_still % int(FPS * 5) == 0:
			_issue("CHOOSING_NO_CARDS", "choosing=true, но карточек нет: " + _state())
	if rt_still > 0:
		return
	var arena = _g(m, "arena")
	var in_arena: bool = arena != null
	var balive: bool = m._boss_alive()
	# 3) враги
	var ne: int = m.enemies.size()
	if MODE != "rush" and MODE != "tower" and not in_arena and rt > 30.0:
		if ne == 0:
			no_enemy_t += delta
			if no_enemy_t > 20.0 and int(no_enemy_t * FPS) % int(FPS * 20) == 0:
				_issue("NO_ENEMIES", "нет врагов %.0f с: %s" % [no_enemy_t, _state()])
		else:
			no_enemy_t = 0.0
	if not in_arena and rt > 60.0 and MODE != "rush" and MODE != "tower":
		if m.kills == last_kills:
			kills_still_t += delta
			if kills_still_t > 60.0 and int(kills_still_t * FPS) % int(FPS * 60) == 0:
				_issue("NO_KILLS", "нет убийств %.0f с: %s" % [kills_still_t, _state()])
		else:
			kills_still_t = 0.0
		last_kills = m.kills
	# 4) боссы
	if balive:
		no_boss_t = 0.0
		boss_alive_t += delta
		var b = _nearest(m.player.position, true)
		if b != boss_ref:
			boss_ref = b
			boss_best_hp = b.hp
			boss_hp_still_t = 0.0
			bosses_seen += 1
			boss_spawn_times.append(snappedf(rt, 0.1))
			if VERBOSE:
				print("BOSS #%d t=%.1f %s hp=%.0f" % [bosses_seen, rt, b.enemy_name, b.hp])
		elif b.hp < boss_best_hp - 0.5:
			boss_best_hp = b.hp
			boss_hp_still_t = 0.0
		else:
			boss_hp_still_t += delta
			if PROBE and int(boss_hp_still_t * FPS) % 60 == 30:
				var ag: Array = []
				for mv in m._active_group():
					ag.append("%s t=%.2f cd=%.2f" % [mv["id"], float(mv.get("t", 0)), float(mv.get("cd", 0))])
				var near := 0
				for bl in m.bullets:
					if is_instance_valid(bl) and bl.position.distance_to(b.position) < 120.0:
						near += 1
				print("PROBE t=%.1f boss=%s pos=%s ppos=%s d=%.0f spd=%.0f behavior=%s jump=%s slot=%d ag=%s bullets=%d near=%d target_is_boss=%s hp=%.0f" % [rt, b.enemy_name, b.position.round(), m.player.position.round(),
					b.position.distance_to(m.player.position), float(_g(b, "spd", 0)), _g(b, "behavior"), _g(b, "jump") != null, m.player.slot, ag, m.bullets.size(), near, m.target == b, b.hp])
			if boss_hp_still_t > 45.0 and int(boss_hp_still_t * FPS) % int(FPS * 45) == 0:
				var dd: float = b.position.distance_to(m.player.position)
				var mv: Array = []
				for x in m.player.moves:
					mv.append("%s:%s" % [x.get("id", "?"), x.get("lvl", x.get("level", "?"))] if x is Dictionary else str(x))
				_issue("BOSS_NO_DAMAGE", "босс %s dex=%d types=%s hp=%.0f/%.0f shield=%.0f 45 с без урона, дист=%.0f active=%s visible=%s target=%s bullets=%d moves=%s: %s" % [
					b.enemy_name, int(_g(b, "dex", 0)), _g(b, "types"), b.hp, b.max_hp, float(_g(b, "shield", 0.0)), dd, _g(b, "active"), b.visible,
					_g(m, "target") == b, (_g(m, "bullets", []) as Array).size(), mv, _state()])
	else:
		boss_alive_t = 0.0
		boss_ref = null
		if (MODE == "rush") and not in_arena:
			no_boss_t += delta
			if no_boss_t > 30.0 and int(no_boss_t * FPS) % int(FPS * 30) == 0:
				_issue("RUSH_NO_BOSS", "нет босса %.0f с: %s" % [no_boss_t, _state()])
	# 5) арена разлома
	if in_arena:
		arena_t += delta
		if arena_t > 200.0 and int(arena_t * FPS) % int(FPS * 60) == 0:
			_issue("ARENA_STUCK", "в арене %.0f с: %s" % [arena_t, _state()])
	else:
		if arena_t > 0.0:
			rift_entered += 1
		arena_t = 0.0
	# 6) Башня
	if MODE == "tower":
		var tf: int = int(m.tw_floor)
		if tf != tw_floor_last:
			tw_floor_last = tf
			tw_floor_t = 0.0
		else:
			tw_floor_t += delta
			if tw_floor_t > 240.0 and int(tw_floor_t * FPS) % int(FPS * 60) == 0:
				_issue("TOWER_STUCK", "этаж %d %.0f с: %s" % [tf, tw_floor_t, _state()])
	# 7) биом: смена по времени (rush 150 с, иначе 240 с; башня — по этажу)
	var bi: int = int(m.biome_idx)
	if not biome_seen.has(bi):
		biome_seen.append(bi)
	if MODE != "tower" and not in_arena:
		var want: int = int(rt / (150.0 if MODE == "rush" else 240.0)) + int(_g(m, "biome_off", 0))
		if want != bi:
			biome_bad_t += delta
			if biome_bad_t > 15.0 and int(biome_bad_t * FPS) % int(FPS * 15) == 0:
				_issue("BIOME_STUCK", "биом %d, ожидался %d: %s" % [bi, want, _state()])
		else:
			biome_bad_t = 0.0
	# 8) пустые куски на экране
	if not in_arena:
		_blank_check()


func _blank_check() -> void:
	var g = _g(m, "ground")
	if g == null or not ("chunks" in g):
		return
	var half: Vector2 = m.get_viewport_rect().size * 0.5 / float(_g(m, "cam_zoom", 1.0))
	var p: Vector2 = m.player.position
	var cw: float = g.CW
	var bad := 0
	for ky in range(floori((p.y - half.y) / cw), floori((p.y + half.y) / cw) + 1):
		for kx in range(floori((p.x - half.x) / cw), floori((p.x + half.x) / cw) + 1):
			var ch = g.chunks.get(Vector2i(kx, ky))
			if ch == null or (ch["tex"] == null and (ch["old"] == null or g.fade_t >= 1.0)):
				bad += 1
	if bad > 0:
		blank_frames += 1
		blank_run += 1
		blank_run_max = maxi(blank_run_max, blank_run)
		if blank_run == int(FPS * 1.0):
			_issue("BLANK_CHUNKS", "пустые куски на экране >1 с (%d шт.) у %s: %s" % [bad, p, _state()])
	else:
		blank_run = 0


func _finish(why: String) -> bool:
	ended = why
	for a in ["move_left", "move_right", "move_up", "move_down"]:
		Input.action_release(a)
	var p = _g(m, "player")
	var res := {
		"mode": MODE, "dex": DEX, "seed": SEED, "meta": META, "ended": why,
		"run_time": snappedf(float(_g(m, "run_time", 0.0)), 0.1),
		"wall_s": snappedf((Time.get_ticks_usec() - wall_t0) / 1e6, 0.1),
		"level": int(_g(p, "level", 0)), "kills": int(_g(m, "kills", 0)),
		"bosses": int(_g(m, "run_bosses", 0)), "bosses_seen": bosses_seen, "boss_t": boss_spawn_times.slice(0, 12),
		"rush_i": int(_g(m, "rush_i", 0)), "tw_floor": int(_g(m, "tw_floor", 0)),
		"biomes": biome_seen, "rifts": int(_g(m, "run_rifts", 0)), "rift_entered": rift_entered,
		"cards": cards_picked, "slot_sw": slot_switches, "z": z_used, "dyn": dyn_used, "near_deaths": near_deaths,
		"dist": roundi(dist_total), "far": roundi(max_from_origin),
		"hitches": hitches.size(), "worst_ms": snappedf(worst_ms, 0.1), "hitch_list": hitches.slice(0, 6),
		"blank_frames": blank_frames, "blank_run_max": blank_run_max,
		"issues": issues, "issue_kinds": issue_kinds,
	}
	res["ok"] = issues.is_empty()
	print("MATRIX_RESULT " + JSON.stringify(res))
	return true
