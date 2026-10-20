# Efectos de la habilidad pasiva del Pokemon (AB.FX[..]["fx"] de abilities.gd) en campos con tipo.
# Se leen en cada golpe dado o recibido: un campo con tipo es mas barato que buscar la clave en un Dictionary.
# Una clave ausente queda con su valor por defecto (0.0, "", [] o {}); en los datos ninguna clave presente
# vale 0/""/[], asi que "tiene la clave" equivale a "el campo no esta en su valor por defecto".
extends RefCounted

var empty := true
var taken := 0.0
var contact := ""
var contact_p := 0.0
var resist: Array = []
var resist_k := 1.0   # mismo valor por defecto que tenia ab_fx.get("resist_k", 1.0)
var dmg := 0.0
var pinch := ""
var pinch_k := 0.0
var wspd := ""
var wspd_k := 0.0
var typedmg: Dictionary = {}
var spd := 0.0
var wximm := 0.0
var kind_dmg: Array = []
var kind_k := 0.0
var crit := 0.0
var coin := 0.0
var xp := 0.0
var stimm: Array = []
var trapimm := 0.0
var thorns := 0.0
var sturdy := 0.0
var regen := 0.0
var owntype := 0.0
var magnet := 0.0
var se_taken := 0.0
var first_hit := 0.0
var moxie := 0.0
var moxie_cap := 0.0
var cd := 0.0
var tinted := 0.0
var defiant := 0.0
var boss_dmg := 0.0
var ground := 0.0


func _init(d: Dictionary = {}) -> void:
	empty = d.is_empty()
	for k in d:
		var v = d[k]
		match typeof(v):
			TYPE_INT, TYPE_FLOAT:
				set(k, float(v))
			TYPE_STRING:
				set(k, String(v))
			_:
				set(k, v)
