class_name ShopScreen
extends Control

signal closed

@onready var _dim: ColorRect = %Dim
@onready var _panel: PanelContainer = %Panel
@onready var _close_button: Button = %CloseButton
@onready var _cards: HBoxContainer = %OfferRow
@onready var _title: Label = %TitleLabel
@onready var _subtitle: Label = %SubtitleLabel

var _offer_host: VBoxContainer = null
var _status: Label = null


func _ready() -> void:
	hide()
	_apply_theme()
	_close_button.pressed.connect(_on_close_pressed)
	_rebuild_offers()


func open_shop() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_rebuild_offers()
	show()
	move_to_front()
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
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	closed.emit()


func _apply_theme() -> void:
	_panel.add_theme_stylebox_override("panel", UIStyles.popup_panel())
	UIStyles.apply_cartoon_label(_title, 40, 8)
	UIStyles.apply_cartoon_label(_subtitle, 20, 5)
	UIStyles.style_gold_button(_close_button, 26)


func _rebuild_offers() -> void:
	_subtitle.text = "Coins: %d   Gems: %d   Lives: %d/%d" % [
		GameSettings.total_coins, GameSettings.total_gems, GameSettings.lives, GameSettings.MAX_LIVES
	]
	# Replace static row with a scrollable offer list under subtitle.
	if _offer_host == null:
		var parent_vbox := _cards.get_parent() as VBoxContainer
		_cards.hide()
		_status = Label.new()
		_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		UIStyles.apply_cartoon_label(_status, 18, 4)
		_status.add_theme_color_override("font_color", Color(1.0, 0.9, 0.45))
		parent_vbox.add_child(_status)
		parent_vbox.move_child(_status, _cards.get_index() + 1)
		var scroll := ScrollContainer.new()
		scroll.custom_minimum_size = Vector2(0, 480)
		scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		parent_vbox.add_child(scroll)
		parent_vbox.move_child(scroll, _status.get_index() + 1)
		_offer_host = VBoxContainer.new()
		_offer_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_offer_host.add_theme_constant_override("separation", 10)
		scroll.add_child(_offer_host)
	for child in _offer_host.get_children():
		child.queue_free()

	_add_offer("❤️ Extra Life", "Restore 1 life", 100, "coins", "life")
	_add_offer("⚡ Lightning", "Buy 1 Lightning booster", 80, "coins", "booster_0")
	_add_offer("⏳ Freeze", "Buy 1 Freeze booster", 80, "coins", "booster_1")
	_add_offer("🧲 Magnet", "Buy 1 Magnet booster", 100, "coins", "booster_2")
	_add_offer("🪙×2 Double Coins", "Buy 1 Double Coins booster", 120, "coins", "booster_3")
	_add_offer("💰 500 Coins", "Coin pack (costs gems)", 40, "gems", "coins_500")


func _add_offer(title: String, desc: String, price: int, currency: String, product_id: String) -> void:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UIStyles.shop_card())
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var t := Label.new()
	t.text = title
	UIStyles.apply_cartoon_label(t, 22, 4)
	var d := Label.new()
	d.text = desc
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UIStyles.apply_cartoon_label(d, 16, 3)
	col.add_child(t)
	col.add_child(d)
	var buy := Button.new()
	buy.custom_minimum_size = Vector2(140, 56)
	buy.text = "%d %s" % [price, "💎" if currency == "gems" else "🪙"]
	UIStyles.style_primary_button(buy, 20)
	buy.pressed.connect(_on_buy.bind(product_id, price, currency))
	row.add_child(col)
	row.add_child(buy)
	margin.add_child(row)
	card.add_child(margin)
	_offer_host.add_child(card)


func _on_buy(product_id: String, price: int, currency: String) -> void:
	GameSettings.play_ui_click()
	var ok := false
	if currency == "gems":
		ok = GameSettings.spend_gems(price)
	else:
		ok = GameSettings.spend_coins(price)
	if not ok:
		_status.text = "Not enough %s." % ("gems" if currency == "gems" else "coins")
		return
	match product_id:
		"life":
			if not GameSettings.refill_one_life():
				if currency == "gems":
					GameSettings.total_gems += price
				else:
					GameSettings.total_coins += price
				GameSettings.save_profile()
				_status.text = "Lives are already full."
				_rebuild_offers()
				return
			_status.text = "Life restored!"
		"booster_0":
			GameSettings.add_booster(0, 1)
			_status.text = "Lightning booster purchased!"
		"booster_1":
			GameSettings.add_booster(1, 1)
			_status.text = "Freeze booster purchased!"
		"booster_2":
			GameSettings.add_booster(2, 1)
			_status.text = "Magnet booster purchased!"
		"booster_3":
			GameSettings.add_booster(3, 1)
			_status.text = "Double Coins booster purchased!"
		"coins_500":
			GameSettings.total_coins += 500
			GameSettings.save_profile()
			_status.text = "Received 500 coins!"
		_:
			_status.text = "Purchase complete."
	GameSettings.vibrate(25)
	_rebuild_offers()


func _on_close_pressed() -> void:
	GameSettings.play_ui_click()
	close_shop()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		close_shop()
		get_viewport().set_input_as_handled()
