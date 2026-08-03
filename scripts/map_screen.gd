class_name MapScreen
extends Control

signal closed
signal level_selected(level: int)

const MILESTONE_EVERY := 5
const NODE_HEIGHT := 78.0

@onready var _bg: ColorRect = %Bg
@onready var _header: PanelContainer = %Header
@onready var _level_pill: PanelContainer = %LevelPill
@onready var _level_info: Label = %LevelInfo
@onready var _title: Label = %TitleLabel
@onready var _close_button: Button = %CloseButton
@onready var _status: Label = %StatusLabel
@onready var _scroll: ScrollContainer = %Scroll
@onready var _path_stack: VBoxContainer = %PathStack

var _built: bool = false
var _current_node: Control = null
var _pulse_tween: Tween = null
var _level_nodes: Dictionary = {} # level -> Control


func _ready() -> void:
	hide()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_theme()
	_close_button.pressed.connect(_on_close_pressed)
	if not GameSettings.profile_changed.is_connected(_on_profile_changed):
		GameSettings.profile_changed.connect(_on_profile_changed)


func open_map() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_bg.mouse_filter = Control.MOUSE_FILTER_STOP
	_status.text = ""
	_refresh_header()
	_rebuild_path()
	_built = true
	show()
	move_to_front()
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.18)
	await get_tree().process_frame
	await get_tree().process_frame
	_scroll_to_current(true)
	_start_current_pulse()


## Compatibility with home_screen close helpers.
func close_modal() -> void:
	close_map()


func close_map() -> void:
	if not visible:
		return
	_stop_current_pulse()
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.14)
	tween.tween_callback(_finish_close)


func _finish_close() -> void:
	hide()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	modulate.a = 1.0
	closed.emit()


func _apply_theme() -> void:
	var header_style := UIStyles.glossy_panel(
		Color(0.1, 0.34, 0.72, 1.0), 0, 0.0, Color(0.95, 0.78, 0.22, 1.0)
	)
	header_style.corner_radius_bottom_left = 20
	header_style.corner_radius_bottom_right = 20
	header_style.set_border_width_all(0)
	header_style.border_width_bottom = 5
	header_style.border_color = Color(0.95, 0.78, 0.22, 1.0)
	header_style.shadow_size = 12
	header_style.shadow_offset = Vector2(0, 5)
	_header.add_theme_stylebox_override("panel", header_style)

	_level_pill.add_theme_stylebox_override("panel", UIStyles.pill_panel(Color(1, 1, 1, 0.96)))
	UIStyles.apply_dark_cartoon_label(_level_info, 16)
	UIStyles.apply_cartoon_label(_title, 36, 7)
	UIStyles.apply_cartoon_label(_status, 15, 4)
	_status.add_theme_color_override("font_color", Color(1.0, 0.95, 0.45))

	var close_style := UIStyles.glossy_button(UIStyles.COLOR_DANGER, 999, Color(1, 1, 1, 0.75))
	_close_button.add_theme_stylebox_override("normal", close_style)
	_close_button.add_theme_stylebox_override("hover", UIStyles.glossy_button(Color(1.0, 0.42, 0.45), 999))
	_close_button.add_theme_stylebox_override("pressed", UIStyles.glossy_button(Color(0.78, 0.22, 0.28), 999))
	_close_button.add_theme_font_size_override("font_size", 28)
	_close_button.add_theme_color_override("font_color", Color.WHITE)
	_close_button.add_theme_constant_override("outline_size", 5)
	UIStyles.bind_button(_close_button)


func _refresh_header() -> void:
	var play_lv := GameSettings.get_play_level()
	var unlocked := GameSettings.highest_unlocked_level
	_level_info.text = "Lv %d" % play_lv
	_title.text = "JOURNEY"
	if _status.text.is_empty():
		_status.text = "Unlocked %d / %d" % [unlocked, LevelTheme.MAX_LEVEL]


func _on_profile_changed() -> void:
	if visible:
		_refresh_header()


