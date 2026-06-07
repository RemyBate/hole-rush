class_name HomeScreen
extends Control

signal play_level(level: int, boosters: Array)

const SettingsPopupScene: PackedScene = preload("res://scenes/ui/settings_popup.tscn")
const ShopScreenScene: PackedScene = preload("res://scenes/ui/shop_screen.tscn")
const GoldCoinIconScript: Script = preload("res://scripts/gold_coin_icon.gd")

const EVENT_LEFT: Array = [
	["🏆", "Tournament", Color(0.92, 0.55, 0.18), 2 * 86400 + 9 * 3600],
	["🗺️", "Treasure Hunt", Color(0.28, 0.62, 0.95), 0],
	["📅", "Daily Event", Color(0.45, 0.82, 0.38), 5 * 3600],
]
const EVENT_RIGHT: Array = [
	["⭐", "Star Event", Color(0.95, 0.35, 0.55), 26 * 86400 + 13 * 3600],
	["🪙", "Coin Frenzy", Color(0.98, 0.78, 0.2), 2 * 86400 + 18 * 3600],
	["🐚", "Special Event", Color(0.55, 0.38, 0.92), 21 * 3600 + 33 * 60],
]

@onready var _top_bar: PanelContainer = %TopBar
@onready var _avatar_button: Button = %AvatarButton
@onready var _coins_frame: PanelContainer = %CoinsFrame
@onready var _coin_icon: Control = %CoinIcon
@onready var _coins_label: Label = %CoinsLabel
@onready var _lives_frame: PanelContainer = %LivesFrame
@onready var _lives_label: Label = %LivesLabel
@onready var _lives_status: Label = %LivesStatus
@onready var _settings_button: Button = %SettingsButton
@onready var _progress_section: PanelContainer = %ProgressSection
@onready var _meta_bar: ProgressBar = %MetaBar
@onready var _meta_label: Label = %MetaLabel
@onready var _progress_timer: Label = %ProgressTimer
@onready var _level_frame: PanelContainer = %LevelFrame
@onready var _level_button: Button = %LevelButton
@onready var _level_prep: LevelPrepScreen = %LevelPrep
@onready var _left_events: VBoxContainer = %LeftEvents
@onready var _right_events: VBoxContainer = %RightEvents
@onready var _bottom_nav: PanelContainer = %BottomNav

var _nav_buttons: Array[Button] = []
var _nav_wraps: Array[PanelContainer] = []
var _settings_popup: Control = null
var _shop_screen: Control = null
var _level_bounce_time: float = 0.0
var _event_timers: Dictionary = {}
var _progress_timer_end: int = 0
var _coin_anim_layer: CanvasLayer = null
var _coin_anim_busy: bool = false


func _ready() -> void:
	_cache_nav()
	_apply_premium_theme()
	_build_event_buttons()
	_level_button.pressed.connect(_on_level_button_pressed)
	_settings_button.pressed.connect(_on_settings_pressed)
	_avatar_button.pressed.connect(_on_avatar_pressed)
	_level_prep.play_pressed.connect(_on_prep_play)
	GameSettings.profile_changed.connect(refresh_ui)
	_setup_settings()
	_setup_shop()
	_progress_timer_end = int(Time.get_unix_time_from_system()) + 6 * 86400 + 11 * 3600
	refresh_ui()
	_start_event_timers()
	_highlight_nav(2)


func _process(delta: float) -> void:
	GameSettings.tick_lives_regen()
	_level_bounce_time += delta
	var bounce := sin(_level_bounce_time * 2.0) * 0.035
	_level_frame.scale = Vector2(1.0 + bounce, 1.0 - bounce * 0.4)
	_update_event_labels()
	_update_progress_timer_label()


func refresh_ui() -> void:
	GameSettings.tick_lives_regen()
	if not _coin_anim_busy:
		_coins_label.text = _format_number(GameSettings.total_coins)
	_lives_label.text = str(GameSettings.lives)
	_lives_status.text = GameSettings.lives_status_text()
	_level_button.text = "LEVEL %d" % GameSettings.highest_unlocked_level
	_meta_bar.value = GameSettings.meta_progress_ratio() * 100.0
	_meta_label.text = GameSettings.meta_progress_text()


func _format_number(value: int) -> String:
	return str(value)


func play_coin_collection_animation(payload: Dictionary) -> void:
	call_deferred("_run_coin_collection_animation", payload)


