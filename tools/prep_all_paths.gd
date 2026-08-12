extends Node
func _ready() -> void:
	await get_tree().process_frame
	GameSettings.lives = 5
	var fails := 0
	fails += await _run(1, [])
	fails += await _run(24, [])
	fails += await _run(24, [0])
	fails += await _run(24, [0, 1])
	# Hover check
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	add_child(main)
	await get_tree().create_timer(0.7).timeout
	var hs: HomeScreen
	for c in main.get_children():
		if c is HomeScreen: hs = c
	var prep: LevelPrepScreen = hs.get_node("%LevelPrep")
	prep.open_for_level(24)
	await get_tree().create_timer(0.3).timeout
	var btn: Button = prep.get_node("%PlayButton")
	get_viewport().warp_mouse(btn.get_global_rect().get_center())
	await get_tree().process_frame
	var hovered = get_viewport().gui_get_hovered_control()
	print("[HOVER] ", hovered, " is_play=", hovered == btn)
	if hovered != btn:
		fails += 1
		push_error("[HOVER] PlayButton not hovered")
	main.queue_free()
	print("[ALL] fails=", fails)
	get_tree().quit(0 if fails == 0 else 1)

func _run(level: int, boosters: Array) -> int:
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	add_child(main)
	await get_tree().create_timer(0.65).timeout
	var hs: HomeScreen
	for c in main.get_children():
		if c is HomeScreen: hs = c
	var prep: LevelPrepScreen = hs.get_node("%LevelPrep")
	prep.open_for_level(level)
	await get_tree().process_frame
	# apply boosters
	for id in boosters:
		if id not in prep._selected:
			prep._on_booster_toggled(id)
	prep._on_play_pressed()
	await get_tree().create_timer(1.0).timeout
	var ok := false
	for c in main.get_children():
		if c is Node2D and c.has_method("begin_level"):
			ok = true
	print("[RUN] L", level, " boosters=", boosters, " ok=", ok, " prep_open=", prep.visible)
	main.queue_free()
	await get_tree().process_frame
	return 0 if ok else 1
