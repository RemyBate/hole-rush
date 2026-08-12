class_name Hole
extends Area2D

signal item_collected

## Survives Android packaging so AAB inspection can prove this control model is present.
const CONTROL_POSITION_MOVEMENT_MARKER: String = "hole_control_position_absolute_v2"

## Extra world-space tweak applied after the automatic upward visibility offset.
## X = 0 keeps the hole centred above the control position; negative Y raises it further.
@export var pointer_visibility_offset: Vector2 = Vector2.ZERO
## Extra clear gap (world units) between the hole rim and the control-position contact pad.
@export var touch_visibility_margin: float = 14.0
## Approximate touch contact radius in viewport/screen pixels (converted once via canvas).
@export var touch_contact_radius_screen: float = 34.0
## Smaller desktop mouse contact radius in viewport/screen pixels.
@export var mouse_contact_radius_screen: float = 10.0

var radius: float = GameConstants.INITIAL_HOLE_RADIUS
var _target_position: Vector2 = Vector2.ZERO
var _is_dragging: bool = false
var _paused: bool = false
var _play_bounds: Rect2 = Rect2()
var _pulse: float = 0.0
var _blocked_flash: float = 0.0
var _swallow_pulse: float = 0.0

## Active control-position tracking (absolute screen/touch coords + fixed upward offset).
var _active_touch_index: int = -1
var _control_is_touch: bool = false


func _ready() -> void:
	add_to_group("hole")
	z_index = 8
	collision_layer = 1
	collision_mask = 2
	monitoring = true
	monitorable = false
	_target_position = global_position
	_apply_radius(radius)
	area_entered.connect(_on_area_entered)
	_redraw_visuals()


func setup(start_position: Vector2, bounds: Rect2) -> void:
	global_position = start_position
	_target_position = start_position
	_play_bounds = bounds
	radius = GameConstants.INITIAL_HOLE_RADIUS
	_apply_radius(radius)
	_is_dragging = false
	_active_touch_index = -1
	_control_is_touch = false
	_redraw_visuals()


func set_play_bounds(bounds: Rect2) -> void:
	_play_bounds = bounds
	_target_position = _clamp_position(_target_position)
	global_position = _clamp_position(global_position)


func set_paused(value: bool) -> void:
	_paused = value
	if value:
		_is_dragging = false
		_active_touch_index = -1
		_control_is_touch = false


func is_paused() -> bool:
	return _paused


## True when hole movement is driven by absolute control position + fixed upward offset
## (not relative deltas / smoothing). Used by export / regression checks.
func uses_absolute_control_position() -> bool:
	return CONTROL_POSITION_MOVEMENT_MARKER == "hole_control_position_absolute_v2"


func get_hole_size() -> int:
	if radius >= GameConstants.HOLE_SIZE_5_RADIUS:
		return 5
	if radius >= GameConstants.HOLE_SIZE_4_RADIUS:
		return 4
	if radius >= GameConstants.HOLE_SIZE_3_RADIUS:
		return 3
	if radius >= GameConstants.HOLE_SIZE_2_RADIUS:
		return 2
	return 1


func grow(amount: float) -> bool:
	var size_before := get_hole_size()
	radius = clampf(radius + amount, GameConstants.MIN_HOLE_RADIUS, GameConstants.MAX_HOLE_RADIUS)
	_apply_radius(radius)
	_redraw_visuals()
	var size_after := get_hole_size()
	if size_after > size_before:
		_play_size_up_feedback()
		return true
	return false