func _rebuild_path() -> void:
	_stop_current_pulse()
	_current_node = null
	_level_nodes.clear()
	while _path_stack.get_child_count() > 0:
		var child := _path_stack.get_child(0)
		_path_stack.remove_child(child)
		child.free()

	_path_stack.add_child(_make_scenery_banner())

	var unlocked := GameSettings.highest_unlocked_level
	var current := GameSettings.get_play_level()
	var last_theme := -1

	for level in range(1, LevelTheme.MAX_LEVEL + 1):
		var theme := LevelTheme.theme_for_level(level)
		if theme != last_theme:
			last_theme = theme
			_path_stack.add_child(_make_chapter_card(theme, level, unlocked))

		if level % MILESTONE_EVERY == 0:
			_path_stack.add_child(_make_milestone_card(level, unlocked))

		var row := _make_level_row(level, unlocked, current)
		_path_stack.add_child(row)
		_level_nodes[level] = row
		if level == current:
			_current_node = row

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 24)
	_path_stack.add_child(spacer)


func _make_scenery_banner() -> PanelContainer:
	var panel := PanelContainer.new()
	var style := UIStyles.glossy_panel(Color(0.45, 0.82, 0.95, 0.92), 18, 3.0, Color(1, 1, 1, 0.45))
	style.shadow_size = 6
	panel.add_theme_stylebox_override("panel", style)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 8)
	var label := Label.new()
	label.text = "☁️  Fruit Valley Path  🍉  🌳  ⭐"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIStyles.apply_cartoon_label(label, 18, 4)
	margin.add_child(label)
	panel.add_child(margin)
	return panel


func _make_chapter_card(theme: int, start_level: int, unlocked: int) -> PanelContainer:
	var end_level := mini(LevelTheme.MAX_LEVEL, start_level + 9)
	var locked := start_level > unlocked
	var bg := _theme_color(theme)
	if locked:
		bg = bg.darkened(0.35)
	var panel := PanelContainer.new()
	var style := UIStyles.glossy_panel(bg, 20, 4.0, Color(0.98, 0.82, 0.28, 0.95))
	style.shadow_size = 10
	panel.add_theme_stylebox_override("panel", style)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	var title := Label.new()
	title.text = "%s %s" % [_theme_emoji(theme), LevelTheme.theme_display_name(theme)]
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIStyles.apply_cartoon_label(title, 22, 5)
	var sub := Label.new()
	if locked:
		sub.text = "🔒 Unlocks at Level %d" % start_level
	else:
		sub.text = "Levels %d – %d" % [start_level, end_level]
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIStyles.apply_cartoon_label(sub, 15, 3)
	col.add_child(title)
	col.add_child(sub)
	margin.add_child(col)
	panel.add_child(margin)
	return panel


func _make_milestone_card(level: int, unlocked: int) -> PanelContainer:
	var reached := unlocked > level
	var at_gate := unlocked == level
	var reward := _milestone_reward(level)
	var panel := PanelContainer.new()
	var bg := Color(0.95, 0.72, 0.2, 0.95) if reached or at_gate else Color(0.45, 0.42, 0.55, 0.92)
	var style := UIStyles.glossy_panel(bg, 16, 3.0, Color(1, 1, 1, 0.5))
	panel.add_theme_stylebox_override("panel", style)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 8)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var icon := Label.new()
	icon.text = str(reward.get("icon", "🎁"))
	icon.add_theme_font_size_override("font_size", 28)
	UIStyles.apply_cartoon_label(icon, 28, 4)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var title := Label.new()
	title.text = "Milestone %d · %s" % [level, str(reward.get("title", "Reward"))]
	UIStyles.apply_cartoon_label(title, 16, 3)
	var sub := Label.new()
	if reached:
		sub.text = "Preview reward · auto on clear (coming soon)"
	elif at_gate:
		sub.text = "Clear this level to unlock reward preview"
	else:
		sub.text = "Reach Level %d · preview only" % level
	UIStyles.apply_cartoon_label(sub, 13, 2)
	col.add_child(title)
	col.add_child(sub)
	var badge := Label.new()
	badge.text = "👀"
	badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UIStyles.apply_cartoon_label(badge, 20, 3)
	row.add_child(icon)
	row.add_child(col)
	row.add_child(badge)
	margin.add_child(row)
	panel.add_child(margin)
	return panel


