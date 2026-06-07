class_name GrowFx
extends Node2D

var _particles: Array[Dictionary] = []
var _alive: float = 0.0
var _ring_radius: float = 0.0
var _ring_max: float = 80.0


static func burst(parent: Node, world_position: Vector2) -> void:
	if parent == null:
		return
	var fx := GrowFx.new()
	fx.start(world_position)
	parent.add_child(fx)


func start(world_position: Vector2) -> void:
	global_position = world_position
	z_index = 60
	_ring_radius = 12.0
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in 18:
		var angle := rng.randf() * TAU
		var speed := rng.randf_range(120.0, 280.0)
		_particles.append({
			"pos": Vector2.ZERO,
			"vel": Vector2(cos(angle), sin(angle)) * speed,
			"life": rng.randf_range(0.35, 0.7),
			"max_life": 0.7,
			"radius": rng.randf_range(4.0, 9.0),
			"color": Color(0.45, 0.88, 1.0).lerp(Color(0.95, 0.98, 1.0), rng.randf()),
		})
	_alive = 0.75


func _process(delta: float) -> void:
	if _alive <= 0.0:
		queue_free()
		return
	_alive -= delta
	_ring_radius = lerpf(_ring_radius, _ring_max, delta * 5.0)
	for p in _particles:
		p["life"] -= delta
		p["pos"] += p["vel"] * delta
		p["vel"] *= 0.9
	queue_redraw()


func _draw() -> void:
	var ring_a: float = clampf(_alive / 0.75, 0.0, 1.0)
	draw_arc(Vector2.ZERO, _ring_radius, 0.0, TAU, 48, Color(0.5, 0.9, 1.0, 0.45 * ring_a), 4.0)
	draw_arc(Vector2.ZERO, _ring_radius * 0.65, 0.0, TAU, 40, Color(1.0, 1.0, 1.0, 0.25 * ring_a), 2.0)

	for p in _particles:
		var life: float = p["life"]
		if life <= 0.0:
			continue
		var t: float = life / float(p["max_life"])
		var c: Color = p["color"]
		c.a = t
		draw_circle(p["pos"], float(p["radius"]) * t, c)
