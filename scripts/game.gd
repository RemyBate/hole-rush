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


func _ready() -> void:
	add_to_group("game")
	_play_bounds = Rect2(Vector2.ZERO, GameConstants.PLAY_AREA_SIZE)
	hud.setup(GameConstants.GAME_TIME_SECONDS)
	hud.restart_pressed.connect(_on_restart_pressed)
	hud.victory_continue_pressed.connect(_on_victory_continue_pressed)
	hud.bonus_reward_pressed.connect(_on_bonus_reward_pressed)
	hud.pause_pressed.connect(_on_pause_pressed)
	hud.save_progress_requested.connect(_on_save_progress_requested)
	hud.settings_opened.connect(_on_settings_opened)
	hud.settings_closed.connect(_on_settings_closed)


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

	_time_left -= delta
	hud.update_timer(_time_left)

	if _time_left <= 0.0:
		_time_left = 0.0
		_lose_match()


func _start_match() -> void:
	_state = GameState.PLAYING
	_paused = false
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

	# Fruit catalog levels always use the light-green Fruit Garden field
	# (avoids Fast Food grey checkerboard when save progress is in later themes).
	var bg_theme := theme
	if plan != null and plan.category == ItemCatalog.CATEGORY_FRUITS:
		bg_theme = LevelTheme.Id.FRUIT_GARDEN
	_setup_play_area(bg_theme)
	food_spawner.clear_food()
	currency_spawner.clear_pickups()
	food_spawner.spawn_level(_play_bounds, theme, _current_level, plan)
	currency_spawner.spawn_level(_play_bounds, _current_level, food_spawner)

	var center := _play_bounds.position + _play_bounds.size * 0.5
	hole.setup(center, _play_bounds)

	if food_spawner.food_collected.is_connected(_on_food_collected):
		food_spawner.food_collected.disconnect(_on_food_collected)
	food_spawner.food_collected.connect(_on_food_collected)
	if currency_spawner.pickup_collected.is_connected(_on_currency_collected):
		currency_spawner.pickup_collected.disconnect(_on_currency_collected)
	currency_spawner.pickup_collected.connect(_on_currency_collected)

	camera.make_current()
	camera.position = center
	camera.limit_left = int(_play_bounds.position.x)
	camera.limit_top = int(_play_bounds.position.y)
	camera.limit_right = int(_play_bounds.position.x + _play_bounds.size.x)
	camera.limit_bottom = int(_play_bounds.position.y + _play_bounds.size.y)


func _setup_play_area(theme: int = LevelTheme.Id.FRUIT_GARDEN) -> void:
	if play_area.has_method("setup"):
		play_area.setup(_play_bounds, theme)


func _physics_process(_delta: float) -> void:
	if _started and _state == GameState.PLAYING and not _paused:
		camera.global_position = hole.global_position


func _on_pause_pressed() -> void:
	if _state != GameState.PLAYING:
		return
	_paused = not _paused
	hole.set_paused(_paused)
	hud.set_paused(_paused)


func _on_food_collected(food: Food) -> void:
	if _state != GameState.PLAYING:
		return

	# Choose sound before progress update so completed targets use the normal pop.
	var is_target := _is_unfinished_mission_target(food)
	GameSettings.play_item_collect_sfx(is_target)

	if food.catalog_entry != null:
		GameSettings.mark_fruit_discovered(food.catalog_entry.image_id)
	if is_target:
		GameSettings.register_mission_item_collected()

	_collected += 1
	_score += food.score_value
	hud.update_score(_score)
	_apply_mission_progress(food)

	if _collected % GameConstants.GROWTH_EVERY == 0:
		hole.grow(food.get_growth_contribution())

	if _all_missions_complete():
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
func _apply_mission_progress(food_or_type: Variant) -> void:
	for mission in _missions:
		var m := mission as Mission
		if m == null:
			continue
		if food_or_type is Food:
			if m.matches_food(food_or_type as Food):
				m.add_progress()
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
	hud.show_victory(_pending_victory)


func _lose_match() -> void:
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
