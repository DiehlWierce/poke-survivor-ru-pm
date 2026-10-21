extends SceneTree

const SV = preload("res://scripts/save_data.gd")

var failures := 0
var cases := 0
var real_root := ""
var legacy_files: Array = []   # --legacy <файл.json> (можно несколько): сейв старой версии с прогрессом (coins 12345, tickets 42, owned.25 shiny, tower_best 17, rifts_best 9, mods [fast])


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var root_arg := args.find("--real-root")
	if root_arg >= 0 and root_arg + 1 < args.size():
		real_root = String(args[root_arg + 1])
	for i in range(args.size() - 1):
		if args[i] == "--legacy":
			legacy_files.append(args[i + 1])
	call_deferred("_run")


func _check(condition: bool, label: String) -> void:
	cases += 1
	if condition:
		print("SAVE_CHECK_OK: " + label)
	else:
		push_error("SAVE_CHECK_FAIL: " + label)
		failures += 1


func _clear_test_files() -> void:
	for name in ["save.json", "save.bak", "save.tmp"]:
		var path := ProjectSettings.globalize_path("user://" + name)
		if FileAccess.file_exists(path):
			var err := DirAccess.remove_absolute(path)
			if err != OK:
				push_error("SAVE_CHECK_FAIL: не удалось очистить временный файл %s" % name)
				failures += 1


func _reset_state() -> void:
	SV.loaded = false
	SV.save_blocked = false
	SV.recovered_from_backup = false
	SV.last_save_error = ""
	SV._field_warning = ""
	SV.d = {}
	_clear_test_files()


