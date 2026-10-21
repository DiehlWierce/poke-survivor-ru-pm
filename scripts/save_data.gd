extends RefCounted
# Datos guardados + datos compartidos entre el menu y la partida

const PATH := "user://save.json"
const BAK := "user://save.bak"
const TMP := "user://save.tmp"
const SAVE_SCHEMA_VERSION := 1
const STARTERS_D = preload("res://scripts/starters_data.gd")
const NATURES_D = preload("res://scripts/natures_data.gd")

static var d: Dictionary = {}
static var loaded := false
static var save_blocked := false
static var recovered_from_backup := false
static var last_save_error := ""
static var _field_warning := ""
static var dex_list: Array = []
static var dex_by: Dictionary = {}
static var smeta: Dictionary = {}
static var starter_by: Dictionary = {}
static var run_dex := 25
static var run_mode := "normal"    # normal | daily | rush | party | type | team
static var run_mods: Array = []
static var run_seed := 0
static var party_dex := 25
static var run_type := "fire"      # modo Supervivencia por tipo
static var team_dex: Array = []    # modo Equipo (2-3 Pokemon)
const MOD_IDS := ["fast", "horde", "tank", "hard", "frail", "nohealing", "slow", "brainy", "glass", "rich", "plague"]
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
	{"id": "hp", "name": "Vitalidad", "unit": "+8 vida", "max": 10, "base": 100.0, "grow": 1.39},
	{"id": "atk", "name": "Fuerza", "unit": "+4% daño", "max": 10, "base": 130.0, "grow": 1.42},
	{"id": "spd", "name": "Zancada", "unit": "+3% velocidad", "max": 8, "base": 110.0, "grow": 1.44},
	{"id": "cd", "name": "Reflejos", "unit": "-3% recarga", "max": 8, "base": 140.0, "grow": 1.46},
	{"id": "def", "name": "Coraza", "unit": "+2% defensa", "max": 8, "base": 130.0, "grow": 1.44},
	{"id": "regen", "name": "Síntesis", "unit": "+0,2 vida/s", "max": 5, "base": 190.0, "grow": 1.54},
	{"id": "magnet", "name": "Imán", "unit": "+12% recogida", "max": 6, "base": 80.0, "grow": 1.44},
	{"id": "xp", "name": "Sabiduría", "unit": "+5% experiencia", "max": 8, "base": 160.0, "grow": 1.46},
	{"id": "coins", "name": "Fortuna", "unit": "+8% Pokémonedas", "max": 8, "base": 190.0, "grow": 1.49},
	{"id": "moves", "name": "Repertorio", "unit": "Empiezas con 2 movimientos", "max": 1, "base": 2400.0, "grow": 1.0},
	{"id": "crit", "name": "Golpe Crítico", "unit": "+3% de críticos (x1,5 de daño)", "max": 10, "base": 140.0, "grow": 1.44},
	{"id": "size", "name": "Calibre", "unit": "+8% de tamaño de proyectiles, orbes y áreas", "max": 6, "base": 130.0, "grow": 1.44},
	{"id": "reroll", "name": "Cambio de cartas", "unit": "+1 cambio de cartas por partida", "max": 5, "base": 240.0, "grow": 1.64},
	{"id": "tm", "name": "MT", "unit": "Elige tu movimiento inicial (de tus tipos)", "max": 1, "base": 3200.0, "grow": 1.0},
	{"id": "ban", "name": "Veto", "unit": "Bloquea 1 movimiento: no te sale en las cartas", "max": 3, "base": 480.0, "grow": 1.94},
	{"id": "revive", "name": "Segunda oportunidad", "unit": "+1 corazón: al caer, revives con la vida completa", "max": 2, "base": 4000.0, "grow": 2.04},
	{"id": "wslot", "name": "Huecos de arma", "unit": "4 huecos base: +1 por nivel (máximo 6)", "max": 2, "base": 9000.0, "grow": 2.2},
	{"id": "bag", "name": "Mochila", "unit": "Llevas 2 objetos a la vez por partida", "max": 1, "base": 12000.0, "grow": 1.0},
	{"id": "bag3", "name": "Mochila grande", "unit": "Llevas 3 objetos a la vez por partida (requiere Mochila)", "max": 1, "base": 28000.0, "grow": 1.0},
]


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
		"v": SAVE_SCHEMA_VERSION, "created": int(Time.get_unix_time_from_system()), "title": "", "nick": "", "favs": [0, 0, 0], "coins": 600, "tickets": 10, "tickets10": 3, "pity": {}, "legends": {}, "arenas": {}, "lshiny": {}, "owned": {}, "selected": 25, "shiny_on": false,
		"fusions": [], "upgrades": {}, "pup": {}, "claimed": {}, "pban": {}, "pbind": {}, "ptm": {}, "pz": {}, "natures": {}, "pability": {}, "ability_capsules": 0, "learned_tms": {},
		"stats": {"runs": 0, "kills": 0, "best_time": 0, "best_level": 1, "bosses": 0, "chests": 0, "pulls": 0, "shinies": 0, "total_time": 0, "coins_total": 0, "defeated_runs": 0, "rifts": 0},
		"settings": {"master": 80, "music": 70, "sfx": 80, "dmg_numbers": true, "vibration": true, "shake": true, "stick": 1, "stick_fixed": false, "lang": "en", "view": 100, "fov": 165, "pad": 0, "padmap": {}, "mute": false, "quality": 0, "fps": false, "stats_box": false, "adaptive": true, "max_fps": -1, "manual_aim": false, "mono_bonus": false, "fx_op": 1, "act_side": 0, "text_sz": 0},
	}


