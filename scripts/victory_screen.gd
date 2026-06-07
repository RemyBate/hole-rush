class_name VictoryScreen
extends Control

signal continue_pressed
signal bonus_reward_pressed

const COLOR_GOLD := Color(0.98, 0.78, 0.18, 1.0)
const COLOR_GOLD_DARK := Color(0.72, 0.42, 0.08, 1.0)
const COLOR_CYAN := Color(0.2, 0.72, 0.96, 0.98)
const COLOR_GREEN := Color(0.42, 0.84, 0.28, 0.98)
const SEGMENT_COLORS: Array[Color] = [
	Color(0.95, 0.55, 0.2),
	Color(0.98, 0.82, 0.22),
	Color(0.42, 0.82, 0.32),
	Color(0.98, 0.82, 0.22),
	Color(0.95, 0.55, 0.2),
]

@onready var _dim: ColorRect = %Dim
@onready var _blur: ColorRect = %Blur
@onready var _content: Control = %Content
@onready var _star_nodes: Array[Control] = [%Star1, %Star2, %Star3]
@onready var _banner_label: Label = %BannerLabel
@onready var _banner_panel: PanelContainer = %BannerPanel
@onready var _key_column: Control = %KeyColumn
@onready var _trophy_column: Control = %TrophyColumn
@onready var _coin_column: Control = %CoinColumn
@onready var _key_value: Label = %KeyValue
@onready var _trophy_value: Label = %TrophyValue
@onready var _coin_value: Label = %CoinValue
@onready var _gem_value: Label = %GemValue
@onready var _gem_column: Control = %GemColumn
@onready var _coin_summary: Label = %CoinSummary
@onready var _rewards_row: HBoxContainer = %RewardsRow
@onready var _progress_fill: Control = %ProgressFill
@onready var _progress_arrow: Control = %ProgressArrow
@onready var _progress_track: Control = %ProgressTrack
@onready var _bonus_button: Button = %BonusButton
@onready var _continue_button: Button = %ContinueButton
@onready var _sparkle_host: Control = %SparkleHost
@onready var _firework_host: Control = %FireworkHost

var _open: bool = false
var _segment_widths: PackedFloat32Array = PackedFloat32Array()
var _reward_targets: Dictionary = {}
var _visible_reward_labels: Array[Label] = []


func _ready() -> void:
	hide()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.modulate.a = 0.0
	_dim.modulate.a = 0.0
	_blur.modulate.a = 0.0
	_apply_theme()
	_style_progress_segments()
	_cache_segment_layout()
	call_deferred("_apply_star_arc_offsets")
	_bonus_button.pressed.connect(_on_bonus_pressed)
	_continue_button.pressed.connect(_on_continue_pressed)
	for star in _star_nodes:
		star.modulate.a = 0.0
		star.scale = Vector2(0.2, 0.2)


func show_victory(data: Dictionary) -> void:
	if _open:
		return
	_open = true
	show()
	mouse_filter = Control.MOUSE_FILTER_STOP
	_reset_visuals()
	_apply_data(data)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_dim, "modulate:a", 1.0, 0.28)
	tween.tween_property(_blur, "modulate:a", 1.0, 0.32)
	tween.tween_property(_content, "modulate:a", 1.0, 0.35)
	tween.chain().tween_callback(_run_intro_sequence)


func get_coin_reward_global_center() -> Vector2:
	if _coin_column.visible:
		return _coin_column.get_global_rect().get_center()
	if _coin_summary.visible:
		return _coin_summary.get_global_rect().get_center()
	return _continue_button.get_global_rect().get_center()


func hide_victory() -> void:
	if not _open:
		return
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_dim, "modulate:a", 0.0, 0.2)
	tween.tween_property(_blur, "modulate:a", 0.0, 0.2)
	tween.tween_property(_content, "modulate:a", 0.0, 0.2)
	tween.chain().tween_callback(_finish_hide)


