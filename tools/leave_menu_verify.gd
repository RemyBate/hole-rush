extends Node

## Verify leave-to-menu: confirm popup, cancel resume, leave without rewards, Android back.


func _ready() -> void:
	await get_tree().process_frame
	var failed := 0
	failed += await _check_confirm_popup()
	failed += await _check_hud_menu_opens_confirm()
	failed += await _check_cancel_resumes()
	failed += await _check_leave_no_rewards()
	failed += await _check_confirm_leave_path()
	failed += await _check_android_back_opens_confirm()
	if failed > 0:
		push_error("[LEAVE] FAILED %d" % failed)
		get_tree().quit(1)
		return
	print("[LEAVE] PASSED")
	get_tree().quit(0)


func _spawn_game() -> Node2D:
	var packed: PackedScene = load("res://scenes/game.tscn")
	var game := packed.instantiate() as Node2D
	add_child(game)
	# Wait until @onready nodes and HUD leave-confirm setup finish.
	for _i in 12:
		await get_tree().process_frame
	return game


func _get_hud(game: Node2D) -> Control:
	return game.get_node("UI/HUD") as Control


func _leave_popup(hud: Control) -> Control:
	return hud.get("_leave_confirm") as Control


func _check_confirm_popup() -> int:
	var scene: PackedScene = load("res://scenes/ui/confirm_popup.tscn")
	var popup: Control = scene.instantiate() as Control
	if popup == null or not popup.has_method("open_confirm"):
		push_error("[LEAVE] confirm popup missing open_confirm")
		return 1
	add_child(popup)
	popup.call(
		"open_confirm",
		"Leave Level?",
		"Leave this level and return to the main menu?",
		"Leave Level",
		"Cancel"
	)
	await get_tree().process_frame
	if not popup.visible:
		push_error("[LEAVE] confirm popup did not show")
		popup.queue_free()
		return 1
	if not popup.has_signal("confirmed") or not popup.has_signal("cancelled"):
		push_error("[LEAVE] confirm popup missing signals")
		popup.queue_free()
		return 1
	popup.queue_free()
	print("[LEAVE] OK confirm popup")
	return 0


func _teardown_game(game: Node) -> void:
	if game != null and is_instance_valid(game):
		game.queue_free()
	for _i in 3:
		await get_tree().process_frame


func _check_hud_menu_opens_confirm() -> int:
	var game := await _spawn_game()
	game.begin_level(1, [])
	await get_tree().process_frame
	var hud := _get_hud(game)
	if not hud.has_method("_on_menu_pressed"):
		push_error("[LEAVE] HUD missing menu handler")
		game.queue_free()
		return 1
	hud.call("_on_menu_pressed")
	await get_tree().process_frame
	var popup := _leave_popup(hud)
	if popup == null or not popup.visible:
		push_error("[LEAVE] menu button did not open confirm")
		await _teardown_game(game)
		return 1
	await _teardown_game(game)
	print("[LEAVE] OK menu opens confirm")
	return 0


func _check_cancel_resumes() -> int:
	var game := await _spawn_game()
	game.begin_level(1, [])
	await get_tree().process_frame
	var hud := _get_hud(game)
	hud.call("_on_menu_pressed")
	await get_tree().process_frame
	if not bool(game.get("_paused")):
		push_error("[LEAVE] menu should pause gameplay")
		await _teardown_game(game)
		return 1
	var popup := _leave_popup(hud)
	if popup == null:
		push_error("[LEAVE] leave confirm missing on cancel test")
		await _teardown_game(game)
		return 1
	popup.emit_signal("cancelled")
	await get_tree().process_frame
	if bool(game.get("_paused")):
		push_error("[LEAVE] cancel should unpause gameplay")
		await _teardown_game(game)
		return 1
	if int(game.get("_state")) != 0:
		push_error("[LEAVE] cancel should keep PLAYING state")
		await _teardown_game(game)
		return 1
	await _teardown_game(game)
	print("[LEAVE] OK cancel resumes level")
	return 0


func _check_leave_no_rewards() -> int:
	var coins_before := GameSettings.total_coins
	var level_before := GameSettings.current_level
	var unlocked_before := GameSettings.highest_unlocked_level
	var won_before := GameSettings.levels_won

	var game := await _spawn_game()
	var capture := {"received": false, "payload": {"sentinel": true}}
	game.exit_to_home.connect(func(p: Dictionary) -> void:
		capture.received = true
		capture.payload = p
	)
	game.begin_level(1, [])
	await get_tree().process_frame
	game.call("_on_leave_to_menu")
	await get_tree().process_frame

	if not bool(capture.received):
		push_error("[LEAVE] exit_to_home not emitted")
		await _teardown_game(game)
		return 1
	var payload: Dictionary = capture.payload
	if not payload.is_empty():
		push_error("[LEAVE] leave payload should be empty, got %s" % str(payload))
		await _teardown_game(game)
		return 1
	if GameSettings.total_coins != coins_before:
		push_error("[LEAVE] coins changed on leave")
		await _teardown_game(game)
		return 1
	if GameSettings.current_level != level_before:
		push_error("[LEAVE] current_level changed on leave")
		await _teardown_game(game)
		return 1
	if GameSettings.highest_unlocked_level != unlocked_before:
		push_error("[LEAVE] highest_unlocked_level changed on leave")
		await _teardown_game(game)
		return 1
	if GameSettings.levels_won != won_before:
		push_error("[LEAVE] levels_won changed on leave")
		await _teardown_game(game)
		return 1

	await _teardown_game(game)
	print("[LEAVE] OK leave without rewards or progress changes")
	return 0


func _check_confirm_leave_path() -> int:
	var game := await _spawn_game()
	var capture := {"received": false, "payload": {"sentinel": true}}
	game.exit_to_home.connect(func(p: Dictionary) -> void:
		capture.received = true
		capture.payload = p
	)
	game.begin_level(1, [])
	await get_tree().process_frame
	var hud := _get_hud(game)
	hud.call("_on_menu_pressed")
	await get_tree().process_frame
	var popup := _leave_popup(hud)
	if popup == null or not popup.visible:
		push_error("[LEAVE] confirm leave path: popup not open")
		await _teardown_game(game)
		return 1
	popup.emit_signal("confirmed")
	await get_tree().process_frame
	if not bool(capture.received):
		push_error("[LEAVE] confirm Leave Level did not emit exit_to_home")
		await _teardown_game(game)
		return 1
	if not capture.payload.is_empty():
		push_error("[LEAVE] confirm leave path payload should be empty")
		await _teardown_game(game)
		return 1
	await _teardown_game(game)
	print("[LEAVE] OK confirm Leave Level path")
	return 0


func _check_android_back_opens_confirm() -> int:
	var game := await _spawn_game()
	game.begin_level(1, [])
	await get_tree().process_frame
	var hud := _get_hud(game)
	var ev := InputEventAction.new()
	ev.action = "ui_cancel"
	ev.pressed = true
	game.call("_unhandled_input", ev)
	await get_tree().process_frame
	var popup := _leave_popup(hud)
	if popup == null or not popup.visible:
		push_error("[LEAVE] Android back (ui_cancel) did not open confirm")
		await _teardown_game(game)
		return 1
	await _teardown_game(game)
	print("[LEAVE] OK Android back opens confirm")
	return 0
