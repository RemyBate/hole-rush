extends "res://scripts/home_modal.gd"


func open_trophies() -> void:
	open_modal("TROPHIES")


func refresh_content() -> void:
	clear_box(_content)
	clear_box(_footer)
	var intro := Label.new()
	intro.text = "Achievements from your save progress"
	intro.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIStyles.apply_cartoon_label(intro, 18, 4)
	_content.add_child(intro)

	for def in GameSettings.trophy_definitions():
		var unlocked: bool = bool(def.get("unlocked", false))
		var progress: int = int(def.get("progress", 0))
		var target: int = int(def.get("target", 1))
		var card := PanelContainer.new()
		card.add_theme_stylebox_override(
			"panel",
			UIStyles.shop_card() if unlocked else UIStyles.glossy_panel(Color(0.12, 0.18, 0.3, 0.95), 16, 2.0)
		)
		var margin := MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 12)
		margin.add_theme_constant_override("margin_top", 10)
		margin.add_theme_constant_override("margin_right", 12)
		margin.add_theme_constant_override("margin_bottom", 10)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		var icon := Label.new()
		icon.text = str(def.get("icon", "🏆"))
		icon.custom_minimum_size = Vector2(48, 48)
		icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		UIStyles.apply_cartoon_label(icon, 28, 4)
		if not unlocked:
			icon.modulate = Color(0.55, 0.55, 0.6)
		var col := VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var title := Label.new()
		title.text = str(def.get("title", "Trophy"))
		UIStyles.apply_cartoon_label(title, 22, 4)
		var req := Label.new()
		req.text = str(def.get("requirement", ""))
		req.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		UIStyles.apply_cartoon_label(req, 16, 3)
		req.add_theme_color_override("font_color", Color(0.85, 0.9, 1.0))
		var prog := Label.new()
		if unlocked:
			prog.text = "Unlocked"
			prog.add_theme_color_override("font_color", Color(0.45, 1.0, 0.55))
		else:
			prog.text = "Progress %d / %d" % [mini(progress, target), target]
			prog.add_theme_color_override("font_color", Color(1.0, 0.85, 0.45))
		UIStyles.apply_cartoon_label(prog, 16, 3)
		col.add_child(title)
		col.add_child(req)
		col.add_child(prog)
		row.add_child(icon)
		row.add_child(col)
		margin.add_child(row)
		card.add_child(margin)
		_content.add_child(card)
