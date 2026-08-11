class_name LevelPrepScreen
extends Control

const _BoosterArt := preload("res://scripts/booster_art.gd")

signal play_pressed(level: int, boosters: Array)
signal closed

@onready var _dim: ColorRect = %Dim
@onready var _panel: PanelContainer = %Panel
@onready var _title: Label = %TitleLabel
@onready var _objectives_box: HBoxContainer = %ObjectivesBox
@onready var _booster_row: HBoxContainer = %BoosterRow
@onready var _play_button: Button = %PlayButton
@onready var _close_button: Button = %CloseButton

var _level: int = 1
var _selected: Array[int] = []
var _booster_buttons: Dictionary = {}


func _ready() -> void:
	hide()
	_apply_theme()
	_close_button.pressed.connect(_on_close_pressed)
	_play_button.pressed.connect(_on_play_pressed)
	_build_booster_buttons()


func open_for_level(level: int) -> void:
	_level = GameSettings.resolve_play_level(level)
	_selected.clear()
	_title.text = "Level %d" % _level
	_refresh_objectives()
	_refresh_booster_ui()
	mouse_filter = Control.MOUSE_FILTER_STOP
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_play_button.disabled = false
	_play_button.mouse_filter = Control.MOUSE_FILTER_STOP
	show()
	move_to_front()
	_dim.modulate.a = 0.0
	_panel.scale = Vector2(0.9, 0.9)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_dim, "modulate:a", 1.0, 0.2)
	tween.tween_property(_panel, "scale", Vector2.ONE, 0.24).set_trans(Tween.TRANS_BACK)


func close_panel() -> void:
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_dim, "modulate:a", 0.0, 0.16)
	tween.tween_property(_panel, "scale", Vector2(0.92, 0.92), 0.16)
	tween.chain().tween_callback(_finish_close)


func _finish_close() -> void:
	hide()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	closed.emit()


func _refresh_objectives() -> void:
	for child in _objectives_box.get_children():
		child.queue_free()
	var theme := LevelTheme.theme_for_level(_level)
	var category := MissionFactory.category_for_theme(theme)
	var plan := LevelPlan.for_level(_level, category)
	var missions := MissionFactory.create_missions(theme, _level, plan)
	for mission in missions:
		var m := mission as Mission
		if m == null:
			continue
		var card := PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.add_theme_stylebox_override(
			"panel",
			UIStyles.glossy_panel(Color(0.18, 0.42, 0.82, 0.95), 16, 3.0)
		)
		var margin := MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 10)
		margin.add_theme_constant_override("margin_top", 8)
		margin.add_theme_constant_override("margin_right", 10)
		margin.add_theme_constant_override("margin_bottom", 8)
		card.add_child(margin)

		var col := VBoxContainer.new()
		col.alignment = BoxContainer.ALIGNMENT_CENTER
		col.add_theme_constant_override("separation", 4)
		margin.add_child(col)

		var icon_box := CenterContainer.new()
		icon_box.custom_minimum_size = Vector2(72, 72)
		col.add_child(icon_box)

		var tex := m.icon_texture
		if tex != null:
			var icon := TextureRect.new()
			icon.texture = tex
			icon.custom_minimum_size = Vector2(64, 64)
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
			icon.modulate = Color.WHITE
			icon.self_modulate = Color.WHITE
			icon_box.add_child(icon)
		else:
			var fallback := Label.new()
			fallback.text = str(m.icon) if not str(m.icon).is_empty() else "?"
			fallback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			UIStyles.apply_cartoon_label(fallback, 32, 4)
			icon_box.add_child(fallback)

		var id_label := Label.new()
		var image_id := _image_id_from_mission(m)
		id_label.text = "#%d" % image_id if image_id > 0 else m.display_name
		id_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		UIStyles.apply_cartoon_label(id_label, 18, 3)
		id_label.add_theme_color_override("font_color", Color(0.85, 0.93, 1.0))
		col.add_child(id_label)

		var count_label := Label.new()
		count_label.text = "0/%d" % m.target
		count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		UIStyles.apply_cartoon_label(count_label, 24, 5)
		count_label.add_theme_color_override("font_color", Color(0.2, 0.28, 0.42))
		col.add_child(count_label)

		_objectives_box.add_child(card)


