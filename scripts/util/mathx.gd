extends RefCounted
# Hash, ruido, tonos y paletas del mundo (antes en arena.gd). Funciones puras; resultado identico al original.


static func hsh(x: int, y: int, s: int) -> float:
	# Mismo hash de 32 bits que util.js del original (Math.imul).
	var h: int = ((x * 374761393) & 0xFFFFFFFF) ^ ((y * 668265263) & 0xFFFFFFFF) ^ ((s * 2246822519) & 0xFFFFFFFF)
	h = (((h ^ (h >> 13)) & 0xFFFFFFFF) * 1274126177) & 0xFFFFFFFF
	h = h ^ (h >> 16)
	return float(h) / 4294967296.0


static func vnoise(x: float, y: float, s: int) -> float:
	var xi: int = int(floorf(x))
	var yi: int = int(floorf(y))
	var xf: float = x - float(xi)
	var yf: float = y - float(yi)
	var u: float = xf * xf * (3.0 - 2.0 * xf)
	var v: float = yf * yf * (3.0 - 2.0 * yf)
	var a: float = hsh(xi, yi, s)
	var b: float = hsh(xi + 1, yi, s)
	var c: float = hsh(xi, yi + 1, s)
	var d: float = hsh(xi + 1, yi + 1, s)
	return (a + (b - a) * u) * (1.0 - v) + (c + (d - c) * u) * v


static func fbm(x: float, y: float, s: int) -> float:
	return vnoise(x, y, s) * 0.65 + vnoise(x * 2.13 + 17.0, y * 2.13 - 9.0, s + 1) * 0.35


static func shade(c: Color, k: float) -> Color:
	if k >= 0.0:
		return Color(c.r + (1.0 - c.r) * k, c.g + (1.0 - c.g) * k, c.b + (1.0 - c.b) * k, 1.0)
	return Color(c.r * (1.0 + k), c.g * (1.0 + k), c.b * (1.0 + k), 1.0)


static func make_palette(th: Dictionary) -> Dictionary:
	var f := Color(String(th["floor"]))
	var w := Color(String(th["wall"]))
	var lq := Color(String(th["liq"]))
	var lf := Color(String(th["leaf"]))
	var tk := Color(String(th["trunk"]))
	var rk := Color(String(th["rock"]))
	var gr := Color(String(th["grass"]))
	var fls: Array = []
	for h in th["flowers"]:
		fls.append(Color(String(h)))
	return {
		"floor": [f, shade(f, 0.05), shade(f, -0.06)], "dirt": [shade(f, -0.16), shade(f, -0.12), shade(f, -0.2)],
		"speck": shade(f, -0.25), "light": shade(f, 0.22), "flowers": fls,
		"wallTop": [w, shade(w, 0.07), shade(w, -0.07)], "wallLight": shade(w, 0.32), "wallEdge": shade(w, -0.7),
		"wallFace": [shade(w, -0.3), shade(w, -0.38)], "wallFaceDark": shade(w, -0.55), "bg": shade(w, -0.8),
		"liq": lq, "liqDeep": shade(lq, -0.22),
		"foam": Color(String(th["foam"])) if th.has("foam") else shade(lq, 0.55),
		"shore": shade(f, -0.32), "liquid": String(th.get("liquid", "water")), "prop": String(th.get("prop", "tree")),
		"leaf": [shade(lf, -0.35), shade(lf, -0.15), lf, shade(lf, 0.3)],
		"trunk": [shade(tk, -0.2), tk],
		"rock": [shade(rk, -0.2), rk, shade(rk, 0.22)],
		"grass": [shade(gr, -0.28), gr, shade(gr, 0.28)],
	}
