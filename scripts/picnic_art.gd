class_name PicnicArt
extends RefCounted

enum ItemType {
	COOKIE,
	TOMATO,
	CUPCAKE,
	SANDWICH,
	CHEESE,
	BREAD,
	SODA,
	CRATE,
	TABLE,
	STAND,
}


static func draw_item(canvas: CanvasItem, item_type: int, scale: float = 1.0) -> void:
	match item_type:
		ItemType.COOKIE:
			_draw_cookie(canvas, scale)
		ItemType.TOMATO:
			_draw_tomato(canvas, scale)
		ItemType.CUPCAKE:
			_draw_cupcake(canvas, scale)
		ItemType.SANDWICH:
			_draw_sandwich(canvas, scale)
		ItemType.CHEESE:
			_draw_cheese(canvas, scale)
		ItemType.BREAD:
			_draw_bread(canvas, scale)
		ItemType.SODA:
			_draw_soda(canvas, scale)
		ItemType.CRATE:
			_draw_crate(canvas, scale)
		ItemType.TABLE:
			_draw_table(canvas, scale)
		ItemType.STAND:
			_draw_stand(canvas, scale)
		_:
			_draw_cookie(canvas, scale)


static func visual_radius(item_type: int) -> float:
	match item_type:
		ItemType.COOKIE:
			return 16.0
		ItemType.TOMATO:
			return 17.0
		ItemType.SODA:
			return 18.0
		ItemType.CUPCAKE:
			return 22.0
		ItemType.CHEESE:
			return 24.0
		ItemType.BREAD:
			return 26.0
		ItemType.SANDWICH:
			return 28.0
		ItemType.CRATE:
			return 44.0
		ItemType.TABLE:
			return 68.0
		ItemType.STAND:
			return 62.0
		_:
			return 20.0


static func item_color(item_type: int) -> Color:
	match item_type:
		ItemType.COOKIE:
			return Color(0.82, 0.58, 0.34)
		ItemType.TOMATO:
			return Color(0.92, 0.32, 0.34)
		ItemType.CUPCAKE:
			return Color(0.95, 0.58, 0.74)
		ItemType.SANDWICH:
			return Color(0.96, 0.82, 0.45)
		ItemType.CHEESE:
			return Color(0.98, 0.85, 0.35)
		ItemType.BREAD:
			return Color(0.92, 0.72, 0.42)
		ItemType.SODA:
			return Color(0.5, 0.78, 0.95)
		ItemType.CRATE:
			return Color(0.62, 0.44, 0.28)
		ItemType.TABLE:
			return Color(0.55, 0.36, 0.22)
		ItemType.STAND:
			return Color(0.95, 0.55, 0.35)
		_:
			return Color.WHITE


static func display_name(item_type: int) -> String:
	match item_type:
		ItemType.COOKIE:
			return "Cookie"
		ItemType.TOMATO:
			return "Tomato"
		ItemType.CUPCAKE:
			return "Cupcake"
		ItemType.SANDWICH:
			return "Sandwich"
		ItemType.CHEESE:
			return "Cheese"
		ItemType.BREAD:
			return "Bread"
		ItemType.SODA:
			return "Soda"
		ItemType.CRATE:
			return "Crate"
		ItemType.TABLE:
			return "Table"
		ItemType.STAND:
			return "Stand"
		_:
			return "Item"


static func _draw_cookie(canvas: CanvasItem, s: float) -> void:
	canvas.draw_circle(Vector2.ZERO, 14.0 * s, Color(0.82, 0.58, 0.34))
	canvas.draw_circle(Vector2(-4.0 * s, -4.0 * s), 10.0 * s, Color(0.9, 0.66, 0.42))
	for p in [Vector2(-6.0, 2.0), Vector2(4.0, -5.0), Vector2(6.0, 4.0)]:
		canvas.draw_circle(p * s, 2.5 * s, Color(0.45, 0.28, 0.18))


static func _draw_tomato(canvas: CanvasItem, s: float) -> void:
	canvas.draw_circle(Vector2(0.0, 3.0 * s), 15.0 * s, Color(0.92, 0.3, 0.32))
	canvas.draw_circle(Vector2(-5.0 * s, -2.0 * s), 8.0 * s, Color(1.0, 0.45, 0.4))
	var leaf := PackedVector2Array([
		Vector2(0.0, -14.0) * s, Vector2(10.0, -22.0) * s, Vector2(4.0, -12.0) * s,
	])
	canvas.draw_colored_polygon(leaf, Color(0.38, 0.72, 0.38))


