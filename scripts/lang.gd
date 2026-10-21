extends RefCounted
# Idioma: el texto fuente del juego esta en espanol (de Espana). Cada idioma es una Translation
# cuya clave es ese texto en espanol. Se cambia en Ajustes y se guarda en la partida.
# "es" = Espanol (Espana): sin traduccion. "es_419" = Espanol latinoamericano: solo las
# diferencias. El resto carga data/lang_<codigo>.json (incluye nombres de Pokemon y movimientos).

# [codigo, nombre en su propio idioma]
const LANGS := [
	["en", "English"],
	["es_419", "Español (Latinoamérica)"],
	["es", "Español (España)"],
	["fr", "Français"],
	["it", "Italiano"],
	["pt_BR", "Português (Brasil)"],
	["pt_PT", "Português (Portugal)"],
	["ru", "Русский"],
	["ja", "日本語"],
	["zh_CN", "中文（普通话）"],
	["zh_HK", "廣東話（粵語）"],
	["vi", "Tiếng Việt"],
]
const DEFAULT := "en"
const SV = preload("res://scripts/save_data.gd")
const PX = preload("res://scripts/pxfont.gd")

static var tr: Translation = null
static var added := false
static var loaded_code := ""


static func codes() -> Array:
	var a: Array = []
	for l in LANGS:
		a.append(l[0])
	return a


static func lang() -> String:
	SV.ensure()
	var c := String(SV.d["settings"].get("lang", DEFAULT))
	return c if c in codes() else DEFAULT


static func lang_name(code: String) -> String:
	for l in LANGS:
		if l[0] == code:
			return l[1]
	return code


static func _load_json(path: String) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var dct = JSON.parse_string(f.get_as_text())
	return dct if dct is Dictionary else {}


static func apply() -> void:
	var code := lang()
	if added and tr != null:
		TranslationServer.remove_translation(tr)
		added = false
	if code == "es":  # el texto fuente ya esta en espanol de Espana
		tr = null
		loaded_code = code
	elif tr == null or loaded_code != code:
		tr = Translation.new()
		tr.locale = "en"
		var dct := _load_json("res://data/lang_%s.json" % code)
		for feature_path in ["res://data/lang_features.json", "res://data/lang_second_move.json"]:
			var feature_root := _load_json(feature_path)
			var feature_strings = feature_root.get(code, {})
			if feature_strings is Dictionary:
				for key in feature_strings:
					dct[key] = feature_strings[key]
		for k in dct:
			tr.add_message(StringName(k), StringName(String(dct[k])))
		loaded_code = code
	if tr != null:
		TranslationServer.add_translation(tr)
		added = true
	TranslationServer.set_locale("en")
	PX.set_lang(code)


static var log := {}
static var logging := false


static func t(s: String) -> String:
	var r: String = TranslationServer.translate(s)
	if logging:
		log[s] = r
	return r


# Nombre de especie (clave = nombre del pokedex en ingles).
static func sp(name: String) -> String:
	return t(name)


static func is_en() -> bool:
	return lang() == "en"
