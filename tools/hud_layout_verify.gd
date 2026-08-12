extends Node

## Verify HUD header stays at the top and playable objects stay below it.


const RESOLUTIONS: Array[Vector2i] = [
	Vector2i(720, 1280),
	Vector2i(1080, 1920),
	Vector2i(1080, 2340),
	Vector2i(1080, 2400),
	Vector2i(1440, 3200),
]


func _ready() -> void:
	await get_tree().process_frame
	var failed := 0
	for res in RESOLUTIONS:
		failed += await _check_resolution(res)
	failed += await _check_spawn_and_hole()
	if failed > 0:
		push_error("[HUDLAY] FAILED %d" % failed)
		get_tree().quit(1)
		return
	print("[HUDLAY] PASSED")
	get_tree().quit(0)


func _set_resolution(res: Vector2i) -> void:
	var win := get_window()
	if win:
		win.size = res
	await get_tree().process_frame
	await get_tree().process_frame


func _check_resolution(res: Vector2i) -> int:
	await _set_resolution(res)
	var game := (load("res://scenes/game.tscn") as PackedScene).instantiate() as Node2D
	add_child(game)
	game.begin_level(2, [])
	for _i in 18:
		await get_tree().process_frame

	var hud := game.get_node("UI/HUD") as Control
	if hud == null:
		push_error("[HUDLAY] missing HUD at %s" % str(res))
		await _teardown(game)
		return 1
	hud.call("_refresh_header_layout")
	game.call("_refresh_play_regions")
	await get_tree().process_frame

	var header: Rect2 = hud.call("get_header_rect")
	var play: Rect2 = hud.call("get_playable_screen_rect")
	var vr := get_viewport().get_visible_rect()

	if header.position.y > 8.0:
		push_error("[HUDLAY] header not at top (%s) y=%s" % [str(res), header.position.y])
		await _teardown(game)
		return 1
	if header.size.y < 120.0 or header.size.y > vr.size.y * 0.55:
		push_error("[HUDLAY] header height unreasonable (%s) h=%s" % [str(res), header.size.y])
		await _teardown(game)
		return 1
	if play.position.y < header.end.y - 1.0:
		push_error("[HUDLAY] playable overlaps header (%s)" % str(res))
		await _teardown(game)
		return 1
	if play.size.y < 200.0:
		push_error("[HUDLAY] playable area too small (%s) h=%s" % [str(res), play.size.y])
		await _teardown(game)
		return 1

	var spawn: Rect2 = game.call("get_spawn_bounds")
	var header_world: float = float(game.call("_header_height_in_world"))
	if spawn.position.y + 1.0 < header_world * 0.45:
		push_error("[HUDLAY] spawn top not below header inset (%s) top=%s inset=%s" % [str(res), spawn.position.y, header_world])
		await _teardown(game)
		return 1

	print("[HUDLAY] OK layout ", res, " header_h=", int(header.size.y), " play_h=", int(play.size.y), " spawn_top=", int(spawn.position.y))
	await _teardown(game)
	return 0


func _check_spawn_and_hole() -> int:
	await _set_resolution(Vector2i(720, 1280))
	var game := (load("res://scenes/game.tscn") as PackedScene).instantiate() as Node2D
	add_child(game)
	game.begin_level(2, [])
	for _i in 24:
		await get_tree().process_frame
	var hud := game.get_node("UI/HUD") as Control
	hud.call("_refresh_header_layout")
	game.call("_refresh_play_regions")
	var hole: Hole = game.get_node("Hole") as Hole
	var cam: Camera2D = game.get_node("Camera2D") as Camera2D
	cam.position_smoothing_enabled = false
	cam.global_position = hole.global_position + game.call("_camera_offset_for_hud")
	game.call("_enforce_hud_exclusion")
	await get_tree().process_frame

	var header_bottom: float = float(hud.call("get_header_bottom"))
	var failed := 0
	for node in get_tree().get_nodes_in_group("food"):
		var food := node as Food
		if food == null or not food.visible:
			continue
		var screen_y: float = float(game.call("_world_to_screen", food.global_position).y)
		var top := screen_y - food.get_visual_radius()
		if top < header_bottom - 1.0:
			push_error("[HUDLAY] visible food intersects HUD y=%s top=%s header=%s" % [screen_y, top, header_bottom])
			failed += 1
			break
	for node in get_tree().get_nodes_in_group("currency"):
		var pickup := node as CurrencyPickup
		if pickup == null or not pickup.visible:
			continue
		var screen_y: float = float(game.call("_world_to_screen", pickup.global_position).y)
		var top := screen_y - pickup.get_visual_radius()
		if top < header_bottom - 1.0:
			push_error("[HUDLAY] visible currency intersects HUD")
			failed += 1
			break

	var hole_screen: float = float(game.call("_world_to_screen", hole.global_position).y)
	if hole_screen - hole.radius < header_bottom - 1.0:
		push_error("[HUDLAY] hole intersects HUD")
		failed += 1

	var play: Rect2 = game.call("get_play_bounds")
	var illegal := Vector2(play.position.x + play.size.x * 0.5, play.position.y - 200.0)
	hole.global_position = illegal
	hole.set_play_bounds(play)
	if hole.global_position.y < play.position.y + hole.radius - 1.0:
		push_error("[HUDLAY] hole not clamped out of header strip")
		failed += 1

	var missions: Array = game.get("_missions")
	var spawner = game.get_node("FoodSpawner")
	for m in missions:
		var mission := m as Mission
		var have: int = spawner.count_catalog_key(mission.catalog_key)
		if have < mission.target:
			push_error("[HUDLAY] L2 mission under-spawned %s have=%d need=%d" % [mission.catalog_key, have, mission.target])
			failed += 1

	if failed == 0:
		print("[HUDLAY] OK spawn/hole exclusion + L2 counts")
	await _teardown(game)
	return failed


func _teardown(game: Node) -> void:
	if game != null and is_instance_valid(game):
		game.queue_free()
	for _i in 3:
		await get_tree().process_frame
