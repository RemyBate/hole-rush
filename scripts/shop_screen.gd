class_name ShopScreen
extends Control

signal closed

const CONFIRM_COIN_COST := 500
const CONFIRM_GEM_COST := 40

@onready var _bg: ColorRect = %Bg
@onready var _header: PanelContainer = %Header
@onready var _coin_pill: PanelContainer = %CoinPill
@onready var _gem_pill: PanelContainer = %GemPill
@onready var _coin_label: Label = %CoinLabel
@onready var _gem_label: Label = %GemLabel
@onready var _title: Label = %TitleLabel
@onready var _close_button: Button = %CloseButton
@onready var _status: Label = %StatusLabel
@onready var _scroll: ScrollContainer = %Scroll
@onready var _offer_list: VBoxContainer = %OfferList
@onready var _confirm_dim: ColorRect = %ConfirmDim
@onready var _confirm_panel: PanelContainer = %ConfirmPanel
@onready var _confirm_title: Label = %ConfirmTitle
@onready var _confirm_body: Label = %ConfirmBody
@onready var _confirm_cancel: Button = %ConfirmCancel
@onready var _confirm_buy: Button = %ConfirmBuy

var _built: bool = false
var _busy: bool = false
var _pending_offer: Dictionary = {}
var _idle_tweens: Array[Tween] = []


func _ready() -> void:
	hide()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_theme()
	_close_button.pressed.connect(_on_close_pressed)
	_confirm_cancel.pressed.connect(_hide_confirm)
	_confirm_buy.pressed.connect(_on_confirm_buy)
	if not GameSettings.profile_changed.is_connected(_refresh_balances):
		GameSettings.profile_changed.connect(_refresh_balances)
	_refresh_balances()


func open_shop() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_bg.mouse_filter = Control.MOUSE_FILTER_STOP
	_hide_confirm()
	_status.text = ""
	_refresh_balances()
	if not _built:
		_rebuild_offers()
		_built = true
	else:
		_refresh_offer_buttons()
	show()
	move_to_front()
	_scroll.scroll_vertical = 0
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.18)
	_start_idle_anims()


func close_shop() -> void:
	if not visible:
		return
	_hide_confirm()
	_stop_idle_anims()
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
		Color(0.08, 0.24, 0.58, 1.0), 0, 0.0, Color(0.95, 0.78, 0.22, 1.0)
	)
	header_style.corner_radius_bottom_left = 22
	header_style.corner_radius_bottom_right = 22
	header_style.set_border_width_all(0)
	header_style.border_width_bottom = 5
	header_style.border_color = Color(0.95, 0.78, 0.22, 1.0)
	header_style.shadow_size = 14
	header_style.shadow_offset = Vector2(0, 6)
	_header.add_theme_stylebox_override("panel", header_style)

	_coin_pill.add_theme_stylebox_override("panel", UIStyles.pill_panel(Color(1, 1, 1, 0.96)))
	_gem_pill.add_theme_stylebox_override("panel", UIStyles.pill_panel(Color(0.93, 0.97, 1.0, 0.96)))
	UIStyles.apply_dark_cartoon_label(_coin_label, 20)
	UIStyles.apply_dark_cartoon_label(_gem_label, 18)
	UIStyles.apply_cartoon_label(_title, 40, 8)
	UIStyles.apply_cartoon_label(_status, 16, 4)
	_status.add_theme_color_override("font_color", Color(1.0, 0.92, 0.45))

	var close_style := UIStyles.glossy_button(UIStyles.COLOR_DANGER, 999, Color(1, 1, 1, 0.75))
	close_style.shadow_size = 10
	_close_button.add_theme_stylebox_override("normal", close_style)
	_close_button.add_theme_stylebox_override("hover", UIStyles.glossy_button(Color(1.0, 0.42, 0.45), 999))
	_close_button.add_theme_stylebox_override("pressed", UIStyles.glossy_button(Color(0.78, 0.22, 0.28), 999))
	_close_button.add_theme_font_size_override("font_size", 28)
	_close_button.add_theme_color_override("font_color", Color.WHITE)
	_close_button.add_theme_constant_override("outline_size", 5)
	UIStyles.bind_button(_close_button)

	_confirm_panel.add_theme_stylebox_override("panel", UIStyles.popup_panel())
	UIStyles.apply_cartoon_label(_confirm_title, 24, 5)
	UIStyles.apply_cartoon_label(_confirm_body, 17, 4)
	UIStyles.style_secondary_button(_confirm_cancel, 20)
	UIStyles.style_primary_button(_confirm_buy, 22)


