extends RefCounted

# A small, original nature system for permanent Pokémon profiles.
const IDS := ["steady", "swift", "fierce", "vital", "light"]
const DEFINITIONS := {
	"steady": {"name": "Equilibrada", "hp": 1.0, "atk": 1.0, "spd": 1.0},
	"swift": {"name": "Veloz", "hp": 1.0, "atk": 0.96, "spd": 1.08},
	"fierce": {"name": "Fuerte", "hp": 1.0, "atk": 1.08, "spd": 0.96},
	"vital": {"name": "Vital", "hp": 1.08, "atk": 0.96, "spd": 1.0},
	"light": {"name": "Ligera", "hp": 0.96, "atk": 1.0, "spd": 1.08},
}


static func random_id() -> String:
	return String(IDS[randi() % IDS.size()])


static func valid_id(id: String) -> bool:
	return DEFINITIONS.has(id)


static func definition(id: String) -> Dictionary:
	return DEFINITIONS.get(id, DEFINITIONS["steady"])
