extends Node

## Full-screen Shop graphical verification + purchase smoke tests.


func _ready() -> void:
	await get_tree().process_frame
	DisplayServer.window_set_size(Vector2i(405, 720))
	await get_tree().process_frame

	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	add_child(main)
	await get_tree().create_timer(0.85).timeout

	var hs: HomeScreen = null
	for c in main.get_children():
		if c is HomeScreen:
			hs = c
			break
	if hs == null:
		push_error("[SHOP] HomeScreen missing")
		get_tree().quit(1)
		return

	var shop: ShopScreen = hs._shop_screen as ShopScreen
	if shop == null:
		push_error("[SHOP] ShopScreen missing")
		get_tree().quit(1)
		return

	var fails := 0

	# Seed currencies for purchase tests (local verify only).
	GameSettings.total_coins = maxi(GameSettings.total_coins, 5000)
	GameSettings.total_gems = maxi(GameSettings.total_gems, 200)
	GameSettings.lives = mini(GameSettings.lives, 2)
	GameSettings.save_profile()

	hs._on_nav_pressed(0)
	await get_tree().create_timer(0.45).timeout
	if not shop.visible:
		push_error("[SHOP] shop did not open")
		fails += 1
	else:
		print("[SHOP] OK opened full-screen")

	fails += await _capture("shop_fullscreen")

	# Scroll to reveal more cards.
	shop._scroll.scroll_vertical = 220
	await get_tree().process_frame
	RenderingServer.force_draw()
	await get_tree().process_frame
	fails += await _capture("shop_offers")

	# Confirmation for starter pack.
	shop._show_confirm({
		"id": "starter_pack",
		"title": "Starter Booster Pack",
		"contents": "2 Magnet · 2 Freeze · 2 Lightning · 2 Double Coins",
		"price": 1200,
		"currency": "coins",
	})
	await get_tree().create_timer(0.25).timeout
	fails += await _capture("shop_confirm")

	var coins_before := GameSettings.total_coins
	var magnets_before := GameSettings.booster_magnet
	shop._on_confirm_buy()
	await get_tree().process_frame
	if GameSettings.total_coins != coins_before - 1200:
		push_error("[SHOP] starter pack coin deduct failed %d -> %d" % [coins_before, GameSettings.total_coins])
		fails += 1
	elif GameSettings.booster_magnet < magnets_before + 2:
		push_error("[SHOP] starter pack reward missing")
		fails += 1
	else:
		print("[SHOP] OK starter purchase")
	fails += await _capture("shop_success")

	# Insufficient funds path.
	GameSettings.total_coins = 10
	GameSettings.save_profile()
	shop._refresh_balances()
	var busy_before := GameSettings.total_coins
	shop._execute_purchase({
		"id": "magnet_pack",
		"title": "Magnet Pack",
		"contents": "3 Magnet boosters",
		"price": 250,
		"currency": "coins",
	})
	if GameSettings.total_coins != busy_before:
		push_error("[SHOP] insufficient funds mutated coins")
		fails += 1
	elif "Not enough" not in shop._status.text:
		push_error("[SHOP] missing insufficient message: " + shop._status.text)
		fails += 1
	else:
		print("[SHOP] OK insufficient funds")

	# Close + reopen balances.
	shop.close_shop()
	await get_tree().create_timer(0.25).timeout
	if shop.visible:
		push_error("[SHOP] close failed")
		fails += 1
	hs._on_nav_pressed(0)
	await get_tree().create_timer(0.3).timeout
	if str(shop._coin_label.text).replace(",", "") != str(GameSettings.total_coins):
		# label may include commas
		var label_num := str(shop._coin_label.text).replace(",", "")
		if label_num != str(GameSettings.total_coins):
			push_error("[SHOP] balance mismatch label=%s coins=%d" % [shop._coin_label.text, GameSettings.total_coins])
			fails += 1
		else:
			print("[SHOP] OK reopen balances")
	else:
		print("[SHOP] OK reopen balances")

	# Android Back
	var ev := InputEventAction.new()
	ev.action = "ui_cancel"
	ev.pressed = true
	shop._unhandled_input(ev)
	await get_tree().create_timer(0.2).timeout
	if shop.visible:
		push_error("[SHOP] back did not close")
		fails += 1
	else:
		print("[SHOP] OK back closes")

	print("[SHOP] fails=", fails)
	get_tree().quit(0 if fails == 0 else 1)


func _capture(name: String) -> int:
	RenderingServer.force_draw()
	await get_tree().process_frame
	var img: Image = get_viewport().get_texture().get_image()
	if img == null:
		push_error("[SHOP] no image for " + name)
		return 1
	var path := ProjectSettings.globalize_path("res://tools/%s_verify.png" % name)
	img.save_png(path)
	print("[SHOP] screenshot=", path)
	return 0