static func _merge(base: Dictionary, over: Dictionary) -> Dictionary:
	for k in over:
		if base.has(k) and base[k] is Dictionary and over[k] is Dictionary and k != "owned" and k != "upgrades" and k != "pup" and k != "claimed" and k != "pban" and k != "pbind" and k != "ptm" and k != "pz":
			base[k] = _merge(base[k], over[k])
		else:
			base[k] = over[k]
	return base


static func _save_error(message: String) -> void:
	last_save_error = message
	push_warning("[SaveData] " + message)


# Keep older saves compatible: fill missing fields during merge, and replace only malformed
# optional field values with their defaults while preserving the rest of the save.
static func _matches_default_shape(defaults: Dictionary, parsed: Dictionary, path: String = "") -> bool:
	for key in defaults:
		if not parsed.has(key):
			continue
		var expected = defaults[key]
		var actual = parsed[key]
		var field := String(key) if path == "" else path + "." + String(key)
		if expected is Dictionary:
			if actual is Dictionary:
				_matches_default_shape(expected, actual, field)
			else:
				_replace_save_field(parsed, key, expected, field)
		elif expected is Array:
			if not (actual is Array):
				_replace_save_field(parsed, key, expected, field)
		elif expected is int or expected is float:
			if not (actual is int or actual is float):
				_replace_save_field(parsed, key, expected, field)
		elif typeof(actual) != typeof(expected):
			_replace_save_field(parsed, key, expected, field)
	return true


static func _replace_save_field(parsed: Dictionary, key: Variant, expected: Variant, field: String) -> void:
	var fallback: Variant = expected
	if expected is Dictionary or expected is Array:
		fallback = expected.duplicate(true)
	parsed[key] = fallback
	var warning := "Save field '%s' has an invalid type; its default value was used." % field
	_field_warning = warning if _field_warning.is_empty() else _field_warning + "\n" + warning
	last_save_error = _field_warning
	push_warning("[SaveData] " + warning)


