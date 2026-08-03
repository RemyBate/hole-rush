extends Node

## Open each home popup once and capture screenshots.


func _ready() -> void:
	await get_tree().process_frame
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	add_child(main)
	await get_tree().create_timer(0.9).timeout
	var hs: HomeScreen = null
	for c in main.get_children():
		if c is HomeScreen:
			hs = c
			break
	if hs == null:
		push_error("[HOMEUI] no home")
		get_tree().quit(1)
		return

	var fails := 0
	fails += await _shot(hs, "map", func(): hs._map_popup.open_map())
	fails += await _shot(hs, "trophy", func(): hs._trophy_popup.open_trophies())
	fails += await _shot(hs, "collection", func(): hs._collection_popup.open_collection())
	fails += await _shot(hs, "event", func(): hs._event_popup.open_event("tournament", "Tournament"))
	fails += await _shot(hs, "shop", func(): hs._shop_screen.open_shop())

	hs._close_home_popups()
	await get_tree().process_frame
	hs._map_popup.open_map()
	await get_tree().process_frame
	hs._map_popup._on_level_pressed(GameSettings.get_play_level(), false)
	await get_tree().create_timer(0.35).timeout
	if not hs.get_node("%LevelPrep").visible:
		push_error("[HOMEUI] prep did not open from map")
		fails += 1
	else:
		print("[HOMEUI] OK map->prep")

	hs._level_prep.close_panel()
	await get_tree().process_frame
	hs._map_popup.open_map()
	await get_tree().process_frame
	var locked := mini(LevelTheme.MAX_LEVEL, GameSettings.highest_unlocked_level + 5)
	hs._map_popup._on_level_pressed(locked, true)
	var status_txt := str(hs._map_popup.get_node("%StatusLabel").text).to_lower()
	if "locked" not in status_txt:
		push_error("[HOMEUI] locked message missing: " + status_txt)
		fails += 1
	else:
		print("[HOMEUI] OK locked message")

	print("[HOMEUI] fails=", fails)
	get_tree().quit(0 if fails == 0 else 1)


func _shot(hs: HomeScreen, name: String, open_cb: Callable) -> int:
	hs._close_home_popups()
	await get_tree().process_frame
	open_cb.call()
	await get_tree().create_timer(0.35).timeout
	RenderingServer.force_draw()
	await get_tree().process_frame
	var img: Image = get_viewport().get_texture().get_image()
	if img:
		var path := ProjectSettings.globalize_path("res://tools/homeui_%s_verify.png" % name)
		img.save_png(path)
		print("[HOMEUI] screenshot=", path)
	else:
		push_error("[HOMEUI] no image for " + name)
		return 1
	return 0
