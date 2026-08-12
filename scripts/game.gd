extends Node2D

enum GameState { PLAYING, WON, LOST }

signal exit_to_home(reward_payload: Dictionary)

@onready var hole: Hole = $Hole
@onready var food_spawner: FoodSpawner = $FoodSpawner
@onready var currency_spawner: CurrencySpawner = $CurrencySpawner
@onready var camera: Camera2D = $Camera2D
@onready var hud: Control = $UI/HUD
@onready var play_area: Node2D = $PlayArea

var _state: GameState = GameState.PLAYING
var _time_left: float = GameConstants.GAME_TIME_SECONDS
var _score: int = 0
var _collected: int = 0
var _run_coins: int = 0
var _run_keys: int = 0
var _run_gems: int = 0
var _run_trophies: int = 0
var _play_bounds: Rect2 = Rect2()
var _paused: bool = false
var _missions: Array = []
var _current_level: int = 1
var _paused_for_settings: bool = false
var _pending_victory: Dictionary = {}
var _active_boosters: Array = []
var _double_coins: bool = false
var _started: bool = false
var _world_bounds: Rect2 = Rect2()
var _spawn_bounds: Rect2 = Rect2()
## True after missions are complete; victory waits until in-flight swallows finish.
var _awaiting_swallow_clear: bool = false


func _ready() -> void:
	add_to_group("game")
	_world_bounds = Rect2(Vector2.ZERO, GameConstants.PLAY_AREA_SIZE)
	_play_bounds = _world_bounds
	_spawn_bounds = _world_bounds
	hud.setup(GameConstants.GAME_TIME_SECONDS)
	hud.restart_pressed.connect(_on_restart_pressed)
	hud.victory_continue_pressed.connect(_on_victory_continue_pressed)
	hud.bonus_reward_pressed.connect(_on_bonus_reward_pressed)
	hud.pause_pressed.connect(_on_pause_pressed)
	hud.save_progress_requested.connect(_on_save_progress_requested)
	hud.settings_opened.connect(_on_settings_opened)
	hud.settings_closed.connect(_on_settings_closed)
	hud.menu_pressed.connect(_on_leave_to_menu)
	get_viewport().size_changed.connect(_on_viewport_resized)


func _on_viewport_resized() -> void:
	if _started:
		call_deferred("_refresh_play_regions")


func begin_level(level: int, boosters: Array) -> void:
	_current_level = GameSettings.resolve_play_level(level)
	_active_boosters = boosters.duplicate()
	_time_left = GameConstants.GAME_TIME_SECONDS
	_double_coins = false
	_started = true
	_apply_booster_start_bonuses()
	_start_match()


func _apply_booster_start_bonuses() -> void:
	for id in _active_boosters:
		match int(id):
			BoosterData.Id.LIGHTNING:
				_time_left += 12.0
			BoosterData.Id.FREEZE_TIME:
				_time_left += 18.0
			BoosterData.Id.MAGNET:
				_time_left += 10.0
			BoosterData.Id.DOUBLE_COINS:
				_double_coins = true


func _process(delta: float) -> void:
	if not _started or _state != GameState.PLAYING or _paused:
		return

	if _awaiting_swallow_clear:
		_try_finalize_win_after_swallows()
		return

	_time_left -= delta
	hud.update_timer(_time_left)

	if _time_left <= 0.0:
		_time_left = 0.0
		_lose_match()


