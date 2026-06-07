class_name InfoPopup
extends Control

signal closed

@onready var _dim: ColorRect = %Dim
@onready var _panel: PanelContainer = %Panel
@onready var _title_label: Label = %TitleLabel
@onready var _message_label: Label = %MessageLabel
@onready var _ok_button: Button = %OkButton
@onready var _close_button: Button = %CloseButton

var _open: bool = false


func _ready() -> void:
	hide()
	_panel.scale = Vector2(0.88, 0.88)
	_panel.modulate.a = 0.0
	_dim.modulate.a = 0.0
	_ok_button.pressed.connect(_close)
	_close_button.pressed.connect(_close)
	_apply_theme()


func _apply_theme() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.16, 0.38, 0.78, 0.98)
	style.set_corner_radius_all(24)
	style.border_color = Color(1, 1, 1, 0.35)
	style.set_border_width_all(2)
	_panel.add_theme_stylebox_override("panel", style)
	_close_button.add_theme_stylebox_override("normal", StyleBoxFlat.new())
	var close_style := StyleBoxFlat.new()
	close_style.bg_color = Color(0.88, 0.22, 0.28)
	close_style.set_corner_radius_all(999)
	_close_button.add_theme_stylebox_override("normal", close_style)
	_ok_button.add_theme_stylebox_override("normal", StyleBoxFlat.new())
	var ok_style := StyleBoxFlat.new()
	ok_style.bg_color = Color(0.28, 0.55, 0.95)
	ok_style.set_corner_radius_all(16)
	_ok_button.add_theme_stylebox_override("normal", ok_style)
	UIStyles.bind_button(_ok_button)
	UIStyles.bind_button(_close_button)


func open(title: String, message: String) -> void:
	_title_label.text = title
	_message_label.text = message
	show()
	_open = true
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_dim, "modulate:a", 1.0, 0.2)
	tween.tween_property(_panel, "modulate:a", 1.0, 0.22)
	tween.tween_property(_panel, "scale", Vector2.ONE, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _close() -> void:
	if not _open:
		return
	GameSettings.play_ui_click()
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_dim, "modulate:a", 0.0, 0.16)
	tween.tween_property(_panel, "modulate:a", 0.0, 0.16)
	tween.tween_property(_panel, "scale", Vector2(0.9, 0.9), 0.16)
	tween.chain().tween_callback(_finish_close)


func _finish_close() -> void:
	_open = false
	hide()
	closed.emit()
