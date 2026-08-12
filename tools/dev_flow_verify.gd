extends Node
const _SafeCapture := preload("res://tools/safe_viewport_capture.gd")

## Smoke-check progression helpers after the legacy watermelon DEV path was removed.


func _ready() -> void:
	await get_tree().process_frame
	var failed := 0

	var saved_highest := GameSettings.highest_unlocked_level
	print("[FLOW] saved_highest=", saved_highest)

	if GameSettings.get("DEV_ENABLE_WATERMELON_TEST") == null:
		print("[FLOW] OK legacy watermelon DEV path removed")
	else:
		failed += 1
		push_error("[FLOW] unexpected watermelon DEV flag still present")

	# Highest unlocked must not shrink after a continue.
	var before := GameSettings.highest_unlocked_level
	GameSettings.apply_victory_continue(mini(before + 1, 60), 20, 0, 0, 0, 120, 10)
	if GameSettings.highest_unlocked_level < before:
		failed += 1
		push_error("[FLOW] highest unlocked was reduced")
	else:
		print("[FLOW] OK highest preserved/updated=", GameSettings.highest_unlocked_level)

	var m1 := MissionFactory.create_missions(LevelTheme.Id.FRUIT_GARDEN, 1)
	var m2 := MissionFactory.create_missions(LevelTheme.Id.FRUIT_GARDEN, 2)
	var m3 := MissionFactory.create_missions(LevelTheme.Id.FRUIT_GARDEN, 3)
	if m1.size() != 1 or m2.size() != 2 or m3.size() != 3:
		failed += 1
		push_error("[FLOW] mission stages wrong")
	else:
		print("[FLOW] OK mission stages 1/2/3")

	var home: HomeScreen = load("res://scenes/ui/home_screen.tscn").instantiate()
	add_child(home)
	await get_tree().process_frame
	home.refresh_ui()
	await get_tree().process_frame
	var btn: Button = home.get_node("%LevelButton") as Button
	var txt := btn.text if btn else ""
	print("[FLOW] home button=", txt)
	if not txt.begins_with("LEVEL "):
		failed += 1
		push_error("[FLOW] unexpected home button text: %s" % txt)
	else:
		print("[FLOW] OK home shows level label")

	if _SafeCapture.is_headless():
		print("[FLOW] skip headless screenshot")
	else:
		RenderingServer.force_draw()
		await get_tree().process_frame
		var tex := get_viewport().get_texture()
		if tex != null:
			var img: Image = tex.get_image()
			if img != null:
				img.save_png(ProjectSettings.globalize_path("res://tools/dev_flow_verify.png"))

	home.queue_free()

	if failed > 0:
		push_error("[FLOW] FAILED %d" % failed)
		get_tree().quit(1)
	else:
		print("[FLOW] PASSED")
		get_tree().quit(0)
