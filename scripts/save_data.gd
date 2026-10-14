extends RefCounted
# Datos guardados + datos compartidos entre el menu y la partida

const PATH := "user://save.json"
const BAK := "user://save.bak"
const TMP := "user://save.tmp"
const STARTERS_D = preload("res://scripts/starters_data.gd")

static var d: Dictionary = {}
static var loaded := false
static var dex_list: Array = []
static var dex_by: Dictionary = {}
static var smeta: Dictionary = {}
static var starter_by: Dictionary = {}
static var run_dex := 25
static var last_run: Dictionary = {}
static var reopen := ""

const REGIONS := ["Kanto", "Johto", "Hoenn", "Sinnoh", "Teselia", "Kalos", "Alola", "Galar", "Paldea"]
const RARITY_W := [40.0, 30.0, 18.0, 9.0, 3.0]
const RARITY_NAME := ["Común", "Poco común", "Raro", "Muy raro", "Legendario"]
const SHINY_PULL := 0.01
const PULL_RATES := [45.0, 30.0, 17.0, 6.5, 1.5]
const PITY_5 := 70
const REFUND := [15, 30, 60, 120, 300]

# Mejoras permanentes (upgrades.js)
const UPGRADES := [
	{"id": "hp", "name": "Vitalidad", "unit": "+8 vida", "max": 10, "base": 60.0, "grow": 1.35},
	{"id": "atk", "name": "Fuerza", "unit": "+4% daño", "max": 10, "base": 80.0, "grow": 1.38},
	{"id": "spd", "name": "Zancada", "unit": "+3% velocidad", "max": 8, "base": 70.0, "grow": 1.4},
	{"id": "cd", "name": "Reflejos", "unit": "-3% recarga", "max": 8, "base": 90.0, "grow": 1.42},
	{"id": "def", "name": "Coraza", "unit": "+2% defensa", "max": 8, "base": 80.0, "grow": 1.4},
	{"id": "regen", "name": "Síntesis", "unit": "+0,2 vida/s", "max": 5, "base": 120.0, "grow": 1.5},
	{"id": "magnet", "name": "Imán", "unit": "+12% recogida", "max": 6, "base": 50.0, "grow": 1.4},
	{"id": "xp", "name": "Sabiduría", "unit": "+5% experiencia", "max": 8, "base": 100.0, "grow": 1.42},
	{"id": "coins", "name": "Fortuna", "unit": "+8% Pokémonedas", "max": 8, "base": 120.0, "grow": 1.45},
	{"id": "moves", "name": "Repertorio", "unit": "Empiezas con 2 movimientos", "max": 1, "base": 1500.0, "grow": 1.0},
	{"id": "crit", "name": "Golpe Crítico", "unit": "+3% de críticos (x1,5 de daño)", "max": 10, "base": 90.0, "grow": 1.4},
	{"id": "reroll", "name": "Cambio de cartas", "unit": "+1 cambio de cartas por partida", "max": 5, "base": 150.0, "grow": 1.6},
	{"id": "ban", "name": "Veto", "unit": "Bloquea 1 movimiento: no te sale en las cartas", "max": 3, "base": 300.0, "grow": 1.9},
]