func _run_coin_collection_animation(payload: Dictionary) -> void:
	var earned: int = int(payload.get("coins_earned", 0))
	if earned <= 0:
		refresh_ui()
		return

	var before: int = int(payload.get("coins_before", GameSettings.total_coins - earned))
	var after: int = before + earned
	var from_global: Vector2 = payload.get("fly_from", get_viewport().get_visible_rect().get_center())

	_coin_anim_busy = true
	_coins_label.text = _format_number(before)
	_pulse_coin_counter(0.45)

	var layer := _ensure_coin_anim_layer()
	var to_global := _coin_counter_global_center()
	var burst_count := clampi(maxi(1, earned / 20), 6, 14)
	var finished := 0

	for i in burst_count:
		var coin := Control.new()
		coin.custom_minimum_size = Vector2(40.0, 40.0)
		coin.size = coin.custom_minimum_size
		coin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var mini_icon: Control = GoldCoinIconScript.new() as Control
		mini_icon.set_anchors_preset(Control.PRESET_FULL_RECT)
		mini_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		coin.add_child(mini_icon)
		layer.add_child(coin)
		var scatter := Vector2(randf_range(-48.0, 48.0), randf_range(-28.0, 28.0))
		coin.global_position = from_global + scatter - coin.size * 0.5
		coin.scale = Vector2(0.35, 0.35)
		coin.modulate.a = 0.0

		var mid := from_global.lerp(to_global, 0.45) + Vector2(randf_range(-60.0, 60.0), -120.0 - float(i) * 8.0)
		var start_pos := coin.global_position
		var end_pos := to_global - coin.size * 0.5
		var path := PackedVector2Array([start_pos, mid, end_pos])
		var fly_duration := 0.62 + float(i) * 0.02
		var fly_delay := float(i) * 0.045

		var fly := create_tween()
		fly.tween_interval(fly_delay)
		fly.tween_property(coin, "modulate:a", 1.0, 0.08)
		var move := fly.parallel()
		move.tween_property(coin, "scale", Vector2(1.05, 1.05), 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		move.tween_method(
			func(t: float) -> void:
				if is_instance_valid(coin):
					coin.global_position = _bezier_point(path, t),
			0.0,
			1.0,
			fly_duration
		).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		move.tween_property(coin, "scale", Vector2(0.22, 0.22), fly_duration)
		move.tween_property(coin, "modulate:a", 0.0, 0.16).set_delay(fly_duration * 0.82)
		fly.tween_callback(func() -> void:
			if is_instance_valid(coin):
				coin.queue_free()
			finished += 1
			if finished >= burst_count:
				_finish_coin_collection(after)
		)

	_animate_coin_counter_steps(before, after, 0.35)


func _finish_coin_collection(final_total: int) -> void:
	_coin_anim_busy = false
	_coins_label.text = _format_number(final_total)
	_pulse_coin_counter(0.0)
	refresh_ui()


func _animate_coin_counter_steps(before: int, after: int, start_delay: float) -> void:
	var steps := after - before
	if steps <= 0:
		_coins_label.text = _format_number(after)
		return
	var total_time := clampf(float(steps) * 0.045, 1.4, 5.5)
	var step_time := total_time / float(steps)
	var tween := create_tween()
	if start_delay > 0.0:
		tween.tween_interval(start_delay)
	for i in range(1, steps + 1):
		var value := before + i
		tween.tween_callback(_apply_coin_step_display.bind(value, after))
		tween.tween_interval(step_time)


func _apply_coin_step_display(value: int, final_total: int) -> void:
	_coins_label.text = _format_number(value)
	if value == final_total:
		_pulse_coin_counter_on_tick()


func _pulse_coin_counter_on_tick() -> void:
	var pop := create_tween()
	pop.tween_property(_coins_label, "scale", Vector2(1.08, 1.08), 0.04).set_trans(Tween.TRANS_BACK)
	pop.tween_property(_coins_label, "scale", Vector2.ONE, 0.08)


func _pulse_coin_counter(delay: float) -> void:
	var tween := create_tween()
	if delay > 0.0:
		tween.tween_interval(delay)
	tween.tween_property(_coins_frame, "scale", Vector2(1.14, 1.14), 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_coins_frame, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(_coin_icon, "scale", Vector2(1.2, 1.2), 0.12).set_trans(Tween.TRANS_BACK)
	tween.tween_property(_coin_icon, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_ELASTIC)


func _coin_counter_global_center() -> Vector2:
	var icon_rect := _coin_icon.get_global_rect()
	var label_rect := _coins_label.get_global_rect()
	return Vector2(
		(icon_rect.position.x + icon_rect.size.x * 0.5),
		(icon_rect.position.y + label_rect.size.y * 0.5)
	)


func _ensure_coin_anim_layer() -> CanvasLayer:
	if _coin_anim_layer == null or not is_instance_valid(_coin_anim_layer):
		_coin_anim_layer = CanvasLayer.new()
		_coin_anim_layer.layer = 90
		add_child(_coin_anim_layer)
	return _coin_anim_layer


func _bezier_point(points: PackedVector2Array, t: float) -> Vector2:
	if points.size() < 2:
		return points[0] if points.size() > 0 else Vector2.ZERO
	if points.size() == 2:
		return points[0].lerp(points[1], t)
	var a := points[0].lerp(points[1], t)
	var b := points[1].lerp(points[2], t)
	return a.lerp(b, t)


func _cache_nav() -> void:
	_nav_buttons = [%NavShop, %NavMap, %NavHome, %NavTrophies, %NavCollection]
	_nav_wraps.clear()
	for btn in _nav_buttons:
		var wrap := btn.get_parent() as PanelContainer
		if wrap:
			_nav_wraps.append(wrap)
	for i in _nav_buttons.size():
		_nav_buttons[i].pressed.connect(_on_nav_pressed.bind(i))


func _build_event_buttons() -> void:
	for child in _left_events.get_children():
		child.queue_free()
	for child in _right_events.get_children():
		child.queue_free()
	_event_timers.clear()
	_fill_events(_left_events, EVENT_LEFT)
	_fill_events(_right_events, EVENT_RIGHT)


func _fill_events(container: VBoxContainer, defs: Array) -> void:
	for def in defs:
		var col := _make_event_widget(str(def[0]), str(def[1]), def[2] as Color, int(def[3]))
		container.add_child(col)


func _make_event_widget(icon: String, title: String, color: Color, timer_offset: int) -> Control:
	var root := VBoxContainer.new()
	root.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_theme_constant_override("separation", 4)

	var btn_panel := PanelContainer.new()
	btn_panel.add_theme_stylebox_override("panel", UIStyles.event_orb(color))

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(96, 96)
	btn.text = icon
	btn.focus_mode = Control.FOCUS_NONE
	btn.flat = true
	btn.add_theme_font_size_override("font_size", 42)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_outline_color", Color(0.06, 0.12, 0.2, 0.9))
	btn.add_theme_constant_override("outline_size", 4)
	UIStyles.bind_button(btn)
	btn_panel.add_child(btn)

	var name_lbl := Label.new()
	name_lbl.text = title
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIStyles.apply_cartoon_label(name_lbl, 15, 4)

	var timer_lbl := Label.new()
	timer_lbl.name = "Timer"
	timer_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIStyles.apply_cartoon_label(timer_lbl, 13, 3)
	timer_lbl.add_theme_color_override("font_color", Color(1.0, 0.95, 0.75))

	root.add_child(btn_panel)
	root.add_child(name_lbl)
	root.add_child(timer_lbl)

	if timer_offset > 0:
		_event_timers[timer_lbl.get_instance_id()] = timer_offset
	else:
		timer_lbl.text = "START"

	return root


func _start_event_timers() -> void:
	var now := int(Time.get_unix_time_from_system())
	for id in _event_timers.keys():
		_event_timers[id] = now + int(_event_timers[id])


func _update_event_labels() -> void:
	var now := int(Time.get_unix_time_from_system())
	for container in [_left_events, _right_events]:
		for col in container.get_children():
			var timer_lbl := _find_timer_label(col)
			if timer_lbl == null:
				continue
			var id := timer_lbl.get_instance_id()
			if not _event_timers.has(id):
				continue
			var remain := maxi(0, int(_event_timers[id]) - now)
			timer_lbl.text = _format_countdown(remain)


func _find_timer_label(node: Node) -> Label:
	if node is Label and node.name == "Timer":
		return node as Label
	for child in node.get_children():
		var found := _find_timer_label(child)
		if found:
			return found
	return null


func _update_progress_timer_label() -> void:
	var remain := maxi(0, _progress_timer_end - int(Time.get_unix_time_from_system()))
	_progress_timer.text = _format_countdown(remain)


func _format_countdown(seconds: int) -> String:
	if seconds >= 86400:
		return "%dd %dh" % [seconds / 86400, (seconds % 86400) / 3600]
	if seconds >= 3600:
		return "%02d:%02d:%02d" % [seconds / 3600, (seconds % 3600) / 60, seconds % 60]
	return "%02d:%02d" % [seconds / 60, seconds % 60]


func _highlight_nav(active_index: int) -> void:
	for i in mini(_nav_wraps.size(), _nav_buttons.size()):
		var wrap: PanelContainer = _nav_wraps[i]
		if wrap:
			wrap.add_theme_stylebox_override("panel", UIStyles.nav_item(i == active_index))
		var btn := _nav_buttons[i]
		if btn:
			btn.modulate = Color.WHITE if i == active_index else Color(0.82, 0.88, 1.0)


func _on_level_button_pressed() -> void:
	GameSettings.play_ui_click()
	GameSettings.vibrate(25)
	_level_prep.open_for_level(GameSettings.highest_unlocked_level)


func _on_prep_play(level: int, boosters: Array) -> void:
	if not GameSettings.can_play():
		return
	play_level.emit(level, boosters)


func _on_settings_pressed() -> void:
	GameSettings.play_ui_click()
	if _settings_popup:
		_settings_popup.open_popup()


func _on_avatar_pressed() -> void:
	GameSettings.play_ui_click()
	if _settings_popup:
		_settings_popup.show_info_message(
			"Profile",
			"Level: %d\nCoins: %d\nGems: %d\nKeys: %d\nLives: %d/%d" % [
				GameSettings.highest_unlocked_level,
				GameSettings.total_coins,
				GameSettings.total_gems,
				GameSettings.total_keys,
				GameSettings.lives,
				GameSettings.MAX_LIVES,
			]
		)


func _on_nav_pressed(index: int) -> void:
	GameSettings.play_ui_click()
	_highlight_nav(index)
	match index:
		0:
			if _shop_screen and _shop_screen.has_method("open_shop"):
				_shop_screen.open_shop()
		2:
			pass
		_:
			if _settings_popup and _settings_popup.has_method("show_info_message"):
				_settings_popup.show_info_message(
					"Coming Soon",
					"This section will be available in a future update."
				)


func _setup_shop() -> void:
	var shop := ShopScreenScene.instantiate()
	if shop == null:
		push_error("HomeScreen: failed to instantiate shop screen.")
		return
	add_child(shop)
	shop.z_index = 75
	_shop_screen = shop


func _setup_settings() -> void:
	var popup := SettingsPopupScene.instantiate()
	if popup == null:
		push_error("HomeScreen: failed to instantiate settings popup scene.")
		return
	add_child(popup)
	popup.z_index = 80
	_settings_popup = popup
	if popup.has_signal("save_progress_requested"):
		popup.save_progress_requested.connect(func(): GameSettings.save_profile())


func _apply_premium_theme() -> void:
	_top_bar.add_theme_stylebox_override("panel", UIStyles.blue_deep_panel())
	_coins_frame.add_theme_stylebox_override("panel", UIStyles.pill_panel(Color(0.98, 0.97, 0.92, 0.98)))
	_lives_frame.add_theme_stylebox_override("panel", UIStyles.pill_panel(Color(0.99, 0.94, 0.96, 0.98)))
	_progress_section.add_theme_stylebox_override("panel", UIStyles.gold_frame_panel(Color(0.14, 0.32, 0.62, 0.92)))
	_meta_bar.add_theme_stylebox_override("background", UIStyles.progress_track_style())
	_meta_bar.add_theme_stylebox_override("fill", UIStyles.progress_fill_style())
	_bottom_nav.add_theme_stylebox_override("panel", UIStyles.glossy_panel(Color(0.08, 0.22, 0.52, 0.98), 24, 4.0))

	_level_frame.add_theme_stylebox_override("panel", UIStyles.level_outer_frame())
	_level_button.add_theme_stylebox_override("normal", UIStyles.level_inner_button())
	_level_button.add_theme_stylebox_override("hover", UIStyles.level_inner_button())
	_level_button.add_theme_stylebox_override("pressed", UIStyles.glossy_button(Color(0.32, 0.72, 0.22), 26))
	UIStyles.apply_cartoon_label(_level_button, 46, 8)
	_level_button.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	_level_button.add_theme_color_override("font_outline_color", Color(0.08, 0.22, 0.12, 0.95))

	_avatar_button.add_theme_stylebox_override("normal", UIStyles.glossy_button(Color(0.06, 0.14, 0.32), 999))
	_avatar_button.add_theme_stylebox_override("hover", UIStyles.glossy_button(Color(0.1, 0.22, 0.48), 999))
	_avatar_button.add_theme_stylebox_override("pressed", UIStyles.glossy_button(Color(0.04, 0.1, 0.24), 999))

	UIStyles.style_gold_button(_settings_button, 38)
	UIStyles.bind_button(_level_button)
	UIStyles.bind_button(_avatar_button)

	UIStyles.apply_cartoon_label(_coins_label, 42, 8)
	_coins_label.add_theme_color_override("font_color", Color.WHITE)
	_coins_label.add_theme_color_override("font_outline_color", Color(0.05, 0.1, 0.22, 0.98))
	UIStyles.apply_cartoon_label(_lives_label, 34, 7)
	UIStyles.apply_cartoon_label(_lives_status, 18, 4)
	_lives_status.add_theme_color_override("font_color", Color(0.35, 0.95, 0.55))
	_lives_status.add_theme_color_override("font_outline_color", Color(0.05, 0.15, 0.1, 0.9))

	UIStyles.apply_cartoon_label(_meta_label, 24, 5)
	UIStyles.apply_cartoon_label(_progress_timer, 20, 4)
	_progress_timer.add_theme_color_override("font_color", Color(1.0, 0.55, 0.45))

	for btn in _nav_buttons:
		btn.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
		btn.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
		btn.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
		UIStyles.apply_cartoon_label(btn, 17, 4)
		UIStyles.bind_button(btn)