func _start_match() -> void:
	_state = GameState.PLAYING
	_paused = false
	_awaiting_swallow_clear = false
	hole.set_paused(false)
	hud.set_paused(false)
	_score = 0
	_collected = 0
	_run_coins = 0
	_run_keys = 0
	_run_gems = 0
	_run_trophies = 0
	_pending_victory = {}
	var theme := LevelTheme.theme_for_level(_current_level)
	var plan := LevelPlan.for_level(_current_level, MissionFactory.category_for_theme(theme))
	if plan.is_empty():
		plan = null
	_missions = MissionFactory.create_missions(theme, _current_level, plan)

	hud.hide_result_screens()
	hud.update_timer(_time_left)
	hud.update_score(_score)
	hud.update_level_coins(_run_coins)
	hud.update_missions(_missions)
	_refresh_play_regions()

	GameDebug.log_level_start(_current_level, _missions, plan)

	# Fruit catalog levels always use the light-green Fruit Garden field
	# (avoids Fast Food grey checkerboard when save progress is in later themes).
	var bg_theme := theme
	if plan != null and plan.category == ItemCatalog.CATEGORY_FRUITS:
		bg_theme = LevelTheme.Id.FRUIT_GARDEN
	_setup_play_area(bg_theme)
	food_spawner.clear_food()
	currency_spawner.clear_pickups()
	food_spawner.spawn_level(_spawn_bounds, theme, _current_level, plan)
	currency_spawner.spawn_level(_spawn_bounds, _current_level, food_spawner)
	_validate_level_spawns(plan)
	GameDebug.log_spawn_counts(food_spawner, _missions)

	var center := _spawn_bounds.position + _spawn_bounds.size * 0.5
	hole.setup(center, _play_bounds)

	if food_spawner.food_collected.is_connected(_on_food_collected):
		food_spawner.food_collected.disconnect(_on_food_collected)
	food_spawner.food_collected.connect(_on_food_collected)
	if food_spawner.has_signal("food_swallow_fx"):
		if food_spawner.food_swallow_fx.is_connected(_on_food_swallow_fx):
			food_spawner.food_swallow_fx.disconnect(_on_food_swallow_fx)
		food_spawner.food_swallow_fx.connect(_on_food_swallow_fx)
	if currency_spawner.pickup_collected.is_connected(_on_currency_collected):
		currency_spawner.pickup_collected.disconnect(_on_currency_collected)
	currency_spawner.pickup_collected.connect(_on_currency_collected)

	camera.make_current()
	camera.position_smoothing_enabled = false
	_apply_camera_limits()
	camera.global_position = hole.global_position + _camera_offset_for_hud()
	_enforce_hud_exclusion()
	call_deferred("_refresh_play_regions")
	call_deferred("_enforce_hud_exclusion")


func _refresh_play_regions() -> void:
	_world_bounds = Rect2(Vector2.ZERO, GameConstants.PLAY_AREA_SIZE)
	var header_world := _header_height_in_world()
	var bottom_safe_world := _bottom_safe_inset_in_world()
	var top_inset := header_world + GameConstants.FOOD_MARGIN * 0.35
	var bottom_inset := bottom_safe_world
	var left_inset := GameConstants.FOOD_MARGIN * 0.25
	var right_inset := GameConstants.FOOD_MARGIN * 0.25
	_spawn_bounds = Rect2(
		_world_bounds.position + Vector2(left_inset, top_inset),
		_world_bounds.size - Vector2(left_inset + right_inset, top_inset + bottom_inset)
	)
	# Hole may use the full spawn floor (same rectangle).
	_play_bounds = _spawn_bounds
	if hole != null and hole.has_method("set_play_bounds"):
		hole.set_play_bounds(_play_bounds)
	_apply_camera_limits()


func _header_height_in_world() -> float:
	if hud != null and hud.has_method("get_header_height"):
		var zoom_y := camera.zoom.y if camera != null and camera.zoom.y > 0.001 else 1.0
		return float(hud.get_header_height()) / zoom_y
	return 260.0


func _bottom_safe_inset_in_world() -> float:
	var vr := get_viewport().get_visible_rect()
	var safe := DisplayServer.get_display_safe_area()
	var bottom_pad_px := 0.0
	if safe.size.y > 0:
		bottom_pad_px = maxf(0.0, vr.end.y - float(safe.end.y))
	# Keep a small floor margin so edge items aren't clipped by home indicators.
	bottom_pad_px = maxf(bottom_pad_px, 12.0)
	var zoom_y := camera.zoom.y if camera != null and camera.zoom.y > 0.001 else 1.0
	return bottom_pad_px / zoom_y


func _camera_offset_for_hud() -> Vector2:
	if hud == null or not hud.has_method("get_playable_screen_rect"):
		return Vector2.ZERO
	var play := hud.get_playable_screen_rect() as Rect2
	var vr := get_viewport().get_visible_rect()
	var playable_center_y := play.position.y + play.size.y * 0.5
	var screen_center_y := vr.position.y + vr.size.y * 0.5
	# camera = hole + offset  =>  hole screen Y = screen_center - offset.y
	return Vector2(0.0, screen_center_y - playable_center_y)


