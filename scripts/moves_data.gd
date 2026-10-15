# moves_data.gd - generado desde moves.js del juego original. No editar a mano.
extends RefCounted

const ORDER := ["tackle", "quick-attack", "swords-dance", "agility", "harden", "ember", "flamethrower", "fire-spin", "heat-wave", "water-gun", "bubble", "hydro-pump", "aqua-ring", "vine-whip", "razor-leaf", "leaf-storm", "giga-drain", "thunder-shock", "discharge", "thunderbolt", "confusion", "psybeam", "psychic", "hypnosis", "dream-eater", "sludge", "mud-shot", "gust", "wing-attack", "body-slam", "hyper-voice", "poison-sting", "toxic", "bulldoze", "bug-bite", "string-shot", "bug-buzz", "rock-throw", "rock-slide", "ice-beam", "powder-snow", "karate-chop", "aura-sphere", "lick", "shadow-ball", "dragon-rage", "dragon-dance", "fairy-wind", "dazzling-gleam", "metal-claw", "flash-cannon", "bite", "dark-pulse", "night-shade", "bonemerang", "psycho-cut", "spikes", "toxic-spikes", "hail", "meteor-mash", "will-o-wisp", "substitute", "aerial-ace", "flame-wheel", "bubble-beam", "hex"]

