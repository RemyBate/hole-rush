extends "res://scripts/home_modal.gd"

signal level_selected(level: int)

const PAGE_SIZE: int = 20
var _page: int = 0


func _build_content() -> void:
	pass


func open_map() -> void:
	_page = maxi(0, (GameSettings.highest_unlocked_level - 1) / PAGE_SIZE)
	open_modal("MAP")


func refresh_content() -> void:
	clear_box(_content)
	clear_box(_footer)
	var unlocked := GameSettings.highest_unlocked_level
	var current := GameSettings.get_play_level()
	var info := Label.new()
	info.text = "Current: %d   Unlocked: %d / %d" % [current, unlocked, LevelTheme.MAX_LEVEL]
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIStyles.apply_cartoon_label(info, 20, 4)
	_content.add_child(info)

	var max_page := maxi(0, (LevelTheme.MAX_LEVEL - 1) / PAGE_SIZE)
	_page = clampi(_page, 0, max_page)
	var start := _page * PAGE_SIZE + 1
	var end_l := mini(LevelTheme.MAX_LEVEL, start + PAGE_SIZE - 1)

	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	_content.add_child(grid)

	for level in range(start, end_l + 1):
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(130, 72)
		btn.focus_mode = Control.FOCUS_NONE
		var is_locked := level > unlocked
		var is_current := level == current
		var is_done := level < unlocked
		if is_locked:
			btn.text = "🔒 %d" % level
			btn.disabled = false # still clickable for message
			UIStyles.style_action_button(btn, Color(0.28, 0.32, 0.4), Color(0.35, 0.4, 0.48), 22)
		elif is_current:
			btn.text = "▶ %d" % level
			UIStyles.style_primary_button(btn, 24)
		elif is_done:
			btn.text = "✓ %d" % level
			UIStyles.style_action_button(btn, Color(0.18, 0.55, 0.75), Color(0.25, 0.65, 0.88), 22)
		else:
			btn.text = "%d" % level
			UIStyles.style_secondary_button(btn, 22)
		btn.pressed.connect(_on_level_pressed.bind(level, is_locked))
		grid.add_child(btn)

	var nav := HBoxContainer.new()
	nav.alignment = BoxContainer.ALIGNMENT_CENTER
	nav.add_theme_constant_override("separation", 12)
	var prev := Button.new()
	prev.text = "◀ Prev"
	prev.disabled = _page <= 0
	UIStyles.style_gold_button(prev, 22)
	prev.pressed.connect(func():
		GameSettings.play_ui_click()
		_page = maxi(0, _page - 1)
		refresh_content()
	)
	var next := Button.new()
	next.text = "Next ▶"
	next.disabled = _page >= max_page
	UIStyles.style_gold_button(next, 22)
	next.pressed.connect(func():
		GameSettings.play_ui_click()
		_page = mini(max_page, _page + 1)
		refresh_content()
	)
	nav.add_child(prev)
	nav.add_child(next)
	_footer.add_child(nav)


func _on_level_pressed(level: int, locked: bool) -> void:
	GameSettings.play_ui_click()
	if locked:
		set_status("Level %d is locked. Complete earlier levels first." % level)
		return
	set_status("")
	level_selected.emit(level)
	close_modal()
