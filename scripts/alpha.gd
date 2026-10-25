extends RefCounted





const MAX_PER_RUN := 2
const MAX_ALLIES := 2          # союзников за забег (Альфа + боссы/гиганты вместе)
const BIG_RATE_BOSS := 0.6     # шанс поимки обычного босса
const BIG_RATE_MINI := 0.75    # шанс поимки гиганта
const FIRST_AT := 360.0
const GAP_MIN := 480.0
const GAP_MAX := 720.0
const WINDOW := 8.0
const RATE := 0.8
const FLIGHT := 0.45
const SHAKES := 3
const LIFE := 150.0
const AIM_TOL := 46.0

static var _bt: Texture2D = null

var m = null
var poi = null
var cur = null
var next_id := 1
var spawned := 0
var allies_made := 0
var t_next := FIRST_AT
var throw_cd := 0.0
var done := {}
var log: Array = []


static func ball_tex() -> Texture2D:
	if _bt == null and ResourceLoader.exists("res://assets/world/ball.png"):
		_bt = load("res://assets/world/ball.png")
	return _bt


class BallFx extends Node2D:
	var from := Vector2.ZERO
	var to := Vector2.ZERO
	var t := 0.0
	var flight := 0.45
	var shake := 0.0
	var miss := false
	var open := 0.0
	func _process(delta: float) -> void :
		t += delta
		var k: float = clampf(t / flight, 0.0, 1.0)
		if k < 1.0:
			position = from.lerp(to, k) + Vector2(0.0, - sin(k * PI) * 60.0)
			rotation = t * 14.0
		else:
			position = to
			rotation = sin((t - flight) * 18.0) * 0.5 * clampf(shake, 0.0, 1.0)
		queue_redraw()
	func _draw() -> void :
		var tx: Texture2D = load("res://assets/world/ball.png")
		if tx == null:
			draw_circle(Vector2.ZERO, 8.0, Color.RED)
			return
		var sz := Vector2(tx.get_width(), tx.get_height()) * 0.42
		draw_texture_rect(tx, Rect2( - sz * 0.5, sz), false)


class Down extends Node2D:
	var col := Color("#ff6b6b")
	var t := 0.0
	var actor = null
	var vanish := -1.0
	func _process(delta: float) -> void :
		t += delta
		if vanish >= 0.0:
			vanish -= delta
			modulate.a = clampf(vanish / 0.5, 0.0, 1.0)
			if vanish <= 0.0:
				queue_free()
		queue_redraw()
	func _draw() -> void :
		draw_circle(Vector2(0, 4), 24.0, Color(0, 0, 0, 0.3))
		draw_arc(Vector2(0, -18), 40.0 + 3.0 * sin(t * 4.0), 0, TAU, 32, Color(col.r, col.g, col.b, 0.6), 3.0)


func _legend_free() -> bool:
	return allies_made < MAX_ALLIES


func _spawn_ok() -> bool:
	return spawned < MAX_PER_RUN and ["normal", "type", "daily", "coop"].has(m.mode) and not poi._busy() and not m.shop_open and m.run_time >= FIRST_AT\
	and (poi.supply == null or not is_instance_valid(poi.supply)) and (m.kec.active == null or not is_instance_valid(m.kec.active))\
	and m.rescue.cur == null


func _name(dex: int) -> String:
	var nm: String = String(m._dex_by[dex].get("name", "?")) if m._dex_by.has(dex) else "?"
	return m.L.t("Alfa %s") % nm


func spawn() -> bool:
	if cur != null or spawned >= MAX_PER_RUN:
		return false
	var bag: Array = m._bag_at(m._dt())
	var cand: Array = []
	for d in bag:
		if int(d.get("dex", 0)) > 0 and not bool(d.get("boss", false)) and m._smeta.has(str(int(d["dex"]))):
			cand.append(d)
	if cand.is_empty() or m.enemies.size() >= m.ENEMY_CAP - 2:
		return false
	var def: Dictionary = (cand[randi() % cand.size()] as Dictionary).duplicate()
	def["behavior"] = "chase"
	var pos: Vector2 = m._free_spot(m.player.position + Vector2.from_angle(randf() * TAU) * randf_range(420.0, 520.0), 20.0)
	var base: Dictionary = m._scale_at(m._dt())
	var lx: float = m._late_x(m._dt())
	var sc := {"hp": float(base["hp"]) * m._hp_k(m._dt()) * (1.0 + lx), "dmg": float(base["dmg"]) * (1.0 + 0.45 * lx), "spd": float(base["spd"]) * (1.0 + 0.08 * lx)}
	var e = m._make_enemy(def, pos, sc)
	e.max_hp = roundf(e.max_hp * 9.0)
	e.hp = e.max_hp
	e.dmg *= 1.4
	e.spd *= 0.92
	e.xp_val = roundf(e.xp_val * 10.0)
	e.modulate = Color(1.0, 0.7, 0.7)
	e.scale = Vector2(1.35, 1.35)
	e.set_meta("enc", "alpha")
	var dex: int = int(def["dex"])
	cur = {"id": next_id, "state": "hostile", "enemy": e, "dex": dex, "name": _name(dex), "ttl": LIFE, "pos": pos, "types": (def.get("types", []) as Array).duplicate()}
	next_id += 1
	spawned += 1
	m._say(m.L.t("¡Un %s ronda por la zona!") % String(cur["name"]), 3.0)
	m.Aud.sfx("boss")
	log.append(["spawn", dex])
	return true



