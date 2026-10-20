extends SceneTree
# Проверка PG.check()/PG.list(): время холодного построения списка достижений и результат check() (хеш для сравнения до/после):
#   godot --headless --path . --script res://tools/pgcheck.gd
func _initialize() -> void:
	var SV = load("res://scripts/save_data.gd")
	var PG = load("res://scripts/progress.gd")
	SV.ensure()
	var t0 := Time.get_ticks_usec()
	SV.load_dex()
	var t1 := Time.get_ticks_usec()
	print("load_dex: %.1f мс (dex=%d)" % [(t1 - t0) / 1000.0, SV.dex_list.size()])
	# состояние сохранения для проверки: статистика, при которой часть достижений выполнена
	var st: Dictionary = SV.d["stats"]
	st["kills"] = 1500
	st["best_time"] = 700
	st["runs"] = 60
	st["bosses"] = 30
	st["best_level"] = 31
	st["tk_fire"] = 1200
	st["towerBest"] = 9
	SV.d["itemsFound"] = {"a": 1, "b": 2, "c": 3, "d": 4, "e": 5}
	SV.d["legends"] = {"150": 1, "151": 1, "249": 1}
	SV.d["ach"] = {}
	SV.d["zmis"] = {}
	t0 = Time.get_ticks_usec()
	PG.list()
	t1 = Time.get_ticks_usec()
	print("PG.list() холодный: %.1f мс (%d достижений)" % [(t1 - t0) / 1000.0, PG.list().size()])
	var c0: int = int(SV.d["coins"])
	t0 = Time.get_ticks_usec()
	var got: Array = PG.check()
	t1 = Time.get_ticks_usec()
	print("PG.check() первый: %.1f мс" % [(t1 - t0) / 1000.0])
	var ids: Array = []
	for a in got:
		ids.append(String(a["id"]))
	var tid: Array = []
	for tt in PG.toasts:
		tid.append(JSON.stringify(tt))
	print("check ids: ", ids.size(), " hash=", str(("|".join(ids)).hash()), " toasts hash=", str("|".join(tid).hash()), " coins+=", int(SV.d["coins"]) - int(c0), " t1=", SV.d["tickets"], " t10=", SV.d.get("tickets10", 0), " zmis=", (SV.d["zmis"] as Dictionary).keys())
	print("ids: ", ",".join(ids))
	t0 = Time.get_ticks_usec()
	SV.save()
	t1 = Time.get_ticks_usec()
	print("SV.save(): %.1f мс" % [(t1 - t0) / 1000.0])
	t0 = Time.get_ticks_usec()
	PG.check()
	t1 = Time.get_ticks_usec()
	print("PG.check() повторный: %.1f мс" % [(t1 - t0) / 1000.0])
	quit()
