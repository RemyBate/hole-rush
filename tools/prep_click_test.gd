extends Node

## Simulate real mouse click on Play button (not pressed.emit).

func _ready() -> void:
	await get_tree().process_frame
	GameSettings.lives = maxi(GameSettings.lives, 1)
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	add_child(main)
	await get_tree().create_timer(0.9).timeout
	var hs: HomeScreen = null
	for c in main.get_children():
		if c is HomeScreen:
			hs = c
			break
	var prep: LevelPrepScreen = hs.get_node("%LevelPrep")
	prep.open_for_level(24)
	await get_tree().create_timer(0.4).timeout
	var btn: Button = prep.get_node("%PlayButton")
	# Ensure we can see hierarchy that might steal clicks
	_dump_overlays(hs)
	var rect := btn.get_global_rect()
	var center := rect.get_center()
	print("[CLICK] button rect=", rect, " center=", center, " viewport=", get_viewport().get_visible_rect().size)
	# Spy
	prep.play_pressed.connect(func(l, b): print("[CLICK] prep play_pressed got", l, b))
	hs.play_level.connect(func(l, b): print("[CLICK] home play_level got", l, b))
	# Real InputEventMouseButton at button center
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = true
	ev.position = center
	ev.global_position = center
	get_viewport().push_input(ev)
	await get_tree().process_frame
	var ev2 := InputEventMouseButton.new()
	ev2.button_index = MOUSE_BUTTON_LEFT
	ev2.pressed = false
	ev2.position = center
	ev2.global_position = center
	get_viewport().push_input(ev2)
	await get_tree().create_timer(1.2).timeout
	var has_game := false
	for c in main.get_children():
		if c is Node2D and c.has_method("begin_level"):
			has_game = true
	print("[CLICK] prep.visible=", prep.visible, " has_game=", has_game)
	# Also test gui_get_hovered / pick
	var hovered = get_viewport().gui_get_hovered_control()
	print("[CLICK] hovered after=", hovered)
	# Force pick at center
	var pick = _find_control_at(hs, center)
	print("[CLICK] topmost control at center=", pick)
	if has_game:
		print("[CLICK] PASSED")
		get_tree().quit(0)
	else:
		push_error("[CLICK] FAIL game did not start from real mouse click")
		get_tree().quit(1)

func _dump_overlays(hs: Node) -> void:
	for c in hs.get_children():
		if c is Control:
			var ctl := c as Control
			print("[OVERLAY] ", ctl.name, " visible=", ctl.visible, " z=", ctl.z_index, " filter=", ctl.mouse_filter, " layer=", ctl.get_class(), " rect=", ctl.get_global_rect().size)

func _find_control_at(root: Node, pos: Vector2) -> String:
	var best := ""
	var best_z := -999999
	_walk(root, pos, 0, best, best_z)
	return best

func _walk(n: Node, pos: Vector2, depth: int, best: String, best_z: int) -> void:
	if n is Control:
		var c := n as Control
		if c.visible and c.mouse_filter != Control.MOUSE_FILTER_IGNORE:
			var r := c.get_global_rect()
			if r.has_point(pos):
				print("[HIT] ", "  ".repeat(depth), c.name, " filter=", c.mouse_filter, " z=", c.z_index, " ", c.get_class())
	for ch in n.get_children():
		_walk(ch, pos, depth + 1, best, best_z)