func _finish_hide() -> void:
	_open = false
	hide()
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _reset_visuals() -> void:
	for star in _star_nodes:
		star.modulate.a = 0.0
		star.scale = Vector2(0.15, 0.15)
		_set_star_visual(star, false, false)
	_progress_fill.size.x = 0.0
	_key_value.scale = Vector2.ONE
	_trophy_value.scale = Vector2.ONE
	_coin_value.scale = Vector2.ONE
	_gem_value.scale = Vector2.ONE


func _apply_data(data: Dictionary) -> void:
	var stars: int = int(data.get("stars", 1))
	_banner_label.text = str(data.get("banner_text", GameSettings.banner_for_stars(stars)))

	var coins_collected: int = int(data.get("coins_collected", 0))
	var coins_star: int = int(data.get("coins_star_bonus", 0))
	var coins: int = int(data.get("coins_earned", coins_collected + coins_star))
	var gems: int = int(data.get("gems_earned", 0))
	var keys: int = int(data.get("keys_earned", 0))
	var trophies: int = int(data.get("trophy_points", 0))

	_reward_targets = {
		"coins": coins,
		"gems": gems,
		"keys": keys,
		"trophies": trophies,
	}
	_visible_reward_labels.clear()

	_coin_column.visible = coins > 0
	_gem_column.visible = gems > 0
	_key_column.visible = keys > 0
	_trophy_column.visible = trophies > 0
	_rewards_row.visible = coins > 0 or gems > 0 or keys > 0 or trophies > 0

	for label in [_coin_value, _gem_value, _key_value, _trophy_value]:
		label.text = "0"

	if coins > 0:
		_visible_reward_labels.append(_coin_value)
	if gems > 0:
		_visible_reward_labels.append(_gem_value)
	if keys > 0:
		_visible_reward_labels.append(_key_value)
	if trophies > 0:
		_visible_reward_labels.append(_trophy_value)

	if coins > 0:
		_coin_summary.visible = true
		_coin_summary.text = (
			"Coins collected: %d\nStar reward (%d★): +%d\nTotal reward: %d" % [
				coins_collected,
				stars,
				coins_star,
				coins,
			]
		)
	else:
		_coin_summary.visible = false

	_pending_stars = stars
	_track_before = float(data.get("track_ratio_before", 0.0))
	_track_after = float(data.get("track_ratio_after", 0.0))


var _pending_stars: int = 0
var _track_before: float = 0.0
var _track_after: float = 0.0


func _run_intro_sequence() -> void:
	_spawn_fireworks()
	await _animate_stars(_pending_stars)
	await _animate_earned_rewards()
	await get_tree().create_timer(0.15).timeout
	_animate_progress_bar()


func _animate_earned_rewards() -> void:
	if _visible_reward_labels.is_empty():
		return
	var delay := 0.0
	for label in _visible_reward_labels:
		var target := _target_for_label(label)
		await _count_up_reward(label, target, delay)
		delay += 0.08


func _target_for_label(label: Label) -> int:
	if label == _coin_value:
		return int(_reward_targets.get("coins", 0))
	if label == _gem_value:
		return int(_reward_targets.get("gems", 0))
	if label == _key_value:
		return int(_reward_targets.get("keys", 0))
	if label == _trophy_value:
		return int(_reward_targets.get("trophies", 0))
	return 0


func _count_up_reward(label: Label, target: int, delay: float) -> void:
	if target <= 0:
		return
	await get_tree().create_timer(delay).timeout
	var steps := clampi(maxi(target, 1), 4, 22)
	var step_time := 0.65 / float(steps)
	for step in steps + 1:
		var value := int(round(float(target) * float(step) / float(steps)))
		label.text = str(value)
		if step == steps:
			_pop_reward(label, 0.0)
			_spawn_reward_sparkles(label)
		await get_tree().create_timer(step_time).timeout
	label.text = str(target)


