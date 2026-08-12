extends Node
const _SafeCapture := preload("res://tools/safe_viewport_capture.gd")

## Full-screen Collection page verification.


func _ready() -> void:
	await get_tree().process_frame
	DisplayServer.window_set_size(Vector2i(405, 720))
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
		push_error("[COL] HomeScreen missing")
		get_tree().quit(1)
		return

	var col = hs._collection_popup
	if col == null or not col.has_method("open_collection"):
		push_error("[COL] CollectionScreen missing")
		get_tree().quit(1)
		return

	var fails := 0
	ItemCatalog.ensure_loaded(ItemCatalog.CATEGORY_FRUITS)
	var entries: Array = ItemCatalog.valid_entries(ItemCatalog.CATEGORY_FRUITS)
	var total := entries.size()

	# Seed partial discoveries for UI + claimable milestone.
	GameSettings.discovered_collectibles.clear()
	GameSettings.discovered_fruit_ids.clear()
	GameSettings.claimed_collection_rewards.clear()
	GameSettings.collected_count_by_id.clear()
	var seed_ids := [1, 2, 3, 7, 8, 13]
	for id in seed_ids:
		GameSettings.mark_collectible_discovered("fruits:%d" % id)
	# Duplicate should not grow unique count.
	var before := GameSettings.discovered_collectible_count()
	GameSettings.mark_collectible_discovered("fruits:1")
	if GameSettings.discovered_collectible_count() != before:
		push_error("[COL] duplicate discovery increased unique count")
		fails += 1
	else:
		print("[COL] OK duplicate blocked")

	hs._on_nav_pressed(4)
	await get_tree().create_timer(0.55).timeout
	if not col.visible:
		push_error("[COL] did not open")
		fails += 1
	elif str(col._title.text) != "COLLECTION":
		push_error("[COL] title wrong")
		fails += 1
	else:
		print("[COL] OK opened discovered=", GameSettings.discovered_collectible_count(), "/", total)
	fails += await _capture("collection_fullscreen")

	# Open first set detail.
	var first_set: Dictionary = {
		"id": "fruits_1",
		"category": "fruits",
		"title": "Fresh Start",
		"icon": "🌱",
		"id_min": 1,
		"id_max": 6,
		"color": Color(0.35, 0.78, 0.42),
	}
	col._open_set(first_set)
	await get_tree().create_timer(0.3).timeout
	fails += await _capture("collection_detail")
	# Back via Android Back.
	var ev := InputEventAction.new()
	ev.action = "ui_cancel"
	ev.pressed = true
	col._unhandled_input(ev)
	await get_tree().process_frame
	if col._view != "overview":
		push_error("[COL] back did not return to overview")
		fails += 1
	else:
		print("[COL] OK detail back")

	fails += await _capture("collection_overview_rewards")

	# Claim milestone if available.
	var claim_id := ""
	for def in GameSettings.collection_reward_definitions(total):
		if bool(def.get("claimable", false)):
			claim_id = str(def.get("id", ""))
			break
	if claim_id == "":
		# Seed more to unlock col_5.
		for id in [4, 5, 9, 10]:
			GameSettings.mark_collectible_discovered("fruits:%d" % id)
		for def in GameSettings.collection_reward_definitions(total):
			if bool(def.get("claimable", false)):
				claim_id = str(def.get("id", ""))
				break
	if claim_id == "":
		push_error("[COL] no claimable reward")
		fails += 1
	else:
		var coins_before := GameSettings.total_coins
		if not GameSettings.claim_collection_reward(claim_id):
			push_error("[COL] claim failed")
			fails += 1
		elif not GameSettings.claimed_collection_rewards.has(claim_id):
			push_error("[COL] claim not saved")
			fails += 1
		elif GameSettings.claim_collection_reward(claim_id):
			push_error("[COL] double claim allowed")
			fails += 1
		else:
			print("[COL] OK claimed ", claim_id, " coins ", coins_before, "->", GameSettings.total_coins)
	col._refresh()
	await get_tree().process_frame
	fails += await _capture("collection_claimed")

	# Persist reopen.
	col.close_collection()
	await get_tree().create_timer(0.25).timeout
	hs._on_nav_pressed(4)
	await get_tree().create_timer(0.35).timeout
	if GameSettings.discovered_collectible_count() < seed_ids.size():
		push_error("[COL] discoveries lost on reopen")
		fails += 1
	else:
		print("[COL] OK reopen preserves discoveries")

	var ev2 := InputEventAction.new()
	ev2.action = "ui_cancel"
	ev2.pressed = true
	col._unhandled_input(ev2)
	await get_tree().create_timer(0.2).timeout
	if col.visible:
		push_error("[COL] back did not close")
		fails += 1
	else:
		print("[COL] OK back closes")

	print("[COL] fails=", fails)
	get_tree().quit(0 if fails == 0 else 1)


func _capture(name: String) -> int:
	var path := ProjectSettings.globalize_path("res://tools/%s_verify.png" % name)
	if _SafeCapture.is_headless():
		print("[CAP] skip headless screenshot ", path)
		return 0
	RenderingServer.force_draw()
	await get_tree().process_frame
	var tex := get_viewport().get_texture()
	if tex == null:
		push_error("[CAP] no image for " + name)
		return 1
	var img: Image = tex.get_image()
	if img == null:
		push_error("[CAP] no image for " + name)
		return 1
	img.save_png(path)
	print("[CAP] screenshot=", path)
	return 0