static func _usable_save(parsed, path: String) -> bool:
	if not (parsed is Dictionary):
		_save_error("Could not load '%s': the root value is not an object." % path)
		return false
	var version = parsed.get("v", SAVE_SCHEMA_VERSION)
	if not (version is int or version is float):
		_save_error("Could not load '%s': the save version is invalid." % path)
		return false
	if int(version) > SAVE_SCHEMA_VERSION:
		_save_error("Could not load '%s': save version %d is newer than supported version %d." % [path, int(version), SAVE_SCHEMA_VERSION])
		return false
	if not _matches_default_shape(default_data(), parsed):
		return false
	return true


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
	save_blocked = false
	recovered_from_backup = false
	last_save_error = ""
	_field_warning = ""
	load_dex()
	d = default_data()
	var parsed = _read_json(PATH)
	var primary_exists := FileAccess.file_exists(PATH)
	var primary_ok := _usable_save(parsed, PATH) if primary_exists else false
	if primary_ok:
		d = _merge(d, parsed)
	else:
		# A future-version primary save must never be replaced with an older backup or defaults.
		var primary_version = parsed.get("v", SAVE_SCHEMA_VERSION) if parsed is Dictionary else SAVE_SCHEMA_VERSION
		var future_primary := primary_exists and (primary_version is int or primary_version is float) and int(primary_version) > SAVE_SCHEMA_VERSION
		var backup = _read_json(BAK)
		var backup_exists := FileAccess.file_exists(BAK)
		var backup_ok := _usable_save(backup, BAK) if backup_exists and not future_primary else false
		if backup_ok:
			_save_error("Loaded backup '%s' because the primary save could not be used." % BAK)
			d = _merge(d, backup)
			recovered_from_backup = true
		elif primary_exists or backup_exists:
			# Keep damaged/unsupported files untouched until the user explicitly resets the save.
			save_blocked = true
	_migrate_upgrades()
	_migrate_natures()
	_migrate_learned_tms()

	if not save_blocked and not recovered_from_backup and not bool(d.get("gift_6h", false)):
		d["gift_6h"] = true
		d["gcoins"] = int(d.get("gcoins", 0)) + 1
		save()
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
		_save_error("Could not open '%s' for reading (error %d)." % [path, FileAccess.get_open_error()])
		return null
	var text := f.get_as_text()
	f.close()
	var parser := JSON.new()
	var err := parser.parse(text)
	if err != OK:
		_save_error("Could not parse '%s' at line %d: %s." % [path, parser.get_error_line(), parser.get_error_message()])
		return null
	return parser.data


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


# Older profiles receive a stable nature once; new Pokémon receive one when first acquired.
static func _migrate_natures() -> void:
	if not (d.get("natures", {}) is Dictionary):
		d["natures"] = {}
	var natures: Dictionary = d["natures"]
	for key in d.get("owned", {}).keys():
		var nature_id := String(natures.get(String(key), ""))
		if not NATURES_D.valid_id(nature_id):
			var stable_seed: int = absi(int(d.get("created", 0)) + int(key) * 7919)
			natures[String(key)] = String(NATURES_D.IDS[stable_seed % NATURES_D.IDS.size()])


static func _migrate_learned_tms() -> void:
	var stored = d.get("learned_tms", {})
	if not (stored is Dictionary):
		d["learned_tms"] = {}
		return
	var MDd = load("res://scripts/moves_data.gd")
	var GPM = load("res://scripts/gachapon.gd")
	var clean := {}
	for dex_key in stored:
		var dex := int(dex_key)
		if not dex_by.has(dex) or not (stored[dex_key] is Array):
			continue
		var known: Array = []
		for value in stored[dex_key]:
			var id := String(value)
			if not MDd.MOVES.has(id) or not GPM.playable(id) or known.has(id):
				continue
			var move: Dictionary = MDd.MOVES[id]
			var ty := String(move["type"])
			if String(move["kind"]) == "buff" or ty == "normal" or Array(dex_by[dex]["types"]).has(ty):
				continue
			known.append(id)
		if not known.is_empty():
			clean[str(dex)] = known
	d["learned_tms"] = clean


