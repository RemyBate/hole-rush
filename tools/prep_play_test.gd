extends Node

func _ready() -> void:
	await get_tree().process_frame
	print("[PREPTEST] lives=", GameSettings.lives, " can_play=", GameSettings.can_play(), " play_level=", GameSettings.get_play_level())
	var main_ps: PackedScene = load("res://scenes/main.tscn")
	var main := main_ps.instantiate()
	add_child(main)
	await get_tree().create_timer(0.8).timeout
	var home := main.get_children().filter(func(c): return c is HomeScreen)
	if home.is_empty():
		# find nested
		for c in main.get_children():
			print("[PREPTEST] child=", c.name, " ", c.get_class())
		push_error("[PREPTEST] no HomeScreen")
		get_tree().quit(1)
		return
	var hs: HomeScreen = home[0]
	print("[PREPTEST] home found, prep visible=", hs.get_node("%LevelPrep").visible)
	# Open prep for level 24
	var prep: LevelPrepScreen = hs.get_node("%LevelPrep")
	prep.open_for_level(24)
	await get_tree().process_frame
	await get_tree().create_timer(0.35).timeout
	var btn: Button = prep.get_node("%PlayButton")
	print("[PREPTEST] play disabled=", btn.disabled, " visible=", btn.visible, " filter=", btn.mouse_filter, " connections=", btn.pressed.get_connections().size())
	print("[PREPTEST] prep mouse_filter=", prep.mouse_filter, " dim filter=", prep.get_node("%Dim").mouse_filter)
	# Connect spy
	if not prep.play_pressed.is_connected(_on_play):
		prep.play_pressed.connect(_on_play)
	if not hs.play_level.is_connected(_on_home_play):
		hs.play_level.connect(_on_home_play)
	print("[PREPTEST] clicking Play via emit pressed")
	btn.pressed.emit()
	await get_tree().create_timer(1.2).timeout
	print("[PREPTEST] after click: prep.visible=", prep.visible, " home.visible=", hs.visible)
	var game_nodes := []
	for c in main.get_children():
		print("[PREPTEST] main child after=", c.name, " ", c.get_class(), " visible=", c.get("visible") if c is CanvasItem else "?")
		if c is Node2D and c.has_method("begin_level"):
			game_nodes.append(c)
	print("[PREPTEST] game_nodes=", game_nodes.size(), " lives=", GameSettings.lives)
	if game_nodes.is_empty():
		push_error("[PREPTEST] FAIL no game started")
		get_tree().quit(1)
	else:
		print("[PREPTEST] PASSED")
		get_tree().quit(0)

func _on_play(level: int, boosters: Array) -> void:
	print("[PREP] Play pressed signal level=", level, " boosters=", boosters)

func _on_home_play(level: int, boosters: Array) -> void:
	print("[MAIN-SPY] home play_level level=", level, " boosters=", boosters)