static func _draw_cupcake(canvas: CanvasItem, s: float) -> void:
	var cup := PackedVector2Array([
		Vector2(-14.0, 6.0) * s, Vector2(14.0, 6.0) * s,
		Vector2(10.0, 20.0) * s, Vector2(-10.0, 20.0) * s,
	])
	canvas.draw_colored_polygon(cup, Color(0.7, 0.46, 0.3))
	canvas.draw_circle(Vector2(0.0, -2.0 * s), 16.0 * s, Color(0.96, 0.58, 0.74))


static func _draw_sandwich(canvas: CanvasItem, s: float) -> void:
	canvas.draw_rect(Rect2(-26.0 * s, -8.0 * s, 52.0 * s, 16.0 * s), Color(0.96, 0.82, 0.45), true, 8.0 * s)
	canvas.draw_rect(Rect2(-22.0 * s, -2.0 * s, 44.0 * s, 6.0 * s), Color(0.35, 0.7, 0.35, 0.9), true, 4.0 * s)
	canvas.draw_rect(Rect2(-26.0 * s, 6.0 * s, 52.0 * s, 10.0 * s), Color(0.92, 0.72, 0.4), true, 6.0 * s)


static func _draw_cheese(canvas: CanvasItem, s: float) -> void:
	var wedge := PackedVector2Array([
		Vector2.ZERO, Vector2(0.0, -28.0) * s, Vector2(30.0, 8.0) * s,
	])
	canvas.draw_colored_polygon(wedge, Color(0.98, 0.85, 0.35))
	canvas.draw_circle(Vector2(8.0, -6.0) * s, 4.0 * s, Color(0.9, 0.75, 0.25))


static func _draw_bread(canvas: CanvasItem, s: float) -> void:
	canvas.draw_rect(Rect2(-24.0 * s, -12.0 * s, 48.0 * s, 24.0 * s), Color(0.92, 0.72, 0.42), true, 12.0 * s)
	canvas.draw_rect(Rect2(-18.0 * s, -8.0 * s, 36.0 * s, 10.0 * s), Color(0.98, 0.85, 0.55), true, 6.0 * s)


static func _draw_soda(canvas: CanvasItem, s: float) -> void:
	canvas.draw_rect(Rect2(-9.0 * s, -16.0 * s, 18.0 * s, 30.0 * s), Color(0.55, 0.82, 0.95, 0.9), true, 4.0 * s)
	canvas.draw_rect(Rect2(-11.0 * s, 10.0 * s, 22.0 * s, 7.0 * s), Color(0.4, 0.65, 0.82), true, 3.0 * s)
	canvas.draw_circle(Vector2(0.0, -18.0 * s), 7.0 * s, Color(0.95, 0.35, 0.35))


static func _draw_crate(canvas: CanvasItem, s: float) -> void:
	canvas.draw_rect(Rect2(-36.0 * s, -28.0 * s, 72.0 * s, 56.0 * s), Color(0.62, 0.44, 0.28), true, 4.0 * s)
	canvas.draw_line(Vector2(-36.0, -28.0) * s, Vector2(36.0, 28.0) * s, Color(0.48, 0.32, 0.2), 3.0 * s)
	canvas.draw_line(Vector2(-36.0, 28.0) * s, Vector2(36.0, -28.0) * s, Color(0.48, 0.32, 0.2), 3.0 * s)


static func _draw_table(canvas: CanvasItem, s: float) -> void:
	canvas.draw_rect(Rect2(-58.0 * s, -10.0 * s, 116.0 * s, 16.0 * s), Color(0.72, 0.48, 0.3), true, 4.0 * s)
	for x in [-44.0, 44.0]:
		canvas.draw_rect(Rect2(x * s - 7.0 * s, 6.0 * s, 14.0 * s, 42.0 * s), Color(0.52, 0.34, 0.2), true, 3.0 * s)


static func _draw_stand(canvas: CanvasItem, s: float) -> void:
	var awning := PackedVector2Array([
		Vector2(-50.0, -8.0) * s, Vector2(50.0, -8.0) * s,
		Vector2(42.0, -38.0) * s, Vector2(-42.0, -38.0) * s,
	])
	canvas.draw_colored_polygon(awning, Color(0.95, 0.45, 0.38))
	canvas.draw_rect(Rect2(-40.0 * s, -6.0 * s, 80.0 * s, 50.0 * s), Color(0.68, 0.46, 0.32), true, 4.0 * s)
	canvas.draw_rect(Rect2(-36.0 * s, 10.0 * s, 72.0 * s, 8.0 * s), Color(0.55, 0.36, 0.22), true, 3.0 * s)
	for x in [-28.0, 28.0]:
		canvas.draw_rect(Rect2(x * s - 5.0 * s, 18.0 * s, 10.0 * s, 28.0 * s), Color(0.48, 0.32, 0.2), true, 2.0 * s)