const MOVES := {
	"tackle": {"id": "tackle", "name": "Placaje", "type": "normal", "kind": "melee", "desc": "Embiste en arco a todo lo que tengas delante.", "cd": 0.5, "dmg": 21, "radius": 68, "arc": 2.13, "knock": 90, "iframes": 0.4},
	"quick-attack": {"id": "quick-attack", "name": "Ataque Rápido", "type": "normal", "kind": "dash", "desc": "Cruzas como un rayo hacia el enemigo y golpeas todo el camino.", "cd": 0.75, "dmg": 28, "radius": 110, "width": 34, "knock": 40, "iframes": 0.7},
	"swords-dance": {"id": "swords-dance", "name": "Danza Espada", "type": "normal", "kind": "buff", "desc": "No hace daño: acumula ATAQUE mientras esté activo.", "cd": 0.85, "stat": "atk", "amount": 0.10, "dur": 7, "stacks": 5},
	"agility": {"id": "agility", "name": "Agilidad", "type": "normal", "kind": "buff", "desc": "No hace daño: acumula VELOCIDAD mientras esté activo.", "cd": 0.85, "stat": "spd", "amount": 0.1, "dur": 7, "stacks": 5},
	"harden": {"id": "harden", "name": "Fortaleza", "type": "normal", "kind": "buff", "desc": "No hace daño: acumula DEFENSA mientras esté activo.", "cd": 0.85, "stat": "def", "amount": 0.07, "dur": 7, "stacks": 5},
	"ember": {"id": "ember", "name": "Ascuas", "type": "fire", "kind": "projectile", "desc": "Bola de fuego al enemigo más cercano.", "cd": 0.52, "dmg": 18, "speed": 310, "count": 1, "spread": 0.12, "pierce": 0, "life": 1.6, "size": 7, "burn": 1},
	"flamethrower": {"id": "flamethrower", "name": "Lanzallamas", "type": "fire", "kind": "cone", "desc": "Chorro de llamas en abanico corto que quema.", "cd": 0.7, "dmg": 7, "count": 7, "arc": 0.9, "speed": 380, "life": 0.42, "size": 6, "pierce": 1, "burn": 1},
	"fire-spin": {"id": "fire-spin", "name": "Giro Fuego", "type": "fire", "kind": "orbit", "desc": "Llamas que giran a tu alrededor. Defensa constante.", "cd": 0.3, "dmg": 14, "count": 3, "radius": 62, "speed": 2.4, "size": 9, "burn": 1},
	"heat-wave": {"id": "heat-wave", "name": "Onda Ígnea", "type": "fire", "kind": "nova", "desc": "Explota en llamas en todas las direcciones.", "cd": 1.25, "dmg": 13, "speed": 250, "count": 10, "pierce": 1, "life": 1.1, "size": 7, "burn": 1},
	"water-gun": {"id": "water-gun", "name": "Pistola Agua", "type": "water", "kind": "projectile", "desc": "Chorro perforante. Fiable a cualquier distancia.", "cd": 0.4, "dmg": 20, "speed": 350, "count": 1, "spread": 0.1, "pierce": 1, "life": 1.5, "size": 6},
	"bubble": {"id": "bubble", "name": "Burbuja", "type": "water", "kind": "nova", "desc": "Burbujas en abanico que ralentizan a quien tocan.", "cd": 1, "dmg": 9, "speed": 210, "count": 8, "pierce": 0, "life": 1.3, "size": 8, "slow": 0.45},
	"hydro-pump": {"id": "hydro-pump", "name": "Hidrobomba", "type": "water", "kind": "beam", "desc": "Cañonazo de agua lento pero devastador.", "cd": 1.5, "dmg": 29, "radius": 250, "width": 30},
	"aqua-ring": {"id": "aqua-ring", "name": "Acua Aro", "type": "water", "kind": "buff", "desc": "No hace daño: acumula REGENERACIÓN de vida.", "cd": 0.9, "stat": "regen", "amount": 1.6, "dur": 8, "stacks": 4},
	"vine-whip": {"id": "vine-whip", "name": "Látigo Cepa", "type": "grass", "kind": "melee", "desc": "Látigos de largo alcance en arco amplio.", "cd": 0.62, "dmg": 25, "radius": 90, "arc": 1.63, "knock": 60, "iframes": 0.22},
	"razor-leaf": {"id": "razor-leaf", "name": "Hoja Afilada", "type": "grass", "kind": "boomerang", "desc": "Dos hojas que van y vuelven cortando a la ida y a la vuelta.", "cd": 0.9, "dmg": 10, "speed": 330, "count": 2, "spread": 0.5, "radius": 210, "size": 6},
	"leaf-storm": {"id": "leaf-storm", "name": "Tormenta Floral", "type": "grass", "kind": "orbit", "desc": "Un ciclón de hojas gira amplio a tu alrededor.", "cd": 0.26, "dmg": 14, "count": 4, "radius": 74, "speed": 2.6, "size": 8},
	"giga-drain": {"id": "giga-drain", "name": "Hierba Lazo", "type": "grass", "kind": "aura", "desc": "Raíces que atrapan y machacan todo lo que tienes cerca.", "cd": 0.55, "dmg": 9, "radius": 76, "cc": "sleep", "ccp": 0.06},
	"thunder-shock": {"id": "thunder-shock", "name": "Impactrueno", "type": "electric", "kind": "projectile", "desc": "Descarga rapidísima que atraviesa varios enemigos.", "cd": 0.4, "dmg": 16, "speed": 480, "count": 1, "spread": 0.08, "pierce": 2, "life": 1.1, "size": 5, "cc": "para", "ccp": 0.18},
	"discharge": {"id": "discharge", "name": "Chispazo", "type": "electric", "kind": "aura", "desc": "Campo eléctrico permanente alrededor de ti.", "cd": 0.45, "dmg": 13, "radius": 100, "cc": "para", "ccp": 0.07},
	"thunderbolt": {"id": "thunderbolt", "name": "Rayo", "type": "electric", "kind": "chain", "desc": "Un rayo que salta de un enemigo a otro.", "cd": 0.95, "dmg": 21, "count": 4, "radius": 140, "cc": "para", "ccp": 0.15},
	"confusion": {"id": "confusion", "name": "Confusión", "type": "psychic", "kind": "projectile", "desc": "Onda que persigue sola a su objetivo.", "cd": 0.5, "dmg": 22, "speed": 280, "count": 1, "spread": 0.1, "pierce": 1, "life": 2.2, "size": 8, "homing": 2, "cc": "conf", "ccp": 0.14},
	"psybeam": {"id": "psybeam", "name": "Psicorrayo", "type": "psychic", "kind": "beam", "desc": "Rayo psíquico ancho y contundente.", "cd": 1.15, "dmg": 17, "radius": 215, "width": 40, "cc": "conf", "ccp": 0.12},
	"psychic": {"id": "psychic", "name": "Psíquico", "type": "psychic", "kind": "nova", "desc": "Estallido mental radial que busca enemigos.", "cd": 1.35, "dmg": 10, "speed": 230, "count": 12, "pierce": 1, "life": 1.6, "size": 7, "homing": 1, "cc": "conf", "ccp": 0.1},
	"hypnosis": {"id": "hypnosis", "name": "Hipnosis", "type": "psychic", "kind": "aura", "desc": "Ondas hipnóticas que pueden dormir a los enemigos cercanos.", "cd": 1.1, "dmg": 5, "radius": 120, "cc": "sleep", "ccp": 0.3},
	"dream-eater": {"id": "dream-eater", "name": "Come Sueños", "type": "psychic", "kind": "aura", "desc": "Devora los sueños: solo golpea a enemigos dormidos, con mucho daño, y te cura.", "cd": 0.7, "dmg": 46, "radius": 150, "dream": 1, "heal": 0.012, "cc": "sleep", "ccp": 0.0},
	"sludge": {"id": "sludge", "name": "Residuos", "type": "poison", "kind": "projectile", "desc": "Lodo tóxico que envenena al impactar.", "cd": 0.6, "dmg": 17, "speed": 290, "count": 1, "spread": 0.12, "pierce": 0, "life": 1.5, "size": 8, "poison": 1},
	"mud-shot": {"id": "mud-shot", "name": "Disparo Lodo", "type": "ground", "kind": "nova", "desc": "Salpica lodo alrededor y ralentiza.", "cd": 1.1, "dmg": 11, "speed": 200, "count": 7, "pierce": 0, "life": 1, "size": 9, "slow": 0.4},
	"gust": {"id": "gust", "name": "Tornado", "type": "flying", "kind": "orbit", "desc": "Remolinos de viento que te escoltan y empujan a los enemigos hacia atrás. Más nivel, más empuje.", "cd": 0.26, "dmg": 22, "count": 3, "radius": 80, "speed": 2.8, "size": 8, "knock": 160},
	"wing-attack": {"id": "wing-attack", "name": "Ataque Ala", "type": "flying", "kind": "melee", "desc": "Barrido de alas amplio que empuja.", "cd": 0.55, "dmg": 22, "radius": 78, "arc": 2.38, "knock": 70, "iframes": 0.24},
	"body-slam": {"id": "body-slam", "name": "Golpe Cuerpo", "type": "normal", "kind": "melee", "desc": "Placaje con todo el peso: lento, corto y brutal.", "cd": 0.65, "dmg": 42, "radius": 66, "arc": 2.75, "knock": 140, "iframes": 0.3},
	"hyper-voice": {"id": "hyper-voice", "name": "Vozarrón", "type": "normal", "kind": "nova", "desc": "Onda sonora que sale en todas direcciones.", "cd": 1.15, "dmg": 12, "speed": 260, "count": 9, "pierce": 1, "life": 0.9, "size": 7},
	"poison-sting": {"id": "poison-sting", "name": "Picotazo Veneno", "type": "poison", "kind": "projectile", "desc": "Aguijón rápido que envenena.", "cd": 0.34, "dmg": 8, "speed": 420, "count": 1, "spread": 0.08, "pierce": 0, "life": 1, "size": 4, "poison": 1},
	"toxic": {"id": "toxic", "name": "Tóxico", "type": "poison", "kind": "trail", "desc": "Vas dejando charcos de veneno que intoxican a quien los pisa.", "cd": 0.3, "dmg": 6, "radius": 26, "dur": 3, "poison": 1},
	"bulldoze": {"id": "bulldoze", "name": "Terratemblor", "type": "ground", "kind": "aura", "desc": "Sacude el suelo: daña y frena a lo cercano.", "cd": 0.7, "dmg": 11, "radius": 80, "slow": 0.35},
	"bug-bite": {"id": "bug-bite", "name": "Picadura", "type": "bug", "kind": "melee", "desc": "Mordisco rápido en arco corto.", "cd": 0.42, "dmg": 17, "radius": 62, "arc": 2, "knock": 40, "iframes": 0.18},
	"string-shot": {"id": "string-shot", "name": "Disparo Demora", "type": "bug", "kind": "mine", "desc": "Deja telarañas en el suelo que atrapan y frenan mucho al que las pisa.", "cd": 1.1, "dmg": 14, "count": 2, "radius": 56, "dur": 7, "slow": 0.6},
	"bug-buzz": {"id": "bug-buzz", "name": "Zumbido", "type": "bug", "kind": "aura", "desc": "Vibración constante que machaca lo cercano.", "cd": 0.45, "dmg": 8, "radius": 66},
	"rock-throw": {"id": "rock-throw", "name": "Lanzarrocas", "type": "rock", "kind": "projectile", "desc": "Pedrusco pesado que empuja al enemigo.", "cd": 0.6, "dmg": 32, "speed": 260, "count": 1, "spread": 0.12, "pierce": 0, "life": 1.4, "size": 9, "knock": 90},
	"rock-slide": {"id": "rock-slide", "name": "Avalancha", "type": "rock", "kind": "meteor", "desc": "Caen rocas del cielo sobre los enemigos cercanos.", "cd": 1.3, "dmg": 21, "count": 3, "radius": 46, "knock": 50},
	"ice-beam": {"id": "ice-beam", "name": "Rayo Hielo", "type": "ice", "kind": "beam", "desc": "Rayo helado que congela casi del todo.", "cd": 1.1, "dmg": 20, "radius": 220, "width": 30, "slow": 0.7, "cc": "freeze", "ccp": 0.15},
	"powder-snow": {"id": "powder-snow", "name": "Nieve Polvo", "type": "ice", "kind": "aura", "desc": "Ventisca a tu alrededor que ralentiza.", "cd": 0.55, "dmg": 8, "radius": 76, "slow": 0.45, "cc": "freeze", "ccp": 0.07},
	"karate-chop": {"id": "karate-chop", "name": "Golpe Kárate", "type": "fighting", "kind": "melee", "desc": "Golpe seco y potente al frente.", "cd": 0.5, "dmg": 28, "radius": 70, "arc": 1.5, "knock": 110, "iframes": 0.22},
	"aura-sphere": {"id": "aura-sphere", "name": "Esfera Aural", "type": "fighting", "kind": "projectile", "desc": "Esfera de energía que nunca falla.", "cd": 0.62, "dmg": 17, "speed": 300, "count": 1, "spread": 0.1, "pierce": 0, "life": 2, "size": 8, "homing": 4},
	"lick": {"id": "lick", "name": "Lengüetazo", "type": "ghost", "kind": "melee", "desc": "Lametazo espectral que paraliza un poco.", "cd": 0.48, "dmg": 18, "radius": 66, "arc": 2.25, "slow": 0.4, "iframes": 0.2, "cc": "para", "ccp": 0.2},
	"shadow-ball": {"id": "shadow-ball", "name": "Bola Sombra", "type": "ghost", "kind": "projectile", "desc": "Esfera oscura que atraviesa a varios.", "cd": 0.66, "dmg": 19, "speed": 280, "count": 1, "spread": 0.1, "pierce": 2, "life": 1.6, "size": 9},
	"dragon-rage": {"id": "dragon-rage", "name": "Furia Dragón", "type": "dragon", "kind": "beam", "desc": "Llamarada dracónica en línea recta.", "cd": 1, "dmg": 26, "radius": 230, "width": 34},
	"dragon-dance": {"id": "dragon-dance", "name": "Danza Dragón", "type": "dragon", "kind": "buff", "desc": "No hace daño: acumula ATAQUE más rápido que Danza Espada.", "cd": 0.7, "stat": "atk", "amount": 0.085, "dur": 7, "stacks": 5},
	"fairy-wind": {"id": "fairy-wind", "name": "Viento Feérico", "type": "fairy", "kind": "nova", "desc": "Brisa mágica en todas direcciones.", "cd": 1, "dmg": 11, "speed": 230, "count": 10, "pierce": 0, "life": 1.2, "size": 7},
	"dazzling-gleam": {"id": "dazzling-gleam", "name": "Brillo Mágico", "type": "fairy", "kind": "aura", "desc": "Destello a tu alrededor.", "cd": 0.5, "dmg": 9, "radius": 72},
	"metal-claw": {"id": "metal-claw", "name": "Garra Metal", "type": "steel", "kind": "melee", "desc": "Zarpazo de acero en arco.", "cd": 0.5, "dmg": 24, "radius": 70, "arc": 2, "knock": 60, "iframes": 0.22},
	"flash-cannon": {"id": "flash-cannon", "name": "Foco Resplandor", "type": "steel", "kind": "beam", "desc": "Rayo de luz metálica que perfora.", "cd": 1.05, "dmg": 23, "radius": 220, "width": 30},
	"bite": {"id": "bite", "name": "Mordisco", "type": "dark", "kind": "melee", "desc": "Dentellada rápida que hace retroceder.", "cd": 0.45, "dmg": 22, "radius": 64, "arc": 1.88, "knock": 70, "iframes": 0.2},
	"dark-pulse": {"id": "dark-pulse", "name": "Pulso Umbrío", "type": "dark", "kind": "nova", "desc": "Onda de energía oscura en todas direcciones.", "cd": 1.15, "dmg": 14, "speed": 240, "count": 10, "pierce": 1, "life": 1.1, "size": 8},
	"night-shade": {"id": "night-shade", "name": "Tinieblas", "type": "dark", "kind": "aura", "desc": "Una sombra te rodea y consume lo cercano.", "cd": 0.5, "dmg": 9, "radius": 72, "cc": "sleep", "ccp": 0.08},
	"bonemerang": {"id": "bonemerang", "name": "Huesomerang", "type": "ground", "kind": "boomerang", "desc": "Un hueso que va y vuelve golpeando fuerte.", "cd": 0.95, "dmg": 16, "speed": 300, "count": 1, "radius": 230, "size": 8, "knock": 40},
	"psycho-cut": {"id": "psycho-cut", "name": "Psicocorte", "type": "psychic", "kind": "boomerang", "desc": "Cuchillas psíquicas que vuelven a ti.", "cd": 0.8, "dmg": 9, "speed": 360, "count": 2, "spread": 0.6, "radius": 200, "size": 7},
	"spikes": {"id": "spikes", "name": "Púas", "type": "ground", "kind": "mine", "desc": "Siembra púas que estallan al pisarlas.", "cd": 1.2, "dmg": 18, "count": 2, "radius": 60, "dur": 8},
	"toxic-spikes": {"id": "toxic-spikes", "name": "Púas Tóxicas", "type": "poison", "kind": "mine", "desc": "Púas venenosas que envenenan mucho al estallar.", "cd": 1.1, "dmg": 11, "count": 2, "radius": 56, "dur": 8, "poison": 2},
	"hail": {"id": "hail", "name": "Granizo", "type": "ice", "kind": "meteor", "desc": "Bolas de hielo caen sobre los enemigos y los frenan.", "cd": 1.2, "dmg": 18, "count": 4, "radius": 40, "slow": 0.4, "cc": "freeze", "ccp": 0.12},
	"meteor-mash": {"id": "meteor-mash", "name": "Puño Meteoro", "type": "steel", "kind": "meteor", "desc": "Dos meteoros de acero que aplastan donde caen.", "cd": 1.4, "dmg": 34, "count": 2, "radius": 54, "knock": 80},
	"will-o-wisp": {"id": "will-o-wisp", "name": "Fuego Fatuo", "type": "fire", "kind": "turret", "desc": "Deja una llama flotante que dispara sola y quema.", "cd": 3.5, "dmg": 15, "rate": 0.55, "dur": 6, "count": 1, "range": 300, "speed": 300, "size": 7, "burn": 1},
	"substitute": {"id": "substitute", "name": "Sustituto", "type": "normal", "kind": "turret", "desc": "Un muñeco que se queda disparando por ti.", "cd": 4, "dmg": 14, "rate": 0.4, "dur": 6, "count": 1, "range": 280, "speed": 320, "size": 6},
	"aerial-ace": {"id": "aerial-ace", "name": "Golpe Aéreo", "type": "flying", "kind": "dash", "desc": "Te lanzas en picado y cortas todo lo que cruzas.", "cd": 0.75, "dmg": 18, "radius": 120, "width": 40, "knock": 60},
	"flame-wheel": {"id": "flame-wheel", "name": "Rueda Fuego", "type": "fire", "kind": "trail", "desc": "Corres envuelto en fuego y dejas un rastro de llamas.", "cd": 0.28, "dmg": 10, "radius": 28, "dur": 2.6, "burn": 1},
	"bubble-beam": {"id": "bubble-beam", "name": "Rayo Burbuja", "type": "water", "kind": "cone", "desc": "Chorro de burbujas en abanico corto que frena.", "cd": 0.65, "dmg": 6, "count": 7, "arc": 1, "speed": 340, "life": 0.45, "size": 6, "slow": 0.3},
	"hex": {"id": "hex", "name": "Infortunio", "type": "ghost", "kind": "chain", "desc": "Maldición que salta entre enemigos. Mucho más daño si están quemados, envenenados, frenados o con un estado alterado.", "cd": 0.9, "dmg": 17, "count": 4, "radius": 150, "hex": 1.7},
}

