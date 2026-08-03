extends "res://scripts/home_modal.gd"


func open_collection() -> void:
	open_modal("COLLECTION")


func refresh_content() -> void:
	clear_box(_content)
	clear_box(_footer)
	ItemCatalog.ensure_loaded(ItemCatalog.CATEGORY_FRUITS)
	var entries: Array = ItemCatalog.valid_entries(ItemCatalog.CATEGORY_FRUITS)
	var discovered := GameSettings.discovered_fruit_ids
	var header := Label.new()
	header.text = "Discovered %d / %d" % [discovered.size(), entries.size()]
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIStyles.apply_cartoon_label(header, 20, 4)
	_content.add_child(header)

	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	_content.add_child(grid)

	for e in entries:
		var entry := e as ItemEntry
		if entry == null:
			continue
		var known := GameSettings.is_fruit_discovered(entry.image_id)
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(180, 180)
		card.add_theme_stylebox_override("panel", UIStyles.shop_card())
		var margin := MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 8)
		margin.add_theme_constant_override("margin_top", 8)
		margin.add_theme_constant_override("margin_right", 8)
		margin.add_theme_constant_override("margin_bottom", 8)
		var vbox := VBoxContainer.new()
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		if known and entry.texture != null:
			var tex := TextureRect.new()
			tex.texture = entry.hud_texture()
			tex.custom_minimum_size = Vector2(120, 120)
			tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tex.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
			tex.modulate = Color.WHITE
			vbox.add_child(tex)
		else:
			var q := Label.new()
			q.text = "?"
			q.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			q.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			q.custom_minimum_size = Vector2(120, 120)
			UIStyles.apply_cartoon_label(q, 48, 6)
			q.modulate = Color(0.55, 0.6, 0.7)
			vbox.add_child(q)
		margin.add_child(vbox)
		card.add_child(margin)
		if not known:
			card.modulate = Color(0.7, 0.72, 0.78)
		grid.add_child(card)
