extends Node
const _SafeCapture := preload("res://tools/safe_viewport_capture.gd")

## Graphical runtime verification: Fruit Garden watermelons + mission cards.
## Saves a PNG screenshot of the playable camera view.


func _ready() -> void:
	await get_tree().process_frame
	print("[VIS] DEV_ENABLE=", GameSettings.DEV_ENABLE_WATERMELON_TEST)
	print("[VIS] test_pending=", GameSettings.is_dev_watermelon_test_pending())
	print("[VIS] saved highest=", GameSettings.highest_unlocked_level)
	print("[VIS] play_level=", GameSettings.get_play_level())
	print("[VIS] theme=", LevelTheme.theme_display_name(LevelTheme.theme_for_level(1)))

	var packed: PackedScene = load("res://scenes/game.tscn")
	if packed == null:
		push_error("[VIS] game.tscn missing")
		get_tree().quit(1)
		return

	var game: Node2D = packed.instantiate() as Node2D
	add_child(game)
	game.begin_level(1, [])

	# Let spawn + first draws settle.
	for _i in 8:
		await get_tree().process_frame
	await get_tree().create_timer(0.35).timeout

	var foods := get_tree().get_nodes_in_group("food")
	var counts := {0: 0, 1: 0, 2: 0, 3: 0, 4: 0}
	var textured := 0
	for food in foods:
		var slot := int(food.item_type)
		counts[slot] = int(counts.get(slot, 0)) + 1
		if CollectibleArt.is_textured_watermelon(LevelTheme.Id.FRUIT_GARDEN, slot):
			textured += 1
			print(
				"[VIS] melon slot=", slot,
				" name=", LevelTheme.collectible_name(LevelTheme.Id.FRUIT_GARDEN, slot),
				" pos=", food.global_position,
				" r=", CollectibleArt.visual_radius(LevelTheme.Id.FRUIT_GARDEN, slot),
				" need_hole=", food.get_required_hole_size(),
				" score=", food.score_value
			)

	print("[VIS] counts=", counts, " textured=", textured, " total=", foods.size())

	var missions := MissionFactory.create_missions(LevelTheme.Id.FRUIT_GARDEN, 1)
	for m in missions:
		print("[VIS] mission=", m.display_name, " 0 / ", m.target)

	# Force a redraw pass then capture the viewport.
	RenderingServer.force_draw()
	await get_tree().process_frame
	await get_tree().process_frame

	var img: Image = null
	if _SafeCapture.is_headless():
		print("[VIS] skip headless screenshot")
	else:
		var tex := get_viewport().get_texture()
		if tex != null:
			img = tex.get_image()
	if img == null and not _SafeCapture.is_headless():
		push_error("[VIS] screenshot failed")
		get_tree().quit(1)
		return

	if img != null:
		var out_path := "user://watermelon_runtime_verify.png"
		var err := img.save_png(out_path)
		var abs_path := ProjectSettings.globalize_path(out_path)
		print("[VIS] screenshot err=", err, " path=", abs_path)
		var project_copy := "res://tools/watermelon_runtime_verify.png"
		img.save_png(ProjectSettings.globalize_path(project_copy))
		print("[VIS] project copy=", ProjectSettings.globalize_path(project_copy))

	var ok := false
	if (
		int(counts[0]) >= 10
		and int(counts[1]) >= 5
		and int(counts[2]) >= 2
		and textured >= 17
		and missions[0].display_name == "Watermelon Slices"
		and missions.size() == 1
	):
		ok = true
	var result_label := "FAIL"
	if ok:
		result_label = "PASS"
	print("[VIS] RESULT=", result_label)
	get_tree().quit(0 if ok else 1)
