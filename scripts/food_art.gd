class_name FoodArt
extends RefCounted


static func draw_food(canvas: CanvasItem, food_type: int, scale: float = 1.0) -> void:
	var s := scale
	match food_type:
		0:
			_draw_apple(canvas, s)
		1:
			_draw_donut(canvas, s)
		2:
			_draw_pizza(canvas, s)
		3:
			_draw_cupcake(canvas, s)
		4:
			_draw_hotdog(canvas, s)
		_:
			_draw_cookie(canvas, s)


static func visual_radius(food_type: int, scale: float = 1.0) -> float:
	match food_type:
		0:
			return 34.0 * scale
		1:
			return 36.0 * scale
		2:
			return 38.0 * scale
		3:
			return 34.0 * scale
		4:
			return 40.0 * scale
		_:
			return 32.0 * scale
	return 34.0 * scale


static func _draw_apple(canvas: CanvasItem, s: float) -> void:
	var body_r := 26.0 * s
	canvas.draw_circle(Vector2(0.0, 4.0 * s), body_r, Color(0.92, 0.28, 0.32))
	canvas.draw_circle(Vector2(-10.0 * s, -6.0 * s), body_r * 0.55, Color(1.0, 0.38, 0.4))
	canvas.draw_circle(Vector2(8.0 * s, 10.0 * s), 7.0 * s, Color(1.0, 0.55, 0.5, 0.55))
	var leaf := PackedVector2Array([
		Vector2(2.0, -24.0) * s,
		Vector2(16.0, -34.0) * s,
		Vector2(8.0, -18.0) * s,
	])
	canvas.draw_colored_polygon(leaf, Color(0.35, 0.78, 0.38))
	canvas.draw_line(Vector2(0.0, -20.0 * s), Vector2(4.0, -30.0) * s, Color(0.45, 0.3, 0.2), 3.0 * s)


static func _draw_donut(canvas: CanvasItem, s: float) -> void:
	var outer := 34.0 * s
	var inner := 14.0 * s
	var ring_width := outer - inner
	canvas.draw_arc(Vector2.ZERO, (outer + inner) * 0.5, 0.0, TAU, 48, Color(0.96, 0.78, 0.45), ring_width)
	canvas.draw_arc(Vector2.ZERO, (outer + inner) * 0.5, 0.0, TAU, 48, Color(0.92, 0.62, 0.78), ring_width - 6.0 * s)
	canvas.draw_arc(Vector2.ZERO, outer, 0.0, TAU, 48, Color(0.85, 0.5, 0.65), 5.0 * s)
	canvas.draw_circle(Vector2(-8.0 * s, -10.0 * s), 5.0 * s, Color(1.0, 0.95, 0.98, 0.7))


static func _draw_pizza(canvas: CanvasItem, s: float) -> void:
	var slice := PackedVector2Array([
		Vector2.ZERO,
		Vector2(0.0, -42.0) * s,
		Vector2(38.0, 18.0) * s,
	])
	canvas.draw_colored_polygon(slice, Color(0.98, 0.82, 0.38))
	canvas.draw_polyline(
		PackedVector2Array([Vector2.ZERO, Vector2(0.0, -42.0) * s, Vector2(38.0, 18.0) * s, Vector2.ZERO]),
		Color(0.82, 0.55, 0.22),
		4.0 * s
	)
	for p in [Vector2(-4.0, -18.0), Vector2(12.0, -8.0), Vector2(18.0, 8.0), Vector2(-2.0, 6.0)]:
		canvas.draw_circle(p * s, 5.0 * s, Color(0.88, 0.22, 0.28))
	canvas.draw_circle(Vector2(6.0, -6.0) * s, 7.0 * s, Color(0.3, 0.72, 0.32))


static func _draw_cupcake(canvas: CanvasItem, s: float) -> void:
	var cup := PackedVector2Array([
		Vector2(-22.0, 12.0) * s,
		Vector2(22.0, 12.0) * s,
		Vector2(16.0, 32.0) * s,
		Vector2(-16.0, 32.0) * s,
	])
	canvas.draw_colored_polygon(cup, Color(0.72, 0.48, 0.32))
	canvas.draw_line(Vector2(-14.0, 18.0) * s, Vector2(14.0, 18.0) * s, Color(0.55, 0.35, 0.22), 2.0 * s)
	canvas.draw_circle(Vector2(0.0, -2.0 * s), 24.0 * s, Color(0.95, 0.55, 0.72))
	canvas.draw_circle(Vector2(-8.0 * s, -10.0 * s), 8.0 * s, Color(1.0, 0.7, 0.82, 0.65))
	canvas.draw_circle(Vector2(10.0, -16.0) * s, 6.0 * s, Color(0.98, 0.25, 0.45))


static func _draw_hotdog(canvas: CanvasItem, s: float) -> void:
	var bun := Color(0.96, 0.82, 0.48)
	canvas.draw_circle(Vector2(-24.0, 0.0) * s, 18.0 * s, bun)
	canvas.draw_circle(Vector2(24.0, 0.0) * s, 18.0 * s, bun)
	canvas.draw_rect(Rect2(-26.0 * s, -12.0 * s, 52.0 * s, 24.0 * s), bun, true, 12.0 * s)
	canvas.draw_rect(Rect2(-20.0 * s, -7.0 * s, 40.0 * s, 14.0 * s), Color(0.82, 0.32, 0.28), true, 8.0 * s)
	canvas.draw_circle(Vector2(-18.0, -4.0) * s, 3.0 * s, Color(0.95, 0.7, 0.5))
	canvas.draw_circle(Vector2(16.0, 4.0) * s, 3.0 * s, Color(0.95, 0.7, 0.5))


static func _draw_cookie(canvas: CanvasItem, s: float) -> void:
	canvas.draw_circle(Vector2.ZERO, 30.0 * s, Color(0.82, 0.58, 0.34))
	canvas.draw_circle(Vector2(-8.0 * s, -8.0 * s), 26.0 * s, Color(0.9, 0.66, 0.42))
	for p in [
		Vector2(-12.0, -6.0), Vector2(10.0, -12.0), Vector2(14.0, 8.0),
		Vector2(-6.0, 14.0), Vector2(-16.0, 10.0)
	]:
		canvas.draw_circle(p * s, 4.0 * s, Color(0.45, 0.28, 0.18))
