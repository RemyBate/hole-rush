class_name ConfirmPopup
extends Control

signal confirmed
signal cancelled

@onready var _dim: ColorRect = %Dim
@onready var _panel: PanelContainer = %Panel
@onready var _title_label: Label = %TitleLabel
@onready var _message_label: Label = %MessageLabel
@onready var _cancel_button: Button = %CancelButton
@onready var _confirm_button: Button = %ConfirmButton

var _open: bool = false


func _ready() -> void:
	hide()
	_apply_theme()
	_cancel_button.pressed.connect(_on_cancel)
	_confirm_button.pressed.connect(_on_confirm)


func _apply_theme() -> void:
	_panel.add_theme_stylebox_override("panel", UIStyles.glossy_panel(Color(0.14, 0.38, 0.78, 0.98), 24, 4.0))
	UIStyles.apply_cartoon_label(_title_label, 30, 6)
	UIStyles.apply_cartoon_label(_message_label, 22, 4)
	UIStyles.style_secondary_button(_cancel_button, 24)
	UIStyles.style_primary_button(_confirm_button, 24)


func open_confirm(title: String, message: String, confirm_text: String = "Leave Level", cancel_text: String = "Cancel") -> void:
	_title_label.text = title
	_message_label.text = message
	_confirm_button.text = confirm_text
	_cancel_button.text = cancel_text
	show()
	move_to_front()
	_open = true
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_filter = Control.MOUSE_FILTER_STOP
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_dim, "modulate:a", 1.0, 0.18)
	tween.tween_property(_panel, "scale", Vector2.ONE, 0.22).from(Vector2(0.9, 0.9)).set_trans(Tween.TRANS_BACK)


func close_popup() -> void:
	if not _open:
		return
	_open = false
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_dim, "modulate:a", 0.0, 0.14)
	tween.tween_property(_panel, "scale", Vector2(0.92, 0.92), 0.14)
	tween.chain().tween_callback(func():
		hide()
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	)


func _on_cancel() -> void:
	GameSettings.play_ui_click()
	close_popup()
	cancelled.emit()


func _on_confirm() -> void:
	GameSettings.play_ui_click()
	close_popup()
	confirmed.emit()