func _refresh_balances() -> void:
	if _coin_label:
		_coin_label.text = _format_num(GameSettings.total_coins)
	if _gem_label:
		_gem_label.text = _format_num(GameSettings.total_gems)


func _rebuild_offers() -> void:
	_stop_idle_anims()
	while _offer_list.get_child_count() > 0:
		var child := _offer_list.get_child(0)
		_offer_list.remove_child(child)
		child.free()

	_add_section("FEATURED OFFERS", Color(0.9, 0.22, 0.28))
	_add_offer_card({
		"id": "starter_pack",
		"title": "Starter Booster Pack",
		"artwork": "🎁 🧲 ⏳ ⚡ 🪙×2",
		"contents": "2 Magnet · 2 Freeze · 2 Lightning · 2 Double Coins",
		"badge": "Best Value",
		"price": 1200,
		"currency": "coins",
		"confirm": true,
		"accent": Color(0.72, 0.18, 0.28),
		"footer": Color(0.92, 0.72, 0.2),
		"featured": true,
	})

	_add_section("BOOSTER BUNDLES", Color(0.18, 0.48, 0.92))
	_add_offer_card({
		"id": "magnet_pack",
		"title": "Magnet Pack",
		"artwork": "🧲 ×3",
		"contents": "3 Magnet boosters",
		"badge": "Popular",
		"price": 250,
		"currency": "coins",
		"accent": Color(0.2, 0.42, 0.78),
		"footer": Color(0.95, 0.78, 0.25),
	})
	_add_offer_card({
		"id": "freeze_pack",
		"title": "Freeze Pack",
		"artwork": "⏳ ×3",
		"contents": "3 Freeze boosters",
		"price": 220,
		"currency": "coins",
		"accent": Color(0.18, 0.55, 0.78),
		"footer": Color(0.95, 0.78, 0.25),
	})
	_add_offer_card({
		"id": "lightning_pack",
		"title": "Lightning Pack",
		"artwork": "⚡ ×3",
		"contents": "3 Lightning boosters",
		"price": 220,
		"currency": "coins",
		"accent": Color(0.55, 0.38, 0.12),
		"footer": Color(0.95, 0.78, 0.25),
	})
	_add_offer_card({
		"id": "double_pack",
		"title": "Double Coins Pack",
		"artwork": "🪙×2 ×3",
		"contents": "3 Double Coin boosters",
		"price": 300,
		"currency": "coins",
		"accent": Color(0.62, 0.42, 0.12),
		"footer": Color(0.95, 0.78, 0.25),
	})

	_add_section("COIN PACKS", Color(0.95, 0.62, 0.12))
	_add_offer_card({
		"id": "coins_500",
		"title": "Coin Pack",
		"artwork": "🪙 500",
		"contents": "+500 coins",
		"price": 40,
		"currency": "gems",
		"accent": Color(0.78, 0.52, 0.08),
		"footer": Color(0.22, 0.48, 0.82),
	})
	_add_offer_card({
		"id": "coins_2000",
		"title": "Large Coin Pack",
		"artwork": "💰 2,000",
		"contents": "+2,000 coins",
		"badge": "Popular",
		"price": 140,
		"currency": "gems",
		"confirm": true,
		"accent": Color(0.85, 0.58, 0.1),
		"footer": Color(0.18, 0.42, 0.78),
		"featured": true,
	})

	_add_section("GEM PACKS", Color(0.45, 0.32, 0.82))
	_add_coming_soon_card("Gem Top-Up", "💎💎💎", "Real-money gem packs coming soon")

	_add_section("LIVES", Color(0.88, 0.28, 0.42))
	_add_offer_card({
		"id": "lives_3",
		"title": "Lives Pack",
		"artwork": "❤️ ×3",
		"contents": "+3 lives (up to max %d)" % GameSettings.MAX_LIVES,
		"price": 250,
		"currency": "coins",
		"accent": Color(0.78, 0.22, 0.38),
		"footer": Color(0.95, 0.78, 0.25),
	})

	_add_section("SPECIAL DEALS", Color(0.55, 0.22, 0.68))
	_add_coming_soon_card("Mega Hole Bundle", "🕳️ ⭐ 🔑", "Special real-money deals coming soon")

	_add_section("DAILY OFFER", Color(0.18, 0.72, 0.48))
	_add_offer_card(_daily_offer_def())

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 18)
	_offer_list.add_child(spacer)
	_start_idle_anims()


