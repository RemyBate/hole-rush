extends Node

## Graphical verify: L1/L2/L3 watermelon missions are distinct and track correctly.


func _ready() -> void:
	await get_tree().process_frame
	GameSettings._dev_watermelon_test_pending = false
	GameSettings._session_play_level = 0

	var failed := 0
	failed += _check_factory()
	failed += await _check_level(1, ["Watermelon Slices"], [10], [0])
	failed += await _check_level(2, ["Watermelon Slices", "Half Watermelons"], [10, 10], [0, 1])
	failed += await _check_level(
		3,
		["Watermelon Slices", "Half Watermelons", "Whole Watermelons"],
		[10, 10, 10],
		[0, 1, 2]
	)

	if failed > 0:
		push_error("[MISS] FAILED %d" % failed)
		get_tree().quit(1)
	else:
		print("[MISS] PASSED")
		get_tree().quit(0)


func _check_factory() -> int:
	var m3 := MissionFactory.create_missions(LevelTheme.Id.FRUIT_GARDEN, 3)
	if m3.size() != 3:
		push_error("[MISS] L3 factory size")
		return 1
	if int(m3[0].item_type) == int(m3[1].item_type):
		push_error("[MISS] duplicate item types")
		return 1
	if m3[0].display_name == m3[1].display_name:
		push_error("[MISS] duplicate names")
		return 1
	if m3[0].target != 10 or m3[1].target != 10 or m3[2].target != 10:
		push_error("[MISS] targets not 10/10/10")
		return 1
	print("[MISS] OK factory L3 distinct 10/10/10")
	return 0


func _check_level(
	level: int,
	expected_names: Array,
	expected_targets: Array,
	expected_types: Array
) -> int:
	var failed := 0
	var game: Node2D = load("res://scenes/game.tscn").instantiate()
	add_child(game)
	game.begin_level(level, [])
	for _i in 10:
		await get_tree().process_frame

	var missions: Array = game.get("_missions")
	# Fallback: rebuild if private access unavailable
	if typeof(missions) != TYPE_ARRAY or missions.is_empty():
		missions = MissionFactory.create_missions(LevelTheme.Id.FRUIT_GARDEN, level)

	print("[MISS] L", level, " mission_count=", missions.size())
	for i in missions.size():
		var m: Mission = missions[i]
		print(
			"[MISS] L", level, " M", i,
			" type=", m.item_type,
			" name=", m.display_name,
			" target=", m.target
		)
		if m.display_name != expected_names[i]:
			push_error("[MISS] name mismatch")
			failed += 1
		if m.target != expected_targets[i]:
			push_error("[MISS] target mismatch")
			failed += 1
		if int(m.item_type) != int(expected_types[i]):
			push_error("[MISS] type mismatch")
			failed += 1

	var hud := game.find_child("HUD", true, false)
	if hud == null:
		push_error("[MISS] HUD missing")
		failed += 1
	else:
		hud.call("update_missions", missions)
		await get_tree().process_frame
		for i in missions.size():
			var card_name := "MissionCard%d" % (i + 1)
			var card := hud.find_child(card_name, true, false) as PanelContainer
			if card == null:
				push_error("[MISS] missing " + card_name)
				failed += 1
				continue
			var title := card.find_child("Title", true, false) as Label
			var progress := card.find_child("Progress", true, false) as Label
			print("[MISS] L", level, " HUD ", card_name, "=", title.text, " ", progress.text)
			if title.text != expected_names[i]:
				push_error("[MISS] HUD title wrong")
				failed += 1
			if not card.visible:
				push_error("[MISS] mission card hidden")
				failed += 1
		for i in range(missions.size(), 3):
			var extra := hud.find_child("MissionCard%d" % (i + 1), true, false) as PanelContainer
			if extra and extra.visible:
				push_error("[MISS] unused card visible")
				failed += 1

	var counts := {0: 0, 1: 0, 2: 0}
	for node in get_tree().get_nodes_in_group("food"):
		var slot := int((node as Food).item_type)
		if counts.has(slot):
			counts[slot] = int(counts[slot]) + 1
	print("[MISS] L", level, " spawns=", counts)
	if int(counts[0]) < 10:
		push_error("[MISS] not enough slices")
		failed += 1
	if level >= 2 and int(counts[1]) < 10:
		push_error("[MISS] not enough halves")
		failed += 1
	if level >= 3 and int(counts[2]) < 10:
		push_error("[MISS] not enough wholes")
		failed += 1

	# Isolation against the live mission array used by the game.
	if missions.size() >= 2:
		var before1: int = missions[1].progress
		game.call("_apply_mission_progress", 0)
		if missions[0].progress != 1 or missions[1].progress != before1:
			push_error("[MISS] slice progress isolation failed")
			failed += 1
		else:
			print("[MISS] OK L", level, " slice-only progress")
		var before0: int = missions[0].progress
		game.call("_apply_mission_progress", 1)
		if missions[1].progress != before1 + 1 or missions[0].progress != before0:
			push_error("[MISS] half progress isolation failed")
			failed += 1
		else:
			print("[MISS] OK L", level, " half-only progress")

	RenderingServer.force_draw()
	await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png(
		ProjectSettings.globalize_path("res://tools/mission_l%d_verify.png" % level)
	)

	game.queue_free()
	await get_tree().process_frame
	return failed
