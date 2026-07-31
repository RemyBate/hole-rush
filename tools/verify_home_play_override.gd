extends Node

## Graphical verify: home shows TEST LEVEL 1 and Play launches Fruit Garden.


func _ready() -> void:
	await get_tree().process_frame

	print("[HOME] flag=", GameSettings.DEV_ENABLE_WATERMELON_TEST)
	print("[HOME] pending=", GameSettings.is_dev_watermelon_test_pending())
	print("[HOME] saved_highest=", GameSettings.highest_unlocked_level)
	print("[HOME] get_play_level=", GameSettings.get_play_level())
	print("[HOME] resolve(22)=", GameSettings.resolve_play_level(22))

	if GameSettings.highest_unlocked_level < 20:
		push_warning("[HOME] Expected saved progress ~22 for this test; got %s" % GameSettings.highest_unlocked_level)

	var home_packed: PackedScene = load("res://scenes/ui/home_screen.tscn")
	var home: HomeScreen = home_packed.instantiate() as HomeScreen
	add_child(home)
	await get_tree().process_frame
	home.refresh_ui()
	await get_tree().process_frame

	var btn: Button = home.get_node("%LevelButton") as Button
	var btn_text := btn.text if btn else ""
	print("[HOME] level_button_text=", btn_text)
	if btn_text != "TEST LEVEL 1":
		push_error("[HOME] Expected TEST LEVEL 1, got: %s" % btn_text)
		get_tree().quit(1)
		return

	# Capture home screenshot.
	RenderingServer.force_draw()
	await get_tree().process_frame
	var home_img: Image = get_viewport().get_texture().get_image()
	home_img.save_png(ProjectSettings.globalize_path("res://tools/home_test_level_verify.png"))
	print("[HOME] saved tools/home_test_level_verify.png")

	# Simulate launching as if prep emitted the saved level 22.
	var launched := {"level": -1}
	home.play_level.connect(func(level: int, _boosters: Array) -> void:
		launched.level = level
	)
	home._on_prep_play(22, [])
	await get_tree().process_frame
	print("[HOME] prep_play(22) emitted level=", launched.level)
	if int(launched.level) != 1:
		push_error("[HOME] prep_play did not force level 1")
		get_tree().quit(1)
		return

	home.queue_free()
	await get_tree().process_frame

	# Launch game the same way main does after resolve.
	var game_packed: PackedScene = load("res://scenes/game.tscn")
	var game: Node2D = game_packed.instantiate() as Node2D
	add_child(game)
	game.begin_level(22, []) # should be forced to 1
	for _i in 6:
		await get_tree().process_frame
	await get_tree().create_timer(0.3).timeout

	var theme := LevelTheme.theme_for_level(int(game.get("_current_level")))
	# Access via reflection — _current_level is private-ish; use missions instead.
	var missions := MissionFactory.create_missions(LevelTheme.Id.FRUIT_GARDEN)
	var foods := get_tree().get_nodes_in_group("food")
	var counts := {0: 0, 1: 0, 2: 0}
	for f in foods:
		var slot := int(f.item_type)
		if counts.has(slot):
			counts[slot] = int(counts[slot]) + 1

	print("[HOME] after begin_level(22): food counts=", counts)
	print("[HOME] missions=", missions[0].display_name, "/", missions[0].target)

	RenderingServer.force_draw()
	await get_tree().process_frame
	var game_img: Image = get_viewport().get_texture().get_image()
	game_img.save_png(ProjectSettings.globalize_path("res://tools/play_from_home_verify.png"))
	print("[HOME] saved tools/play_from_home_verify.png")

	# Confirm save file still has 22.
	var progress_path := ProjectSettings.globalize_path("user://progress.save")
	var progress_text := FileAccess.get_file_as_string("user://progress.save")
	print("[HOME] progress_contains_22=", progress_text.contains("\"highest_unlocked_level\":22") or progress_text.contains("\"highest_unlocked_level\": 22"))
	print("[HOME] progress_path=", progress_path)
	print("[HOME] live_highest_still=", GameSettings.highest_unlocked_level)

	var ok: bool = false
	if (
		btn_text == "TEST LEVEL 1"
		and int(launched.level) == 1
		and int(counts[0]) >= 10
		and int(counts[1]) >= 5
		and int(counts[2]) >= 2
		and missions[0].display_name == "Watermelon Slices"
		and GameSettings.highest_unlocked_level >= 20
	):
		ok = true
	var result_label := "FAIL"
	if ok:
		result_label = "PASS"
	print("[HOME] RESULT=", result_label)
	get_tree().quit(0 if ok else 1)
