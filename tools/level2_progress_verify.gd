extends Node

## Verify Level 2 mission matching and progress counters.


func _ready() -> void:
	await get_tree().process_frame
	var failed := 0
	failed += _check_plan_consistency()
	failed += await _check_collect_progress()
	if failed > 0:
		push_error("[L2PROG] FAILED %d" % failed)
		get_tree().quit(1)
	print("[L2PROG] PASSED")
	get_tree().quit(0)


func _check_plan_consistency() -> int:
	var theme := LevelTheme.theme_for_level(2)
	var category := MissionFactory.category_for_theme(theme)
	var plan := LevelPlan.for_level(2, category)
	var missions := MissionFactory.create_missions(theme, 2, plan)
	if missions.size() != 2:
		push_error("[L2PROG] expected 2 missions got %d" % missions.size())
		return 1
	for m in missions:
		var mission := m as Mission
		print("[L2PROG] mission ", mission.catalog_key, " target=", mission.target, " tex=", mission.icon_texture != null)
		if mission.catalog_key == "":
			push_error("[L2PROG] empty catalog_key")
			return 1
		var entry := ItemCatalog.get_by_key(mission.catalog_key)
		if entry != null and entry.size_class > ItemEntry.SizeClass.SMALL:
			push_error("[L2PROG] target too large for L2: %s class=%d" % [mission.catalog_key, entry.size_class])
			return 1
	return 0


func _check_collect_progress() -> int:
	var packed: PackedScene = load("res://scenes/game.tscn")
	var game: Node2D = packed.instantiate() as Node2D
	add_child(game)
	game.begin_level(2, [])
	for _i in 8:
		await get_tree().process_frame

	var missions: Array = game.get("_missions")
	var failed := 0
	var keys: Array[String] = []
	for m in missions:
		keys.append((m as Mission).catalog_key)

	for key in keys:
		var mission: Mission = null
		for m in missions:
			if (m as Mission).catalog_key == key:
				mission = m as Mission
				break
		if mission == null:
			failed += 1
			continue
		var before := mission.progress
		var food := _find_food(key)
		if food == null:
			push_error("[L2PROG] no field food for %s" % key)
			failed += 1
			continue
		print("[L2PROG] collect ", key, " food.catalog_key=", food.catalog_key, " matches=", mission.matches_food(food))
		if not mission.matches_food(food):
			push_error("[L2PROG] matches_food false for %s" % key)
			failed += 1
			continue
		mission.add_progress()
		if mission.progress != before + 1:
			push_error("[L2PROG] progress not incremented for %s" % key)
			failed += 1
		else:
			print("[L2PROG] OK progress ", key, " -> ", mission.progress, "/", mission.target)

	game.queue_free()
	return failed


func _find_food(catalog_key: String) -> Food:
	for node in get_tree().get_nodes_in_group("food"):
		var food := node as Food
		if food != null and food.catalog_key == catalog_key:
			return food
	return null
