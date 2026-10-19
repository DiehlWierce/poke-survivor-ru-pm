extends SceneTree
# Замер генерации куска мира на Mac: godot --headless --path . --script res://tools/bench_chunk.gd
# На приставке (H700) всё примерно в 40 раз медленнее.
const TW = preload("res://scripts/tileworld.gd")
const MAINS = preload("res://scripts/main.gd")

func _init() -> void:
	var SVl = load("res://scripts/save_data.gd")
	SVl.ensure()
	var root_n := Node2D.new()
	root.add_child(root_n)
	var tw = TW.new()
	root_n.add_child(tw)
	tw.setup(1234)
	var props := Node2D.new()
	root_n.add_child(props)
	var gen = MAINS.new()
	gen.ground = tw
	gen.world = props
	gen.world_seed = 1234
	gen.menu_mode = true
	MAINS.Prop.tw = tw
	for k in range(6):
		var key := Vector2i(10 + k, 7)
		var t0 := Time.get_ticks_usec()
		while not gen._warm_terrain(key):
			pass
		var t1 := Time.get_ticks_usec()
		gen.chunks[key] = gen._gen_chunk(key.x, key.y)
		var t2 := Time.get_ticks_usec()
		print("chunk %s  terreno %.1f ms  gen %.1f ms" % [key, (t1 - t0) / 1000.0, (t2 - t1) / 1000.0])
	quit()