# Misiones y logros: progreso = una estadistica acumulada
const GOALS := [
	{"id": "m_kill100", "kind": "m", "text": "Derrota 100 Pokémon", "stat": "kills", "target": 100, "coins": 150, "tickets": 0},
	{"id": "m_kill500", "kind": "m", "text": "Derrota 500 Pokémon", "stat": "kills", "target": 500, "coins": 400, "tickets": 1},
	{"id": "m_time3", "kind": "m", "text": "Sobrevive 3:00 en una partida", "stat": "best_time", "target": 180, "coins": 200, "tickets": 0},
	{"id": "m_time6", "kind": "m", "text": "Sobrevive 6:00 en una partida", "stat": "best_time", "target": 360, "coins": 500, "tickets": 1},
	{"id": "m_lv10", "kind": "m", "text": "Llega al nivel 10", "stat": "best_level", "target": 10, "coins": 200, "tickets": 0},
	{"id": "m_lv25", "kind": "m", "text": "Llega al nivel 25", "stat": "best_level", "target": 25, "coins": 500, "tickets": 0},
	{"id": "m_boss1", "kind": "m", "text": "Derrota a un jefe", "stat": "bosses", "target": 1, "coins": 300, "tickets": 1},
	{"id": "m_chest5", "kind": "m", "text": "Abre 5 cofres", "stat": "chests", "target": 5, "coins": 200, "tickets": 0},
	{"id": "m_runs5", "kind": "m", "text": "Completa 5 partidas", "stat": "runs", "target": 5, "coins": 250, "tickets": 0},
	{"id": "m_pull3", "kind": "m", "text": "Haz 3 tiradas en el gacha", "stat": "pulls", "target": 3, "coins": 150, "tickets": 0},
	{"id": "a_kill2k", "kind": "a", "text": "Derrota 2.000 Pokémon", "stat": "kills", "target": 2000, "coins": 800, "tickets": 2},
	{"id": "a_kill10k", "kind": "a", "text": "Derrota 10.000 Pokémon", "stat": "kills", "target": 10000, "coins": 3000, "tickets": 5},
	{"id": "a_time10", "kind": "a", "text": "Sobrevive 10:00 en una partida", "stat": "best_time", "target": 600, "coins": 1000, "tickets": 2},
	{"id": "a_time15", "kind": "a", "text": "Sobrevive 15:00 en una partida", "stat": "best_time", "target": 900, "coins": 2500, "tickets": 4},
	{"id": "a_lv40", "kind": "a", "text": "Llega al nivel 40", "stat": "best_level", "target": 40, "coins": 1500, "tickets": 3},
	{"id": "a_boss5", "kind": "a", "text": "Derrota 5 jefes", "stat": "bosses", "target": 5, "coins": 1200, "tickets": 3},
	{"id": "a_chest25", "kind": "a", "text": "Abre 25 cofres", "stat": "chests", "target": 25, "coins": 800, "tickets": 2},
	{"id": "a_own10", "kind": "a", "text": "Consigue 10 Pokémon", "stat": "owned", "target": 10, "coins": 500, "tickets": 1},
	{"id": "a_own50", "kind": "a", "text": "Consigue 50 Pokémon", "stat": "owned", "target": 50, "coins": 2000, "tickets": 4},
	{"id": "a_own100", "kind": "a", "text": "Consigue 100 Pokémon", "stat": "owned", "target": 100, "coins": 5000, "tickets": 8},
	{"id": "a_shiny1", "kind": "a", "text": "Consigue un Pokémon shiny", "stat": "shinies", "target": 1, "coins": 1000, "tickets": 3},
	{"id": "a_runs50", "kind": "a", "text": "Completa 50 partidas", "stat": "runs", "target": 50, "coins": 1500, "tickets": 3},
]


static func default_data() -> Dictionary:
	return {
		"v": 1, "created": int(Time.get_unix_time_from_system()), "title": "", "nick": "", "favs": [0, 0, 0], "coins": 600, "tickets": 10, "tickets10": 3, "pity": {}, "legends": {}, "arenas": {}, "lshiny": {}, "owned": {}, "selected": 25, "shiny_on": false,
		"upgrades": {}, "pup": {}, "claimed": {}, "pban": {}, "pbind": {},
		"stats": {"runs": 0, "kills": 0, "best_time": 0, "best_level": 1, "bosses": 0, "chests": 0, "pulls": 0, "shinies": 0, "total_time": 0, "coins_total": 0, "defeated_runs": 0, "rifts": 0},
		"settings": {"master": 80, "music": 70, "sfx": 80, "dmg_numbers": true, "vibration": true, "shake": true, "stick": 1, "stick_fixed": false, "lang": "en", "view": 100, "fov": 165, "pad": 0, "padmap": {}, "mute": false, "quality": 0, "fps": false},
	}


static func _merge(base: Dictionary, over: Dictionary) -> Dictionary:
	for k in over:
		if base.has(k) and base[k] is Dictionary and over[k] is Dictionary and k != "owned" and k != "upgrades" and k != "pup" and k != "claimed" and k != "pban" and k != "pbind":
			base[k] = _merge(base[k], over[k])
		else:
			base[k] = over[k]
	return base


static func load_dex() -> void:
	if not dex_list.is_empty():
		return
	var jd: JSON = load("res://data/pokedex.json")
	dex_list = jd.data
	for p in dex_list:
		dex_by[int(p["dex"])] = p
	var js: JSON = load("res://data/sprite_meta.json")
	smeta = js.data
	for s in STARTERS_D.STARTERS:
		starter_by[int(s["dex"])] = s