func _daily_offer_def() -> Dictionary:
	var ymd := GameSettings.today_ymd()
	var seed := hash(ymd)
	var variants: Array[Dictionary] = [
		{
			"id": "daily_magnet",
			"title": "Daily Magnet Deal",
			"artwork": "🧲 ×2",
			"contents": "2 Magnet boosters · refreshes tomorrow",
			"price": 80,
			"currency": "coins",
		},
		{
			"id": "daily_freeze",
			"title": "Daily Freeze Deal",
			"artwork": "⏳ ×2",
			"contents": "2 Freeze boosters · refreshes tomorrow",
			"price": 70,
			"currency": "coins",
		},
		{
			"id": "daily_coins",
			"title": "Daily Coin Splash",
			"artwork": "🪙 150",
			"contents": "+150 coins · refreshes tomorrow",
			"price": 8,
			"currency": "gems",
		},
		{
			"id": "daily_life",
			"title": "Daily Life Boost",
			"artwork": "❤️ +1",
			"contents": "+1 life · refreshes tomorrow",
			"price": 40,
			"currency": "coins",
		},
	]
	var offer: Dictionary = variants[abs(seed) % variants.size()].duplicate()
	offer["badge"] = "Daily"
	offer["accent"] = Color(0.12, 0.58, 0.48)
	offer["footer"] = Color(0.95, 0.78, 0.25)
	offer["featured"] = true
	offer["daily"] = true
	offer["timer"] = "Resets 00:00"
	return offer


func _add_section(title: String, color: Color) -> void:
	var banner := PanelContainer.new()
	var style := UIStyles.glossy_panel(color, 16, 4.0, Color(0.98, 0.82, 0.28, 0.95))
	style.shadow_size = 8
	banner.add_theme_stylebox_override("panel", style)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 8)
	var label := Label.new()
	label.text = title
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIStyles.apply_cartoon_label(label, 20, 5)
	margin.add_child(label)
	banner.add_child(margin)
	_offer_list.add_child(banner)


func _add_coming_soon_card(title: String, artwork: String, body: String) -> void:
	var card := _make_card_shell(Color(0.28, 0.28, 0.42), Color(0.45, 0.45, 0.58), false)
	var art := card.get_meta("art_label") as Label
	var title_l := card.get_meta("title_label") as Label
	var contents_l := card.get_meta("contents_label") as Label
	var buy := card.get_meta("buy_button") as Button
	art.text = artwork
	title_l.text = title
	contents_l.text = body
	buy.text = "Coming Soon"
	buy.disabled = true
	buy.modulate = Color(0.75, 0.75, 0.75)
	_offer_list.add_child(card)