# Write to a temporary file, verify it, preserve the previous primary as backup, then replace it.
static func save() -> bool:
	if not loaded:
		ensure()
	if save_blocked:
		_save_error("Save was not written because existing save data is damaged or from a newer version. Reset it explicitly to replace it.")
		return false
	_matches_default_shape(default_data(), d)
	var field_warning := _field_warning
	last_save_error = ""
	d["v"] = SAVE_SCHEMA_VERSION
	var payload := JSON.stringify(d)
	var f := FileAccess.open(TMP, FileAccess.WRITE)
	if f == null:
		_save_error("Could not open temporary save for writing (error %d)." % FileAccess.get_open_error())
		return false
	f.store_string(payload)
	f.flush()
	var write_error := f.get_error()
	f.close()
	if write_error != OK:
		_save_error("Could not write temporary save (error %d)." % write_error)
		return false
	var check := JSON.new()
	if check.parse(payload) != OK or not _usable_save(check.data, TMP):
		_save_error("Temporary save failed validation; the previous save was left untouched.")
		return false
	if FileAccess.file_exists(PATH) and not recovered_from_backup:
		var copy_error := DirAccess.copy_absolute(ProjectSettings.globalize_path(PATH), ProjectSettings.globalize_path(BAK))
		if copy_error != OK:
			_save_error("Could not preserve the previous save as backup (error %d); the primary save was left untouched." % copy_error)
			return false
	var rename_error := DirAccess.rename_absolute(ProjectSettings.globalize_path(TMP), ProjectSettings.globalize_path(PATH))
	if rename_error != OK:
		_save_error("Could not replace the primary save (error %d); the previous save remains available." % rename_error)
		return false
	recovered_from_backup = false
	last_save_error = field_warning
	return true


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
	save_blocked = false
	recovered_from_backup = false
	last_save_error = ""
	_field_warning = ""
	save()


static func setting(k: String):
	return d["settings"][k]


static func owns(dex: int) -> bool:
	return d["owned"].has(str(dex))


# Equipo guardado (solo Pokemon que tienes); si falta, el seleccionado + los primeros que tengas.
static func team_list() -> Array:
	var out: Array = []
	for x in Array(d.get("team", [])):
		var k: int = int(x)
		if owns(k) and not out.has(k) and out.size() < 3:
			out.append(k)
	if out.is_empty():
		out.append(int(d["selected"]))
	for key in d["owned"].keys():
		if out.size() >= 3:
			break
		if not out.has(int(key)):
			out.append(int(key))
	return out


# Reliquias de la Torre: una por cada piso multiplo de 5 superado alguna vez.
static func tower_relics() -> int:
	var n := 0
	var cl: Dictionary = (d.get("tower", {}) as Dictionary).get("claimed", {})
	for k in cl.keys():
		if int(k) % 5 == 0:
			n += 1
	return n


static func owned_count() -> int:
	return d["owned"].size()


static func add_owned(dex: int, shiny: bool = false) -> void:
	var key := str(dex)
	if not (d.get("natures", {}) is Dictionary):
		d["natures"] = {}
	if d["owned"].has(key):
		d["owned"][key]["n"] = int(d["owned"][key]["n"]) + 1
		if shiny:
			d["owned"][key]["shiny"] = true
	else:
		d["owned"][key] = {"n": 1, "shiny": shiny}
	if not NATURES_D.valid_id(String(d["natures"].get(key, ""))):
		d["natures"][key] = NATURES_D.random_id()
	if shiny:
		d["stats"]["shinies"] = int(d["stats"]["shinies"]) + 1


static func nature_id(dex: int) -> String:
	var value: String = String(d.get("natures", {}).get(str(dex), "steady"))
	return value if NATURES_D.valid_id(value) else "steady"


static func nature_of(dex: int) -> Dictionary:
	return NATURES_D.definition(nature_id(dex))


static func buy_ability_capsule() -> bool:
	const COST := 400
	if int(d.get("coins", 0)) < COST:
		return false
	d["coins"] = int(d["coins"]) - COST
	d["ability_capsules"] = int(d.get("ability_capsules", 0)) + 1
	save()
	return true


