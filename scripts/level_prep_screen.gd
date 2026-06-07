class_name LevelPrepScreen
extends Control

signal play_pressed(level: int, boosters: Array)
signal closed

@onready var _dim: ColorRect = %Dim
@onready var _panel: PanelContainer = %Panel
@onready var _title: Label = %TitleLabel
@onready var _objectives_box: VBoxContainer = %ObjectivesBox
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
	_level = clampi(level, 1, LevelTheme.MAX_LEVEL)
	_selected.clear()
	_title.text = "Level %d" % _level
	_refresh_objectives()
	_refresh_booster_ui()
	show()
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
	closed.emit()


func _refresh_objectives() -> void:
	for child in _objectives_box.get_children():
		child.queue_free()
	for line in GameSettings.level_objective_lines(_level):
		var label := Label.new()
		label.text = "• " + line
		UIStyles.apply_cartoon_label(label, 24, 5)
		label.add_theme_color_override("font_color", Color(0.2, 0.28, 0.42))
		label.add_theme_color_override("font_outline_color", Color(1, 1, 1, 0.35))
		_objectives_box.add_child(label)


func _build_booster_buttons() -> void:
	for child in _booster_row.get_children():
		child.queue_free()
	_booster_buttons.clear()
	for id in BoosterData.IDS:
		var col := VBoxContainer.new()
		col.alignment = BoxContainer.ALIGNMENT_CENTER
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(120, 120)
		btn.toggle_mode = true
		btn.focus_mode = Control.FOCUS_NONE
		btn.pressed.connect(_on_booster_toggled.bind(id))
		UIStyles.style_action_button(btn, Color(0.2, 0.55, 0.92), Color(0.3, 0.65, 1.0), 40)
		var count_lbl := Label.new()
		count_lbl.name = "Count"
		count_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		UIStyles.apply_cartoon_label(count_lbl, 22, 4)
		col.add_child(btn)
		col.add_child(count_lbl)
		_booster_row.add_child(col)
		_booster_buttons[id] = btn


func _refresh_booster_ui() -> void:
	for id in _booster_buttons:
		var btn: Button = _booster_buttons[id]
		var count := GameSettings.get_booster_count(id)
		btn.text = BoosterData.ICONS.get(id, "?")
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
		return
	var boosters: Array = []
	for id in _selected:
		if GameSettings.get_booster_count(id) > 0:
			boosters.append(id)
	GameSettings.consume_boosters(boosters)
	play_pressed.emit(_level, boosters)
	close_panel()


func _on_close_pressed() -> void:
	GameSettings.play_ui_click()
	close_panel()


func _apply_theme() -> void:
	_panel.add_theme_stylebox_override("panel", UIStyles.glossy_panel(Color(0.14, 0.38, 0.78, 0.98), 28, 5.0))
	UIStyles.apply_cartoon_label(_title, 40, 7)
	UIStyles.style_primary_button(_play_button, 36)
	UIStyles.style_action_button(_close_button, UIStyles.COLOR_DANGER, Color(1.0, 0.45, 0.5), 28)
