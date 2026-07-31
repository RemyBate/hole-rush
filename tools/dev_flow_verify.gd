extends Node

## Verify one-shot watermelon test then Level 1 → 2 → 3 session progression.


func _ready() -> void:
	await get_tree().process_frame
	var failed := 0

	# Snapshot save-facing values (must not be wiped).
	var saved_highest := GameSettings.highest_unlocked_level
	print("[FLOW] saved_highest=", saved_highest)
	print("[FLOW] DEV_ENABLE=", GameSettings.DEV_ENABLE_WATERMELON_TEST)

	if not GameSettings.DEV_ENABLE_WATERMELON_TEST:
		print("[FLOW] DEV disabled — skip one-shot test checks")
		get_tree().quit(0)
		return

	# Force a clean session state for this verify (does not write save).
	GameSettings._dev_watermelon_test_pending = true
	GameSettings._session_play_level = 0

	if not GameSettings.is_dev_watermelon_test_pending():
		failed += 1
		push_error("[FLOW] expected test pending")
	if GameSettings.get_play_level() != 1:
		failed += 1
		push_error("[FLOW] expected play level 1 while pending")
	else:
		print("[FLOW] OK pending play=1")

	# Simulate completing the test via victory continue path.
	GameSettings.finish_dev_watermelon_test()
	GameSettings.apply_victory_continue(1, 20, 0, 0, 0, 100, 10)

	if GameSettings.is_dev_watermelon_test_pending():
		failed += 1
		push_error("[FLOW] test should no longer be pending")
	if GameSettings.get_play_level() != 1:
		failed += 1
		push_error("[FLOW] after test, expected Level 1, got %s" % GameSettings.get_play_level())
	else:
		print("[FLOW] OK after test play=1")
	if GameSettings.resolve_play_level(22) != 22:
		failed += 1
		push_error("[FLOW] resolve should no longer force 1, got %s" % GameSettings.resolve_play_level(22))
	else:
		print("[FLOW] OK resolve(22)=22 after test")

	# Complete Level 1 → should unlock session Level 2
	GameSettings.apply_victory_continue(2, 20, 0, 0, 0, 120, 10)
	if GameSettings.get_play_level() != 2:
		failed += 1
		push_error("[FLOW] expected session Level 2, got %s" % GameSettings.get_play_level())
	else:
		print("[FLOW] OK after L1 continue play=2")

	GameSettings.apply_victory_continue(3, 20, 0, 0, 0, 140, 15)
	if GameSettings.get_play_level() != 3:
		failed += 1
		push_error("[FLOW] expected session Level 3, got %s" % GameSettings.get_play_level())
	else:
		print("[FLOW] OK after L2 continue play=3")

	# Highest unlocked should still be at least the previous save (not wiped).
	if GameSettings.highest_unlocked_level < saved_highest:
		failed += 1
		push_error("[FLOW] highest unlocked was reduced")
	else:
		print("[FLOW] OK highest preserved/updated=", GameSettings.highest_unlocked_level)

	# Mission stages still progressive.
	var m1 := MissionFactory.create_missions(LevelTheme.Id.FRUIT_GARDEN, 1)
	var m2 := MissionFactory.create_missions(LevelTheme.Id.FRUIT_GARDEN, 2)
	var m3 := MissionFactory.create_missions(LevelTheme.Id.FRUIT_GARDEN, 3)
	if m1.size() != 1 or m2.size() != 2 or m3.size() != 3:
		failed += 1
		push_error("[FLOW] mission stages wrong")
	else:
		print("[FLOW] OK mission stages 1/2/3")

	# Graphical: home button text should be LEVEL 1 (not TEST) after consume.
	var home: HomeScreen = load("res://scenes/ui/home_screen.tscn").instantiate()
	add_child(home)
	await get_tree().process_frame
	home.refresh_ui()
	await get_tree().process_frame
	var btn: Button = home.get_node("%LevelButton") as Button
	var txt := btn.text if btn else ""
	print("[FLOW] home button=", txt)
	# Session play is 3 now from above continues
	if txt != "LEVEL %d" % GameSettings.get_play_level():
		failed += 1
		push_error("[FLOW] unexpected home button text")
	else:
		print("[FLOW] OK home shows normal level label")

	RenderingServer.force_draw()
	await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png(
		ProjectSettings.globalize_path("res://tools/dev_flow_verify.png")
	)

	home.queue_free()

	if failed > 0:
		push_error("[FLOW] FAILED %d" % failed)
		get_tree().quit(1)
	else:
		print("[FLOW] PASSED")
		get_tree().quit(0)
