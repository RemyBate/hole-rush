extends Node

## Graphical verify: L1/L2/L3 numbered images, image-only HUD, no watermelon test.


func _ready() -> void:
	await get_tree().process_frame
	var failed := 0

	# No watermelon test APIs.
	if GameSettings.get("DEV_ENABLE_WATERMELON_TEST") != null:
		# Const may still resolve via get in some builds — prefer has_method checks.
		pass
	if GameSettings.has_method("is_dev_watermelon_test_pending"):
		push_error("[PROG] watermelon test API still present")
		failed += 1

	failed += await _check_level(1, 1)
	failed += await _check_level(2, 2)
	failed += await _check_level(3, 3)
	failed += await _check_level(4, 3)

	if failed > 0:
		push_error("[PROG] FAILED %d" % failed)
		get_tree().quit(1)
	else:
		print("[PROG] PASSED")
		get_tree().quit(0)


func _check_level(level: int, expect_missions: int) -> int:
	var failed := 0
	var plan := LevelPlan.for_level(level)
	print("[PROG] L", level, " ", plan.summary())

	var packed: PackedScene = load("res://scenes/game.tscn")
	var game: Node2D = packed.instantiate() as Node2D
	add_child(game)
	game.begin_level(level, [])

	for _i in 12:
		await get_tree().process_frame
	await get_tree().create_timer(0.3).timeout

	var foods := get_tree().get_nodes_in_group("food")
	var by_key: Dictionary = {}
	for food in foods:
		var f := food as Food
		if f == null or f.catalog_key == "":
			continue
		by_key[f.catalog_key] = int(by_key.get(f.catalog_key, 0)) + 1
		if f.modulate != Color.WHITE and f.modulate.a >= 0.99:
			# Allow brief feedback tints only; idle items must be white.
			if f.get("_feedback_timer") <= 0.0:
				push_error("[PROG] non-white modulate on %s: %s" % [f.catalog_key, str(f.modulate)])
				failed += 1

	print("[PROG] L", level, " types=", by_key.size(), " foods=", foods.size())
	if by_key.size() < 8:
		push_error("[PROG] L%d too few field types %d" % [level, by_key.size()])
		failed += 1

	var missions: Array = game.get("_missions")
	if missions.size() != expect_missions:
		push_error("[PROG] L%d mission count %d want %d" % [level, missions.size(), expect_missions])
		failed += 1

	var hud: Control = game.get_node("UI/HUD")
	for i in expect_missions:
		var m := missions[i] as Mission
		if m.icon_texture == null:
			push_error("[PROG] L%d missing icon texture" % level)
			failed += 1
		if not str(m.display_name).is_empty():
			push_error("[PROG] L%d display name still set: %s" % [level, m.display_name])
			failed += 1
		var card: PanelContainer = hud.get("_mission_cards")[i]
		var title: Label = hud.get("_mission_titles")[i]
		if title.visible:
			push_error("[PROG] L%d title visible" % level)
			failed += 1
		var tex: TextureRect = hud.get("_mission_icon_textures")[i]
		if tex == null or not tex.visible or tex.texture == null:
			push_error("[PROG] L%d HUD texture missing" % level)
			failed += 1
		elif tex.modulate != Color.WHITE:
			push_error("[PROG] L%d HUD tinted" % level)
			failed += 1
		if not card.visible:
			push_error("[PROG] L%d card hidden" % level)
			failed += 1
		# Extra cards must be hidden.
	for i in range(expect_missions, 3):
		var card2: PanelContainer = hud.get("_mission_cards")[i]
		if card2.visible:
			push_error("[PROG] L%d extra card visible" % level)
			failed += 1

	# Non-target must not bump counters.
	var keys := {}
	for m in missions:
		keys[(m as Mission).catalog_key] = true
	var nontarget: Food = null
	for food in foods:
		var f := food as Food
		if f and f.catalog_key != "" and not keys.has(f.catalog_key):
			nontarget = f
			break
	if nontarget:
		game.call("_apply_mission_progress", nontarget)
		for m in missions:
			if (m as Mission).progress != 0:
				push_error("[PROG] nontarget progress")
				failed += 1
				break

	RenderingServer.force_draw()
	await get_tree().process_frame
	var img: Image = get_viewport().get_texture().get_image()
	if img:
		var path := ProjectSettings.globalize_path("res://tools/prog_l%d_verify.png" % level)
		img.save_png(path)
		print("[PROG] screenshot=", path)

	game.queue_free()
	await get_tree().process_frame
	return failed