static func use_ability_capsule(dex: int) -> bool:
	if not owns(dex) or int(d.get("ability_capsules", 0)) <= 0:
		return false
	var ab = load("res://scripts/abilities.gd")
	var options: Array = ab.capsule_options(dex)
	var current: String = ab.of(dex)
	if options.size() < 2:
		return false
	var next_id: String = String(options[(options.find(current) + 1) % options.size()])
	d["ability_capsules"] = int(d["ability_capsules"]) - 1
	if not (d.get("pability", {}) is Dictionary):
		d["pability"] = {}
	d["pability"][str(dex)] = next_id
	save()
	return true


# MT (mejora permanente): el movimiento inicial elegido para este Pokemon, si ya compraste la MT.
static func start_move_of(dex: int) -> String:
	if up_level("tm", dex) > 0:
		var pick: String = String(d.get("ptm", {}).get(str(dex), ""))
		if pick != "" and tm_pool(dex).has(pick):
			return pick
	return natural_start_of(dex)


static func natural_start_of(dex: int) -> String:
	if starter_by.has(dex):
		return String(starter_by[dex]["start"])
	var MDd = load("res://scripts/moves_data.gd")
	var p: Dictionary = dex_by[dex]
	return String(MDd.START[String(p["types"][0])])


# Movimiento Z (scripts/zmove.gd): tipo desbloqueado para este Pokemon (el elegido, o el primero desbloqueado de sus tipos).
static func zm_types(dex: int) -> Array:
	var ZM = load("res://scripts/zmove.gd")
	var out: Array = []
	for t in dex_by[dex]["types"]:
		if ZM.unlocked(String(t), d["stats"]):
			out.append(String(t))
	return out


static func zm_type_for(dex: int) -> String:
	var l: Array = zm_types(dex)
	if l.is_empty():
		return ""
	var pick: String = String(d.get("pz", {}).get(str(dex), ""))
	if pick != "" and l.has(pick):
		return pick
	return String(l[0])


# Movimientos que se pueden elegir como inicial con la MT: los de sus tipos (Mew, todos), sin los de apoyo.
static func tm_pool(dex: int) -> Array:
	var MDd = load("res://scripts/moves_data.gd")
	var types: Array = dex_by[dex]["types"]
	var out: Array = []
	for id in MDd.ORDER:
		var m: Dictionary = MDd.MOVES[id]
		if String(m["kind"]) == "buff" or not load("res://scripts/gachapon.gd").playable(String(id)):
			continue
		var ty: String = String(m["type"])
		if dex == 151 or ty == "normal" or types.has(ty):
			out.append(String(id))
	for id in Array(d.get("learned_tms", {}).get(str(dex), [])):
		var move_id := String(id)
		if MDd.MOVES.has(move_id) and not out.has(move_id):
			out.append(move_id)
	return out


static func tm_set(dex: int, id: String) -> void:
	d["ptm"][str(dex)] = id
	# El nuevo movimiento inicial no puede estar vetado ni atado a un hueco.
	var l: Array = ban_list(dex).duplicate()
	l.erase(id)
	d["pban"][str(dex)] = l
	save()


# ---- veto y atajos de movimientos (por Pokemon, como en el original) ----
# Movimientos que le pueden salir a un Pokemon en las cartas (sin el de inicio).
static func move_pool(dex: int) -> Array:
	var MDd = load("res://scripts/moves_data.gd")
	var types: Array = dex_by[dex]["types"]
	var start: String = start_move_of(dex)
	var out: Array = []
	for id in MDd.ORDER:
		var ty: String = String(MDd.MOVES[id]["type"])
		if id != start and load("res://scripts/gachapon.gd").playable(String(id)) and (ty == "normal" or types.has(ty) or learned_tm(dex, String(id))):
			out.append(String(id))
	return out


static func learned_tm(dex: int, id: String) -> bool:
	var stored = d.get("learned_tms", {}).get(str(dex), [])
	return stored is Array and stored.has(id)


static func teachable_moves(dex: int) -> Array:
	var MDd = load("res://scripts/moves_data.gd")
	var GPM = load("res://scripts/gachapon.gd")
	var types: Array = dex_by[dex]["types"]
	var out: Array = []
	for id in MDd.ORDER:
		var mid := String(id)
		var move: Dictionary = MDd.MOVES[mid]
		var ty := String(move["type"])
		if String(move["kind"]) == "buff" or ty == "normal" or types.has(ty) or learned_tm(dex, mid) or not GPM.playable(mid):
			continue
		out.append(mid)
	return out


