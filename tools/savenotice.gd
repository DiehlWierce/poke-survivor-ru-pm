extends SceneTree
# Проверка R3: сообщение о проблемах с сохранением в menu.tscn.
#   godot --headless --path . --script res://tools/savenotice.gd   (HOME — временный, как в check_all.sh)
const SV = preload("res://scripts/save_data.gd")
var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _check(ok: bool, what: String) -> void:
	if ok:
		print("SAVENOTICE_OK: ", what)
	else:
		failures += 1
		push_error("SAVENOTICE_FAIL: " + what)


func _put(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()


func _menu() -> Node:
	SV.loaded = false
	SV.ensure()
	var m: Node = load("res://scenes/menu.tscn").instantiate()
	root.add_child(m)
	await process_frame
	await process_frame
	return m


func _run() -> void:
	var home := OS.get_environment("HOME")
	if not (home.contains("/tmp") or home.contains("/var/folders") or home.contains("poke-check-home")):
		push_error("SAVENOTICE: HOME не временный (%s), тест затирает сохранение — отказ" % home)
		quit(2)
		return
	# 1) битый основной файл без копии -> блок и плашка
	_put(SV.PATH, "{ broken")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SV.BAK))
	var m = await _menu()
	_check(SV.save_blocked, "save_blocked при битом файле")
	_check(m.save_notice != null and m.save_notice.is_inside_tree(), "плашка есть")
	_check(m.save_notice.focus_mode == Control.FOCUS_NONE and m.save_notice.get_child(0).focus_mode == Control.FOCUS_NONE, "плашка без фокуса")
	for sz in [Vector2i(640, 480), Vector2i(1280, 720)]:
		root.size = sz
		await process_frame
		await process_frame
		var vs: Vector2 = root.get_visible_rect().size
		var r: Rect2 = m.save_notice.get_global_rect()
		_check(r.position.x >= 0.0 and r.end.x <= vs.x + 0.5 and r.end.y < vs.y * 0.3, "плашка в экране %s: %s" % [str(sz), str(r)])
	m.queue_free()
	await process_frame
	# 2) битый основной, годная копия -> тост, плашки нет
	var good := JSON.stringify(SV.default_data())
	_put(SV.BAK, good)
	m = await _menu()
	_check(SV.recovered_from_backup and not SV.save_blocked, "восстановление из копии")
	_check(m.save_notice == null, "плашки нет при восстановлении")
	_check(m.toast_lbl.text != "", "тост показан")
	m.queue_free()
	await process_frame
	# 3) чистое сохранение -> ни плашки, ни тоста
	_put(SV.PATH, good)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SV.BAK))
	m = await _menu()
	_check(m.save_notice == null and m.toast_lbl.text == "", "чистое сохранение: тишина")
	print("SAVENOTICE_DONE failures=%d" % failures)
	quit(1 if failures > 0 else 0)
