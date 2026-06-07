class_name Food
extends Area2D

signal collected(food: Food)

## Collectible slot 0–4 for the active level theme (see LevelTheme).
enum Collectible {
	A,
	B,
	C,
	D,
	E,
}

@export var item_type: Collectible = Collectible.A

var level_theme: int = LevelTheme.Id.FRUIT_GARDEN
var size_tier: int = ItemSizeTier.Tier.SMALL
var is_mission_highlight: bool = false
var score_value: int = 10

var _radius: float = 16.0
var _tier_visual_scale: float = 1.0
var _required_hole_size: int = 1
var _bob_phase: float = 0.0
var _collecting: bool = false
var _feedback_timer: float = 0.0
var _shake_offset: Vector2 = Vector2.ZERO
var _draw_scale: float = 1.0
var _draw_alpha: float = 1.0
var _draw_rotation: float = 0.0
var _fall_depth: float = 0.0

var _collect_hole: Hole = null
var _collect_elapsed: float = 0.0
var _collect_duration: float = 0.45
var _approach_duration: float = 0.18
var _inside_duration: float = 0.28
var _fade_duration: float = 0.14
var _collect_start_pos: Vector2 = Vector2.ZERO
var _collect_wobble_phase: float = 0.0
var _inside_hole: bool = false
var _sink_offset_y: float = 0.0


func _ready() -> void:
	add_to_group("food")
	collision_layer = 2
	collision_mask = 0
	_bob_phase = randf() * TAU
	queue_redraw()


func setup(
	position: Vector2,
	type: Collectible,
	theme: int,
	tier: int,
	mission_highlight: bool = false
) -> void:
	global_position = position
	item_type = type
	level_theme = theme
	size_tier = tier
	is_mission_highlight = mission_highlight

	_tier_visual_scale = ItemSizeTier.visual_scale(tier)
	_required_hole_size = ItemSizeTier.required_hole_size(tier)
	score_value = ItemSizeTier.score_value(tier)

	var slot := int(type)
	var base_r: float = CollectibleArt.visual_radius(theme, slot)
	var visual_r: float = base_r * _tier_visual_scale
	_radius = visual_r * 0.78

	var shape := $CollisionShape2D.shape as CircleShape2D
	if shape:
		shape.radius = _radius
	_draw_scale = 1.0
	_draw_alpha = 1.0
	modulate = Color.WHITE
	queue_redraw()


func get_collision_radius() -> float:
	return _radius


func get_required_hole_size() -> int:
	return _required_hole_size


func can_be_collected_by_hole_size(hole_size: int) -> bool:
	return hole_size >= _required_hole_size


func is_busy() -> bool:
	return _collecting


func try_collect(hole: Hole) -> bool:
	if _collecting:
		return false
	var hole_size := hole.get_hole_size()
	if not can_be_collected_by_hole_size(hole_size):
		if _feedback_timer <= 0.0:
			_show_too_large_feedback(hole)
		return false
	_start_collect_animation(hole)
	return true


func _start_collect_animation(hole: Hole) -> void:
	_collecting = true
	_collect_hole = hole
	_collect_elapsed = 0.0
	var phase_times := ItemSizeTier.collect_phase_times(size_tier)
	_approach_duration = phase_times.x
	_inside_duration = phase_times.y
	_fade_duration = 0.14
	_collect_duration = _approach_duration + _inside_duration + _fade_duration
	_collect_wobble_phase = randf() * TAU
	_inside_hole = false
	_sink_offset_y = 0.0
	_draw_rotation = randf_range(-0.3, 0.3)
	_fall_depth = 0.0
	_draw_scale = 1.0
	_draw_alpha = 1.0

	collision_layer = 0
	monitoring = false
	monitorable = false

	# Parent under hole: draws above black pit, below rim (item stays visible while falling in).
	var world_pos := global_position
	hole.add_child(self)
	global_position = world_pos
	_collect_start_pos = position
	z_index = 5


func _approach_curve(t: float) -> float:
	return t * t * (3.0 - 2.0 * t)


func _update_collect_animation(delta: float) -> void:
	if _collect_hole == null or not is_instance_valid(_collect_hole):
		_finish_collect()
		return

	_collect_elapsed += delta
	_inside_hole = false

	if _collect_elapsed < _approach_duration:
		_update_approach_phase(delta)
	elif _collect_elapsed < _approach_duration + _inside_duration:
		_update_inside_phase(delta)
	elif _collect_elapsed < _collect_duration:
		_update_fade_phase()
	else:
		_finish_collect()


func _update_approach_phase(delta: float) -> void:
	var at := clampf(_collect_elapsed / _approach_duration, 0.0, 1.0)
	var suction := _approach_curve(at)
	_fall_depth = suction * 0.25

	_collect_wobble_phase += delta * 11.0
	var wobble_amp := (1.0 - suction) * (8.0 + float(size_tier) * 1.5)
	var wobble := Vector2(cos(_collect_wobble_phase), sin(_collect_wobble_phase * 1.15)) * wobble_amp
	position = _collect_start_pos.lerp(Vector2.ZERO, suction) + wobble

	_draw_scale = 1.0
	_draw_alpha = 1.0
	_sink_offset_y = lerpf(0.0, 6.0, suction)


func _update_inside_phase(delta: float) -> void:
	_inside_hole = true
	var it := clampf(
		(_collect_elapsed - _approach_duration) / _inside_duration, 0.0, 1.0
	)
	_fall_depth = lerpf(0.25, 1.0, it)

	_collect_wobble_phase += delta * 5.0
	var wobble := Vector2(cos(_collect_wobble_phase), sin(_collect_wobble_phase * 1.1)) * (2.5 * (1.0 - it))
	position = wobble

	_draw_rotation += delta * (2.0 + float(size_tier) * 0.35)
	# Stay large and readable while sitting inside the pit.
	_draw_scale = lerpf(1.0, 0.42, it * 0.75)
	_draw_alpha = 1.0
	_sink_offset_y = lerpf(6.0, 24.0 + float(size_tier) * 2.0, it)


