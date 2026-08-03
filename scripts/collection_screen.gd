class_name CollectionScreen
extends Control

signal closed

## Decorative fruit sets by numeric ID ranges (source files stay numbered).
const SET_DEFS: Array = [
	{"id": "fruits_1", "category": "fruits", "title": "Fresh Start", "icon": "🌱", "id_min": 1, "id_max": 6, "color": Color(0.35, 0.78, 0.42)},
	{"id": "fruits_2", "category": "fruits", "title": "Tropical Mix", "icon": "🌴", "id_min": 7, "id_max": 12, "color": Color(0.95, 0.62, 0.22)},
	{"id": "fruits_3", "category": "fruits", "title": "Berry Basket", "icon": "🧺", "id_min": 13, "id_max": 18, "color": Color(0.72, 0.38, 0.78)},
	{"id": "fruits_4", "category": "fruits", "title": "Garden Picks", "icon": "🌻", "id_min": 19, "id_max": 24, "color": Color(0.28, 0.58, 0.92)},
]

@onready var _bg: ColorRect = %Bg
@onready var _header: PanelContainer = %Header
@onready var _count_pill: PanelContainer = %CountPill
@onready var _count_info: Label = %CountInfo
@onready var _title: Label = %TitleLabel
@onready var _close_button: Button = %CloseButton
@onready var _status: Label = %StatusLabel
@onready var _scroll: ScrollContainer = %Scroll
@onready var _content: VBoxContainer = %ContentBox

var _view: String = "overview" # overview | detail
var _active_set: Dictionary = {}
var _busy: bool = false


func _ready() -> void:
	hide()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_to_group("collection_screen")
	_apply_theme()
	_close_button.pressed.connect(_on_close_pressed)


func open_collection() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_bg.mouse_filter = Control.MOUSE_FILTER_STOP
	_status.text = ""
	_busy = false
	_view = "overview"
	_active_set = {}
	_refresh()
	show()
	move_to_front()
	_scroll.scroll_vertical = 0
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.18)


func close_modal() -> void:
	close_collection()


func close_collection() -> void:
	if not visible:
		return
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
		Color(0.42, 0.32, 0.78, 0.98), 0, 0.0, Color(0.95, 0.78, 0.22, 1.0)
	)
	header_style.corner_radius_bottom_left = 20
	header_style.corner_radius_bottom_right = 20
	header_style.set_border_width_all(0)
	header_style.border_width_bottom = 5
	header_style.border_color = Color(0.95, 0.78, 0.22, 1.0)
	header_style.shadow_size = 12
	_header.add_theme_stylebox_override("panel", header_style)
	_count_pill.add_theme_stylebox_override("panel", UIStyles.pill_panel())
	UIStyles.apply_dark_cartoon_label(_count_info, 15)
	UIStyles.apply_cartoon_label(_title, 32, 7)
	UIStyles.apply_cartoon_label(_status, 15, 4)
	_status.add_theme_color_override("font_color", Color(1.0, 0.95, 0.4))

	var close_style := UIStyles.glossy_button(UIStyles.COLOR_DANGER, 999, Color(1, 1, 1, 0.75))
	_close_button.add_theme_stylebox_override("normal", close_style)
	_close_button.add_theme_stylebox_override("hover", UIStyles.glossy_button(Color(1.0, 0.42, 0.45), 999))
	_close_button.add_theme_stylebox_override("pressed", UIStyles.glossy_button(Color(0.78, 0.22, 0.28), 999))
	_close_button.add_theme_font_size_override("font_size", 28)
	_close_button.add_theme_color_override("font_color", Color.WHITE)
	UIStyles.bind_button(_close_button)


func _refresh() -> void:
	ItemCatalog.ensure_loaded(ItemCatalog.CATEGORY_FRUITS)
	var all_entries: Array = ItemCatalog.valid_entries(ItemCatalog.CATEGORY_FRUITS)
	var discovered := GameSettings.discovered_collectible_count()
	var total := all_entries.size()
	_count_info.text = "⭐ %d/%d" % [discovered, total]
	_title.text = "COLLECTION" if _view == "overview" else str(_active_set.get("title", "Set"))

	while _content.get_child_count() > 0:
		var child := _content.get_child(0)
		_content.remove_child(child)
		child.free()

	if _view == "detail":
		_build_detail_view()
	else:
		_build_overview(all_entries, discovered, total)


