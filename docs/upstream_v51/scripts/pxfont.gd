extends RefCounted



const OUTLINE: = Color("#1b1528")
const CJK: = {
	"ja": "res://fonts/NotoCJK_ja.otf", 
	"zh_CN": "res://fonts/NotoCJK_zh_CN.otf", 
	"zh_HK": "res://fonts/NotoCJK_zh_HK.otf", 
}

static var font: FontVariation = null
static var lang_code: = ""


static func get_font() -> Font:
	if font == null:
		var base: FontFile = load("res://fonts/PixelifySansFix.ttf")
		if base == null:
			return ThemeDB.fallback_font
		font = FontVariation.new()
		font.base_font = base
		font.variation_opentype = {"weight": 500}
		font.opentype_features = {"liga": 0, "clig": 0, "dlig": 0}
		_set_fallbacks()
	return font



static func _set_fallbacks() -> void :
	if font == null:
		return

	var bp: String = "res://fonts/Inter_vi.otf" if lang_code == "vi" else "res://fonts/PixelifySansFix.ttf"
	var nb = load(bp)
	if nb is Font and font.base_font != nb:
		font.base_font = nb
	var path: String = CJK.get(lang_code, CJK["ja"])
	var fb = load(path)
	var arr: Array[Font] = []
	if fb is Font:
		arr.append(fb)
	font.fallbacks = arr


static func set_lang(code: String) -> void :
	lang_code = code
	if font != null:
		_set_fallbacks()



static func apply(theme: Theme = null) -> void :
	var f: Font = get_font()
	ThemeDB.fallback_font = f
	if theme != null:
		theme.default_font = f
		for cls in ["Label", "Button", "CheckButton"]:

			theme.set_color("font_shadow_color", cls, OUTLINE)
			theme.set_constant("shadow_offset_x", cls, 2)
			theme.set_constant("shadow_offset_y", cls, 2)
			theme.set_constant("outline_size", cls, 0)