func _apply_camera_limits() -> void:
	if camera == null:
		return
	# Keep the full world drawable behind the header; gameplay clamp uses _play_bounds.
	camera.limit_left = int(_world_bounds.position.x)
	camera.limit_top = int(_world_bounds.position.y)
	camera.limit_right = int(_world_bounds.position.x + _world_bounds.size.x)
	camera.limit_bottom = int(_world_bounds.position.y + _world_bounds.size.y)


func get_playable_screen_rect() -> Rect2:
	if hud != null and hud.has_method("get_playable_screen_rect"):
		return hud.get_playable_screen_rect()
	var vr := get_viewport().get_visible_rect()
	return Rect2(Vector2(vr.position.x, 260.0), Vector2(vr.size.x, maxf(100.0, vr.size.y - 260.0)))


func get_spawn_bounds() -> Rect2:
	return _spawn_bounds


func get_play_bounds() -> Rect2:
	return _play_bounds


func _world_to_screen(world_pos: Vector2) -> Vector2:
	# Use the intended camera pose (ignore smoothing) so HUD exclusion stays exact.
	var cam_pos := hole.global_position + _camera_offset_for_hud()
	var vr := get_viewport().get_visible_rect()
	var zoom := camera.zoom if camera != null else Vector2.ONE
	return (world_pos - cam_pos) * zoom + vr.position + vr.size * 0.5


func _enforce_hud_exclusion() -> void:
	if hud == null or not hud.has_method("get_header_bottom"):
		return
	var header_bottom := float(hud.get_header_bottom())
	for node in get_tree().get_nodes_in_group("food"):
		var food := node as Food
		if food == null or not is_instance_valid(food):
			continue
		var radius := food.get_visual_radius()
		var screen_y := _world_to_screen(food.global_position).y
		food.set_playfield_blocked(screen_y - radius < header_bottom + 0.5)
	for node in get_tree().get_nodes_in_group("currency"):
		var pickup := node as CurrencyPickup
		if pickup == null or not is_instance_valid(pickup):
			continue
		var radius := pickup.get_visual_radius()
		var screen_y := _world_to_screen(pickup.global_position).y
		pickup.set_playfield_blocked(screen_y - radius < header_bottom + 0.5)


func _setup_play_area(theme: int = LevelTheme.Id.FRUIT_GARDEN) -> void:
	if play_area.has_method("setup"):
		# Background still covers the full world; gameplay objects use _spawn_bounds.
		play_area.setup(_world_bounds, theme)


func _physics_process(_delta: float) -> void:
	if not _started or _state != GameState.PLAYING:
		return
	camera.global_position = hole.global_position + _camera_offset_for_hud()
	if not _paused:
		_enforce_hud_exclusion()
		# Keep the hole fully inside the playable floor (world region below header).
		if hole != null and hole.has_method("set_play_bounds"):
			hole.set_play_bounds(_play_bounds)


func _on_pause_pressed() -> void:
	if _state != GameState.PLAYING:
		return
	_paused = not _paused
	hole.set_paused(_paused)
	hud.set_paused(_paused)


func _on_food_swallow_fx(food: Food) -> void:
	if _state != GameState.PLAYING:
		return
	var is_target := _is_unfinished_mission_target(food)
	GameSettings.play_item_collect_sfx(is_target)


func _on_food_collected(food: Food) -> void:
	if _state != GameState.PLAYING:
		return

	if food.catalog_entry != null:
		GameSettings.mark_collectible_discovered(food.catalog_entry.catalog_key())
	var is_target := _is_unfinished_mission_target(food)
	if is_target:
		GameSettings.register_mission_item_collected()

	_collected += 1
	_score += food.score_value
	hud.update_score(_score)
	_apply_mission_progress(food)

	if _collected % GameConstants.GROWTH_EVERY == 0:
		hole.grow(food.get_growth_contribution())

	if _all_missions_complete():
		_awaiting_swallow_clear = true
		_try_finalize_win_after_swallows()


