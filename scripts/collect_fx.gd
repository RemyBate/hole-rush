class_name CollectFx
extends Node2D

var _particles: Array[Dictionary] = []
var _alive: float = 0.0


static func burst(parent: Node, world_position: Vector2, color: Color) -> void:
	var fx := CollectFx.new()
	fx.start(world_position, color, false)
	parent.add_child(fx)


static func swallow_sparks(parent: Node, world_position: Vector2, color: Color) -> void:
	if parent == null:
		return
	var fx := CollectFx.new()
	fx.start(world_position, color, true)
	parent.add_child(fx)


static func coin_sparkle(parent: Node, world_position: Vector2) -> void:
	if parent == null:
		return
	var fx := CollectFx.new()
	fx.start(world_position, Color(1.0, 0.88, 0.22, 1.0), false)
	parent.add_child(fx)
	swallow_sparks(parent, world_position, Color(1.0, 0.95, 0.55, 1.0))


func start(world_position: Vector2, color: Color, inward: bool = false) -> void:
	global_position = world_position
	z_index = 50
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var count := 14 if inward else 10
	for i in count:
		var angle := rng.randf() * TAU
		var dist := rng.randf_range(14.0, 32.0) if inward else 0.0
		var speed := rng.randf_range(60.0, 140.0) if inward else rng.randf_range(90.0, 200.0)
		var vel := Vector2(cos(angle), sin(angle))
		if inward:
			vel = -vel * speed
		else:
			vel *= speed
		_particles.append({
			"pos": vel.normalized() * dist if inward else Vector2.ZERO,
			"vel": vel,
			"life": rng.randf_range(0.18, 0.42) if inward else rng.randf_range(0.25, 0.5),
			"max_life": 0.45,
			"radius": rng.randf_range(2.0, 5.0) if inward else rng.randf_range(3.0, 7.0),
			"color": color.lightened(rng.randf_range(0.1, 0.45)),
		})
	_alive = 0.45 if inward else 0.55


func _process(delta: float) -> void:
	if _alive <= 0.0:
		queue_free()
		return
	_alive -= delta
	for p in _particles:
		p["life"] -= delta
		p["pos"] += p["vel"] * delta
		p["vel"] *= 0.92
		p["vel"].y += 260.0 * delta
	queue_redraw()


func _draw() -> void:
	for p in _particles:
		var life: float = p["life"]
		if life <= 0.0:
			continue
		var t: float = life / float(p["max_life"])
		var c: Color = p["color"]
		c.a = t
		var pos: Vector2 = p["pos"]
		var particle_radius: float = p["radius"]
		draw_circle(pos, particle_radius * t, c)
