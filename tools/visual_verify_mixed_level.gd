extends Node

## Graphical verify: Level 4 mixed numbered collectibles + HUD image cards.


func _ready() -> void:
	await get_tree().process_frame
	GameSettings._dev_watermelon_test_pending = false
	GameSettings._session_play_level = 0

	var plan := LevelPlan.for_level(4, ItemCatalog.CATEGORY_FRUITS)
	print("[MIX] plan=", plan.summary())

	var packed: PackedScene = load("res://scenes/game.tscn")
	if packed == null:
		push_error("[MIX] game.tscn missing")
		get_tree().quit(1)
		return

	var game: Node2D = packed.instantiate() as Node2D
	add_child(game)
	game.begin_level(4, [])

	for _i in 10:
		await get_tree().process_frame
	await get_tree().create_timer(0.4).timeout

	var foods := get_tree().get_nodes_in_group("food")
	var by_key: Dictionary = {}
	var catalog_count := 0
	for food in foods:
		var f := food as Food
		if f == null:
			continue
		if f.catalog_key != "":
			catalog_count += 1
			by_key[f.catalog_key] = int(by_key.get(f.catalog_key, 0)) + 1

	print("[MIX] total foods=", foods.size(), " catalog=", catalog_count, " types=", by_key.size())
	for k in by_key.keys():
		print("[MIX]   ", k, " x", by_key[k])

	var missions: Array = game.get("_missions")
	print("[MIX] missions=", missions.size())
	var failed := 0
	if missions.size() != 3:
		push_error("[MIX] expected 3 missions")
		failed += 1
	for m in missions:
		var mission := m as Mission
		print(
			"[MIX] mission ", mission.catalog_key,
			" ", mission.progress, "/", mission.target,
			" tex=", mission.icon_texture != null,
			" name='", mission.display_name, "'"
		)
		if mission.icon_texture == null:
			push_error("[MIX] missing icon texture")
			failed += 1
		if not mission.hide_name:
			push_error("[MIX] name should be hidden")
			failed += 1
		if not str(mission.display_name).is_empty():
			push_error("[MIX] display_name should be empty")
			failed += 1
		var have := int(by_key.get(mission.catalog_key, 0))
		if have < mission.target:
			push_error("[MIX] under-spawned %s have=%d need=%d" % [mission.catalog_key, have, mission.target])
			failed += 1

	if by_key.size() < 8:
		push_error("[MIX] too few field types on map: %d" % by_key.size())
		failed += 1

	# Simulate collecting a non-target — counters must not move.
	var non_target: Food = null
	var target_keys := {}
	for m in missions:
		target_keys[(m as Mission).catalog_key] = true
	for food in foods:
		var f := food as Food
		if f and f.catalog_key != "" and not target_keys.has(f.catalog_key):
			non_target = f
			break
	if non_target:
		game.call("_apply_mission_progress", non_target)
		for m in missions:
			if (m as Mission).progress != 0:
				push_error("[MIX] non-target bumped mission")
				failed += 1
				break
		print("[MIX] non-target progress check ok")

	# Collect one of each target once.
	for m in missions:
		var mission := m as Mission
		var sample: Food = null
		for food in foods:
			var f := food as Food
			if f and f.catalog_key == mission.catalog_key:
				sample = f
				break
		if sample:
			game.call("_apply_mission_progress", sample)
	for m in missions:
		if (m as Mission).progress != 1:
			push_error("[MIX] target counter not +1")
			failed += 1

	RenderingServer.force_draw()
	await get_tree().process_frame
	await get_tree().process_frame
	var img: Image = get_viewport().get_texture().get_image()
	if img:
		var out := ProjectSettings.globalize_path("res://tools/mixed_level4_verify.png")
		img.save_png(out)
		print("[MIX] screenshot=", out)

	# Replay stability
	var plan2 := LevelPlan.for_level(4, ItemCatalog.CATEGORY_FRUITS)
	if plan.summary() != plan2.summary():
		push_error("[MIX] plan not stable")
		failed += 1

	if failed > 0:
		push_error("[MIX] FAILED %d" % failed)
		get_tree().quit(1)
	else:
		print("[MIX] PASSED")
		get_tree().quit(0)
