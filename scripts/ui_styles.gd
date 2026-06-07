class_name UIStyles
extends RefCounted

## Hole Rush mobile UI design tokens (Kenney-inspired palette, original StyleBox implementation).

const COLOR_PRIMARY := Color(0.18, 0.48, 0.92, 1.0)
const COLOR_PRIMARY_DARK := Color(0.1, 0.3, 0.68, 1.0)
const COLOR_ACCENT_GOLD := Color(0.98, 0.78, 0.18, 1.0)
const COLOR_SUCCESS := Color(0.38, 0.82, 0.28, 1.0)
const COLOR_DANGER := Color(0.92, 0.32, 0.38, 1.0)
const COLOR_PANEL := Color(0.12, 0.28, 0.58, 0.97)
const COLOR_PANEL_LIGHT := Color(0.97, 0.98, 1.0, 0.96)
const COLOR_TEXT := Color.WHITE
const COLOR_OUTLINE := Color(0.05, 0.1, 0.22, 0.95)


static func glossy_panel(bg: Color, corner: int = 22, border: float = 4.0, border_col: Color = Color(1, 1, 1, 0.45)) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(corner)
	s.border_color = border_col
	s.set_border_width_all(int(border))
	s.shadow_color = Color(0.02, 0.06, 0.14, 0.55)
	s.shadow_size = 12
	s.shadow_offset = Vector2(0, 5)
	return s


static func glossy_button(bg: Color, corner: int = 20, border_col: Color = Color(1, 1, 1, 0.5)) -> StyleBoxFlat:
	var s := glossy_panel(bg, corner, 3.0, border_col)
	s.shadow_size = 14
	s.shadow_offset = Vector2(0, 7)
	return s


static func gold_frame_panel(inner: Color = Color(0.98, 0.96, 0.9, 1.0)) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = inner
	s.set_corner_radius_all(24)
	s.border_color = Color(0.92, 0.68, 0.18, 1.0)
	s.set_border_width_all(5)
	s.shadow_color = Color(0.15, 0.08, 0.02, 0.45)
	s.shadow_size = 10
	s.shadow_offset = Vector2(0, 4)
	return s


static func blue_deep_panel() -> StyleBoxFlat:
	return glossy_panel(Color(0.1, 0.28, 0.62, 0.98), 28, 4.0, Color(0.35, 0.62, 0.95, 0.85))


static func pill_panel(bg: Color = Color(0.97, 0.98, 1.0, 0.96)) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(999)
	s.border_color = Color(0.75, 0.82, 0.95, 0.9)
	s.set_border_width_all(3)
	s.shadow_size = 8
	s.shadow_offset = Vector2(0, 3)
	s.shadow_color = Color(0.05, 0.1, 0.2, 0.35)
	return s


static func progress_track_style() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.08, 0.2, 0.42, 0.95)
	s.set_corner_radius_all(18)
	s.border_color = Color(0.45, 0.72, 0.98, 0.7)
	s.set_border_width_all(3)
	return s


static func progress_fill_style() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.25, 0.62, 0.98, 1.0)
	s.set_corner_radius_all(16)
	return s


static func level_outer_frame() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.14, 0.38, 0.78, 1.0)
	s.set_corner_radius_all(32)
	s.border_color = Color(0.45, 0.75, 1.0, 0.9)
	s.set_border_width_all(6)
	s.shadow_color = Color(0.02, 0.08, 0.18, 0.6)
	s.shadow_size = 16
	s.shadow_offset = Vector2(0, 8)
	return s


static func level_inner_button() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.38, 0.82, 0.28, 1.0)
	s.set_corner_radius_all(26)
	s.border_color = Color(0.75, 1.0, 0.65, 0.85)
	s.set_border_width_all(4)
	s.shadow_color = Color(0.05, 0.15, 0.05, 0.45)
	s.shadow_size = 10
	s.shadow_offset = Vector2(0, 5)
	return s


