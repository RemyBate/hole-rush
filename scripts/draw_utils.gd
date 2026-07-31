class_name DrawUtils
extends RefCounted


static func draw_soft_shadow(
	canvas: CanvasItem,
	center: Vector2,
	size: Vector2,
	alpha: float = 0.22,
	offset: Vector2 = Vector2(4.0, 6.0)
) -> void:
	var shadow_color := Color(0.08, 0.1, 0.16, alpha)
	var steps := 3
	for i in steps:
		var t := float(i + 1) / float(steps)
		var spread := 1.0 + t * 0.18
		var spread_size := size * spread
		var layer_color := shadow_color
		layer_color.a = alpha * (1.0 - t * 0.35)
		canvas.draw_ellipse(
			center + offset * t,
			spread_size.x,
			spread_size.y,
			layer_color
		)


static func draw_rounded_panel(
	canvas: CanvasItem,
	rect: Rect2,
	fill: Color,
	border: Color = Color(1.0, 1.0, 1.0, 0.35),
	border_width: float = 3.0,
	_corner: float = 14.0
) -> void:
	# Godot draw_rect has no corner-radius arg; filled rects must omit width.
	canvas.draw_rect(rect, fill, true)
	if border_width > 0.0 and border.a > 0.0:
		canvas.draw_rect(rect, border, false, border_width)