func _make_level_row(level: int, unlocked: int, current: int) -> Control:
	var is_locked := level > unlocked
	var is_current := level == current
	var is_done := level < unlocked
	var side_left := (level % 2) == 1

	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, NODE_HEIGHT)
	row.add_theme_constant_override("separation", 8)
	row.set_meta("level", level)

	var path_col := CenterContainer.new()
	path_col.custom_minimum_size = Vector2(28, 0)
	var path_dot := PanelContainer.new()
	path_dot.custom_minimum_size = Vector2(18, 18)
	var dot_color := Color(0.95, 0.35, 0.45) if is_current else (Color(0.35, 0.85, 0.4) if is_done else (Color(0.55, 0.75, 0.95) if not is_locked else Color(0.35, 0.35, 0.45)))
	var dot_style := UIStyles.glossy_panel(dot_color, 999, 2.0, Color(1, 1, 1, 0.7))
	dot_style.shadow_size = 4
	path_dot.add_theme_stylebox_override("panel", dot_style)
	path_col.add_child(path_dot)

	var card := _make_level_card(level, is_locked, is_current, is_done)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var pin := Label.new()
	pin.text = "🕳️"
	pin.visible = is_current
	pin.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pin.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pin.custom_minimum_size = Vector2(40, 0)
	pin.add_theme_font_size_override("font_size", 26)
	UIStyles.apply_cartoon_label(pin, 26, 3)

	var filler := Control.new()
	filler.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	if side_left:
		row.add_child(card)
		row.add_child(path_col)
		if is_current:
			row.add_child(pin)
		else:
			row.add_child(filler)
	else:
		if is_current:
			row.add_child(pin)
		else:
			row.add_child(filler)
		row.add_child(path_col)
		row.add_child(card)

	if is_current:
		row.set_meta("pulse_target", card)
	return row


func _make_level_card(level: int, is_locked: bool, is_current: bool, is_done: bool) -> Control:
	var theme := LevelTheme.theme_for_level(level)
	var btn := Button.new()
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.custom_minimum_size = Vector2(0, NODE_HEIGHT - 4)
	var bg: Color
	var border: Color
	if is_locked:
		bg = Color(0.28, 0.3, 0.38, 0.95)
		border = Color(0.45, 0.48, 0.55, 0.9)
	elif is_current:
		bg = Color(0.22, 0.72, 0.38, 0.98)
		border = Color(1.0, 0.92, 0.35, 1.0)
	elif is_done:
		bg = Color(0.18, 0.55, 0.82, 0.98)
		border = Color(0.45, 0.95, 0.55, 0.95)
	else:
		bg = _theme_color(theme).lightened(0.08)
		border = Color(0.95, 0.78, 0.28, 0.95)
	var style := UIStyles.glossy_panel(bg, 18, 4.0 if is_current else 3.0, border)
	style.shadow_size = 12 if is_current else 8
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", style)
	btn.clip_text = false

	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 10
	row.offset_top = 8
	row.offset_right = -10
	row.offset_bottom = -8
	row.add_theme_constant_override("separation", 8)

	var left := VBoxContainer.new()
	left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var title := Label.new()
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if is_locked:
		title.text = "🔒 Level %d" % level
	elif is_current:
		title.text = "▶ Level %d" % level
	elif is_done:
		title.text = "✓ Level %d" % level
	else:
		title.text = "Level %d" % level
	UIStyles.apply_cartoon_label(title, 18, 4)
	var sub := Label.new()
	sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sub.text = "%s %s" % [_theme_emoji(theme), LevelTheme.theme_display_name(theme)]
	UIStyles.apply_cartoon_label(sub, 12, 2)
	left.add_child(title)
	left.add_child(sub)

	var reward := Label.new()
	reward.mouse_filter = Control.MOUSE_FILTER_IGNORE
	reward.text = "⭐" if is_done else (_theme_emoji(theme) if not is_locked else "🔒")
	reward.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UIStyles.apply_cartoon_label(reward, 22, 3)

	row.add_child(left)
	row.add_child(reward)
	btn.add_child(row)
	btn.pressed.connect(_on_level_pressed.bind(level, is_locked, btn))
	UIStyles.bind_button(btn)
	return btn


