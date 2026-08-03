extends Node

## Headless checks for collect SFX routing + silent hole movement.


var _failed: int = 0


func _ready() -> void:
	await get_tree().process_frame
	_check_streams()
	_check_routing()
	_check_hole_has_no_audio()
	_check_sound_toggle()
	await _check_ingame_collect_path()

	if _failed > 0:
		push_error("[COLLECT_SFX] FAILED %d" % _failed)
		get_tree().quit(1)
	else:
		print("[COLLECT_SFX] PASSED")
		get_tree().quit(0)


func _fail(msg: String) -> void:
	push_error("[COLLECT_SFX] " + msg)
	_failed += 1


func _ok(msg: String) -> void:
	print("[COLLECT_SFX] OK ", msg)


func _check_streams() -> void:
	for path in [
		"res://audio/collect_normal.wav",
		"res://audio/collect_target.wav",
		"res://audio/ui_click.wav",
	]:
		var stream: AudioStream = load(path) as AudioStream
		if stream == null:
			_fail("failed to load audio %s" % path)
		else:
			_ok("loaded %s" % path)


func _check_routing() -> void:
	GameSettings.sound_enabled = true
	GameSettings.play_collect_normal_sfx()
	GameSettings.play_collect_target_sfx()
	GameSettings.play_item_collect_sfx(false)
	GameSettings.play_item_collect_sfx(true)
	_ok("collect sfx APIs callable")

	var m := Mission.new()
	m.catalog_key = "fruits:7"
	m.target = 2
	m.progress = 0
	if m.is_complete():
		_fail("mission should start incomplete")
	m.progress = 2
	if not m.is_complete():
		_fail("mission should complete at target")
	else:
		_ok("completed mission is_complete for normal-sound rule")


func _check_hole_has_no_audio() -> void:
	var src := FileAccess.get_file_as_string("res://scripts/hole.gd")
	if "play_sfx" in src or "AudioStream" in src or "GameSettings.play" in src:
		_fail("hole.gd still references audio playback")
	else:
		_ok("hole.gd has no movement audio calls")

	var food_src := FileAccess.get_file_as_string("res://scripts/food.gd")
	if "GameSettings.play_sfx()" in food_src:
		_fail("food.gd still plays generic play_sfx on collect")
	else:
		_ok("food.gd no longer plays generic collect click")

	var game_src := FileAccess.get_file_as_string("res://scripts/game.gd")
	if "play_item_collect_sfx" not in game_src or "_is_unfinished_mission_target" not in game_src:
		_fail("game.gd missing mission-aware collect sfx")
	else:
		_ok("game.gd routes mission-aware collect sfx")


func _check_sound_toggle() -> void:
	GameSettings.sound_enabled = false
	GameSettings.play_collect_normal_sfx()
	GameSettings.play_collect_target_sfx()
	GameSettings.sound_enabled = true
	_ok("sound_enabled=false path returns without error")


func _check_ingame_collect_path() -> void:
	var packed: PackedScene = load("res://scenes/game.tscn")
	var game: Node2D = packed.instantiate() as Node2D
	add_child(game)
	game.begin_level(1, [])
	for _i in 10:
		await get_tree().process_frame

	if not game.has_method("_is_unfinished_mission_target"):
		_fail("game missing _is_unfinished_mission_target")
	else:
		_ok("in-game mission target helper present")

	# Rapid fire API should not error / allocate unbounded players.
	for _i in 12:
		GameSettings.play_item_collect_sfx(_i % 2 == 0)
	_ok("rapid collect sfx burst")

	game.queue_free()
	await get_tree().process_frame