const LADDERS := {
	"projectile": [{"t": "+1 proyectil", "m": {"count": 1, "spread": 1.4}}, {"t": "+45% daño", "m": {"dmg": 1.45}}, {"t": "-25% recarga", "m": {"cd": 0.75}}, {"t": "+1 proyectil y +1 perforación", "m": {"count": 1, "pierce": 1, "spread": 1.2}}],
	"melee": [{"t": "+40% daño", "m": {"dmg": 1.4}}, {"t": "+25% alcance", "m": {"radius": 1.25}}, {"t": "-25% recarga", "m": {"cd": 0.75}}, {"t": "Golpea en 360° y +50% daño", "m": {"arc": 9, "dmg": 1.5}}],
	"beam": [{"t": "+45% daño", "m": {"dmg": 1.45}}, {"t": "+30% alcance y grosor", "m": {"radius": 1.3, "width": 1.3}}, {"t": "-25% recarga", "m": {"cd": 0.75}}, {"t": "+50% daño", "m": {"dmg": 1.5}}],
	"orbit": [{"t": "+1 orbe", "m": {"count": 1}}, {"t": "+55% daño", "m": {"dmg": 1.55}}, {"t": "+25% radio y gira más rápido", "m": {"radius": 1.25, "speed": 1.35}}, {"t": "+1 orbe y +55% daño", "m": {"count": 1, "dmg": 1.55}}],
	"nova": [{"t": "+4 proyectiles", "m": {"count": 4}}, {"t": "+40% daño", "m": {"dmg": 1.4}}, {"t": "-25% recarga", "m": {"cd": 0.75}}, {"t": "+4 proyectiles y +1 perforación", "m": {"count": 4, "pierce": 1}}],
	"aura": [{"t": "+30% radio", "m": {"radius": 1.3}}, {"t": "+45% daño", "m": {"dmg": 1.45}}, {"t": "Golpea un 40% más a menudo", "m": {"cd": 0.7}}, {"t": "+30% radio y +50% daño", "m": {"radius": 1.3, "dmg": 1.5}}],
	"boomerang": [{"t": "+1 bumerán", "m": {"count": 1}}, {"t": "+45% daño", "m": {"dmg": 1.45}}, {"t": "+30% alcance", "m": {"radius": 1.3}}, {"t": "+1 bumerán y +40% daño", "m": {"count": 1, "dmg": 1.4}}],
	"chain": [{"t": "+2 saltos", "m": {"count": 2}}, {"t": "+45% daño", "m": {"dmg": 1.45}}, {"t": "-25% recarga", "m": {"cd": 0.75}}, {"t": "+2 saltos y +40% daño", "m": {"count": 2, "dmg": 1.4}}],
	"mine": [{"t": "+1 mina", "m": {"count": 1}}, {"t": "+50% daño", "m": {"dmg": 1.5}}, {"t": "+30% radio de explosión", "m": {"radius": 1.3}}, {"t": "+1 mina y -25% recarga", "m": {"count": 1, "cd": 0.75}}],
	"meteor": [{"t": "+1 meteoro", "m": {"count": 1}}, {"t": "+45% daño", "m": {"dmg": 1.45}}, {"t": "+30% radio", "m": {"radius": 1.3}}, {"t": "+2 meteoros y -20% recarga", "m": {"count": 2, "cd": 0.8}}],
	"turret": [{"t": "+50% daño", "m": {"dmg": 1.5}}, {"t": "Dispara un 35% más rápido", "m": {"rate": 0.74}}, {"t": "+1 a la vez", "m": {"count": 1}}, {"t": "+50% duración y +40% daño", "m": {"dur": 1.5, "dmg": 1.4}}],
	"dash": [{"t": "+40% daño", "m": {"dmg": 1.4}}, {"t": "+30% distancia", "m": {"radius": 1.3}}, {"t": "-25% recarga", "m": {"cd": 0.75}}, {"t": "+60% daño y más ancho", "m": {"dmg": 1.6, "width": 1.4}}],
	"trail": [{"t": "+40% daño", "m": {"dmg": 1.4}}, {"t": "+40% duración", "m": {"dur": 1.4}}, {"t": "Charcos un 30% más grandes", "m": {"radius": 1.3}}, {"t": "+50% daño y +30% radio", "m": {"dmg": 1.5, "radius": 1.3}}],
	"cone": [{"t": "+3 disparos", "m": {"count": 3}}, {"t": "+40% daño", "m": {"dmg": 1.4}}, {"t": "+30% alcance", "m": {"life": 1.3}}, {"t": "+3 disparos y +1 perforación", "m": {"count": 3, "pierce": 1}}],
	"buff": [{"t": "+1 acumulación máxima", "m": {"stacks": 1}}, {"t": "+40% potencia", "m": {"amount": 1.4}}, {"t": "+50% duración", "m": {"dur": 1.5}}, {"t": "+1 acumulación y +40% potencia", "m": {"stacks": 1, "amount": 1.4}}],
}