static func ensure() -> void:
	if loaded:
		return
	loaded = true
	load_dex()
	d = default_data()
	var parsed = _read_json(PATH)
	if not (parsed is Dictionary):
		parsed = _read_json(BAK)   # el guardado principal falto o esta danado: usa la copia
	if parsed is Dictionary:
		d = _merge(d, parsed)
	_migrate_upgrades()
	# v1.0.1: sprites al tamano del original (vision 165 %); el valor por defecto antiguo era 140.
	if not bool(d["settings"].get("fov_v2", false)):
		d["settings"]["fov_v2"] = true
		if int(d["settings"].get("fov", 165)) == 140:
			d["settings"]["fov"] = 165


static func _read_json(path: String):
	if not FileAccess.file_exists(path):
		return null
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return null
	return JSON.parse_string(f.get_as_text())


# Las mejoras eran globales; ahora cada Pokemon tiene las suyas. Las antiguas pasan al companero actual.
static func _migrate_upgrades() -> void:
	if not d.has("pup"):
		d["pup"] = {}
	var old: Dictionary = d.get("upgrades", {})
	if not old.is_empty():
		var key := str(int(d.get("selected", 25)))
		if not d["pup"].has(key):
			d["pup"][key] = old.duplicate()
		d["upgrades"] = {}


# Guardado a prueba de cierres: escribe en un temporal, guarda la copia anterior y renombra.
static func save() -> void:
	var f := FileAccess.open(TMP, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(d))
	f.close()
	if FileAccess.file_exists(PATH):
		DirAccess.copy_absolute(PATH, BAK)
	DirAccess.rename_absolute(TMP, PATH)


# Ranking local: las 10 mejores partidas por tiempo aguantado.
static func _add_top(e: Dictionary) -> void:
	var top: Array = d.get("top", [])
	top.append(e)
	top.sort_custom(func(a, b): return int(a["time"]) > int(b["time"]))
	if top.size() > 10:
		top.resize(10)
	d["top"] = top


static func reset_all() -> void:
	d = default_data()
	last_run = {}
	save()


static func setting(k: String):
	return d["settings"][k]


static func owns(dex: int) -> bool:
	return d["owned"].has(str(dex))


static func owned_count() -> int:
	return d["owned"].size()


static func add_owned(dex: int, shiny: bool = false) -> void:
	var key := str(dex)
	if d["owned"].has(key):
		d["owned"][key]["n"] = int(d["owned"][key]["n"]) + 1
		if shiny:
			d["owned"][key]["shiny"] = true
	else:
		d["owned"][key] = {"n": 1, "shiny": shiny}
	if shiny:
		d["stats"]["shinies"] = int(d["stats"]["shinies"]) + 1


static func start_move_of(dex: int) -> String:
	if starter_by.has(dex):
		return String(starter_by[dex]["start"])
	var MDd = load("res://scripts/moves_data.gd")
	var p: Dictionary = dex_by[dex]
	return String(MDd.START[String(p["types"][0])])


# ---- veto y atajos de movimientos (por Pokemon, como en el original) ----
# Movimientos que le pueden salir a un Pokemon en las cartas (sin el de inicio).
static func move_pool(dex: int) -> Array:
	var MDd = load("res://scripts/moves_data.gd")
	var types: Array = dex_by[dex]["types"]
	var start: String = start_move_of(dex)
	var out: Array = []
	for id in MDd.ORDER:
		var ty: String = String(MDd.MOVES[id]["type"])
		if id != start and (ty == "normal" or types.has(ty)):
			out.append(String(id))
	return out


static func ban_list(dex: int) -> Array:
	return d["pban"].get(str(dex), [])


# Marca o desmarca un movimiento vetado. Devuelve false si ya no caben mas.
static func ban_toggle(dex: int, id: String, max_n: int) -> bool:
	var key := str(dex)
	var l: Array = d["pban"].get(key, []).duplicate()
	if l.has(id):
		l.erase(id)
	elif l.size() >= max_n:
		return false
	else:
		l.append(id)
	d["pban"][key] = l
	save()
	return true


static func bind_list(dex: int) -> Array:
	var l: Array = d["pbind"].get(str(dex), []).duplicate()
	while l.size() < 4:
		l.append("")
	return l


static func bind_set(dex: int, slot: int, id: String) -> void:
	var l: Array = bind_list(dex)
	if id != "":
		for j in range(4):
			if String(l[j]) == id:
				l[j] = ""
	l[slot] = id
	d["pbind"][str(dex)] = l
	save()


# ---- mejoras ----
static func up_level(id: String, dex: int = -1) -> int:
	var key := str(run_dex if dex < 0 else dex)
	var m: Dictionary = d["pup"].get(key, {})
	return int(m.get(id, 0))