func on_down(e) -> void :
	if cur == null or cur["state"] != "hostile" or cur["enemy"] != e:
		return
	_begin_down(e)


# Ослабленный обычный босс (enc open_boss) или гигант (enc mini): то же окно броска, свой шанс.
func on_big_down(e, kind: String) -> void :
	if cur != null or allies_made >= MAX_ALLIES or m.balls <= 0 or not ["normal", "type", "daily", "coop"].has(m.mode):
		return
	var dx: int = int(e.dex)
	if not m._smeta.has(str(dx)):
		return
	cur = {"id": next_id, "state": "hostile", "enemy": e, "dex": dx, "name": String(e.enemy_name), "ttl": WINDOW, "pos": e.position, "types": (e.types as Array).duplicate(),
		"big": true, "rate": BIG_RATE_BOSS if kind == "open_boss" else BIG_RATE_MINI}
	next_id += 1
	_begin_down(e)
	m._say(m.L.t("¡%s debilitado! Lanza una Poké Ball (8 s).") % String(cur["name"]), 3.0)


func _begin_down(e) -> void :
	cur["state"] = "down"
	cur["ttl"] = WINDOW
	cur["pos"] = e.position
	var node := Down.new()
	node.position = e.position
	node.z_index = 1
	m.world.add_child(node)
	var a = m.Actor.new()
	a.setup(int(cur["dex"]), m._sm(int(cur["dex"])), m.flash_shader, 1.35)
	if is_instance_valid(e) and int(e.dex) == int(cur["dex"]) and not e.shiny:
		a.textures = e.textures.duplicate()   # кадры уже загружены у врага: без повторной загрузки
	a.modulate = Color(1, 0.8, 0.8)
	node.add_child(a)
	if a.has_anim("Faint"):
		a.play("Faint", 1.0, true)
	node.actor = a
	cur["node"] = node
	if not cur.has("big"):
		m._say(m.L.t("¡Alfa derrotado! Lanza una Poké Ball (8 s)."), 3.0)
	m.pfx.burst(e.position + Vector2(0, -20), Color("#ffd23f"), 22, 160.0)
	log.append(["down", cur["dex"]])


func window_ok(pp: Vector2) -> bool:
	return cur != null and cur["state"] == "down" and m.balls > 0 and _legend_free() and (cur["pos"] as Vector2).distance_to(pp) < 560.0


func throw() -> void :
	if throw_cd > 0.0 or not window_ok(m.player.position):
		return
	throw_cd = 0.4
	var pp: Vector2 = m.player.position + Vector2(0, -16)
	var tp: Vector2 = (cur["pos"] as Vector2) + Vector2(0, -16)

	if bool(m.SV.d["settings"].get("manual_aim", false)):
		var av: Vector2 = m._manual_aim_vec()
		if av != Vector2.ZERO:
			var rel: Vector2 = tp - pp
			var along: float = rel.dot(av)
			var perp: float = absf(rel.cross(av))
			if along < 0.0 or along > 580.0 or perp > AIM_TOL:
				var fx := BallFx.new()
				fx.from = pp
				fx.to = pp + av * 260.0
				fx.flight = 0.4
				m.world.add_child(fx)
				fx.get_tree().create_timer(0.9).timeout.connect(fx.queue_free)
				m.add_text(m.player.position + Vector2(0, - m.player.body_h - 20.0), m.L.t("¡Fallaste! Apunta al Alfa."), Color("#ff8a8a"), 20)
				log.append(["aim_miss"])
				return

	cur["state"] = "throw"
	m.balls -= 1
	var ok: bool = randf() < float(cur.get("rate", RATE))
	cur["roll"] = ok
	var fx2 := BallFx.new()
	fx2.from = pp
	fx2.to = tp
	fx2.flight = FLIGHT
	fx2.shake = 1.0
	m.world.add_child(fx2)
	cur["fx"] = fx2
	cur["t"] = 0.0
	m.Aud.sfx("ball")
	log.append(["throw", ok])


