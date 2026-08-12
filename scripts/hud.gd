extends Control

signal restart_pressed
signal victory_continue_pressed
signal bonus_reward_pressed
signal pause_pressed
signal menu_pressed
signal save_progress_requested
signal settings_opened
signal settings_closed

@onready var header_band: PanelContainer = %HeaderBand
@onready var top_safe: MarginContainer = $HeaderBand/TopSafe
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
@onready var menu_button: Button = %MenuButton

const ConfirmPopupScene: PackedScene = preload("res://scenes/ui/confirm_popup.tscn")
const SettingsPopupScene: PackedScene = preload("res://scenes/ui/settings_popup.tscn")
const VictoryScreenScene: PackedScene = preload("res://scenes/ui/victory_screen.tscn")
const GameOverScreenScene: PackedScene = preload("res://scenes/ui/game_over_screen.tscn")
const _UiIcons := preload("res://scripts/ui_icons.gd")
const MISSION_ICON_SIZE := Vector2(48, 48)
const HEADER_BOTTOM_PAD := 4.0

var _settings_popup: Control = null
var _leave_confirm: Control = null
var _victory_screen: VictoryScreen = null
var _game_over_screen: GameOverScreen = null
var _max_time: float = GameConstants.GAME_TIME_SECONDS
var _is_paused: bool = false
var _mission_cards: Array[PanelContainer] = []
var _mission_icons: Array[Label] = []
var _mission_icon_textures: Array[TextureRect] = []
var _mission_titles: Array[Label] = []
var _mission_progress: Array[Label] = []
var _header_height: float = 280.0