# Suma de niveles comprados de un Pokemon.
static func up_total(dex: int) -> int:
	var n := 0
	var m: Dictionary = d["pup"].get(str(dex), {})
	for k in m:
		n += int(m[k])
	return n


static func up_def(id: String) -> Dictionary:
	for u in UPGRADES:
		if String(u["id"]) == id:
			return u
	return {}


static func up_cost(id: String, lvl: int) -> int:
	var u: Dictionary = up_def(id)
	return int(roundf(float(u["base"]) * pow(float(u["grow"]), float(lvl)) / 10.0)) * 10


static func buy_upgrade(id: String, dex: int = -1) -> bool:
	var u: Dictionary = up_def(id)
	var lv: int = up_level(id, dex)
	if lv >= int(u["max"]):
		return false
	var c: int = up_cost(id, lv)
	if int(d["coins"]) < c:
		return false
	d["coins"] = int(d["coins"]) - c
	var key := str(run_dex if dex < 0 else dex)
	if not d["pup"].has(key):
		d["pup"][key] = {}
	d["pup"][key][id] = lv + 1
	save()
	return true


static func perks() -> Dictionary:
	var L := func(id: String) -> int:
		return clampi(up_level(id), 0, int(up_def(id)["max"]))
	return {
		"hp": float(L.call("hp")) * 8.0,
		"atk": 1.0 + float(L.call("atk")) * 0.04,
		"spd": 1.0 + float(L.call("spd")) * 0.03,
		"cd": 1.0 - float(L.call("cd")) * 0.03,
		"def": float(L.call("def")) * 0.02,
		"regen": float(L.call("regen")) * 0.2,
		"magnet": 1.0 + float(L.call("magnet")) * 0.12,
		"xp": 1.0 + float(L.call("xp")) * 0.05,
		"coins": 1.0 + float(L.call("coins")) * 0.08,
		"moves": 1 + L.call("moves"),
		"crit": float(L.call("crit")) * 0.03,
		"rerolls": L.call("reroll"),
		"bans": L.call("ban"),
	}


# ---- metas ----
static func stat_value(stat: String) -> int:
	if stat == "owned":
		return owned_count()
	return int(d["stats"].get(stat, 0))


static func goal_done(g: Dictionary) -> bool:
	return stat_value(String(g["stat"])) >= int(g["target"])


static func goal_claimed(g: Dictionary) -> bool:
	return d["claimed"].has(String(g["id"]))


static func claim_goal(g: Dictionary) -> bool:
	if not goal_done(g) or goal_claimed(g):
		return false
	d["claimed"][String(g["id"])] = true
	d["coins"] = int(d["coins"]) + int(g["coins"])
	d["tickets"] = int(d["tickets"]) + int(g["tickets"])
	save()
	return true


# ---- gacha ----
static func region_pool(region: int) -> Array:
	var out: Array = []
	for p in dex_list:
		if int(p["gen"]) == region and smeta.has(str(int(p["dex"]))):
			out.append(p)
	return out


static func can_pull(n: int, use: String) -> bool:
	if n == 10 and use == "t10":
		return int(d.get("tickets10", 0)) >= 1
	return int(d["tickets"]) >= n


# Pool de una rareza; si esta vacio, el mas cercano (como en el original).
static func _pool_near(rarity: int, region: int) -> Array:
	var all: Array = region_pool(region)
	for off in [0, -1, 1, -2, 2, -3, 3, -4, 4]:
		var r: int = rarity + int(off)
		if r < 1 or r > 5:
			continue
		var out: Array = []
		for p in all:
			if int(p["rarity"]) == r:
				out.append(p)
		if not out.is_empty():
			return out
	return all


static func _roll_rarity(minr: int = 1) -> int:
	var total := 0.0
	for i in range(minr - 1, 5):
		total += PULL_RATES[i]
	var x: float = randf() * total
	for i in range(minr - 1, 5):
		x -= PULL_RATES[i]
		if x <= 0.0:
			return i + 1
	return 5