func _add_offer_card(offer: Dictionary) -> void:
	var accent: Color = offer.get("accent", Color(0.2, 0.45, 0.85))
	var footer: Color = offer.get("footer", Color(0.95, 0.78, 0.25))
	var featured: bool = bool(offer.get("featured", false))
	var card := _make_card_shell(accent, footer, featured)
	var art := card.get_meta("art_label") as Label
	var title_l := card.get_meta("title_label") as Label
	var contents_l := card.get_meta("contents_label") as Label
	var buy := card.get_meta("buy_button") as Button
	var badge_l := card.get_meta("badge_label") as Label
	var timer_l := card.get_meta("timer_label") as Label

	art.text = str(offer.get("artwork", "⭐"))
	title_l.text = str(offer.get("title", "Offer"))
	contents_l.text = str(offer.get("contents", ""))
	var badge := str(offer.get("badge", ""))
	badge_l.visible = not badge.is_empty()
	badge_l.text = badge
	var timer := str(offer.get("timer", ""))
	timer_l.visible = not timer.is_empty()
	timer_l.text = "⏱ " + timer

	var currency := str(offer.get("currency", "coins"))
	var price := int(offer.get("price", 0))
	var icon := "💎" if currency == "gems" else "🪙"
	buy.text = "%s %s" % [icon, _format_num(price)]
	buy.set_meta("offer", offer)
	buy.pressed.connect(_on_buy_pressed.bind(offer))

	if bool(offer.get("daily", false)) and not GameSettings.can_claim_daily_offer():
		buy.text = "Claimed"
		buy.disabled = true
		buy.modulate = Color(0.75, 0.75, 0.75)

	card.set_meta("offer_id", str(offer.get("id", "")))
	card.set_meta("buy_button", buy)
	if featured:
		art.set_meta("idle_anim", true)
	_offer_list.add_child(card)


func _make_card_shell(top_color: Color, footer_color: Color, featured: bool) -> PanelContainer:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var border := Color(0.98, 0.82, 0.28, 1.0) if featured else Color(0.92, 0.72, 0.22, 0.95)
	var style := UIStyles.glossy_panel(top_color, 22, 5.0 if featured else 4.0, border)
	style.shadow_size = 14 if featured else 10
	style.shadow_offset = Vector2(0, 6)
	card.add_theme_stylebox_override("panel", style)

	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 0)

	var top := MarginContainer.new()
	top.add_theme_constant_override("margin_left", 12)
	top.add_theme_constant_override("margin_top", 12)
	top.add_theme_constant_override("margin_right", 12)
	top.add_theme_constant_override("margin_bottom", 8)
	var top_col := VBoxContainer.new()
	top_col.add_theme_constant_override("separation", 6)

	var badge_row := HBoxContainer.new()
	var badge_l := Label.new()
	badge_l.visible = false
	UIStyles.apply_cartoon_label(badge_l, 14, 4)
	badge_l.add_theme_color_override("font_color", Color(1.0, 0.92, 0.35))
	badge_row.add_child(badge_l)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	badge_row.add_child(spacer)
	top_col.add_child(badge_row)

	var art := Label.new()
	art.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	art.add_theme_font_size_override("font_size", 36 if featured else 32)
	UIStyles.apply_cartoon_label(art, 36 if featured else 32, 5)
	art.custom_minimum_size = Vector2(0, 54)
	top_col.add_child(art)

	var contents_l := Label.new()
	contents_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	contents_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UIStyles.apply_cartoon_label(contents_l, 15, 3)
	top_col.add_child(contents_l)

	var timer_l := Label.new()
	timer_l.visible = false
	timer_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIStyles.apply_cartoon_label(timer_l, 13, 3)
	timer_l.add_theme_color_override("font_color", Color(1.0, 0.95, 0.7))
	top_col.add_child(timer_l)

	top.add_child(top_col)
	outer.add_child(top)

	var footer := PanelContainer.new()
	var foot_style := UIStyles.glossy_panel(footer_color, 0, 0.0)
	foot_style.corner_radius_bottom_left = 18
	foot_style.corner_radius_bottom_right = 18
	foot_style.shadow_size = 0
	footer.add_theme_stylebox_override("panel", foot_style)
	var foot_margin := MarginContainer.new()
	foot_margin.add_theme_constant_override("margin_left", 12)
	foot_margin.add_theme_constant_override("margin_top", 10)
	foot_margin.add_theme_constant_override("margin_right", 12)
	foot_margin.add_theme_constant_override("margin_bottom", 12)
	var foot_row := HBoxContainer.new()
	foot_row.add_theme_constant_override("separation", 10)
	var title_l := Label.new()
	title_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UIStyles.apply_cartoon_label(title_l, 18, 4)
	var buy := Button.new()
	buy.custom_minimum_size = Vector2(128, 52)
	buy.focus_mode = Control.FOCUS_NONE
	UIStyles.style_primary_button(buy, 18)
	foot_row.add_child(title_l)
	foot_row.add_child(buy)
	foot_margin.add_child(foot_row)
	footer.add_child(foot_margin)
	outer.add_child(footer)

	card.add_child(outer)
	card.set_meta("art_label", art)
	card.set_meta("title_label", title_l)
	card.set_meta("contents_label", contents_l)
	card.set_meta("buy_button", buy)
	card.set_meta("badge_label", badge_l)
	card.set_meta("timer_label", timer_l)
	return card


