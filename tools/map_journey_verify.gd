extends Node
const _SafeCapture := preload("res://tools/safe_viewport_capture.gd")

## Full-screen Journey map graphical verification.


func _ready() -> void:
	await get_tree().process_frame
	DisplayServer.window_set_size(Vector2i(405, 720))
	await get_tree().process_frame

	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	add_child(main)
	await get_tree().create_timer(0.85).timeout

	var hs: HomeScreen = null
	for c in main.get_children():
		if c is HomeScreen:
			hs = c
			break
	if hs == null:
		push_error("[MAP] HomeScreen missing")
		get_tree().quit(1)
		return

	var map_screen = hs._map_popup
	if map_screen == null or not map_screen.has_method("open_map"):
		push_error("[MAP] MapScreen missing")
		get_tree().quit(1)
		return

	var fails := 0

	# Seed progress so completed / current / locked are all visible.
	GameSettings.highest_unlocked_level = 8
	GameSettings.current_level = 8
	GameSettings.save_profile()

	hs._on_nav_pressed(1)
	await get_tree().create_timer(0.7).timeout
	if not map_screen.visible:
		push_error("[MAP] map did not open")
		fails += 1
	else:
		print("[MAP] OK opened full-screen")

	fails += await _capture("map_fullscreen")

	# Ensure current node exists and scroll moved near it.
	if map_screen._current_node == null:
		push_error("[MAP] current node missing")
		fails += 1
	else:
		print("[MAP] OK current marker node")
	fails += await _capture("map_current")

	# Scroll down to show locked levels + milestone.
	map_screen._scroll.scroll_vertical = int(map_screen._scroll.get_v_scroll_bar().max_value * 0.35)
	await get_tree().process_frame
	fails += await _capture("map_locked_milestone")

	# Locked press.
	map_screen._on_level_pressed(20, true, null)
	await get_tree().process_frame
	if "previous level" not in map_screen._status.text.to_lower() and "complete" not in map_screen._status.text.to_lower():
		push_error("[MAP] locked message missing: " + map_screen._status.text)
		fails += 1
	else:
		print("[MAP] OK locked message")

	# Unlocked select -> prep.
	var unlocked_level := 5
	map_screen._on_level_pressed(unlocked_level, false, null)
	await get_tree().create_timer(0.35).timeout
	if map_screen.visible:
		push_error("[MAP] map still open after level select")
		fails += 1
	var prep = hs.get_node("%LevelPrep")
	if prep == null or not prep.visible:
		push_error("[MAP] level prep did not open")
		fails += 1
	else:
		print("[MAP] OK unlocked opens prep")
	fails += await _capture("map_to_prep")

	# Close prep, reopen map, back closes.
	if prep and prep.has_method("close_panel"):
		prep.close_panel()
	await get_tree().process_frame
	hs._on_nav_pressed(1)
	await get_tree().create_timer(0.45).timeout
	var ev := InputEventAction.new()
	ev.action = "ui_cancel"
	ev.pressed = true
	map_screen._unhandled_input(ev)
	await get_tree().create_timer(0.2).timeout
	if map_screen.visible:
		push_error("[MAP] back did not close")
		fails += 1
	else:
		print("[MAP] OK back closes")

	print("[MAP] fails=", fails)
	get_tree().quit(0 if fails == 0 else 1)


func _capture(name: String) -> int:
	var path := ProjectSettings.globalize_path("res://tools/%s_verify.png" % name)
	if _SafeCapture.is_headless():
		print("[CAP] skip headless screenshot ", path)
		return 0
	RenderingServer.force_draw()
	await get_tree().process_frame
	var tex := get_viewport().get_texture()
	if tex == null:
		push_error("[CAP] no image for " + name)
		return 1
	var img: Image = tex.get_image()
	if img == null:
		push_error("[CAP] no image for " + name)
		return 1
	img.save_png(path)
	print("[CAP] screenshot=", path)
	return 0