static func buy_and_teach_tm(dex: int, id: String, cost: int = 400) -> bool:
	if not owns(dex) or not teachable_moves(dex).has(id) or int(d.get("coins", 0)) < cost:
		return false
	d["coins"] = int(d["coins"]) - cost
	var learned: Dictionary = d.get("learned_tms", {})
	if not learned.has(str(dex)):
		learned[str(dex)] = []
	learned[str(dex)].append(id)
	d["learned_tms"] = learned
	save()
	return true


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
	if id == "bag3" and up_level("bag", dex) < 1:
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
		"wslots": L.call("wslot"),
		"crit": float(L.call("crit")) * 0.03,
		"size": 1.0 + float(L.call("size")) * 0.08,
		"rerolls": L.call("reroll"),
		"bans": L.call("ban"),
	}



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
const Z_CRYSTAL_P := 0.03   # probabilidad de cristal Z por tirada de 10
static var last_crystal := ""


static func pull(region: int, n: int = 1, use: String = "t1") -> Array:
	last_crystal = ""
	if not can_pull(n, use):
		return []
	var purple: bool = n == 10 and use == "t10"
	if purple:
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
		elif purple and i == n - 1:
			want = 5 if randf() < PURPLE_LEGEND_P else 4
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

	var ZM = load("res://scripts/zmove.gd")
	if n >= 10 and randf() < (Z_CRYSTAL_P_PURPLE if purple else Z_CRYSTAL_P):
		var locked: Array = []
		for zt in ZM.ORDER:
			if not ZM.unlocked(String(zt), d["stats"]):
				locked.append(String(zt))
		if not locked.is_empty():
			last_crystal = String(locked[randi() % locked.size()])
			d["stats"]["zcr_" + last_crystal] = 1
	return out




static var daily_seed_override := -1   # solo tools/mode_matrix.gd: otro "dia" (otro Pokemon y modificador) por semilla


static func daily_seed() -> int:
	if daily_seed_override >= 0:
		return daily_seed_override
	var t: Dictionary = Time.get_date_dict_from_system()
	return int(t["year"]) * 10000 + int(t["month"]) * 100 + int(t["day"])


static func daily_dex(sd: int) -> int:
	var pool: Array = []
	for p in dex_list:
		if not bool(p.get("leg", false)) and smeta.has(str(int(p["dex"]))):
			pool.append(int(p["dex"]))
	if pool.is_empty():
		return 25
	return int(pool[(sd * 7919 + 13) % pool.size()])


static func daily_mod(sd: int) -> String:
	return String(MOD_IDS[(sd * 31 + 7) % MOD_IDS.size()])


static func finish_run(r: Dictionary) -> Dictionary:
	# r: time, kills, level, bosses, chests, coins, tickets
	var pk: Dictionary = perks()
	var coins: int = int(roundf(float(r["coins"]) * float(pk["coins"]))) + int(float(r["time"]) / 6.0) + int(float(r["kills"]) / 10.0)
	coins = int(roundf(float(coins) * float(r.get("mul", 1.0))))
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
		"dead": bool(r.get("dead", true)), "record": record, "moves": r.get("moves", []), "other_dmg": int(r.get("other_dmg", 0)), "other_kills": int(r.get("other_kills", 0)), "ally_dmg": int(r.get("ally_dmg", 0)), "ally_kills": int(r.get("ally_kills", 0)),
		"breakdown": "Recogidas %d · Tiempo +%d · Derrotados +%d" % [picked, int(float(r["time"]) / 6.0), int(float(r["kills"]) / 10.0)] + String(r.get("extra", ""))}
	save()
	return last_run

static var run_chal: Dictionary = {}

const Z_CRYSTAL_P_PURPLE := 0.06

const PURPLE_LEGEND_P := 0.3
