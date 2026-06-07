class_name GameOverScreen
extends Control

signal retry_pressed

@onready var _dim: ColorRect = %Dim
@onready var _blur: ColorRect = %Blur
@onready var _content: Control = %Content
@onready var _title: Label = %TitleLabel
@onready var _message: Label = %MessageLabel
@onready var _retry_button: Button = %RetryButton

var _open: bool = false


func _ready() -> void:
	hide()
	_content.modulate.a = 0.0
	_dim.modulate.a = 0.0
	_blur.modulate.a = 0.0
	_apply_theme()
	_retry_button.pressed.connect(_on_retry_pressed)


func show_game_over(score: int, missions_done: int) -> void:
	if _open:
		return
	_open = true
	_title.text = "Time's Up!"
	_message.text = "Missions done: %d / 3\nFinal score: %d" % [missions_done, score]
	show()
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_dim, "modulate:a", 1.0, 0.25)
	tween.tween_property(_blur, "modulate:a", 1.0, 0.28)
	tween.tween_property(_content, "modulate:a", 1.0, 0.3)


func hide_game_over() -> void:
	if not _open:
		return
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_dim, "modulate:a", 0.0, 0.18)
	tween.tween_property(_blur, "modulate:a", 0.0, 0.18)
	tween.tween_property(_content, "modulate:a", 0.0, 0.18)
	tween.chain().tween_callback(_finish_hide)


func _finish_hide() -> void:
	_open = false
	hide()


func _apply_theme() -> void:
	var blur_mat := ShaderMaterial.new()
	blur_mat.shader = load("res://shaders/ui_backdrop_blur.gdshader")
	_blur.material = blur_mat

	UIStyles.apply_cartoon_label(_title, 48, 8)
	_title.add_theme_color_override("font_color", Color(1, 0.92, 0.88))
	_title.add_theme_color_override("font_outline_color", Color(0.35, 0.1, 0.12, 0.95))
	UIStyles.apply_cartoon_label(_message, 28, 5)
	UIStyles.style_primary_button(_retry_button, 34)


func _on_retry_pressed() -> void:
	GameSettings.play_ui_click()
	retry_pressed.emit()