func _refresh_offer_buttons() -> void:
	for child in _offer_list.get_children():
		if not child.has_meta("offer_id"):
			continue
		var buy := child.get_meta("buy_button") as Button
		if buy == null or not buy.has_meta("offer"):
			continue
		var offer: Dictionary = buy.get_meta("offer")
		if bool(offer.get("daily", false)):
			if GameSettings.can_claim_daily_offer():
				var currency := str(offer.get("currency", "coins"))
				var price := int(offer.get("price", 0))
				var icon := "💎" if currency == "gems" else "🪙"
				buy.text = "%s %s" % [icon, _format_num(price)]
				buy.disabled = false
				buy.modulate = Color.WHITE
			else:
				buy.text = "Claimed"
				buy.disabled = true
				buy.modulate = Color(0.75, 0.75, 0.75)


func _on_buy_pressed(offer: Dictionary) -> void:
	if _busy:
		return
	GameSettings.play_ui_click()
	if bool(offer.get("daily", false)) and not GameSettings.can_claim_daily_offer():
		_flash_status("Daily offer already claimed today.")
		GameSettings.play_lose_sfx()
		return
	var needs_confirm := bool(offer.get("confirm", false))
	var price := int(offer.get("price", 0))
	var currency := str(offer.get("currency", "coins"))
	if not needs_confirm:
		if currency == "gems":
			needs_confirm = price >= CONFIRM_GEM_COST
		else:
			needs_confirm = price >= CONFIRM_COIN_COST
	if needs_confirm:
		_show_confirm(offer)
		return
	_execute_purchase(offer)


func _show_confirm(offer: Dictionary) -> void:
	_pending_offer = offer
	var currency := str(offer.get("currency", "coins"))
	var price := int(offer.get("price", 0))
	_confirm_title.text = "Buy %s?" % str(offer.get("title", "Offer"))
	_confirm_body.text = "%s\n\nCost: %s %s" % [
		str(offer.get("contents", "")),
		_format_num(price),
		"gems" if currency == "gems" else "coins",
	]
	_confirm_dim.show()
	_confirm_dim.move_to_front()
	_confirm_panel.scale = Vector2(0.92, 0.92)
	var tween := create_tween()
	tween.tween_property(_confirm_panel, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK)


func _hide_confirm() -> void:
	_pending_offer = {}
	if _confirm_dim:
		_confirm_dim.hide()


func _on_confirm_buy() -> void:
	if _pending_offer.is_empty():
		_hide_confirm()
		return
	GameSettings.play_ui_click()
	var offer := _pending_offer.duplicate()
	_hide_confirm()
	_execute_purchase(offer)


