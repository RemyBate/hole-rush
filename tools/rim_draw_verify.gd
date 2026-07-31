extends Node

## Graphical Level 4: hole rim indicator, growth, mission counters, no draw_rect width spam.


func _ready() -> void:
	await get_tree().process_frame
	GameSettings._dev_watermelon_test_pending = false
	GameSettings._session_play_level = 0

	var packed: PackedScene = load("res://scenes/game.tscn")
	var game: Node2D = packed.instantiate() as Node2D
	add_child(game)
	game.begin_level(4, [])

	for _i in 12:
		await get_tree().process_frame
	await get_tree().create_timer(0.25).timeout

	var hole: Hole = game.get_node("Hole") as Hole
	var start_r := hole.radius
	print("[RIM] start radius=", start_r, " hole_size=", hole.get_hole_size())

	# Move the hole toward nearby foods and swallow.
	var foods := get_tree().get_nodes_in_group("food")
	var swallowed := 0
	var missions: Array = game.get("_missions")
	var before: Array[int] = []
	for m in missions:
		before.append((m as Mission).progress)

	# Grow enough to swallow medium items.
	for _g in 20:
		hole.grow(3.0)
	print("[RIM] after forced growth radius=", hole.radius, " size=", hole.get_hole_size())

	# Swallow several catalog items via try_collect.
	for food in foods:
		if swallowed >= 12:
			break
		var f := food as Food
		if f == null or not is_instance_valid(f):
			continue
		hole.global_position = f.global_position
		if f.try_collect(hole):
			swallowed += 1
			# Let collect animation advance a few frames.
			for _i in 4:
				await get_tree().process_frame

	# Wait for collect animations / mission updates.
	await get_tree().create_timer(0.8).timeout
	for _i in 20:
		await get_tree().process_frame

	print("[RIM] swallowed=", swallowed, " radius=", hole.radius)
	for i in missions.size():
		var m := missions[i] as Mission
		print("[RIM] mission ", m.catalog_key, " ", m.progress, "/", m.target)

	# Verify Food vs int progress paths.
	var sample_target: Food = null
	var sample_nontarget: Food = null
	var keys := {}
	for m in missions:
		keys[(m as Mission).catalog_key] = true
	foods = get_tree().get_nodes_in_group("food")
	for food in foods:
		var f := food as Food
		if f == null:
			continue
		if keys.has(f.catalog_key) and sample_target == null:
			sample_target = f
		elif f.catalog_key != "" and not keys.has(f.catalog_key) and sample_nontarget == null:
			sample_nontarget = f
	var failed := 0
	if sample_nontarget:
		var snap: Array[int] = []
		for m in missions:
			snap.append((m as Mission).progress)
		game.call("_apply_mission_progress", sample_nontarget)
		for i in missions.size():
			if (missions[i] as Mission).progress != snap[i]:
				push_error("[RIM] nontarget Food bumped counter")
				failed += 1
	if sample_target:
		var idx := -1
		for i in missions.size():
			if (missions[i] as Mission).catalog_key == sample_target.catalog_key:
				idx = i
				break
		var before_t: int = (missions[idx] as Mission).progress
		game.call("_apply_mission_progress", sample_target)
		if (missions[idx] as Mission).progress != before_t + 1:
			push_error("[RIM] Food progress failed")
			failed += 1
		# Legacy int must not touch catalog missions.
		var snap2: Array[int] = []
		for m in missions:
			snap2.append((m as Mission).progress)
		game.call("_apply_mission_progress", 0)
		for i in missions.size():
			if (missions[i] as Mission).progress != snap2[i]:
				push_error("[RIM] legacy int affected catalog mission")
				failed += 1

	# Replay same level plan stability + second begin.
	var plan_a := LevelPlan.for_level(4).summary()
	game.begin_level(4, [])
	for _i in 10:
		await get_tree().process_frame
	var plan_b := LevelPlan.for_level(4).summary()
	if plan_a != plan_b:
		push_error("[RIM] plan unstable on replay")
		failed += 1
	var missions2: Array = game.get("_missions")
	if missions2.size() != 3:
		push_error("[RIM] replay mission count")
		failed += 1

	print("[RIM] rim/hole still valid radius=", (game.get_node("Hole") as Hole).radius)
	if failed > 0:
		push_error("[RIM] FAILED %d" % failed)
		get_tree().quit(1)
	else:
		print("[RIM] PASSED")
		get_tree().quit(0)
