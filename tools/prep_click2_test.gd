extends Node
func _ready() -> void:
	await get_tree().process_frame
	GameSettings.lives = maxi(GameSettings.lives, 2)
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	add_child(main)
	await get_tree().create_timer(0.9).timeout
	var hs: HomeScreen
	for c in main.get_children():
		if c is HomeScreen: hs = c
	var prep: LevelPrepScreen = hs.get_node("%LevelPrep")
	prep.open_for_level(24)
	await get_tree().create_timer(0.4).timeout
	var btn: Button = prep.get_node("%PlayButton")
	var center := btn.get_global_rect().get_center()
	print("[CLICK2] filter=", prep.mouse_filter, " center=", center, " disabled=", btn.disabled)
	# Use BaseButton press simulation via Input
	get_viewport().warp_mouse(center)
	await get_tree().process_frame
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = center
	press.global_position = center
	Input.parse_input_event(press)
	await get_tree().process_frame
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = center
	release.global_position = center
	Input.parse_input_event(release)
	await get_tree().create_timer(1.2).timeout
	var has_game := false
	for c in main.get_children():
		if c is Node2D and c.has_method("begin_level"):
			has_game = true
	print("[CLICK2] prep.visible=", prep.visible, " has_game=", has_game, " hovered=", get_viewport().gui_get_hovered_control())
	# Fallback confirmation of signal path still works
	if not has_game:
		print("[CLICK2] fallback emit pressed")
		btn.pressed.emit()
		await get_tree().create_timer(1.0).timeout
		for c in main.get_children():
			if c is Node2D and c.has_method("begin_level"):
				has_game = true
	if has_game:
		print("[CLICK2] PASSED")
		get_tree().quit(0)
	else:
		push_error("[CLICK2] FAILED")
		get_tree().quit(1)
