extends Node
const _SafeCapture := preload("res://tools/safe_viewport_capture.gd")

## Full-screen Trophy page verification.


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
		push_error("[TROPHY] HomeScreen missing")
		get_tree().quit(1)
		return

	var trophy = hs._trophy_popup
	if trophy == null or not trophy.has_method("open_trophies"):
		push_error("[TROPHY] TrophyScreen missing")
		get_tree().quit(1)
		return

	var fails := 0

	# Seed enough progress for a claimable reward and visible ranking.
	GameSettings.levels_won = maxi(GameSettings.levels_won, 12)
	GameSettings.highest_unlocked_level = maxi(GameSettings.highest_unlocked_level, 13)
	GameSettings.lifetime_coins = maxi(GameSettings.lifetime_coins, 400)
	GameSettings.best_score = maxi(GameSettings.best_score, 600)
	GameSettings.three_star_wins = maxi(GameSettings.three_star_wins, 1)
	GameSettings.claimed_trophy_rewards.clear()
	GameSettings.save_profile()

	hs._on_nav_pressed(3)
	await get_tree().create_timer(0.55).timeout
	if not trophy.visible:
		push_error("[TROPHY] did not open")
		fails += 1
	elif str(trophy._title.text) != "TROPHY":
		push_error("[TROPHY] title wrong: " + str(trophy._title.text))
		fails += 1
	else:
		print("[TROPHY] OK opened")
	fails += await _capture("trophy_fullscreen")

	# Weekly podium + list.
	fails += await _capture("trophy_weekly_podium")

	# All-time tab.
	trophy._set_tab(trophy.Tab.ALL_TIME)
	await get_tree().create_timer(0.25).timeout
	fails += await _capture("trophy_alltime")

	# Find player highlight in entries.
	var entries: Array = trophy._build_rank_entries(false)
	var found_player := false
	for e in entries:
		if bool(e.get("is_player", false)):
			found_player = true
			break
	if not found_player:
		push_error("[TROPHY] player missing from ranking")
		fails += 1
	else:
		print("[TROPHY] OK player in ranking rank=", trophy._player_rank)

	# Rewards tab + claim.
	trophy._set_tab(trophy.Tab.REWARDS)
	await get_tree().create_timer(0.25).timeout
	fails += await _capture("trophy_rewards")

	var score_before := GameSettings.compute_trophy_score()
	var coins_before := GameSettings.total_coins
	var claim_id := ""
	for def in GameSettings.trophy_reward_definitions():
		if bool(def.get("claimable", false)):
			claim_id = str(def.get("id", ""))
			break
	if claim_id == "":
		push_error("[TROPHY] no claimable reward after seeding")
		fails += 1
	else:
		var ok := GameSettings.claim_trophy_reward(claim_id)
		if not ok:
			push_error("[TROPHY] claim failed for " + claim_id)
			fails += 1
		elif not GameSettings.claimed_trophy_rewards.has(claim_id):
			push_error("[TROPHY] claim not persisted")
			fails += 1
		else:
			print("[TROPHY] OK claimed ", claim_id, " coins ", coins_before, "->", GameSettings.total_coins)
		if GameSettings.claim_trophy_reward(claim_id):
			push_error("[TROPHY] double claim allowed")
			fails += 1
		else:
			print("[TROPHY] OK double-claim blocked")
	trophy._refresh_all()
	await get_tree().process_frame
	fails += await _capture("trophy_claimed")

	# Score uses save data.
	if GameSettings.compute_trophy_score() < 1 and score_before < 1:
		push_error("[TROPHY] trophy score unexpectedly zero")
		fails += 1
	else:
		print("[TROPHY] OK trophy score=", GameSettings.compute_trophy_score())

	# Back closes.
	var ev := InputEventAction.new()
	ev.action = "ui_cancel"
	ev.pressed = true
	trophy._unhandled_input(ev)
	await get_tree().create_timer(0.2).timeout
	if trophy.visible:
		push_error("[TROPHY] back did not close")
		fails += 1
	else:
		print("[TROPHY] OK back closes")

	print("[TROPHY] fails=", fails)
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