# Empuje que se gana al mejorar el movimiento (nivel 1: sin empuje; sube un 50 % del base por cada nivel desde el 2)
const KNOCK_LV := {"heat-wave": 200, "bubble": 150, "psychic": 150, "mud-shot": 180, "hyper-voice": 260, "fairy-wind": 150, "dark-pulse": 170, "bulldoze": 200, "bug-buzz": 140, "hydro-pump": 180, "flamethrower": 120, "bubble-beam": 100, "water-gun": 60, "shadow-ball": 70, "aura-sphere": 90, "meteor-mash": 90, "hail": 60, "razor-leaf": 60, "fire-spin": 70, "leaf-storm": 70}

const EVO := {"tackle": ["Derribo", "hp"], "quick-attack": ["Velocidad Extrema", "spd"], "body-slam": ["Gigaimpacto", "atk"], "hyper-voice": ["Alboroto", "cd"], "ember": ["Llamarada", "atk"], "flamethrower": ["Sofoco", "cd"], "fire-spin": ["Fuego Sagrado", "rgn"], "heat-wave": ["Erupción", "hp"], "water-gun": ["Escaldar", "atk"], "bubble": ["Surf", "spd"], "hydro-pump": ["Hidrocañón", "atk"], "vine-whip": ["Latigazo", "atk"], "razor-leaf": ["Lluevehojas", "cd"], "leaf-storm": ["Danza Pétalo", "rgn"], "giga-drain": ["Planta Feroz", "hp"], "thunder-shock": ["Trueno", "atk"], "discharge": ["Campo Eléctrico", "def"], "thunderbolt": ["Electrocañón", "cd"], "confusion": ["Psicocarga", "cd"], "psybeam": ["Premonición", "atk"], "psychic": ["Vasta Fuerza", "mag"], "sludge": ["Bomba Lodo", "atk"], "poison-sting": ["Puya Nociva", "spd"], "toxic": ["Gas Venenoso", "rgn"], "mud-shot": ["Tierra Viva", "atk"], "bulldoze": ["Terremoto", "atk"], "gust": ["Vendaval", "spd"], "wing-attack": ["Pájaro Osado", "atk"], "bug-bite": ["Tijera X", "atk"], "string-shot": ["Red Viscosa", "cd"], "bug-buzz": ["Enjambre", "rgn"], "rock-throw": ["Roca Afilada", "atk"], "rock-slide": ["Trampa Rocas", "cd"], "ice-beam": ["Ventisca", "atk"], "powder-snow": ["Viento Hielo", "spd"], "karate-chop": ["A Bocajarro", "atk"], "aura-sphere": ["Onda Certera", "cd"], "lick": ["Puño Sombra", "atk"], "shadow-ball": ["Golpe Fantasma", "cd"], "dragon-rage": ["Cometa Draco", "atk"], "fairy-wind": ["Fuerza Lunar", "atk"], "dazzling-gleam": ["Campo de Niebla", "rgn"], "metal-claw": ["Cabeza de Hierro", "atk"], "flash-cannon": ["Rayo Metálico", "def"], "bite": ["Triturar", "atk"], "dark-pulse": ["Alarido", "spd"], "night-shade": ["Pesadilla", "rgn"], "bonemerang": ["Ataque Óseo", "atk"], "psycho-cut": ["Psicocolmillo", "cd"], "spikes": ["Fisura", "atk"], "toxic-spikes": ["Lanza Mugre", "rgn"], "hail": ["Alud", "cd"], "meteor-mash": ["Bomba Imán", "atk"], "will-o-wisp": ["Infierno", "cd"], "substitute": ["Doble Equipo", "def"], "aerial-ace": ["Acróbata", "spd"], "flame-wheel": ["Envite Ígneo", "spd"], "bubble-beam": ["Acua Cola", "atk"], "hex": ["Poltergeist", "mag"]}

