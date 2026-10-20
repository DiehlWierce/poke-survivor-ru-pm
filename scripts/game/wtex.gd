# Texturas de objetos del mundo (assets/world), cargadas una vez y en cache.
extends RefCounted

const SC := 2.4   # objetos del mundo (cofres, altares, fuentes...) un 20 % mas pequenos
static var cache := {}

static func get_t(n: String) -> Texture2D:
	if not cache.has(n):
		var p: String = "res://assets/world/%s.png" % n
		cache[n] = load(p) if ResourceLoader.exists(p) else null
	return cache[n]
