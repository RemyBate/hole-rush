extends Node

## Runtime verify: radius swallow, progressive missions, growth to whole.


func _ready() -> void:
	await get_tree().process_frame
	var failed := 0

	failed += _check_mission_stages()
	failed += await _check_swallow_and_growth()
	failed += _check_level_objectives()

	if failed > 0:
		push_error("[PROG] FAILED issues=%d" % failed)
		get_tree().quit(1)
	else:
		print("[PROG] PASSED")
		get_tree().quit(0)


func _fail(msg: String) -> int:
	push_error("[PROG] " + msg)
	return 1


func _ok(msg: String) -> void:
	print("[PROG] OK ", msg)


func _check_mission_stages() -> int:
	var failed := 0
	var m1 := MissionFactory.create_missions(LevelTheme.Id.FRUIT_GARDEN, 1)
	if m1.size() != 1 or m1[0].display_name != "Watermelon Slices" or m1[0].target != 10:
		failed += _fail("L1 should be 10 slices only, got %s" % m1.size())
	else:
		_ok("L1 = 10 Watermelon Slices")

	var m2 := MissionFactory.create_missions(LevelTheme.Id.FRUIT_GARDEN, 2)
	if m2.size() != 2 or m2[1].target != 5:
		failed += _fail("L2 should be slices+halves")
	else:
		_ok("L2 = slices + halves")

	var m3 := MissionFactory.create_missions(LevelTheme.Id.FRUIT_GARDEN, 3)
	if m3.size() != 3 or m3[2].target != 2:
		failed += _fail("L3 should be slices+halves+wholes")
	else:
		_ok("L3 = slices + halves + wholes")

	var m11 := MissionFactory.create_missions(LevelTheme.Id.VEGETABLE_FARM, 11)
	if m11.size() != 1:
		failed += _fail("Theme decade reset: level 11 should be stage 1, got %d" % m11.size())
	else:
		_ok("Level 11 (new theme) stage 1")

	var ff := MissionFactory.create_missions(LevelTheme.Id.FAST_FOOD, 23)
	if ff.size() != 3:
		failed += _fail("Fast food L23 should have 3 family missions")
	else:
		_ok("Fast food family missions still work")
	return failed


func _check_level_objectives() -> int:
	var lines1 := GameSettings.level_objective_lines(1)
	var lines3 := GameSettings.level_objective_lines(3)
	if lines1.size() != 1:
		return _fail("objective lines L1 size")
	if lines3.size() != 3:
		return _fail("objective lines L3 size")
	_ok("prep objective lines match stages")
	return 0


func _check_swallow_and_growth() -> int:
	var failed := 0
	var packed: PackedScene = load("res://scenes/game.tscn")
	var game: Node2D = packed.instantiate() as Node2D
	add_child(game)
	game.begin_level(1, [])
	for _i in 6:
		await get_tree().process_frame

	var hole: Hole = game.get_node("Hole") as Hole
	var foods := get_tree().get_nodes_in_group("food")

	var slice: Food = null
	var half: Food = null
	var whole: Food = null
	for f in foods:
		var food := f as Food
		match int(food.item_type):
			0:
				if slice == null:
					slice = food
			1:
				if half == null:
					half = food
			2:
				if whole == null:
					whole = food

	if slice == null or half == null or whole == null:
		game.queue_free()
		return _fail("missing watermelon types on field")

	# Start hole swallows slice, not half/whole.
	if not slice.can_be_swallowed_by(hole):
		failed += _fail("start hole should swallow slice")
	else:
		_ok("start hole swallows slice (r=%.1f need=%.1f)" % [hole.radius, slice.get_visual_radius()])
	if half.can_be_swallowed_by(hole):
		failed += _fail("start hole should NOT swallow half yet")
	else:
		_ok("start hole blocks half")
	if whole.can_be_swallowed_by(hole):
		failed += _fail("start hole should NOT swallow whole yet")
	else:
		_ok("start hole blocks whole")

	# Simulate growth from collecting several slices.
	var sim_r := hole.radius
	for i in 6:
		sim_r += slice.get_growth_contribution()
	# Apply same growth to real hole.
	for i in 6:
		hole.grow(slice.get_growth_contribution())

	print("[PROG] after 6 slice-growths hole.r=", hole.radius, " half=", half.get_visual_radius(), " whole=", whole.get_visual_radius())
	if not half.can_be_swallowed_by(hole):
		failed += _fail("after growth half should be swallowable")
	else:
		_ok("grown hole swallows half")
	if not whole.can_be_swallowed_by(hole):
		failed += _fail("after enough growth whole should be swallowable (r=%.1f need=%.1f)" % [hole.radius, whole.get_visual_radius()])
	else:
		_ok("grown hole swallows whole watermelon")

	# L1 win condition: only slices mission.
	var missions: Array = game.get("_missions") if false else []
	# Access via completing mission progress simulation
	var m := MissionFactory.create_missions(LevelTheme.Id.FRUIT_GARDEN, 1)
	for _j in 10:
		m[0].add_progress()
	if not m[0].is_complete():
		failed += _fail("10 slices should complete L1 mission")
	else:
		_ok("L1 mission completes after 10 slices")

	# Screenshot fruit garden L1 HUD missions
	RenderingServer.force_draw()
	await get_tree().process_frame
	var img := get_viewport().get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path("res://tools/progression_verify.png"))
	print("[PROG] screenshot tools/progression_verify.png")

	game.queue_free()
	return failed