# Segunda evolucion de un movimiento (se elige la que cumpla su condicion): [nombre, estadistica que pide, texto, ajustes]
const EVO_ALT := {
	"gust": ["Ciclón Colosal", "size", "+2 orbes, ×1,5 daño, orbes mucho más grandes y el doble de empuje", {"count": 2, "dmg": 1.5, "size": 1.5, "radius": 1.2, "knock": 320}],
	"fire-spin": ["Vórtice Ígneo", "bigorb", "+2 orbes, ×1,4 daño, orbes y anillo mucho más grandes", {"count": 2, "dmg": 1.4, "size": 1.5, "radius": 1.25}],
	"leaf-storm": ["Huracán Floral", "bigorb", "+2 orbes, ×1,4 daño, orbes y ciclón mucho más grandes", {"count": 2, "dmg": 1.4, "size": 1.5, "radius": 1.25}],
	"bulldoze": ["Sismo Colosal", "bigorb", "×1,5 daño, área ×1,6 y frena más a los enemigos", {"dmg": 1.5, "radius": 1.6, "slow": 0.5}],
	"discharge": ["Descarga Titánica", "bigorb", "×1,5 daño, área ×1,6 y más probabilidad de paralizar", {"dmg": 1.5, "radius": 1.6, "ccp": 0.12}],
	"flamethrower": ["Llamarada Colosal", "bigorb", "+4 llamas, ×1,4 daño y llamas mucho más grandes", {"dmg": 1.4, "size": 1.8, "count": 4}],
	"toxic": ["Ciénaga Colosal", "bigorb", "×2 daño, charcos enormes y mucho más duraderos", {"dmg": 2.0, "radius": 1.8, "dur": 1.5}],
	"flame-wheel": ["Rueda Colosal", "bigorb", "×2 daño, rastro de llamas enorme y mucho más duradero", {"dmg": 2.0, "radius": 1.8, "dur": 1.5}],
	"razor-leaf": ["Hoja Colosal", "bigorb", "+1 hoja, ×1,5 daño y hojas mucho más grandes", {"dmg": 1.5, "size": 1.8, "count": 1}],
}

