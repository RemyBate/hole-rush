## Shared dimmed modal shell for home-screen popups (Shop-style).
extends Control

signal closed
signal action_pressed(action_id: String)

@onready var _dim: ColorRect = %Dim
@onready var _panel: PanelContainer = %Panel
@onready var _title: Label = %TitleLabel
@onready var _close_button: Button = %CloseButton
@onready var _content: VBoxContainer = %ContentBox
@onready var _scroll: ScrollContainer = %ContentScroll
@onready var _footer: VBoxContainer = %FooterBox
@onready var _status: Label = %StatusLabel

var _is_open: bool = false


func _ready() -> void:
	hide()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_close_button.pressed.connect(_on_close_pressed)
	_dim.gui_input.connect(_on_dim_gui_input)
	_apply_shell_theme()
	_build_content()


func _apply_shell_theme() -> void:
	_panel.add_theme_stylebox_override("panel", UIStyles.popup_panel())
	UIStyles.apply_cartoon_label(_title, 36, 7)
	UIStyles.style_gold_button(_close_button, 24)
	UIStyles.apply_cartoon_label(_status, 18, 4)
	_status.add_theme_color_override("font_color", Color(1.0, 0.92, 0.55))


func _build_content() -> void:
	pass


func open_modal(title_text: String = "") -> void:
	if title_text != "":
		_title.text = title_text
	_status.text = ""
	refresh_content()
	mouse_filter = Control.MOUSE_FILTER_STOP
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	show()
	move_to_front()
	_is_open = true
	_dim.modulate.a = 0.0
	_panel.scale = Vector2(0.9, 0.9)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_dim, "modulate:a", 1.0, 0.2)
	tween.tween_property(_panel, "scale", Vector2.ONE, 0.24).set_trans(Tween.TRANS_BACK)


func close_modal() -> void:
	if not _is_open:
		return
	_is_open = false
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_dim, "modulate:a", 0.0, 0.16)
	tween.tween_property(_panel, "scale", Vector2(0.92, 0.92), 0.16)
	tween.chain().tween_callback(_finish_close)


func _finish_close() -> void:
	hide()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	closed.emit()


func refresh_content() -> void:
	pass


func set_status(text: String) -> void:
	_status.text = text


func clear_box(box: VBoxContainer) -> void:
	for child in box.get_children():
		child.queue_free()


func _on_close_pressed() -> void:
	GameSettings.play_ui_click()
	close_modal()


func _on_dim_gui_input(event: InputEvent) -> void:
	# Backdrop absorbs clicks; does not close (avoids accidental dismiss).
	if event is InputEventMouseButton and event.pressed:
		accept_event()


func _unhandled_input(event: InputEvent) -> void:
	if not _is_open or not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		close_modal()
		get_viewport().set_input_as_handled()