func update(delta: float) -> void :
	throw_cd = maxf(0.0, throw_cd - delta)
	_ally_tick(delta)
	if cur == null:
		if spawned >= MAX_PER_RUN:
			return
		t_next -= delta
		if t_next <= 0.0:
			if _spawn_ok() and spawn():
				pass
			else:
				t_next = 20.0
		return
	match String(cur["state"]):
		"hostile":
			var e = cur["enemy"]
			if not is_instance_valid(e) or e.dead:
				if not done.has(cur["id"]):

					_finish(false)
				return
			cur["ttl"] = float(cur["ttl"]) - delta
			if float(cur["ttl"]) <= 0.0 or m.player.dead:
				m.enemies.erase(e)
				e.queue_free()
				m._say(m.L.t("¡El Alfa se ha ido!"), 2.0)
				log.append(["left"])
				_finish(false)
		"down":
			cur["ttl"] = float(cur["ttl"]) - delta
			if float(cur["ttl"]) <= 0.0:
				_vanish()
				m._say(m.L.t("¡Se ha escapado!"), 2.0)
				log.append(["expired"])
				_finish(false)
		"throw":
			cur["t"] = float(cur["t"]) + delta
			var total: float = FLIGHT + float(SHAKES) * 0.45
			if float(cur["t"]) >= total:
				_resolve()


func _vanish() -> void :
	if cur != null and cur.has("node") and is_instance_valid(cur["node"]):
		cur["node"].vanish = 0.5
		m.pfx.burst((cur["pos"] as Vector2) + Vector2(0, -20), Color("#ffffff"), 14, 120.0)


func _finish(_ok: bool) -> void :
	var was_big: bool = cur != null and cur.has("big")
	cur = null
	if not was_big:   # поимка босса/гиганта не сдвигает таймер Альфы
		t_next = randf_range(GAP_MIN, GAP_MAX)


func _resolve() -> void :
	if cur == null or cur["state"] != "throw" or done.has(cur["id"]):
		return
	done[cur["id"]] = true
	var ok: bool = bool(cur["roll"])
	var fx = cur.get("fx")
	if is_instance_valid(fx):
		fx.queue_free()
	var pos: Vector2 = cur["pos"]
	if ok and _legend_free():
		_vanish()
		_make_ally(cur)
		log.append(["ally", cur["dex"]])
	else:
		_vanish()
		m.pfx.burst(pos + Vector2(0, -20), Color("#ff6b6b"), 24, 180.0)
		m._say(m.L.t("¡Se ha escapado!"), 2.2)
		log.append(["failed"])
	_finish(ok)


func _make_ally(c: Dictionary) -> void :
	m.ach_event("alpha", {})
	var dex: int = int(c["dex"])
	var lg = m.Legend.new()
	lg.setup(dex, m._sm(dex), m.flash_shader, 1.2, false)
	lg.m = m
	lg.alpha = true
	var ty: Array = c["types"]
	lg.ltype = String(ty[0]) if not ty.is_empty() else "normal"
	lg.col = Color.html(String(m.MD.TYPE_COLOR.get(lg.ltype, "#ff6b6b")))
	lg.lname = String(c["name"])
	var tm: float = m.run_time / 60.0
	lg.max_hp = roundf(450.0 + float(m.player.level) * 60.0 + tm * 40.0)
	lg.hp = lg.max_hp
	lg.dmg = 22.0 + float(m.player.level) * 4.0 + tm * 1.8
	lg.position = c["pos"]
	lg.z_index = 1
	m.world.add_child(lg)
	allies_made += 1
	m.legend = lg
	m._ring(lg.position, 8.0, 130.0, lg.col, 0.7, 5.0)
	m.pfx.burst(lg.position + Vector2(0, -30), lg.col, 36, 240.0)
	m.pfx.burst(lg.position + Vector2(0, -30), Color("#ffd23f"), 20, 150.0)
	m.Aud.sfx("legend")
	m._say(m.L.t("¡Atrapado! %s se une a ti.") % lg.lname, 3.2)



func _ally_tick(delta: float) -> void :
	var lg = m.legend
	if is_instance_valid(lg) and lg.alpha and not lg.dead:
		lg.hp = minf(lg.max_hp, lg.hp + lg.max_hp * 0.006 * delta)


func mark() -> Variant:
	if cur == null:
		return null
	var ct: Transform2D = m.get_viewport().get_canvas_transform()
	var st: String = String(cur["state"])
	if st == "hostile":
		var e = cur["enemy"]
		if not is_instance_valid(e):
			return null
		return {"sp": ct * (e.position + Vector2(0, -70)), "txt": "%s  %d%%" % [String(cur["name"]), roundi(100.0 * e.hp / maxf(e.max_hp, 1.0))], "col": Color("#ff6b6b")}
	if st == "down":
		var txt: String = m.L.t("Lanza la Poké Ball") if m.balls > 0 else m.L.t("Sin Poké Ball")
		if not _legend_free():
			txt = m.L.t("Ya tienes un aliado")
		return {"sp": ct * ((cur["pos"] as Vector2) + Vector2(0, -70)), "txt": "%s  %ds" % [txt, ceili(float(cur["ttl"]))], "col": Color("#ffd23f")}
	return null
