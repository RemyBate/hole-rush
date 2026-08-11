extends Node

var _passed := 0
var _failed := 0

func _ready() -> void:
	await get_tree().process_frame
	GameSettings.lives = maxi(GameSettings.lives, 3)
	await _test_real_click(24, [])
	await _test_emit_with_boosters()
	await _test_no_lives_feedback()
	print("[PREPFIX] passed=", _passed, " failed=", _failed)
	get_tree().quit(0 if _failed == 0 else 1)

func _ok(msg: String) -> void:
	_passed += 1
	print("[PREPFIX] OK ", msg)

func _bad(msg: String) -> void:
	_failed += 1
	push_error("[PREPFIX] FAIL ", msg)

func _make_main() -> Node:
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	add_child(main)
	return main

func _get_home(main: Node) -> HomeScreen:
	for c in main.get_children():
		if c is HomeScreen:
			return c
	return null

func _has_game(main: Node) -> bool:
	for c in main.get_children():
		if c is Node2D and c.has_method("begin_level"):
			return true
	return false

func _test_real_click(level: int, boosters: Array) -> void:
	var main := _make_main()
	await get_tree().create_timer(0.85).timeout
	var hs := _get_home(main)
	var prep: LevelPrepScreen = hs.get_node("%LevelPrep")
	prep.open_for_level(level)
	await get_tree().create_timer(0.35).timeout
	print("[PREPFIX] prep filter=", prep.mouse_filter, " z=", prep.z_index)
	var btn: Button = prep.get_node("%PlayButton")
	btn.pressed.emit()
	await get_tree().create_timer(1.1).timeout
	if _has_game(main):
		_ok("level %d started" % level)
	else:
		_bad("level %d did not start" % level)
	main.queue_free()
	await get_tree().process_frame

func _test_emit_with_boosters() -> void:
	GameSettings.lives = maxi(GameSettings.lives, 2)
	GameSettings.booster_lightning = maxi(GameSettings.booster_lightning, 2)
	GameSettings.booster_freeze = maxi(GameSettings.booster_freeze, 2)
	var main := _make_main()
	await get_tree().create_timer(0.7).timeout
	var hs := _get_home(main)
	var prep: LevelPrepScreen = hs.get_node("%LevelPrep")
	prep.open_for_level(24)
	await get_tree().process_frame
	# select two boosters via internal API
	prep._on_booster_toggled(0)
	prep._on_booster_toggled(1)
	prep._on_play_pressed()
	await get_tree().create_timer(1.1).timeout
	if _has_game(main):
		_ok("play with two boosters")
	else:
		_bad("play with two boosters failed")
	main.queue_free()
	await get_tree().process_frame

func _test_no_lives_feedback() -> void:
	var saved := GameSettings.lives
	GameSettings.lives = 0
	var main := _make_main()
	await get_tree().create_timer(0.6).timeout
	var hs := _get_home(main)
	var prep: LevelPrepScreen = hs.get_node("%LevelPrep")
	prep.open_for_level(1)
	await get_tree().process_frame
	prep._on_play_pressed()
	await get_tree().create_timer(0.2).timeout
	if prep.visible and not _has_game(main):
		_ok("no-lives blocks start and keeps popup")
	else:
		_bad("no-lives behaviour wrong")
	GameSettings.lives = maxi(saved, 1)
	main.queue_free()
	await get_tree().process_frame
