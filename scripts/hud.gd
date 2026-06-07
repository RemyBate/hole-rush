extends Control

signal restart_pressed
signal victory_continue_pressed
signal bonus_reward_pressed
signal pause_pressed
signal save_progress_requested
signal settings_opened
signal settings_closed

@onready var top_safe: MarginContainer = $TopSafe
@onready var hint_label: Label = $HintLabel
@onready var timer_bar: ProgressBar = %TimerBar
@onready var timer_label: Label = %TimerLabel
@onready var score_label: Label = %ScoreLabel
@onready var score_panel: PanelContainer = %ScorePanel
@onready var coin_label: Label = %CoinLabel
@onready var coin_panel: PanelContainer = %CoinPanel
@onready var pause_button: Button = %PauseButton
@onready var pause_overlay: ColorRect = %PauseOverlay
@onready var result_panel: PanelContainer = %ResultPanel
@onready var mission_card_1: PanelContainer = %MissionCard1
@onready var mission_card_2: PanelContainer = %MissionCard2
@onready var mission_card_3: PanelContainer = %MissionCard3
@onready var settings_button: Button = %SettingsButton

const SettingsPopupScene: PackedScene = preload("res://scenes/ui/settings_popup.tscn")
const VictoryScreenScene: PackedScene = preload("res://scenes/ui/victory_screen.tscn")
const GameOverScreenScene: PackedScene = preload("res://scenes/ui/game_over_screen.tscn")

var _settings_popup: Control = null
var _victory_screen: VictoryScreen = null
var _game_over_screen: GameOverScreen = null
var _max_time: float = GameConstants.GAME_TIME_SECONDS
var _is_paused: bool = false
var _mission_cards: Array[PanelContainer] = []
var _mission_icons: Array[Label] = []
var _mission_titles: Array[Label] = []
var _mission_progress: Array[Label] = []


func _ready() -> void:
	result_panel.hide()
	pause_overlay.hide()
	_cache_mission_widgets()
	_apply_ui_theme()
	_setup_result_screens()
	_setup_settings_popup()
	pause_button.pressed.connect(_on_pause_pressed)
	settings_button.pressed.connect(_on_settings_pressed)


func _cache_mission_widgets() -> void:
	_mission_cards = [mission_card_1, mission_card_2, mission_card_3]
	for card in _mission_cards:
		_mission_icons.append(card.get_node("Margin/VBox/Icon") as Label)
		_mission_titles.append(card.get_node("Margin/VBox/Title") as Label)
		_mission_progress.append(card.get_node("Margin/VBox/Progress") as Label)


func _setup_result_screens() -> void:
	_victory_screen = VictoryScreenScene.instantiate() as VictoryScreen
	add_child(_victory_screen)
	_victory_screen.z_index = 50
	_victory_screen.continue_pressed.connect(func(): victory_continue_pressed.emit())
	_victory_screen.bonus_reward_pressed.connect(func(): bonus_reward_pressed.emit())

	_game_over_screen = GameOverScreenScene.instantiate() as GameOverScreen
	add_child(_game_over_screen)
	_game_over_screen.z_index = 50
	_game_over_screen.retry_pressed.connect(_on_game_over_retry)


func setup(max_time: float) -> void:
	_max_time = max_time
	timer_bar.max_value = _max_time
	timer_bar.value = _max_time


func set_paused(paused: bool) -> void:
	_is_paused = paused
	pause_overlay.visible = paused and _victory_screen != null and not _victory_screen.visible
	pause_button.text = "▶" if paused else "❚❚"


func set_gameplay_hud_visible(visible: bool) -> void:
	top_safe.visible = visible
	if hint_label:
		hint_label.visible = visible


func update_timer(seconds_left: float) -> void:
	var total_seconds := maxi(0, int(ceil(seconds_left)))
	var minutes := total_seconds / 60
	var seconds := total_seconds % 60
	timer_label.text = "%02d:%02d" % [minutes, seconds]
	timer_bar.value = seconds_left

	var ratio := seconds_left / _max_time if _max_time > 0.0 else 0.0
	var fill_style := timer_bar.get_theme_stylebox("fill") as StyleBoxFlat
	if fill_style:
		if ratio <= 0.15:
			fill_style.bg_color = Color(0.95, 0.35, 0.38)
		elif ratio <= 0.35:
			fill_style.bg_color = Color(0.98, 0.72, 0.28)
		else:
			fill_style.bg_color = Color(0.35, 0.88, 0.55)

	if seconds_left <= 10.0:
		timer_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.92))
	else:
		timer_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))