# Ajustes extra al evolucionar un movimiento concreto (ademas de EVO_MODS de su tipo de movimiento).
const EVO_EXTRA := {
	"confusion": {"dmg": 1.6},
	"rock-throw": {"dmg": 1.6, "knock": 30},
	"shadow-ball": {"dmg": 1.3},
	"fairy-wind": {"dmg": 1.5},
	"gust": {"dmg": 1.6},
}

const NEED_NAME := {"hp": "Vigor", "atk": "Potencia", "spd": "Carrera", "cd": "Reflejos", "def": "Coraza", "rgn": "Síntesis", "mag": "Imán", "xp": "Aprendizaje", "size": "Calibre", "bigorb": "Esfera Colosal"}

const EVO_MODS := {
	"projectile": {"t": "×1,8 daño, +2 proyectiles, +2 perforación y más grandes", "m": {"dmg": 1.8, "count": 2, "pierce": 2, "size": 1.3, "spread": 1.1}},
	"melee": {"t": "×1,9 daño, más alcance y golpea en 360°", "m": {"dmg": 1.9, "radius": 1.3, "arc": 9}},
	"beam": {"t": "×1,8 daño, rayo un 50% más grueso y más largo", "m": {"dmg": 1.8, "width": 1.5, "radius": 1.2, "cd": 0.85}},
	"orbit": {"t": "+2 orbes, ×1,7 daño y más radio", "m": {"count": 2, "dmg": 1.7, "radius": 1.15}},
	"nova": {"t": "+6 proyectiles, ×1,6 daño y +1 perforación", "m": {"count": 6, "dmg": 1.6, "pierce": 1}},
	"aura": {"t": "×1,8 daño y un 35% más de radio", "m": {"dmg": 1.8, "radius": 1.35}},
	"boomerang": {"t": "×1,8 daño, +1 bumerán y más alcance", "m": {"dmg": 1.8, "count": 1, "radius": 1.2, "size": 1.2}},
	"chain": {"t": "×1,7 daño y +3 saltos", "m": {"dmg": 1.7, "count": 3, "radius": 1.2}},
	"mine": {"t": "×1,8 daño, +2 minas y explosión más grande", "m": {"dmg": 1.8, "count": 2, "radius": 1.25}},
	"meteor": {"t": "×1,7 daño, +2 meteoros y más radio", "m": {"dmg": 1.7, "count": 2, "radius": 1.2}},
	"turret": {"t": "×1,8 daño, +1 a la vez y dispara más rápido", "m": {"dmg": 1.8, "count": 1, "rate": 0.8}},
	"dash": {"t": "×1,9 daño, más distancia y menos recarga", "m": {"dmg": 1.9, "radius": 1.25, "cd": 0.8}},
	"trail": {"t": "×1,8 daño, charcos más grandes y duraderos", "m": {"dmg": 1.8, "radius": 1.25, "dur": 1.3}},
	"cone": {"t": "×1,7 daño, +4 disparos y +1 perforación", "m": {"dmg": 1.7, "count": 4, "pierce": 1}},
}