func _build_overview(all_entries: Array, discovered: int, total: int) -> void:
	_content.add_child(_make_progress_panel(discovered, total))
	_content.add_child(_make_milestones_row(total))

	var grid_title := Label.new()
	grid_title.text = "Collection Sets"
	grid_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIStyles.apply_cartoon_label(grid_title, 18, 4)
	_content.add_child(grid_title)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	_content.add_child(grid)

	for set_def in SET_DEFS:
		var entries := _entries_for_set(set_def, all_entries)
		if entries.is_empty():
			continue
		grid.add_child(_make_category_card(set_def, entries))

	var note := Label.new()
	note.text = "Numeric image sets · ready for future categories"
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UIStyles.apply_cartoon_label(note, 12, 2)
	_content.add_child(note)


func _make_progress_panel(discovered: int, total: int) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := UIStyles.glossy_panel(Color(0.55, 0.42, 0.88, 0.96), 18, 4.0, Color(0.98, 0.82, 0.28, 0.95))
	style.shadow_size = 10
	panel.add_theme_stylebox_override("panel", style)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)

	var title := Label.new()
	title.text = "Hole Rush Collection"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIStyles.apply_cartoon_label(title, 18, 4)

	var count := Label.new()
	var pct := 0 if total <= 0 else int(round(100.0 * float(discovered) / float(total)))
	count.text = "%d / %d discovered · %d%%" % [discovered, total, pct]
	count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIStyles.apply_cartoon_label(count, 16, 3)

	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(0, 22)
	bar.max_value = maxi(1, total)
	bar.value = discovered
	bar.show_percentage = false
	bar.add_theme_stylebox_override("background", UIStyles.progress_track_style())
	bar.add_theme_stylebox_override("fill", UIStyles.progress_fill_style())
	col.add_child(title)
	col.add_child(count)
	col.add_child(bar)

	var chest_row := HBoxContainer.new()
	chest_row.alignment = BoxContainer.ALIGNMENT_CENTER
	var chest := Label.new()
	chest.text = "🎁 Next milestone rewards below"
	UIStyles.apply_cartoon_label(chest, 13, 2)
	chest_row.add_child(chest)
	col.add_child(chest_row)

	margin.add_child(col)
	panel.add_child(margin)
	return panel


func _make_milestones_row(total: int) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	var label := Label.new()
	label.text = "Discovery Rewards"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIStyles.apply_cartoon_label(label, 16, 3)
	box.add_child(label)
	for def in GameSettings.collection_reward_definitions(total):
		box.add_child(_make_reward_card(def))
	return box


func _make_reward_card(def: Dictionary) -> PanelContainer:
	var claimable := bool(def.get("claimable", false))
	var claimed := bool(def.get("claimed", false))
	var bg := Color(0.22, 0.62, 0.38, 0.98) if claimable else (Color(0.32, 0.38, 0.48, 0.95) if claimed else Color(0.2, 0.28, 0.42, 0.96))
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UIStyles.glossy_panel(bg, 14, 3.0, Color(0.95, 0.78, 0.28, 0.75)))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 6)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var icon := Label.new()
	icon.text = str(def.get("icon", "🎁"))
	icon.custom_minimum_size = Vector2(34, 0)
	UIStyles.apply_cartoon_label(icon, 22, 3)

	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var title := Label.new()
	title.text = "%s · %s" % [str(def.get("title", "Reward")), str(def.get("reward_label", ""))]
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UIStyles.apply_cartoon_label(title, 13, 2)
	var prog := Label.new()
	var p := int(def.get("progress", 0))
	var t := int(def.get("target", 1))
	if claimed:
		prog.text = "Claimed"
	elif claimable:
		prog.text = "Ready to claim"
	else:
		prog.text = "%d / %d" % [mini(p, t), t]
	UIStyles.apply_cartoon_label(prog, 12, 2)
	col.add_child(title)
	col.add_child(prog)
	row.add_child(icon)
	row.add_child(col)

	if claimable:
		var btn := Button.new()
		btn.text = "Claim"
		btn.custom_minimum_size = Vector2(78, 42)
		btn.focus_mode = Control.FOCUS_NONE
		UIStyles.style_primary_button(btn, 16)
		btn.pressed.connect(_on_claim.bind(str(def.get("id", "")), btn))
		row.add_child(btn)
	elif claimed:
		var done := Label.new()
		done.text = "✓"
		UIStyles.apply_cartoon_label(done, 20, 3)
		row.add_child(done)
	else:
		var lock := Label.new()
		lock.text = "🔒"
		UIStyles.apply_cartoon_label(lock, 18, 2)
		row.add_child(lock)

	margin.add_child(row)
	card.add_child(margin)
	return card