func _spawn_reward_sparkles(label: Label) -> void:
	var center := label.global_position + label.size * 0.5
	for _i in 5:
		var spark := Label.new()
		spark.text = "✦"
		spark.add_theme_font_size_override("font_size", 26)
		spark.add_theme_color_override("font_color", Color(1.0, 0.92, 0.35))
		_sparkle_host.add_child(spark)
		spark.global_position = center + Vector2(randf_range(-36, 36), randf_range(-24, 24))
		var tw := create_tween()
		tw.set_parallel(true)
		tw.tween_property(spark, "global_position:y", spark.global_position.y - 32.0, 0.5)
		tw.tween_property(spark, "modulate:a", 0.0, 0.5)
		tw.chain().tween_callback(spark.queue_free)


func _animate_stars(earned: int) -> void:
	for i in _star_nodes.size():
		var lit := i < earned
		await get_tree().create_timer(0.22).timeout
		var star := _star_nodes[i]
		_set_star_visual(star, lit, true)
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(star, "modulate:a", 1.0, 0.12)
		tween.tween_property(star, "scale", Vector2(1.15, 1.15), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.chain().tween_property(star, "scale", Vector2.ONE, 0.1)
		if lit:
			_spawn_star_sparkles(star)
			GameSettings.vibrate(25)


func _set_star_visual(star: Control, lit: bool, glow: bool) -> void:
	var icon := star.get_node("Icon") as Label
	if icon == null:
		return
	if lit:
		icon.text = "⭐"
		icon.add_theme_font_size_override("font_size", 72)
		icon.add_theme_color_override("font_color", Color(1.0, 0.92, 0.25))
		icon.add_theme_color_override("font_outline_color", Color(0.55, 0.32, 0.05))
	else:
		icon.text = "★"
		icon.add_theme_font_size_override("font_size", 64)
		icon.add_theme_color_override("font_color", Color(0.22, 0.14, 0.1))
		icon.add_theme_color_override("font_outline_color", Color(0.08, 0.05, 0.04))
	if glow and lit:
		var halo := star.get_node_or_null("Halo") as ColorRect
		if halo:
			halo.visible = true
			halo.modulate = Color(1.0, 0.85, 0.2, 0.55)


func _pop_reward(label: Label, delay: float) -> void:
	await get_tree().create_timer(delay).timeout
	var tween := create_tween()
	tween.tween_property(label, "scale", Vector2(1.28, 1.28), 0.12).set_trans(Tween.TRANS_BACK)
	tween.tween_property(label, "scale", Vector2.ONE, 0.14)


func _animate_progress_bar() -> void:
	await get_tree().create_timer(0.1).timeout
	var track_w := _progress_track.size.x
	if track_w <= 1.0:
		await get_tree().process_frame
		track_w = _progress_track.size.x
	var start_w := track_w * _track_before
	var end_w := track_w * _track_after
	_progress_fill.size.x = start_w
	_progress_arrow.position.x = start_w - 10.0
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_method(
		func(v: float) -> void:
			_progress_fill.size.x = v
			_progress_arrow.position.x = v - 10.0,
		start_w,
		end_w,
		1.1
	)


func _spawn_star_sparkles(star: Control) -> void:
	for _i in 4:
		var spark := Label.new()
		spark.text = "✦"
		spark.add_theme_font_size_override("font_size", 22)
		spark.add_theme_color_override("font_color", Color(1.0, 0.9, 0.35))
		spark.position = star.position + Vector2(randf_range(-30, 30), randf_range(-20, 20))
		_sparkle_host.add_child(spark)
		var tw := create_tween()
		tw.set_parallel(true)
		tw.tween_property(spark, "position:y", spark.position.y - 40.0, 0.55)
		tw.tween_property(spark, "modulate:a", 0.0, 0.55)
		tw.chain().tween_callback(spark.queue_free)


func _spawn_fireworks() -> void:
	for i in 6:
		var line := ColorRect.new()
		line.custom_minimum_size = Vector2(4, 36)
		line.color = Color(1.0, 0.82, 0.2, 0.85)
		line.rotation = randf_range(-0.8, 0.8)
		line.position = Vector2(randf_range(80, 640), randf_range(40, 180))
		line.pivot_offset = Vector2(2, 36)
		_firework_host.add_child(line)
		var tw := create_tween()
		tw.tween_property(line, "modulate:a", 0.0, 0.7).set_delay(0.05 * float(i))
		tw.chain().tween_callback(line.queue_free)


func _apply_star_arc_offsets() -> void:
	if _star_nodes.size() >= 3:
		_star_nodes[0].position.y += 18.0
		_star_nodes[2].position.y += 18.0


func _style_progress_segments() -> void:
	var row := _progress_track.get_node("SegmentRow") as HBoxContainer
	if row == null:
		return
	var outer := StyleBoxFlat.new()
	outer.bg_color = Color(0.96, 0.9, 0.78, 0.98)
	outer.set_corner_radius_all(18)
	outer.set_border_width_all(4)
	outer.border_color = Color(0.55, 0.42, 0.28, 0.95)
	_progress_track.add_theme_stylebox_override("panel", outer)
	for i in row.get_child_count():
		var panel := row.get_child(i) as Panel
		if panel == null:
			continue
		var style := StyleBoxFlat.new()
		style.bg_color = SEGMENT_COLORS[i % SEGMENT_COLORS.size()]
		style.set_corner_radius_all(10)
		style.border_color = Color(1, 1, 1, 0.25)
		style.set_border_width_all(2)
		panel.add_theme_stylebox_override("panel", style)
		var seg_label := panel.get_node_or_null("Label") as Label
		if seg_label:
			_style_cartoon_label(seg_label, 22)
			seg_label.add_theme_color_override("font_color", Color(0.08, 0.08, 0.1, 1.0))
			seg_label.add_theme_color_override("font_outline_color", Color(1, 1, 1, 0.35))
			seg_label.add_theme_constant_override("outline_size", 2)


func _cache_segment_layout() -> void:
	var total := 0
	for m in GameSettings.REWARD_MILESTONES:
		total += m
	_segment_widths.resize(GameSettings.REWARD_MILESTONES.size())
	for i in GameSettings.REWARD_MILESTONES.size():
		_segment_widths[i] = float(GameSettings.REWARD_MILESTONES[i]) / float(total)


func _apply_theme() -> void:
	var blur_mat := ShaderMaterial.new()
	blur_mat.shader = load("res://shaders/ui_backdrop_blur.gdshader")
	_blur.material = blur_mat

	_banner_panel.add_theme_stylebox_override("panel", _ribbon_style())
	_style_banner_text(_banner_label)

	UIStyles.style_secondary_button(_bonus_button, 30)
	UIStyles.style_primary_button(_continue_button, 36)

	for label in [_key_value, _trophy_value, _coin_value, _gem_value]:
		_style_reward_value(label)
	for icon_label in _rewards_row.find_children("*", "Label", true, false):
		if icon_label.name.ends_with("Icon"):
			_style_icon_label(icon_label as Label)
	_coin_summary.add_theme_font_size_override("font_size", 22)
	_style_cartoon_label(_coin_summary, 22)
	_coin_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


func _style_banner_text(label: Label) -> void:
	_style_cartoon_label(label, 48)
	label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.35))
	label.add_theme_color_override("font_outline_color", COLOR_GOLD_DARK)
	label.add_theme_constant_override("outline_size", 9)


func _style_cartoon_label(label: Label, font_size: int) -> void:
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", Color(0.05, 0.1, 0.2, 0.95))
	label.add_theme_constant_override("outline_size", 7)


func _style_reward_value(label: Label) -> void:
	_style_cartoon_label(label, 44)


func _style_icon_label(label: Label) -> void:
	label.add_theme_font_size_override("font_size", 58)


func _ribbon_style() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.92, 0.62, 0.12, 0.98)
	s.set_corner_radius_all(28)
	s.border_color = Color(0.55, 0.28, 0.05, 0.95)
	s.set_border_width_all(5)
	s.shadow_color = Color(0.25, 0.12, 0.02, 0.55)
	s.shadow_size = 10
	s.shadow_offset = Vector2(0, 5)
	return s


func _on_bonus_pressed() -> void:
	GameSettings.play_ui_click()
	bonus_reward_pressed.emit()


func _on_continue_pressed() -> void:
	GameSettings.play_ui_click()
	continue_pressed.emit()