func _any_pending_swallows() -> bool:
	for node in get_tree().get_nodes_in_group("food"):
		var food := node as Food
		if food != null and food.is_busy():
			return true
	for node in get_tree().get_nodes_in_group("currency"):
		var pickup := node as CurrencyPickup
		if pickup != null and pickup.is_busy():
			return true
	return false


func _try_finalize_win_after_swallows() -> void:
	if _state != GameState.PLAYING or not _awaiting_swallow_clear:
		return
	if not _all_missions_complete():
		_awaiting_swallow_clear = false
		return
	if _any_pending_swallows():
		return
	_awaiting_swallow_clear = false
	_win_match()


func _is_unfinished_mission_target(food: Food) -> bool:
	for mission in _missions:
		var m := mission as Mission
		if m == null:
			continue
		if m.is_complete():
			continue
		if m.matches_food(food):
			return true
	return false


func _on_currency_collected(pickup: CurrencyPickup) -> void:
	if _state != GameState.PLAYING:
		return
	var amount := 2 if _double_coins else 1
	match pickup.pickup_kind:
		CurrencyArt.Kind.COIN:
			GameSettings.play_coin_collect_sfx()
			GameSettings.vibrate(18)
			_run_coins += amount
			CollectFx.coin_sparkle(self, pickup.global_position)
			FloatingFeedback.spawn_coin_pop(self, pickup.global_position + Vector2(0.0, -10.0), amount)
			hud.update_level_coins(_run_coins)
		CurrencyArt.Kind.GEM:
			GameSettings.play_sfx()
			GameSettings.vibrate(20)
			_run_gems += amount
		CurrencyArt.Kind.KEY:
			GameSettings.play_sfx()
			GameSettings.vibrate(20)
			_run_keys += amount
		CurrencyArt.Kind.TROPHY:
			GameSettings.play_sfx()
			GameSettings.vibrate(20)
			_run_trophies += amount


## Accepts a Food (Level 4+ catalog / live collect) or a legacy int slot id (tools / L1–3).
func _validate_level_spawns(plan: LevelPlan) -> void:
	if plan == null or plan.is_empty():
		return
	for mission in _missions:
		var m := mission as Mission
		if m == null or m.catalog_key == "":
			continue
		var have := food_spawner.count_catalog_key(m.catalog_key)
		if have < m.target:
			var entry: ItemEntry = null
			for t in plan.targets:
				if str(t.get("catalog_key", "")) == m.catalog_key:
					entry = t.get("entry")
					break
			if entry != null:
				food_spawner.ensure_catalog_count(entry, m.target, _spawn_bounds.position, true)
				have = food_spawner.count_catalog_key(m.catalog_key)
		if have < m.target:
			push_error(
				"[Game] L%d unwinnable target %s need=%d have=%d"
				% [_current_level, m.catalog_key, m.target, have]
			)


func _apply_mission_progress(food_or_type: Variant) -> void:
	for mission in _missions:
		var m := mission as Mission
		if m == null:
			continue
		if food_or_type is Food:
			if m.matches_food(food_or_type as Food):
				m.add_progress()
				GameDebug.log_collect(m.catalog_key, m.progress, m.target)
		elif typeof(food_or_type) == TYPE_INT or typeof(food_or_type) == TYPE_FLOAT:
			# Legacy slot match only — never apply raw ints to catalog missions.
			if m.catalog_key == "" and int(m.item_type) == int(food_or_type):
				m.add_progress()
	hud.update_missions(_missions)


func _all_missions_complete() -> bool:
	for mission in _missions:
		if not mission.is_complete():
			return false
	return true


func _completed_mission_count() -> int:
	var n := 0
	for mission in _missions:
		if mission.is_complete():
			n += 1
	return n


