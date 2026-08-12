class_name CurrencyPickup
extends Area2D

signal collected(pickup: CurrencyPickup)

var pickup_kind: CurrencyArt.Kind = CurrencyArt.Kind.COIN
var gem_color: int = 0

var _radius: float = 14.0
var _bob_phase: float = 0.0
var _collecting: bool = false
var _collect_elapsed: float = 0.0
var _collect_duration: float = 0.32
var _collect_hole: Hole = null
var _collect_start: Vector2 = Vector2.ZERO
var _draw_scale: float = 1.0
var _draw_alpha: float = 1.0
var _playfield_blocked: bool = false
var _collection_finalized: bool = false


func _ready() -> void:
	add_to_group("currency")
	collision_layer = 2
	collision_mask = 0
	_bob_phase = randf() * TAU
	queue_redraw()


func set_playfield_blocked(blocked: bool) -> void:
	if _collecting:
		return
	if _playfield_blocked == blocked:
		return
	_playfield_blocked = blocked
	visible = not blocked
	monitoring = not blocked
	monitorable = not blocked
	collision_layer = 0 if blocked else 2


func get_visual_radius() -> float:
	return _radius


func setup(position: Vector2, kind: CurrencyArt.Kind, gem_color_index: int = 0) -> void:
	global_position = position
	pickup_kind = kind
	gem_color = gem_color_index
	_radius = CurrencyArt.pickup_radius(kind)
	var shape := $CollisionShape2D.shape as CircleShape2D
	if shape:
		shape.radius = _radius * 0.82
	queue_redraw()


func get_collision_radius() -> float:
	return _radius


func is_busy() -> bool:
	return _collecting


func try_collect(hole: Hole) -> bool:
	if _collecting or _playfield_blocked:
		return false
	# Match food swallow rule: hole radius must cover the pickup's visual size.
	var need := _radius * GameConstants.SWALLOW_FIT_RATIO
	if pickup_kind == CurrencyArt.Kind.KEY or pickup_kind == CurrencyArt.Kind.TROPHY:
		need = maxf(need, GameConstants.HOLE_SIZE_2_RADIUS * 0.85)
	if hole.radius < need:
		return false
	_start_collect(hole)
	return true


func _start_collect(hole: Hole) -> void:
	_collecting = true
	_collection_finalized = false
	_collect_hole = hole
	_collect_elapsed = 0.0
	collision_layer = 0
	# Defer physics flag / reparent — area_entered runs while queries are flushing.
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	call_deferred("_attach_to_hole_for_swallow")


func _attach_to_hole_for_swallow() -> void:
	if not _collecting or _collect_hole == null or not is_instance_valid(_collect_hole):
		return
	if get_parent() == _collect_hole:
		return
	var world_pos := global_position
	reparent(_collect_hole)
	global_position = world_pos
	_collect_start = position
	z_index = 5


func _process(delta: float) -> void:
	if _collecting:
		if _collect_hole != null and is_instance_valid(_collect_hole) and _collect_hole.is_paused():
			queue_redraw()
			return
		_collect_elapsed += delta
		var t := clampf(_collect_elapsed / _collect_duration, 0.0, 1.0)
		var eased := t * t * (3.0 - 2.0 * t)
		position = _collect_start.lerp(Vector2.ZERO, eased)
		_draw_scale = lerpf(1.0, 0.2, eased)
		_draw_alpha = lerpf(1.0, 0.0, maxf(0.0, (t - 0.55) / 0.45))
		if _collect_elapsed >= _collect_duration:
			_finish_collect()
		queue_redraw()
		return
	_bob_phase += delta * 2.8
	queue_redraw()


func _finish_collect() -> void:
	if _collection_finalized:
		return
	_collection_finalized = true
	if _collect_hole != null and is_instance_valid(_collect_hole):
		_collect_hole.pulse_swallow()
	collected.emit(self)
	queue_free()


func _draw() -> void:
	var bob := sin(_bob_phase) * 2.5 if not _collecting else 0.0
	var origin := Vector2(0.0, bob)
	if not _collecting:
		DrawUtils.draw_soft_shadow(self, origin, Vector2(_radius * 1.1, _radius * 0.42), 0.2)
	var prev := modulate
	modulate = Color(prev.r, prev.g, prev.b, prev.a * _draw_alpha)
	draw_set_transform(origin, 0.0, Vector2(_draw_scale, _draw_scale))
	if pickup_kind == CurrencyArt.Kind.COIN:
		CurrencyArt.draw_coin(self, _draw_scale, _bob_phase)
	else:
		CurrencyArt.draw_pickup(self, pickup_kind, gem_color, _bob_phase, _draw_scale)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	modulate = prev