func _make_category_card(set_def: Dictionary, entries: Array) -> Button:
	var known := 0
	for e in entries:
		var entry := e as ItemEntry
		if entry and GameSettings.is_collectible_discovered(entry.catalog_key()):
			known += 1
	var total := entries.size()
	var complete := known >= total and total > 0
	var color: Color = set_def.get("color", Color(0.3, 0.55, 0.9))
	if complete:
		color = Color(0.95, 0.78, 0.22)

	var btn := Button.new()
	btn.focus_mode = Control.FOCUS_NONE
	btn.custom_minimum_size = Vector2(0, 168)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := UIStyles.glossy_panel(color, 22, 4.0, Color(0.98, 0.82, 0.28, 0.95))
	style.shadow_size = 10
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", style)

	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	col.offset_left = 8
	col.offset_top = 8
	col.offset_right = -8
	col.offset_bottom = -8
	col.add_theme_constant_override("separation", 4)
	col.alignment = BoxContainer.ALIGNMENT_CENTER

	var badge_row := HBoxContainer.new()
	badge_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	badge_row.add_child(spacer)
	if known > 0 and not complete:
		var badge := Label.new()
		badge.text = str(known)
		badge.add_theme_font_size_override("font_size", 12)
		UIStyles.apply_cartoon_label(badge, 12, 3)
		badge.add_theme_color_override("font_color", Color(1, 0.35, 0.35))
		badge_row.add_child(badge)
	elif complete:
		var check := Label.new()
		check.text = "✓"
		UIStyles.apply_cartoon_label(check, 16, 3)
		badge_row.add_child(check)
	col.add_child(badge_row)

	var icon := Label.new()
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.text = str(set_def.get("icon", "⭐"))
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIStyles.apply_cartoon_label(icon, 36, 4)
	col.add_child(icon)

	var title := Label.new()
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.text = str(set_def.get("title", "Set"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIStyles.apply_cartoon_label(title, 15, 3)
	col.add_child(title)

	var prog := Label.new()
	prog.mouse_filter = Control.MOUSE_FILTER_IGNORE
	prog.text = "%d / %d" % [known, total]
	prog.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIStyles.apply_cartoon_label(prog, 14, 3)
	col.add_child(prog)

	var bar := ProgressBar.new()
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.custom_minimum_size = Vector2(0, 12)
	bar.max_value = maxi(1, total)
	bar.value = known
	bar.show_percentage = false
	bar.add_theme_stylebox_override("background", UIStyles.progress_track_style())
	bar.add_theme_stylebox_override("fill", UIStyles.progress_fill_style())
	col.add_child(bar)

	btn.add_child(col)
	btn.pressed.connect(_open_set.bind(set_def))
	UIStyles.bind_button(btn)
	return btn


func _entries_for_set(set_def: Dictionary, all_entries: Array) -> Array:
	var out: Array = []
	var id_min := int(set_def.get("id_min", 1))
	var id_max := int(set_def.get("id_max", 999))
	var category := str(set_def.get("category", ItemCatalog.CATEGORY_FRUITS))
	for e in all_entries:
		var entry := e as ItemEntry
		if entry == null:
			continue
		if entry.category != category:
			continue
		if entry.image_id >= id_min and entry.image_id <= id_max:
			out.append(entry)
	return out


func _open_set(set_def: Dictionary) -> void:
	GameSettings.play_ui_click()
	_view = "detail"
	_active_set = set_def
	_scroll.scroll_vertical = 0
	_refresh()


func _build_detail_view() -> void:
	var back := Button.new()
	back.text = "◀ Back to Sets"
	back.custom_minimum_size = Vector2(0, 48)
	back.focus_mode = Control.FOCUS_NONE
	UIStyles.style_secondary_button(back, 18)
	back.pressed.connect(func():
		GameSettings.play_ui_click()
		_view = "overview"
		_active_set = {}
		_scroll.scroll_vertical = 0
		_refresh()
	)
	_content.add_child(back)

	ItemCatalog.ensure_loaded(str(_active_set.get("category", ItemCatalog.CATEGORY_FRUITS)))
	var all_entries: Array = ItemCatalog.valid_entries(str(_active_set.get("category", ItemCatalog.CATEGORY_FRUITS)))
	var entries := _entries_for_set(_active_set, all_entries)
	var known := 0
	for e in entries:
		if GameSettings.is_collectible_discovered((e as ItemEntry).catalog_key()):
			known += 1
	var header := Label.new()
	header.text = "%s · %d / %d" % [str(_active_set.get("title", "Set")), known, entries.size()]
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIStyles.apply_cartoon_label(header, 18, 4)
	_content.add_child(header)

	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	_content.add_child(grid)
	for e in entries:
		grid.add_child(_make_item_card(e as ItemEntry))


func _make_item_card(entry: ItemEntry) -> PanelContainer:
	var known := GameSettings.is_collectible_discovered(entry.catalog_key())
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(110, 130)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var bg := Color(0.96, 0.97, 1.0, 0.98) if known else Color(0.28, 0.32, 0.4, 0.95)
	card.add_theme_stylebox_override(
		"panel",
		UIStyles.glossy_panel(bg, 14, 3.0, Color(0.95, 0.78, 0.28, 0.85) if known else Color(0.5, 0.55, 0.6, 0.7))
	)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER

	if known and entry.texture != null:
		var tex := TextureRect.new()
		tex.texture = entry.hud_texture()
		tex.custom_minimum_size = Vector2(88, 88)
		tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		tex.modulate = Color.WHITE
		col.add_child(tex)
		var count := int(GameSettings.collected_count_by_id.get(entry.catalog_key(), 1))
		var meta := Label.new()
		meta.text = "×%d" % count
		meta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		UIStyles.apply_dark_cartoon_label(meta, 11)
		col.add_child(meta)
	else:
		var q := Label.new()
		q.text = "?"
		q.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		q.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		q.custom_minimum_size = Vector2(88, 88)
		UIStyles.apply_cartoon_label(q, 42, 6)
		q.modulate = Color(0.65, 0.7, 0.8)
		col.add_child(q)
		var lock := Label.new()
		lock.text = "🔒"
		lock.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		UIStyles.apply_cartoon_label(lock, 14, 2)
		col.add_child(lock)

	margin.add_child(col)
	card.add_child(margin)
	return card


func _on_claim(reward_id: String, btn: Button) -> void:
	if _busy:
		return
	_busy = true
	GameSettings.play_ui_click()
	if btn:
		btn.disabled = true
	var ok := GameSettings.claim_collection_reward(reward_id)
	if ok:
		GameSettings.play_coin_collect_sfx()
		_status.text = "Collection reward claimed!"
		_refresh()
	else:
		GameSettings.play_lose_sfx()
		_status.text = "Could not claim reward."
		if btn:
			btn.disabled = false
	_busy = false


func _on_close_pressed() -> void:
	GameSettings.play_ui_click()
	if _view == "detail":
		_view = "overview"
		_active_set = {}
		_refresh()
		return
	close_collection()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		if _view == "detail":
			_view = "overview"
			_active_set = {}
			_refresh()
		else:
			close_collection()
		get_viewport().set_input_as_handled()