func _build_victory_data() -> Dictionary:
	var stars := GameSettings.stars_for_time_left(_time_left, GameConstants.GAME_TIME_SECONDS)
	var keys_earned := _run_keys
	var trophy_points := _run_trophies
	var coins_collected := _run_coins
	var coins_star_bonus := GameConstants.star_coin_reward(stars)
	var coins_total := coins_collected + coins_star_bonus
	var xp_gain := coins_total + keys_earned * 5 + _run_gems * 8 + trophy_points * 3
	var xp_before := GameSettings.reward_track_xp
	return {
		"completed_level": _current_level,
		"stars": stars,
		"banner_text": GameSettings.banner_for_stars(stars),
		"coins_collected": coins_collected,
		"coins_star_bonus": coins_star_bonus,
		"coins_earned": coins_total,
		"keys_earned": keys_earned,
		"gems_earned": _run_gems,
		"trophy_points": trophy_points,
		"coins_before": GameSettings.total_coins,
		"coins_after": GameSettings.total_coins + coins_total,
		"track_ratio_before": GameSettings.track_fill_ratio(xp_before),
		"track_ratio_after": GameSettings.track_fill_ratio(xp_before + xp_gain),
		"score": _score,
		"collected": _collected,
	}


func _win_match() -> void:
	_state = GameState.WON
	set_process(false)
	GameSettings.play_win_sfx()
	_pending_victory = _build_victory_data()
	GameDebug.log_level_complete(
		_current_level,
		mini(_current_level + 1, LevelTheme.MAX_LEVEL)
	)
	hud.show_victory(_pending_victory)


func _lose_match() -> void:
	_awaiting_swallow_clear = false
	_state = GameState.LOST
	set_process(false)
	GameSettings.play_lose_sfx()
	GameSettings.spend_life()
	hud.show_game_over(_score, _completed_mission_count())


func _on_victory_continue_pressed() -> void:
	if _state != GameState.WON or _pending_victory.is_empty():
		return
	var earned := int(_pending_victory.get("coins_earned", 0))
	var before := int(_pending_victory.get("coins_before", GameSettings.total_coins))
	var fly_from := Vector2.ZERO
	if earned > 0 and hud.has_method("get_victory_coin_fly_global_pos"):
		fly_from = hud.get_victory_coin_fly_global_pos()

	var next_level: int = mini(
		int(_pending_victory.get("completed_level", _current_level)) + 1,
		LevelTheme.MAX_LEVEL
	)

	GameSettings.apply_victory_continue(
		next_level,
		earned,
		int(_pending_victory.get("keys_earned", 0)),
		int(_pending_victory.get("gems_earned", 0)),
		int(_pending_victory.get("trophy_points", 0)),
		int(_pending_victory.get("score", 0)),
		int(_pending_victory.get("collected", 0)),
	)
	if int(_pending_victory.get("stars", 0)) >= 3:
		GameSettings.register_three_star_win()
		GameSettings.save_profile()
	var reward_payload := {}
	if earned > 0:
		reward_payload = {
			"coins_earned": earned,
			"coins_before": before,
			"fly_from": fly_from,
		}
	_pending_victory = {}
	hud.hide_result_screens()
	exit_to_home.emit(reward_payload)


func _on_bonus_reward_pressed() -> void:
	GameSettings.play_ui_click()
	hud.show_bonus_reward_message()


func _on_restart_pressed() -> void:
	if _state == GameState.WON:
		return
	hud.hide_result_screens()
	if not GameSettings.can_play():
		exit_to_home.emit({})
		return
	_started = true
	_double_coins = false
	_active_boosters.clear()
	_time_left = GameConstants.GAME_TIME_SECONDS
	set_process(true)
	_start_match()


func save_progress() -> void:
	GameSettings.save_progress(_current_level, _score, _collected)


func _on_save_progress_requested() -> void:
	save_progress()


func _on_settings_opened() -> void:
	if _state != GameState.PLAYING:
		return
	_paused_for_settings = _paused
	_paused = true
	hole.set_paused(true)
	hud.set_paused(true)


func _on_settings_closed() -> void:
	if _state != GameState.PLAYING:
		return
	_paused = _paused_for_settings
	hole.set_paused(_paused)
	hud.set_paused(_paused)


func _on_leave_to_menu() -> void:
	if _state != GameState.PLAYING:
		return
	_awaiting_swallow_clear = false
	set_process(false)
	hud.hide_result_screens()
	exit_to_home.emit({})


func _unhandled_input(event: InputEvent) -> void:
	if not _started or _state != GameState.PLAYING:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		hud.settings_opened.emit()
		hud.show_leave_confirm()