func _play_size_up_feedback() -> void:
	_pulse = 0.0
	var parent := get_parent()
	if parent:
		FloatingFeedback.spawn_text(parent, global_position + Vector2(0.0, -radius - 20.0), "Size Up!", Color(0.55, 0.95, 1.0))
		GrowFx.burst(parent, global_position)
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.12, 1.12), 0.1)
	tween.tween_property(self, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func pulse_blocked_feedback() -> void:
	_blocked_flash = 0.35


func pulse_swallow() -> void:
	_swallow_pulse = 1.0
	_pulse = 0.0


func _process(delta: float) -> void:
	_pulse += delta * 2.2
	if _blocked_flash > 0.0:
		_blocked_flash -= delta
	if _swallow_pulse > 0.0:
		_swallow_pulse -= delta * 2.8
	_redraw_visuals()


func _physics_process(_delta: float) -> void:
	if _paused:
		return
	# No smoothing / momentum: hole position equals the last clamped control-position target.
	_target_position = _clamp_position(_target_position)
	global_position = _target_position
	_collect_overlapping_food()


func _collect_overlapping_food() -> void:
	for area in get_overlapping_areas():
		if area is Food:
			(area as Food).try_collect(self)
		elif area is CurrencyPickup:
			(area as CurrencyPickup).try_collect(self)


func _unhandled_input(event: InputEvent) -> void:
	if _paused:
		return
	# HUD / Menu / Settings / Pause / popups mark input handled, so they never reach here.
	if event is InputEventScreenTouch:
		_handle_screen_touch(event as InputEventScreenTouch)
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		_handle_screen_drag(event as InputEventScreenDrag)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton:
		_handle_mouse_button(event as InputEventMouseButton)
	elif event is InputEventMouseMotion:
		_handle_mouse_motion(event as InputEventMouseMotion)


func _handle_screen_touch(touch: InputEventScreenTouch) -> void:
	if touch.pressed:
		if _active_touch_index >= 0 and touch.index != _active_touch_index:
			return
		_control_is_touch = true
		_active_touch_index = touch.index
		_is_dragging = true
		# Absolute control position + fixed upward offset (no relative-delta accumulation).
		set_from_control_position(touch.position, true)
	else:
		if touch.index == _active_touch_index:
			_active_touch_index = -1
			_is_dragging = false
			_control_is_touch = false


func _handle_screen_drag(drag: InputEventScreenDrag) -> void:
	if _active_touch_index >= 0 and drag.index != _active_touch_index:
		return
	if not _is_dragging:
		_control_is_touch = true
		_active_touch_index = drag.index
		_is_dragging = true
	set_from_control_position(drag.position, true)


func _handle_mouse_button(mouse: InputEventMouseButton) -> void:
	if mouse.button_index != MOUSE_BUTTON_LEFT:
		return
	# Touch is the authoritative control position while active — ignore emulated mouse.
	if _control_is_touch:
		return
	if mouse.pressed:
		_is_dragging = true
		set_from_control_position(mouse.position, false)
	else:
		_is_dragging = false


func _handle_mouse_motion(motion: InputEventMouseMotion) -> void:
	if not _is_dragging or _control_is_touch:
		return
	set_from_control_position(motion.position, false)


## Place the hole from the current absolute control position (mouse or active touch).
## hole_target = converted_control_position + upward_visibility_offset (then clamped).
func set_from_control_position(screen_pos: Vector2, is_touch: bool) -> void:
	var control_world := control_position_to_world(screen_pos)
	var offset := compute_visibility_offset_world(is_touch)
	_target_position = _clamp_position(control_world + offset)
	global_position = _target_position


## Viewport/screen control position → hole global/world space (single canvas inverse).
func control_position_to_world(screen_pos: Vector2) -> Vector2:
	return get_canvas_transform().affine_inverse() * screen_pos


## Fixed upward gap so the control position stays just below the hole centre.
## Uses current hole radius + contact pad (screen→world once) + touch_visibility_margin.
func compute_visibility_offset_world(is_touch: bool = true) -> Vector2:
	var contact_screen := touch_contact_radius_screen if is_touch else mouse_contact_radius_screen
	var contact_world := _screen_length_to_world(contact_screen)
	# Negative Y = above the control position so the centre stays visible.
	var offset_y := -(radius + contact_world + touch_visibility_margin) + pointer_visibility_offset.y
	return Vector2(pointer_visibility_offset.x, offset_y)


func _screen_length_to_world(screen_length: float) -> float:
	if screen_length <= 0.0:
		return 0.0
	var inv := get_canvas_transform().affine_inverse()
	return inv.basis_xform(Vector2(0.0, screen_length)).length()


func _on_area_entered(area: Area2D) -> void:
	if _paused:
		return
	if area is Food:
		(area as Food).try_collect(self)
	elif area is CurrencyPickup:
		(area as CurrencyPickup).try_collect(self)


func notify_collected() -> void:
	item_collected.emit()


func _apply_radius(new_radius: float) -> void:
	var shape_node := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape_node == null:
		return
	var shape := shape_node.shape as CircleShape2D
	if shape:
		shape.radius = new_radius


func _clamp_position(pos: Vector2) -> Vector2:
	if _play_bounds.size == Vector2.ZERO:
		return pos
	var min_pos := _play_bounds.position + Vector2(radius, radius)
	var max_pos := _play_bounds.position + _play_bounds.size - Vector2(radius, radius)
	return pos.clamp(min_pos, max_pos)


func _redraw_visuals() -> void:
	var pit := get_node_or_null("PitVisual")
	var rim := get_node_or_null("RimVisual")
	if pit:
		pit.queue_redraw()
	if rim:
		rim.queue_redraw()


func _draw() -> void:
	pass