func update_missions(missions: Array) -> void:
	for i in mini(missions.size(), _mission_cards.size()):
		var mission := missions[i] as Mission
		if mission == null:
			continue
		var card := _mission_cards[i]
		_mission_icons[i].text = mission.icon
		_mission_titles[i].text = mission.display_name
		_mission_progress[i].text = "%d / %d" % [mission.progress, mission.target]

		var style := card.get_theme_stylebox("panel") as StyleBoxFlat
		if style:
			if mission.is_complete():
				style.bg_color = Color(0.28, 0.62, 0.42, 0.95)
			else:
				style.bg_color = Color(0.22, 0.48, 0.88, 0.95)


func update_score(score: int) -> void:
	score_label.text = "%d" % score


func update_level_coins(coins: int) -> void:
	if coin_label:
		coin_label.text = "%d" % coins
		_bounce_coin_hud()


func _bounce_coin_hud() -> void:
	if coin_panel == null:
		return
	var tween := create_tween()
	tween.tween_property(coin_panel, "scale", Vector2(1.1, 1.1), 0.07).set_trans(Tween.TRANS_BACK)
	tween.tween_property(coin_panel, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_ELASTIC)


func show_victory(data: Dictionary) -> void:
	set_paused(false)
	set_gameplay_hud_visible(false)
	if _victory_screen:
		_victory_screen.show_victory(data)


func get_victory_coin_fly_global_pos() -> Vector2:
	if _victory_screen and _victory_screen.has_method("get_coin_reward_global_center"):
		return _victory_screen.get_coin_reward_global_center()
	return get_viewport().get_visible_rect().get_center()


func show_game_over(score: int, missions_done: int) -> void:
	set_paused(false)
	set_gameplay_hud_visible(false)
	if _game_over_screen:
		_game_over_screen.show_game_over(score, missions_done)


func hide_result_screens() -> void:
	result_panel.hide()
	set_gameplay_hud_visible(true)
	if _victory_screen:
		_victory_screen.hide_victory()
	if _game_over_screen:
		_game_over_screen.hide_game_over()


func show_bonus_reward_message() -> void:
	if _settings_popup:
		_settings_popup.move_to_front()
		_settings_popup.show_info_message(
			"Bonus Reward",
			"Video ads are not connected yet.\n\nPlaceholder: +100 coins would be granted after watching a rewarded ad."
		)


func _on_game_over_retry() -> void:
	restart_pressed.emit()


func _apply_ui_theme() -> void:
	score_panel.add_theme_stylebox_override("panel", UIStyles.glossy_panel(UIStyles.COLOR_PRIMARY, 20, 3.0))
	if coin_panel:
		coin_panel.add_theme_stylebox_override("panel", UIStyles.glossy_panel(Color(0.42, 0.34, 0.1, 0.96), 20, 3.0))
	for card in _mission_cards:
		card.add_theme_stylebox_override("panel", UIStyles.glossy_panel(UIStyles.COLOR_PRIMARY_DARK, 18, 3.0))

	timer_bar.add_theme_stylebox_override("background", UIStyles.progress_track_style())
	timer_bar.add_theme_stylebox_override("fill", UIStyles.progress_fill_style())

	UIStyles.style_secondary_button(pause_button, 22)
	UIStyles.style_gold_button(settings_button, 22)
	UIStyles.apply_cartoon_label(score_label, 34, 6)
	UIStyles.apply_cartoon_label(coin_label, 34, 6)
	coin_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.35))


func _make_panel_style(bg: Color, corner: int = 20) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.corner_radius_top_left = corner
	style.corner_radius_top_right = corner
	style.corner_radius_bottom_left = corner
	style.corner_radius_bottom_right = corner
	style.border_color = Color(1.0, 1.0, 1.0, 0.35)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.shadow_color = Color(0.05, 0.12, 0.25, 0.35)
	style.shadow_size = 6
	style.shadow_offset = Vector2(0, 3)
	return style


func _on_pause_pressed() -> void:
	pause_pressed.emit()


func _setup_settings_popup() -> void:
	var popup := SettingsPopupScene.instantiate()
	if popup == null:
		push_error("HUD: failed to instantiate settings popup scene.")
		return
	add_child(popup)
	popup.z_index = 60
	_settings_popup = popup
	if popup.has_signal("save_progress_requested"):
		popup.save_progress_requested.connect(_on_save_progress_from_settings)
	if popup.has_signal("opened"):
		popup.opened.connect(func(): settings_opened.emit())
	if popup.has_signal("closed"):
		popup.closed.connect(func(): settings_closed.emit())


func _on_settings_pressed() -> void:
	GameSettings.play_ui_click()
	if _settings_popup:
		_settings_popup.open_popup()


func _on_save_progress_from_settings() -> void:
	save_progress_requested.emit()
	if _settings_popup:
		_settings_popup.show_info_message(
			"Progress Saved",
			"Your level and score were saved.\n\nLevel: %d\nBest score: %d\nCoins: %d" % [
				GameSettings.current_level,
				GameSettings.best_score,
				GameSettings.total_coins,
			]
		)
