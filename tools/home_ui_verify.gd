extends Node

## Headless smoke: home screen mounts feature popups without hanging.


func _ready() -> void:
	await get_tree().process_frame
	var hs: HomeScreen = (load("res://scenes/ui/home_screen.tscn") as PackedScene).instantiate()
	add_child(hs)
	for _i in 6:
		await get_tree().process_frame

	var fails := 0
	if hs._map_popup == null or hs._trophy_popup == null or hs._collection_popup == null or hs._shop_screen == null or hs._event_popup == null:
		push_error("[HOMEUI] one or more home popups missing")
		fails += 1
	else:
		print("[HOMEUI] OK popups mounted")

	# Brief open/close — avoid long map rebuild loops that can stall headless runs.
	hs._shop_screen.open_shop()
	await get_tree().process_frame
	hs._close_home_popups()
	await get_tree().process_frame
	hs._trophy_popup.open_trophies()
	await get_tree().process_frame
	hs._close_home_popups()
	await get_tree().process_frame
	print("[HOMEUI] OK shop/trophy open-close")

	print("[HOMEUI] fails=", fails)
	get_tree().quit(0 if fails == 0 else 1)