func _write_primary(value: String) -> void:
	var file := FileAccess.open(SV.PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(value)
		file.close()


func _run() -> void:
	# Broken JSON: block writes and leave the source bytes untouched.
	_reset_state()
	_write_primary("{")
	var broken_before := FileAccess.get_file_as_string(SV.PATH)
	SV.ensure()
	_check(SV.save_blocked, "битый JSON блокирует сохранение")
	_check(not SV.save(), "битый JSON не перезаписывается")
	_check(FileAccess.get_file_as_string(SV.PATH) == broken_before, "битый JSON оставлен без изменений")

	# Older schema with missing fields remains loadable and receives defaults.
	_reset_state()
	_write_primary(JSON.stringify({"v": 0, "coins": 321}))
	SV.ensure()
	_check(not SV.save_blocked and int(SV.d["coins"]) == 321, "старое сохранение загружено")
	_check(String(SV.d["settings"]["lang"]) == "en", "пропущенные поля заполнены defaults")
	_check(SV.save(), "старое сохранение записано в текущей схеме")

	# Extra fields remain forward-compatible and are preserved.
	_reset_state()
	_write_primary(JSON.stringify({"v": SV.SAVE_SCHEMA_VERSION, "coins": 456, "extension": {"keep": true}}))
	SV.ensure()
	_check(not SV.save_blocked and bool(SV.d["extension"]["keep"]), "лишнее поле принято и сохранено в памяти")
	_check(SV.save(), "сохранение с лишним полем записано")
	var extra_disk: Variant = JSON.parse_string(FileAccess.get_file_as_string(SV.PATH))
	_check(extra_disk is Dictionary and bool(extra_disk.get("extension", {}).get("keep", false)), "лишнее поле сохранено на диск")

	# A mistyped optional field is replaced with its default and a user-visible warning.
	_reset_state()
	_write_primary(JSON.stringify({"v": SV.SAVE_SCHEMA_VERSION, "coins": "bad", "tickets": 17}))
	SV.ensure()
	_check(not SV.save_blocked, "неверный тип необязательного поля не блокирует сохранение")
	_check(int(SV.d["coins"]) == int(SV.default_data()["coins"]), "неверный тип заменён значением по умолчанию")
	_check(int(SV.d["tickets"]) == 17, "остальные поля сохранения сохранены")
	_check(not SV.last_save_error.is_empty(), "предупреждение доступно через last_save_error")
	_check(SV.save(), "нормализованное сохранение записано")
	_check(not SV.last_save_error.is_empty(), "предупреждение доступно после успешной записи")
	var wrong_disk: Variant = JSON.parse_string(FileAccess.get_file_as_string(SV.PATH))
	_check(wrong_disk is Dictionary and int(wrong_disk["coins"]) == int(SV.default_data()["coins"]), "на диск записано значение по умолчанию")

	# A future schema is never overwritten.
	_reset_state()
	_write_primary(JSON.stringify({"v": SV.SAVE_SCHEMA_VERSION + 1, "coins": 9999}))
	var future_before := FileAccess.get_file_as_string(SV.PATH)
	SV.ensure()
	_check(SV.save_blocked, "более новая версия блокирует сохранение")
	_check(not SV.save(), "более новая версия не перезаписывается")
	_check(FileAccess.get_file_as_string(SV.PATH) == future_before, "файл новой версии оставлен без изменений")

	_clear_test_files()
	for lp in legacy_files:
		_check_legacy(String(lp))
	_clear_test_files()
	_check_real_saves()
	if failures == 0:
		print("SAVE_CHECK_OK: %d assertions" % cases)
	else:
		print("SAVE_CHECK_FAIL: %d/%d assertions" % [failures, cases])
	quit(1 if failures > 0 else 0)


func _check_real_saves() -> void:
	if real_root.is_empty() or not DirAccess.dir_exists_absolute(real_root):
		print("REAL_SAVE_SCAN: каталог не задан/недоступен; не проверено")
		return
	var dirs := DirAccess.get_directories_at(real_root)
	var found := 0
	for app_name in dirs:
		var path := real_root.path_join(app_name).path_join("save.json")
		if not FileAccess.file_exists(path):
			continue
		found += 1
		var file := FileAccess.open(path, FileAccess.READ)
		if file == null:
			print("REAL_SAVE_READ_ONLY: %s не удалось открыть; не проверено" % app_name)
			continue
		var text := file.get_as_text()
		file.close()
		var parser := JSON.new()
		var parse_result := parser.parse(text)
		if parse_result != OK:
			print("REAL_SAVE_READ_ONLY: %s JSON=broken; содержимое не изменялось" % app_name)
			continue
		SV._field_warning = ""
		SV.last_save_error = ""
		var usable: bool = SV._usable_save(parser.data, path)
		var version = parser.data.get("v", "missing") if parser.data is Dictionary else "non-object"
		print("REAL_SAVE_READ_ONLY: %s version=%s usable=%s; открыт только для чтения" % [app_name, str(version), str(usable)])
	if found == 0:
		print("REAL_SAVE_SCAN: файлов save.json не найдено")


# Сейв старой версии: прогресс на месте, новые поля по умолчанию, повторная загрузка/запись идемпотентна.
func _check_legacy(path: String) -> void:
	var tag := path.get_file()
	_reset_state()
	_write_primary(FileAccess.get_file_as_string(path))
	SV.ensure()
	_check(not SV.save_blocked, "%s: не заблокирован" % tag)
	_check(int(SV.d["coins"]) == 12345 and int(SV.d["tickets"]) == 42, "%s: монеты и билеты на месте" % tag)
	_check(SV.d["owned"].has("25") and bool(SV.d["owned"]["25"]["shiny"]), "%s: покемон и шайни на месте" % tag)
	_check(int(SV.d["tower_best"]) == 17 and int(SV.d.get("rifts_best", 0)) == 9, "%s: рекорды на месте" % tag)
	_check(Array(SV.d["mods"]) == ["fast"], "%s: модификаторы на месте" % tag)
	var dd: Dictionary = SV.default_data()
	var missing: Array = []
	for k in dd:
		if not SV.d.has(k):
			missing.append(k)
	_check(missing.is_empty(), "%s: все поля текущей схемы есть (нет: %s)" % [tag, str(missing)])
	_check(int(SV.d.get("gcoins", 0)) == 1 and int(SV.d.get("gold_coins", 0)) == 0, "%s: Gachapon: разовый подарок 1 монета, золотых 0" % tag)
	_check(SV.save(), "%s: записан" % tag)
	var first: Variant = JSON.parse_string(FileAccess.get_file_as_string(SV.PATH))
	SV.loaded = false
	SV.d = {}
	SV.ensure()
	_check(SV.save(), "%s: повторно записан" % tag)
	var second: Variant = JSON.parse_string(FileAccess.get_file_as_string(SV.PATH))
	_check(first == second, "%s: загрузка+запись идемпотентны (подарок не выдаётся дважды)" % tag)