func _update_fade_phase() -> void:
	_inside_hole = true
	var ft := clampf(
		(_collect_elapsed - _approach_duration - _inside_duration) / _fade_duration, 0.0, 1.0
	)
	_fall_depth = 1.0
	position = Vector2.ZERO
	var scale_inside_end := lerpf(1.0, 0.42, 0.75)
	_sink_offset_y = lerpf(_sink_offset_y, 28.0 + float(size_tier) * 2.0, ft)
	_draw_scale = lerpf(scale_inside_end, 0.0, ft * ft)
	_draw_alpha = lerpf(1.0, 0.0, ft)


func _finish_collect() -> void:
	if _collect_hole != null and is_instance_valid(_collect_hole):
		_collect_hole.pulse_swallow()

	GameSettings.play_sfx()
	GameSettings.vibrate(30)
	collected.emit(self)
	queue_free()


func _show_too_large_feedback(hole: Hole) -> void:
	_feedback_timer = GameConstants.TOO_LARGE_FEEDBACK_DURATION
	hole.pulse_blocked_feedback()
	var parent := get_parent()
	if parent:
		FloatingFeedback.spawn_text(
			parent,
			global_position + Vector2(0.0, -_radius - 18.0),
			"Need Bigger Hole",
			Color(1.0, 0.55, 0.45)
		)
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color(1.0, 0.5, 0.45), 0.06)
	tween.tween_property(self, "modulate", Color.WHITE, 0.1)
	for i in 2:
		tween.tween_property(self, "_shake_offset", Vector2(4.0, 0.0), 0.035)
		tween.tween_property(self, "_shake_offset", Vector2(-4.0, 0.0), 0.035)
	tween.tween_property(self, "_shake_offset", Vector2.ZERO, 0.03)


func _process(delta: float) -> void:
	if _collecting:
		_update_collect_animation(delta)
		queue_redraw()
		return
	_bob_phase += delta * 2.0
	if _feedback_timer > 0.0:
		_feedback_timer -= delta
	queue_redraw()


func _draw() -> void:
	var slot := int(item_type)
	var base_r: float = CollectibleArt.visual_radius(level_theme, slot)
	var visual_r: float = base_r * _tier_visual_scale
	var bob := sin(_bob_phase) * 2.0 if not _collecting else 0.0
	var origin := _shake_offset + Vector2(0.0, bob)
	var draw_scale := _draw_scale

	if _collecting:
		origin.y += _sink_offset_y
		var depth := _fall_depth
		if not _inside_hole:
			DrawUtils.draw_soft_shadow(
				self, origin + Vector2(0.0, 6.0),
				Vector2(visual_r * 1.25, visual_r * 0.48) * draw_scale, 0.2
			)
	else:
		DrawUtils.draw_soft_shadow(
			self, origin, Vector2(visual_r * 1.2, visual_r * 0.45) * draw_scale, 0.22
		)

	if _feedback_timer > 0.0 and not _collecting:
		var pulse: float = 0.5 + sin(_feedback_timer * 20.0) * 0.5
		draw_arc(
			origin, visual_r * draw_scale + 6.0, 0.0, TAU, 32,
			Color(1.0, 0.4, 0.35, 0.5 * pulse), 3.0
		)

	if is_mission_highlight and not _collecting:
		var mission_pulse: float = 0.65 + sin(_bob_phase * 1.4) * 0.35
		draw_arc(
			origin, visual_r * draw_scale + 10.0, 0.0, TAU, 36,
			Color(1.0, 0.92, 0.25, 0.75 * mission_pulse), 4.0
		)
		draw_arc(
			origin, visual_r * draw_scale + 14.0, 0.0, TAU, 36,
			Color(1.0, 1.0, 1.0, 0.25 * mission_pulse), 2.0
		)

	var prev_modulate := modulate
	modulate = Color(prev_modulate.r, prev_modulate.g, prev_modulate.b, prev_modulate.a * _draw_alpha)

	if _draw_scale > 0.01 and _draw_alpha > 0.02:
		draw_set_transform(origin, _draw_rotation, Vector2(draw_scale, draw_scale))
		CollectibleArt.draw_item(self, level_theme, slot, _tier_visual_scale)
		if _inside_hole:
			var rim_r: float = visual_r * draw_scale + 5.0
			draw_arc(Vector2.ZERO, rim_r, 0.0, TAU, 32, Color(1.0, 1.0, 1.0, 0.35 * _draw_alpha), 2.5)
			draw_arc(Vector2.ZERO, rim_r + 2.0, 0.0, TAU, 32, Color(0.55, 0.85, 1.0, 0.22 * _draw_alpha), 1.5)
		elif not _collecting:
			_draw_size_badge(Vector2.ZERO, visual_r)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	modulate = prev_modulate


func _draw_size_badge(origin: Vector2, visual_r: float) -> void:
	var tier_colors := [
		Color(0.55, 0.95, 0.65, 0.45),
		Color(0.65, 0.92, 0.72, 0.45),
		Color(0.98, 0.85, 0.4, 0.5),
		Color(0.95, 0.55, 0.35, 0.5),
		Color(0.92, 0.42, 0.38, 0.55),
		Color(0.88, 0.35, 0.95, 0.6),
	]
	var idx := clampi(size_tier, 0, tier_colors.size() - 1)
	draw_arc(origin, visual_r + 3.0, 0.0, TAU, 28, tier_colors[idx], 2.0)
