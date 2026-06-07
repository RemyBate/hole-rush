class_name Hole
extends Area2D

signal item_collected

## Follow speed while dragging (higher = snappier).
@export var move_drag_smoothing: float = 26.0

var radius: float = GameConstants.INITIAL_HOLE_RADIUS
var _target_position: Vector2 = Vector2.ZERO
var _is_dragging: bool = false
var _paused: bool = false
var _play_bounds: Rect2 = Rect2()
var _pulse: float = 0.0
var _blocked_flash: float = 0.0
var _swallow_pulse: float = 0.0


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
	_redraw_visuals()


func set_play_bounds(bounds: Rect2) -> void:
	_play_bounds = bounds
	_target_position = _clamp_position(_target_position)
	global_position = _clamp_position(global_position)


func set_paused(value: bool) -> void:
	_paused = value


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

	_update_pointer_target()
	_target_position = _clamp_position(_target_position)

	var follow_t := 1.0 - exp(-move_drag_smoothing * _delta)
	global_position = _clamp_position(global_position.lerp(_target_position, follow_t))

	_collect_overlapping_food()


func _update_pointer_target() -> void:
	var follow := _is_dragging
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		follow = true
		_is_dragging = true
	if not follow:
		return
	_target_position = get_global_mouse_position()


func _collect_overlapping_food() -> void:
	for area in get_overlapping_areas():
		if area is Food:
			(area as Food).try_collect(self)
		elif area is CurrencyPickup:
			(area as CurrencyPickup).try_collect(self)


func _unhandled_input(event: InputEvent) -> void:
	if _paused:
		return
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		_is_dragging = touch.pressed
		if touch.pressed:
			_target_position = get_global_mouse_position()
	elif event is InputEventScreenDrag:
		_is_dragging = true
		_target_position = get_global_mouse_position()
	elif event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.button_index == MOUSE_BUTTON_LEFT:
			_is_dragging = mouse.pressed
			if mouse.pressed:
				_target_position = get_global_mouse_position()
	elif event is InputEventMouseMotion and _is_dragging:
		_target_position = get_global_mouse_position()


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
	var shape := $CollisionShape2D.shape as CircleShape2D
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