func _image_id_from_mission(mission: Mission) -> int:
	if mission.catalog_key == "":
		return 0
	var parts := mission.catalog_key.split(":")
	if parts.size() != 2:
		return 0
	return int(parts[1])


func _build_booster_buttons() -> void:
	for child in _booster_row.get_children():
		child.queue_free()
	_booster_buttons.clear()
	for id in BoosterData.IDS:
		var col := VBoxContainer.new()
		col.alignment = BoxContainer.ALIGNMENT_CENTER
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.add_theme_constant_override("separation", 4)

		var btn := Button.new()
		btn.custom_minimum_size = Vector2(100, 100)
		btn.toggle_mode = true
		btn.focus_mode = Control.FOCUS_NONE
		btn.text = ""
		btn.pressed.connect(_on_booster_toggled.bind(id))
		UIStyles.style_action_button(btn, Color(0.2, 0.55, 0.92), Color(0.3, 0.65, 1.0), 36)

		var icon := TextureRect.new()
		icon.name = "Icon"
		icon.texture = _BoosterArt.icon(id, 96)
		icon.custom_minimum_size = Vector2(64, 64)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.set_anchors_preset(Control.PRESET_CENTER)
		icon.anchor_left = 0.5
		icon.anchor_top = 0.5
		icon.anchor_right = 0.5
		icon.anchor_bottom = 0.5
		icon.offset_left = -32
		icon.offset_top = -32
		icon.offset_right = 32
		icon.offset_bottom = 32
		btn.add_child(icon)

		var name_lbl := Label.new()
		name_lbl.text = BoosterData.LABELS.get(id, "Booster")
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		UIStyles.apply_cartoon_label(name_lbl, 16, 3)
		name_lbl.add_theme_color_override("font_color", Color(0.88, 0.95, 1.0))

		var count_lbl := Label.new()
		count_lbl.name = "Count"
		count_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		UIStyles.apply_cartoon_label(count_lbl, 20, 4)

		col.add_child(btn)
		col.add_child(name_lbl)
		col.add_child(count_lbl)
		_booster_row.add_child(col)
		_booster_buttons[id] = btn


func _refresh_booster_ui() -> void:
	for id in _booster_buttons:
		var btn: Button = _booster_buttons[id]
		var count := GameSettings.get_booster_count(id)
		btn.disabled = count <= 0
		btn.button_pressed = id in _selected
		var col := btn.get_parent() as VBoxContainer
		if col:
			var count_lbl := col.get_node("Count") as Label
			if count_lbl:
				count_lbl.text = "x%d" % count


func _on_booster_toggled(id: int) -> void:
	GameSettings.play_ui_click()
	if GameSettings.get_booster_count(id) <= 0:
		_refresh_booster_ui()
		return
	if id in _selected:
		_selected.erase(id)
	else:
		while _selected.size() >= BoosterData.MAX_SELECTED:
			_selected.pop_front()
		_selected.append(id)
	_refresh_booster_ui()


func _on_play_pressed() -> void:
	GameSettings.play_ui_click()
	if not GameSettings.can_play():
		push_warning("[PREP] Play blocked — no lives remaining")
		_show_no_lives_feedback()
		return
	var boosters: Array = []
	for id in _selected:
		if GameSettings.get_booster_count(id) > 0:
			boosters.append(id)
	GameSettings.consume_boosters(boosters)
	_level = GameSettings.resolve_play_level(_level)
	print("[PREP] Play pressed level=", _level, " boosters=", boosters)
	play_pressed.emit(_level, boosters)
	close_panel()


func _show_no_lives_feedback() -> void:
	_play_button.text = "No Lives!"
	var tween := create_tween()
	tween.tween_property(_play_button, "modulate", Color(1.0, 0.45, 0.45), 0.08)
	tween.tween_property(_play_button, "modulate", Color.WHITE, 0.2)
	tween.tween_callback(func(): _play_button.text = "Play")


func _on_close_pressed() -> void:
	GameSettings.play_ui_click()
	close_panel()


func _apply_theme() -> void:
	_panel.add_theme_stylebox_override("panel", UIStyles.glossy_panel(Color(0.14, 0.38, 0.78, 0.98), 28, 5.0))
	UIStyles.apply_cartoon_label(_title, 40, 7)
	UIStyles.style_primary_button(_play_button, 36)
	UIStyles.style_action_button(_close_button, UIStyles.COLOR_DANGER, Color(1.0, 0.45, 0.5), 28)