func _execute_purchase(offer: Dictionary) -> void:
	if _busy:
		return
	_busy = true
	var currency := str(offer.get("currency", "coins"))
	var price := int(offer.get("price", 0))
	var product_id := str(offer.get("id", ""))

	if bool(offer.get("daily", false)) and not GameSettings.can_claim_daily_offer():
		_flash_status("Daily offer already claimed today.")
		GameSettings.play_lose_sfx()
		_busy = false
		return

	var paid := false
	if currency == "gems":
		paid = GameSettings.spend_gems(price)
	else:
		paid = GameSettings.spend_coins(price)
	if not paid:
		_flash_status("Not enough %s." % ("gems" if currency == "gems" else "coins"))
		GameSettings.play_lose_sfx()
		_busy = false
		return

	var ok := _grant_reward(product_id)
	if not ok:
		if currency == "gems":
			GameSettings.total_gems += price
		else:
			GameSettings.total_coins += price
		GameSettings.save_profile()
		_flash_status("Could not complete purchase.")
		GameSettings.play_lose_sfx()
		_busy = false
		_refresh_balances()
		return

	if bool(offer.get("daily", false)):
		GameSettings.claim_daily_offer()

	GameSettings.play_coin_collect_sfx()
	GameSettings.vibrate(25)
	_flash_status("Purchased: %s" % str(offer.get("title", "Offer")))
	_refresh_balances()
	_refresh_offer_buttons()
	_busy = false


func _grant_reward(product_id: String) -> bool:
	match product_id:
		"starter_pack":
			GameSettings.add_booster(BoosterData.Id.MAGNET, 2)
			GameSettings.add_booster(BoosterData.Id.FREEZE_TIME, 2)
			GameSettings.add_booster(BoosterData.Id.LIGHTNING, 2)
			GameSettings.add_booster(BoosterData.Id.DOUBLE_COINS, 2)
			return true
		"magnet_pack":
			GameSettings.add_booster(BoosterData.Id.MAGNET, 3)
			return true
		"freeze_pack":
			GameSettings.add_booster(BoosterData.Id.FREEZE_TIME, 3)
			return true
		"lightning_pack":
			GameSettings.add_booster(BoosterData.Id.LIGHTNING, 3)
			return true
		"double_pack":
			GameSettings.add_booster(BoosterData.Id.DOUBLE_COINS, 3)
			return true
		"coins_500":
			GameSettings.add_coins(500)
			return true
		"coins_2000":
			GameSettings.add_coins(2000)
			return true
		"lives_3":
			var gained := GameSettings.add_lives(3)
			if gained <= 0:
				_flash_status("Lives are already full.")
				return false
			return true
		"daily_magnet":
			GameSettings.add_booster(BoosterData.Id.MAGNET, 2)
			return true
		"daily_freeze":
			GameSettings.add_booster(BoosterData.Id.FREEZE_TIME, 2)
			return true
		"daily_coins":
			GameSettings.add_coins(150)
			return true
		"daily_life":
			var life_gained := GameSettings.add_lives(1)
			if life_gained <= 0:
				_flash_status("Lives are already full.")
				return false
			return true
		_:
			return false


func _flash_status(msg: String) -> void:
	_status.text = msg
	_status.modulate = Color(1, 1, 1, 1)
	var tween := create_tween()
	tween.tween_property(_status, "modulate", Color(1, 1, 1, 0.55), 0.35)


func _start_idle_anims() -> void:
	_stop_idle_anims()
	for child in _offer_list.get_children():
		if not child.has_meta("art_label"):
			continue
		var art := child.get_meta("art_label") as Label
		if art == null or not art.has_meta("idle_anim"):
			continue
		art.pivot_offset = art.size * 0.5
		var tween := create_tween().set_loops()
		tween.tween_property(art, "scale", Vector2(1.06, 1.06), 0.7).set_trans(Tween.TRANS_SINE)
		tween.tween_property(art, "scale", Vector2.ONE, 0.7).set_trans(Tween.TRANS_SINE)
		_idle_tweens.append(tween)


func _stop_idle_anims() -> void:
	for tween in _idle_tweens:
		if tween and tween.is_valid():
			tween.kill()
	_idle_tweens.clear()


func _format_num(n: int) -> String:
	var s := str(maxi(0, n))
	var out := ""
	var count := 0
	for i in range(s.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			out = "," + out
		out = s[i] + out
		count += 1
	return out


func _on_close_pressed() -> void:
	GameSettings.play_ui_click()
	close_shop()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		if _confirm_dim and _confirm_dim.visible:
			_hide_confirm()
		else:
			close_shop()
		get_viewport().set_input_as_handled()