const START := {"fire": "ember", "water": "water-gun", "grass": "vine-whip", "electric": "thunder-shock", "psychic": "confusion", "poison": "sludge", "ground": "mud-shot", "flying": "gust", "bug": "bug-bite", "rock": "rock-throw", "ice": "ice-beam", "fighting": "karate-chop", "ghost": "shadow-ball", "dragon": "dragon-rage", "fairy": "fairy-wind", "steel": "metal-claw", "dark": "bite", "normal": "tackle"}

const TYPE_COLOR := {"normal": "#b0a99f", "fire": "#ff7b3d", "water": "#4b9bff", "grass": "#5fcb6a", "electric": "#ffd33d", "ice": "#7fe0e0", "fighting": "#e0533d", "poison": "#b45ec4", "ground": "#d6b25c", "flying": "#9bb8ff", "psychic": "#ff5f9e", "bug": "#a3c43d", "rock": "#bfa96b", "ghost": "#7a6bc4", "dragon": "#6b58ff", "dark": "#6b5c52", "steel": "#a8b8c4", "fairy": "#ff9ed8"}

const TYPE_NAME := {"normal": "Normal", "fire": "Fuego", "water": "Agua", "grass": "Planta", "electric": "Eléctrico", "ice": "Hielo", "fighting": "Lucha", "poison": "Veneno", "ground": "Tierra", "flying": "Volador", "psychic": "Psíquico", "bug": "Bicho", "rock": "Roca", "ghost": "Fantasma", "dragon": "Dragón", "dark": "Siniestro", "steel": "Acero", "fairy": "Hada"}