func _milestone_reward(level: int) -> Dictionary:
	match level % 20:
		0:
			return {"icon": "💎", "title": "Gem Chest"}
		5:
			return {"icon": "🪙", "title": "Coin Bundle"}
		10:
			return {"icon": "🧲", "title": "Magnet Boost"}
		15:
			return {"icon": "⚡", "title": "Lightning Boost"}
		_:
			return {"icon": "🎁", "title": "Surprise Chest"}


func _theme_color(theme: int) -> Color:
	match theme:
		LevelTheme.Id.FRUIT_GARDEN:
			return Color(0.28, 0.68, 0.38)
		LevelTheme.Id.VEGETABLE_FARM:
			return Color(0.45, 0.72, 0.28)
		LevelTheme.Id.FAST_FOOD:
			return Color(0.92, 0.55, 0.22)
		LevelTheme.Id.BAKERY:
			return Color(0.85, 0.58, 0.72)
		LevelTheme.Id.TOY_ROOM:
			return Color(0.45, 0.48, 0.92)
		LevelTheme.Id.BEACH_PARTY:
			return Color(0.25, 0.68, 0.88)
		_:
			return Color(0.25, 0.5, 0.8)


func _theme_emoji(theme: int) -> String:
	match theme:
		LevelTheme.Id.FRUIT_GARDEN:
			return "🍉"
		LevelTheme.Id.VEGETABLE_FARM:
			return "🥕"
		LevelTheme.Id.FAST_FOOD:
			return "🍕"
		LevelTheme.Id.BAKERY:
			return "🧁"
		LevelTheme.Id.TOY_ROOM:
			return "🧸"
		LevelTheme.Id.BEACH_PARTY:
			return "🏖️"
		_:
			return "⭐"


func _on_level_pressed(level: int, locked: bool, card: Control) -> void:
	GameSettings.play_ui_click()
	if card:
		var tween := create_tween()
		tween.tween_property(card, "scale", Vector2(0.96, 0.96), 0.06)
		tween.tween_property(card, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK)
	if locked:
		_status.text = "Complete the previous level first."
		GameSettings.play_lose_sfx()
		return
	_status.text = ""
	level_selected.emit(level)
	close_map()


func _scroll_to_current(animated: bool = true) -> void:
	if _current_node == null or _scroll == null:
		return
	await get_tree().process_frame
	await get_tree().process_frame
	var node_global := _current_node.get_global_rect()
	var scroll_global := _scroll.get_global_rect()
	var target_y := node_global.position.y - scroll_global.position.y + float(_scroll.scroll_vertical) - _scroll.size.y * 0.42
	target_y = maxf(0.0, target_y)
	var max_scroll := 0.0
	var bar := _scroll.get_v_scroll_bar()
	if bar:
		max_scroll = bar.max_value
	target_y = minf(target_y, max_scroll)
	if animated:
		var tween := create_tween()
		tween.tween_property(_scroll, "scroll_vertical", int(target_y), 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	else:
		_scroll.scroll_vertical = int(target_y)


func _start_current_pulse() -> void:
	_stop_current_pulse()
	if _current_node == null or not _current_node.has_meta("pulse_target"):
		return
	var target: Control = _current_node.get_meta("pulse_target")
	if target == null:
		return
	target.pivot_offset = target.size * 0.5
	_pulse_tween = create_tween().set_loops()
	_pulse_tween.tween_property(target, "scale", Vector2(1.04, 1.04), 0.55).set_trans(Tween.TRANS_SINE)
	_pulse_tween.tween_property(target, "scale", Vector2.ONE, 0.55).set_trans(Tween.TRANS_SINE)


func _stop_current_pulse() -> void:
	if _pulse_tween and _pulse_tween.is_valid():
		_pulse_tween.kill()
	_pulse_tween = null


func _on_close_pressed() -> void:
	GameSettings.play_ui_click()
	close_map()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		close_map()
		get_viewport().set_input_as_handled()
