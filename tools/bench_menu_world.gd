extends SceneTree
# Замер живого фона меню (MenuWorld): время start() и кадры 20 с (процесс, худший кадр, генерация кусков).
# godot --headless --path . --script res://tools/bench_menu_world.gd [-- --keys-only]   (--keys-only = режим приставки)

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var MS = load("res://scripts/menu.gd")
	var sv = load("res://scripts/save_data.gd")
	sv.ensure()
	var holder := Node2D.new()
	root.add_child(holder)
	var w = MS.MenuWorld.new()
	holder.add_child(w)
	var t0 := Time.get_ticks_usec()
	w.start()
	var st_ms: float = (Time.get_ticks_usec() - t0) / 1000.0
	# шаги вручную по 1/60 с (как 60 к/с): время каждой части отдельно; 3600 шагов = 60 с фона (2 смены биома, 1-2 куска)
	var tw: Node = w.get("tw")
	var amb: Node = w.get("amb")
	w.set_process(false)
	tw.set_process(false)
	var n := 3600
	var dt := 1.0 / 60.0
	var tot: Array = []
	var parts := {"world": 0.0, "tile": 0.0, "mons": 0.0, "amb": 0.0}
	var worst := {"world": 0.0, "tile": 0.0, "mons": 0.0, "amb": 0.0}
	var shown_ms := -1.0
	var shown_step := -1
	for _i in range(n):
		if shown_ms < 0.0 and bool(w.get("shown")):
			shown_ms = (Time.get_ticks_usec() - t0) / 1000.0
			shown_step = _i
		var a := Time.get_ticks_usec()
		w._process(dt)
		var b := Time.get_ticks_usec()
		if bool(w.get("shown")):
			tw.set_process(false)
			tw._process(dt)
		elif shown_ms < 0.0:
			pass
		var c := Time.get_ticks_usec()
		for m in (w.get("mons") as Array):
			if is_instance_valid(m):
				m.set_process(false)
				m._process(dt)
		var d := Time.get_ticks_usec()
		if amb != null:
			amb.set_process(false)
		var e := Time.get_ticks_usec()
		await process_frame   # отрисовка (_draw Ambient и пр.) и освобождение
		var f := Time.get_ticks_usec()
		var vals := {"world": (b - a) / 1000.0, "tile": (c - b) / 1000.0, "mons": (d - c) / 1000.0, "amb": (f - e) / 1000.0}
		var sum := 0.0
		for k in vals:
			parts[k] += vals[k]
			worst[k] = maxf(worst[k], vals[k])
			sum += vals[k]
		tot.append(sum)
	tot.sort()
	var gen: Object = w.get("gen")
	var avg := 0.0
	for v in tot:
		avg += v
	print("MENU_WORLD фон виден через %.0f мс (шаг %d)" % [shown_ms, shown_step])
	print("MENU_WORLD start=%.1f мс; шаг ср=%.2f p95=%.2f p99=%.2f макс=%.1f мс; ср по частям мир=%.2f тайлы=%.2f покемоны=%.2f кадр/отрисовка=%.2f; худшие мир=%.1f тайлы=%.1f покемоны=%.1f кадр=%.1f; покемонов=%d кусков=%d узлов=%d" % [st_ms, avg / n, tot[int(n * 0.95)], tot[int(n * 0.99)], tot[n - 1], parts["world"] / n, parts["tile"] / n, parts["mons"] / n, parts["amb"] / n, worst["world"], worst["tile"], worst["mons"], worst["amb"], (w.get("mons") as Array).size(), (gen.get("chunks") as Dictionary).size(), int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))])
	quit(0)
