extends SceneTree

const LANGS := ["en", "es_419", "es", "fr", "it", "pt_BR", "pt_PT", "ru", "ja", "zh_CN", "zh_HK"]

var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var sv = load("res://scripts/save_data.gd")
	var lang = load("res://scripts/lang.gd")
	sv.ensure()
	for scene_path in ["res://scenes/menu.tscn", "res://scenes/main.tscn"]:
		var packed: PackedScene = load(scene_path)
		if packed == null:
			push_error("SMOKE: не загрузилась сцена %s" % scene_path)
			failures += 1
			continue
		var scene := packed.instantiate()
		root.add_child(scene)
		await process_frame
		if scene_path.ends_with("main.tscn"):
			var waited := 0
			while not bool(scene.get("loading_done")) and waited < 1800:
				await process_frame
				waited += 1
			if not bool(scene.get("loading_done")):
				push_error("SMOKE: main.tscn не завершила загрузку за %d кадров" % waited)
				failures += 1
		for code in LANGS:
			sv.d["settings"]["lang"] = code
			lang.apply()
			await process_frame
			print("SMOKE_LANG %s %s" % [scene_path, code])
		scene.queue_free()
		await process_frame
	if failures == 0:
		print("SMOKE_OK: menu.tscn и main.tscn; языков=%d" % LANGS.size())
	else:
		print("SMOKE_FAIL: %d ошибок" % failures)
	quit(1 if failures > 0 else 0)