static func event_orb(color: Color) -> StyleBoxFlat:
	var s := glossy_button(color, 999)
	s.shadow_size = 10
	return s


static func nav_item(active: bool) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	if active:
		s.bg_color = Color(0.22, 0.48, 0.88, 0.95)
		s.border_color = Color(1, 1, 1, 0.55)
	else:
		s.bg_color = Color(0.12, 0.28, 0.55, 0.5)
		s.border_color = Color(1, 1, 1, 0.15)
	s.set_corner_radius_all(16)
	s.set_border_width_all(2)
	return s


static func apply_cartoon_label(node: Control, font_size: int, outline: int = 6) -> void:
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", Color.WHITE)
	node.add_theme_color_override("font_outline_color", Color(0.05, 0.1, 0.2, 0.95))
	node.add_theme_constant_override("outline_size", outline)


static func apply_dark_cartoon_label(label: Label, font_size: int) -> void:
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color(0.12, 0.22, 0.38))
	label.add_theme_color_override("font_outline_color", Color(1, 1, 1, 0.5))
	label.add_theme_constant_override("outline_size", 3)


static func popup_panel() -> StyleBoxFlat:
	return gold_frame_panel(Color(0.14, 0.32, 0.62, 0.96))


static func shop_card() -> StyleBoxFlat:
	var s := glossy_panel(Color(0.16, 0.36, 0.72, 0.98), 20, 3.0, Color(0.55, 0.78, 1.0, 0.7))
	s.shadow_size = 10
	return s


static func style_action_button(btn: Button, base: Color, hover: Color, font_size: int) -> void:
	btn.add_theme_stylebox_override("normal", glossy_button(base, 20))
	btn.add_theme_stylebox_override("hover", glossy_button(hover, 20))
	btn.add_theme_stylebox_override("pressed", glossy_button(base.darkened(0.12), 20))
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_outline_color", Color(0.05, 0.1, 0.18, 0.92))
	btn.add_theme_constant_override("outline_size", 6)
	btn.add_theme_font_size_override("font_size", font_size)
	bind_button(btn)


static func bind_button(btn: Button) -> void:
	if btn == null or btn.has_meta("ui_anim_bound"):
		return
	btn.set_meta("ui_anim_bound", true)
	btn.button_down.connect(func() -> void: _button_press_down(btn))
	btn.button_up.connect(func() -> void: _button_press_up(btn))


static func _button_press_down(btn: Button) -> void:
	var tween := btn.create_tween()
	tween.tween_property(btn, "scale", Vector2(0.94, 0.94), 0.06).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


static func _button_press_up(btn: Button) -> void:
	var tween := btn.create_tween()
	tween.tween_property(btn, "scale", Vector2(1.04, 1.04), 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(btn, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_ELASTIC)


static func style_primary_button(btn: Button, font_size: int = 34) -> void:
	style_action_button(btn, COLOR_SUCCESS, COLOR_SUCCESS.lightened(0.12), font_size)


static func style_secondary_button(btn: Button, font_size: int = 28) -> void:
	style_action_button(btn, COLOR_PRIMARY, COLOR_PRIMARY.lightened(0.1), font_size)


static func style_gold_button(btn: Button, font_size: int = 28) -> void:
	style_action_button(btn, COLOR_ACCENT_GOLD, Color(1.0, 0.9, 0.35), font_size)
	btn.add_theme_color_override("font_outline_color", Color(0.35, 0.2, 0.02, 0.95))


static func apply_panel(node: PanelContainer, style: StyleBoxFlat) -> void:
	node.add_theme_stylebox_override("panel", style)


static func apply_mobile_safe_margin(container: MarginContainer, margin: int = 16) -> void:
	container.add_theme_constant_override("margin_left", margin)
	container.add_theme_constant_override("margin_top", margin)
	container.add_theme_constant_override("margin_right", margin)
	container.add_theme_constant_override("margin_bottom", margin)