# n tiradas: x1 (1 ticket), x10 (10 tickets o 1 ticket x10). Devuelve [] si no hay tickets.
static func pull(region: int, n: int = 1, use: String = "t1") -> Array:
	if not can_pull(n, use):
		return []
	if n == 10 and use == "t10":
		d["tickets10"] = int(d["tickets10"]) - 1
	else:
		d["tickets"] = int(d["tickets"]) - n
	var key := str(region)
	if not d["pity"].has(key):
		d["pity"][key] = 0
	var out: Array = []
	for i in range(n):
		d["pity"][key] = int(d["pity"][key]) + 1
		var want: int
		var got4 := false
		for r in out:
			if int(r["rarity"]) >= 4:
				got4 = true
		if int(d["pity"][key]) >= PITY_5:
			want = 5
		elif n == 10 and i == n - 1 and not got4:
			want = _roll_rarity(4)
		else:
			want = _roll_rarity()
		var list: Array = _pool_near(want, region)
		var rarity: int = int(list[0]["rarity"])
		if rarity == 5:
			d["pity"][key] = 0
		var sp: Dictionary = list[randi() % list.size()]
		var dex: int = int(sp["dex"])
		var shiny: bool = randf() < SHINY_PULL and bool(smeta[str(dex)].get("sh", 0))
		var shiny_owned: bool = owns(dex) and bool(d["owned"][str(dex)]["shiny"])
		if shiny and shiny_owned:
			var missing: Array = []
			for p in list:
				var pk := str(int(p["dex"]))
				if bool(smeta[pk].get("sh", 0)) and not (owns(int(p["dex"])) and bool(d["owned"][pk]["shiny"])):
					missing.append(p)
			if missing.is_empty():
				shiny = false
			else:
				sp = missing[randi() % missing.size()]
				dex = int(sp["dex"])
				shiny_owned = owns(dex) and bool(d["owned"][str(dex)]["shiny"])
		var was_new: bool = not owns(dex)
		var refund := 0
		if shiny:
			was_new = not shiny_owned
			if not was_new:
				refund = int(REFUND[rarity - 1]) * 3
		elif not was_new:
			refund = int(REFUND[rarity - 1])
		if refund > 0:
			d["coins"] = int(d["coins"]) + refund
		add_owned(dex, shiny and not shiny_owned)
		out.append({"dex": dex, "new": was_new, "shiny": shiny, "refund": refund, "rarity": rarity, "name": String(sp["name"])})
	d["stats"]["pulls"] = int(d["stats"]["pulls"]) + n
	return out


# ---- fin de partida ----
static func finish_run(r: Dictionary) -> Dictionary:
	# r: time, kills, level, bosses, chests, coins, tickets
	var pk: Dictionary = perks()
	var coins: int = int(roundf(float(r["coins"]) * float(pk["coins"]))) + int(float(r["time"]) / 6.0) + int(float(r["kills"]) / 10.0)
	var tickets: int = int(r["tickets"])
	var s: Dictionary = d["stats"]
	var record: bool = int(r["time"]) > int(s["best_time"]) and int(s["runs"]) > 0
	var picked: int = int(roundf(float(r["coins"]) * float(pk["coins"])))
	s["runs"] = int(s["runs"]) + 1
	s["kills"] = int(s["kills"]) + int(r["kills"])
	s["bosses"] = int(s["bosses"]) + int(r["bosses"])
	s["chests"] = int(s["chests"]) + int(r["chests"])
	s["total_time"] = int(s["total_time"]) + int(r["time"])
	s["best_time"] = maxi(int(s["best_time"]), int(r["time"]))
	s["best_level"] = maxi(int(s["best_level"]), int(r["level"]))
	s["coins_total"] = int(s["coins_total"]) + coins
	d["coins"] = int(d["coins"]) + coins
	d["tickets"] = int(d["tickets"]) + tickets
	var tickets10: int = int(r.get("tickets10", 0))
	d["tickets10"] = int(d.get("tickets10", 0)) + tickets10
	_add_top({"time": int(r["time"]), "kills": int(r["kills"]), "level": int(r["level"]), "dex": int(r.get("dex", 25)), "judge": int(r.get("judge", {}).get("time", 0)) if r.get("judge", {}) is Dictionary else 0, "date": Time.get_date_string_from_system()})
	last_run = {"judge": r.get("judge", {}), "time": int(r["time"]), "kills": int(r["kills"]), "level": int(r["level"]), "coins": coins, "tickets": tickets, "tickets10": tickets10, "bosses": int(r["bosses"]), "dex": int(r.get("dex", 25)),
		"dead": bool(r.get("dead", true)), "record": record, "moves": r.get("moves", []),
		"breakdown": "Recogidas %d · Tiempo +%d · Derrotados +%d" % [picked, int(float(r["time"]) / 6.0), int(float(r["kills"]) / 10.0)]}
	save()
	return last_run
