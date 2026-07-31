class_name CurrencyArt
extends RefCounted

enum Kind { COIN, GEM, KEY, TROPHY }

const GEM_COLORS: Array[Color] = [
	Color(0.35, 0.55, 0.98, 1.0),
	Color(0.32, 0.82, 0.42, 1.0),
	Color(0.95, 0.32, 0.38, 1.0),
	Color(0.72, 0.38, 0.95, 1.0),
]


static func draw_pickup(canvas: CanvasItem, kind: int, gem_color: int, bob_phase: float, scale: float = 1.0) -> void:
	match kind:
		Kind.COIN:
			draw_coin(canvas, scale, bob_phase)
		Kind.GEM:
			draw_gem(canvas, gem_color, bob_phase, scale)
		Kind.KEY:
			draw_key(canvas, scale)
		Kind.TROPHY:
			draw_trophy(canvas, scale)


static func pickup_radius(kind: int) -> float:
	match kind:
		Kind.COIN:
			return 14.0
		Kind.GEM:
			return 16.0
		Kind.KEY:
			return 17.0
		Kind.TROPHY:
			return 18.0
		_:
			return 14.0


static func draw_coin(canvas: CanvasItem, scale: float = 1.0, bob_phase: float = 0.0) -> void:
	var r := 14.0 * scale
	DrawUtils.draw_soft_shadow(canvas, Vector2(0, 3), Vector2(r * 1.3, r * 0.5), 0.24)
	canvas.draw_circle(Vector2(0, 0), r, Color(0.92, 0.68, 0.12, 1.0))
	canvas.draw_circle(Vector2(0, 0), r - 2.0, Color(1.0, 0.86, 0.22, 1.0))
	canvas.draw_arc(Vector2(0, 0), r - 1.0, -0.8, 0.5, 16, Color(1.0, 0.98, 0.7, 0.65), 2.5)
	var shine := 0.5 + sin(bob_phase * 1.6) * 0.5
	if shine > 0.82:
		var sparkle_a := (shine - 0.82) / 0.18
		canvas.draw_circle(Vector2(-r * 0.35, -r * 0.38), 4.5 * scale, Color(1.0, 1.0, 0.95, 0.85 * sparkle_a))
		canvas.draw_circle(Vector2(r * 0.22, -r * 0.12), 2.5 * scale, Color(1.0, 0.95, 0.6, 0.7 * sparkle_a))
		canvas.draw_arc(Vector2(0, 0), r + 1.5, bob_phase * 0.4, bob_phase * 0.4 + 0.9, 8, Color(1.0, 0.98, 0.75, 0.55 * sparkle_a), 2.0, true)
	var font := ThemeDB.fallback_font
	var font_size := 16
	canvas.draw_string(
		font, Vector2(-5, 6), "$", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size,
		Color(0.72, 0.42, 0.05, 1.0)
	)


static func draw_gem(canvas: CanvasItem, color_index: int, bob_phase: float, scale: float = 1.0) -> void:
	var r := 16.0 * scale
	var base := GEM_COLORS[color_index % GEM_COLORS.size()]
	var sparkle := 0.55 + sin(bob_phase * 2.2) * 0.45
	DrawUtils.draw_soft_shadow(canvas, Vector2(0, 4), Vector2(r * 1.1, r * 0.45), 0.22)
	var points := PackedVector2Array([
		Vector2(0, -r),
		Vector2(r * 0.72, 0),
		Vector2(0, r),
		Vector2(-r * 0.72, 0),
	])
	canvas.draw_colored_polygon(points, base.darkened(0.15))
	canvas.draw_polyline(points + PackedVector2Array([points[0]]), Color(1, 1, 1, 0.55), 2.0)
	canvas.draw_circle(Vector2(-r * 0.2, -r * 0.25), 3.5, Color(1, 1, 1, 0.75 * sparkle))
	canvas.draw_circle(Vector2(r * 0.15, r * 0.1), 2.0, Color(1, 1, 1, 0.5 * sparkle))


static func draw_key(canvas: CanvasItem, scale: float = 1.0) -> void:
	DrawUtils.draw_soft_shadow(canvas, Vector2(0, 4), Vector2(20.0, 8.5), 0.22)
	canvas.draw_circle(Vector2(-5, -4), 7.0, Color(1.0, 0.82, 0.2, 1.0))
	canvas.draw_circle(Vector2(-5, -4), 4.0, Color(0.95, 0.35, 0.4, 1.0))
	canvas.draw_rect(Rect2(-2, -2, 16, 5), Color(1.0, 0.88, 0.25, 1.0), true)
	canvas.draw_rect(Rect2(12, -1, 4, 3), Color(1.0, 0.88, 0.25, 1.0), true)
	canvas.draw_rect(Rect2(12, 4, 4, 3), Color(1.0, 0.88, 0.25, 1.0), true)


static func draw_trophy(canvas: CanvasItem, scale: float = 1.0) -> void:
	DrawUtils.draw_soft_shadow(canvas, Vector2(0, 5), Vector2(22.0, 9.0), 0.22)
	canvas.draw_rect(Rect2(-10, 6, 20, 5), Color(0.85, 0.55, 0.12, 1.0), true)
	canvas.draw_rect(Rect2(-6, 10, 12, 3), Color(0.72, 0.42, 0.08, 1.0), true)
	var cup := PackedVector2Array([
		Vector2(-12, 6), Vector2(-10, -8), Vector2(0, -12), Vector2(10, -8), Vector2(12, 6),
	])
	canvas.draw_colored_polygon(cup, Color(1.0, 0.82, 0.2, 1.0))
	canvas.draw_polyline(cup + PackedVector2Array([cup[0]]), Color(1.0, 0.95, 0.65, 0.8), 2.0)