func _ready() -> void:
	result_panel.hide()
	pause_overlay.hide()
	_cache_mission_widgets()
	_apply_android_icons()
	_apply_safe_area()
	_apply_ui_theme()
	_setup_result_screens()
	_setup_settings_popup()
	_setup_leave_confirm()
	pause_button.pressed.connect(_on_pause_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	if menu_button:
		menu_button.pressed.connect(_on_menu_pressed)
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	call_deferred("_refresh_header_layout")


func _on_viewport_size_changed() -> void:
	_apply_safe_area()
	call_deferred("_refresh_header_layout")


func _cache_mission_widgets() -> void:
	_mission_cards = [mission_card_1, mission_card_2, mission_card_3]
	for card in _mission_cards:
		var vbox := card.get_node("Margin/VBox") as VBoxContainer
		var icon_label := vbox.get_node("Icon") as Label
		_mission_icons.append(icon_label)
		var tex := vbox.get_node_or_null("IconTexture") as TextureRect
		if tex == null:
			tex = TextureRect.new()
			tex.name = "IconTexture"
			tex.custom_minimum_size = MISSION_ICON_SIZE
			tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tex.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			tex.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
			tex.modulate = Color.WHITE
			tex.self_modulate = Color.WHITE
			tex.hide()
			vbox.add_child(tex)
			vbox.move_child(tex, 0)
		else:
			tex.custom_minimum_size = MISSION_ICON_SIZE
		_mission_icon_textures.append(tex)
		_mission_titles.append(vbox.get_node("Title") as Label)
		_mission_progress.append(vbox.get_node("Progress") as Label)


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
	_UiIcons.mount_button_icon(
		pause_button,
		_UiIcons.Id.PLAY if paused else _UiIcons.Id.PAUSE,
		40,
		""
	)


func set_gameplay_hud_visible(visible: bool) -> void:
	if header_band:
		header_band.visible = visible
	elif top_safe:
		top_safe.visible = visible
	if hint_label:
		hint_label.visible = visible


func get_header_height() -> float:
	return _header_height


func get_header_rect() -> Rect2:
	if header_band != null and header_band.visible:
		return header_band.get_global_rect()
	return Rect2(Vector2.ZERO, Vector2(get_viewport().get_visible_rect().size.x, _header_height))


func get_header_bottom() -> float:
	return get_header_rect().end.y


func get_playable_screen_rect() -> Rect2:
	var vr := get_viewport().get_visible_rect()
	var safe := DisplayServer.get_display_safe_area()
	var top := get_header_bottom()
	var left := float(maxi(int(vr.position.x), safe.position.x))
	var right := float(mini(int(vr.end.x), safe.end.x)) if safe.size.x > 0 else vr.end.x
	var bottom := float(mini(int(vr.end.y), safe.end.y)) if safe.size.y > 0 else vr.end.y
	if right <= left:
		left = vr.position.x
		right = vr.end.x
	if bottom <= top:
		bottom = vr.end.y
	return Rect2(Vector2(left, top), Vector2(right - left, bottom - top))


func _refresh_header_layout() -> void:
	if header_band == null or top_safe == null:
		return
	# Prefer minimum size so the band stays compact (size.y can be inflated by anchors).
	var content_h := top_safe.get_combined_minimum_size().y
	if content_h < 160.0:
		# Fallback estimate from known compact children.
		content_h = 56.0 + 4.0 + 40.0 + 6.0 + 78.0 + 6.0 + 52.0
		content_h += float(top_safe.get_theme_constant("margin_top") + top_safe.get_theme_constant("margin_bottom"))
	_header_height = content_h + HEADER_BOTTOM_PAD
	header_band.offset_top = 0.0
	header_band.offset_bottom = _header_height
	header_band.custom_minimum_size = Vector2(0, _header_height)
	if pause_overlay:
		pause_overlay.offset_top = _header_height


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
	for i in _mission_cards.size():
		if i >= missions.size():
			_mission_cards[i].visible = false
			continue
		var mission := missions[i] as Mission
		if mission == null:
			_mission_cards[i].visible = false
			continue
		_mission_cards[i].visible = true
		# Always prefer exact PNG + counter; never show collectible names.
		_mission_titles[i].hide()
		_mission_titles[i].text = ""
		if mission.icon_texture != null:
			_mission_icons[i].hide()
			_mission_icon_textures[i].show()
			_mission_icon_textures[i].texture = mission.icon_texture
			_mission_icon_textures[i].expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			_mission_icon_textures[i].stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			_mission_icon_textures[i].modulate = Color.WHITE
			_mission_icon_textures[i].self_modulate = Color.WHITE
			_mission_icon_textures[i].texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
			_mission_icon_textures[i].custom_minimum_size = MISSION_ICON_SIZE
			_mission_icon_textures[i].size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		else:
			_mission_icon_textures[i].hide()
			_mission_icon_textures[i].texture = null
			_mission_icons[i].show()
			_mission_icons[i].text = str(mission.icon)
		_mission_progress[i].text = "%d/%d" % [mission.progress, mission.target]

		var style := _mission_cards[i].get_theme_stylebox("panel") as StyleBoxFlat
		if style:
			# Duplicate so completion colour is not shared across cards.
			var owned := style.duplicate() as StyleBoxFlat
			if mission.is_complete():
				owned.bg_color = Color(0.28, 0.62, 0.42, 0.95)
			else:
				owned.bg_color = Color(0.22, 0.48, 0.88, 0.95)
			_mission_cards[i].add_theme_stylebox_override("panel", owned)
	call_deferred("_refresh_header_layout")


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


func _apply_android_icons() -> void:
	_UiIcons.mount_button_icon(settings_button, _UiIcons.Id.GEAR, 40, "")
	_UiIcons.mount_button_icon(pause_button, _UiIcons.Id.PAUSE, 40, "")
	var coin_icon := find_child("CoinHudIcon", true, false) as Label
	if coin_icon:
		_UiIcons.replace_label_with_icon(coin_icon, _UiIcons.Id.COIN, 32)
	var score_icon := find_child("ScoreIcon", true, false) as Label
	if score_icon:
		_UiIcons.replace_label_with_icon(score_icon, _UiIcons.Id.STAR, 32)


func _apply_safe_area() -> void:
	if top_safe == null:
		return
	var extra_top := 0
	var extra_left := 0
	var extra_right := 0
	var safe := DisplayServer.get_display_safe_area()
	var win := get_window()
	if win != null:
		# Convert display-space safe rect into this window's local coordinates.
		var win_pos := win.position
		var win_size := win.size
		extra_top = maxi(0, safe.position.y - win_pos.y)
		extra_left = maxi(0, safe.position.x - win_pos.x)
		extra_right = maxi(0, (win_pos.x + win_size.x) - safe.end.x)
	else:
		extra_top = maxi(0, safe.position.y)
		extra_left = maxi(0, safe.position.x)
		extra_right = maxi(0, int(get_viewport().get_visible_rect().size.x) - safe.end.x)
	# Keep mobile notch insets; clamp desktop false-positives that inflate the HUD.
	extra_top = clampi(extra_top, 0, 80)
	extra_left = clampi(extra_left, 0, 40)
	extra_right = clampi(extra_right, 0, 40)
	top_safe.add_theme_constant_override("margin_top", 10 + extra_top)
	top_safe.add_theme_constant_override("margin_left", 12 + extra_left)
	top_safe.add_theme_constant_override("margin_right", 12 + extra_right)
	top_safe.add_theme_constant_override("margin_bottom", 8)


func _apply_ui_theme() -> void:
	if header_band:
		var band := StyleBoxFlat.new()
		band.bg_color = Color(0.07, 0.16, 0.34, 0.98)
		band.set_corner_radius_all(0)
		band.border_color = Color(1.0, 1.0, 1.0, 0.18)
		band.border_width_bottom = 2
		band.shadow_color = Color(0.02, 0.05, 0.12, 0.45)
		band.shadow_size = 8
		band.shadow_offset = Vector2(0, 3)
		header_band.add_theme_stylebox_override("panel", band)
	score_panel.add_theme_stylebox_override("panel", UIStyles.glossy_panel(UIStyles.COLOR_PRIMARY, 16, 2.5))
	if coin_panel:
		coin_panel.add_theme_stylebox_override("panel", UIStyles.glossy_panel(Color(0.42, 0.34, 0.1, 0.96), 16, 2.5))
	for card in _mission_cards:
		card.add_theme_stylebox_override("panel", UIStyles.glossy_panel(UIStyles.COLOR_PRIMARY_DARK, 14, 2.5))

	timer_bar.add_theme_stylebox_override("background", UIStyles.progress_track_style())
	timer_bar.add_theme_stylebox_override("fill", UIStyles.progress_fill_style())

	UIStyles.style_secondary_button(pause_button, 20)
	UIStyles.style_secondary_button(menu_button, 18)
	UIStyles.style_gold_button(settings_button, 20)
	UIStyles.apply_cartoon_label(score_label, 28, 5)
	UIStyles.apply_cartoon_label(coin_label, 28, 5)
	coin_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.35))
	if timer_label:
		UIStyles.apply_cartoon_label(timer_label, 28, 5)


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


func show_leave_confirm() -> void:
	if _leave_confirm and _leave_confirm.has_method("open_confirm"):
		_leave_confirm.call(
			"open_confirm",
			"Leave Level?",
			"Leave this level and return to the main menu?",
			"Leave Level",
			"Cancel"
		)


func _setup_leave_confirm() -> void:
	var popup := ConfirmPopupScene.instantiate() as Control
	if popup == null:
		push_error("HUD: failed to instantiate leave confirm popup.")
		return
	add_child(popup)
	popup.z_index = 95
	_leave_confirm = popup
	if popup.has_signal("confirmed"):
		popup.confirmed.connect(func(): menu_pressed.emit())
	if popup.has_signal("cancelled"):
		popup.cancelled.connect(func(): settings_closed.emit())


func _on_menu_pressed() -> void:
	GameSettings.play_ui_click()
	settings_opened.emit()
	show_leave_confirm()


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
