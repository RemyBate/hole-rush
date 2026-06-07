class_name ShopScreen
extends Control

signal closed

@onready var _dim: ColorRect = %Dim
@onready var _panel: PanelContainer = %Panel
@onready var _close_button: Button = %CloseButton
@onready var _cards: HBoxContainer = %OfferRow


func _ready() -> void:
	hide()
	_apply_theme()
	_close_button.pressed.connect(_on_close_pressed)


func open_shop() -> void:
	show()
	_dim.modulate.a = 0.0
	_panel.scale = Vector2(0.9, 0.9)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_dim, "modulate:a", 1.0, 0.22)
	tween.tween_property(_panel, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK)


func close_shop() -> void:
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_dim, "modulate:a", 0.0, 0.18)
	tween.tween_property(_panel, "scale", Vector2(0.92, 0.92), 0.18)
	tween.chain().tween_callback(_finish_close)


func _finish_close() -> void:
	hide()
	closed.emit()


func _apply_theme() -> void:
	_panel.add_theme_stylebox_override("panel", UIStyles.popup_panel())
	UIStyles.apply_cartoon_label(%TitleLabel, 40, 8)
	UIStyles.apply_cartoon_label(%SubtitleLabel, 22, 5)
	UIStyles.style_gold_button(_close_button, 26)
	for card in _cards.get_children():
		if card is PanelContainer:
			card.add_theme_stylebox_override("panel", UIStyles.shop_card())


func _on_close_pressed() -> void:
	GameSettings.play_ui_click()
	close_shop()
