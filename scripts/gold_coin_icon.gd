extends Control


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _draw() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.44

	draw_circle(center + Vector2(2.0, 4.0), radius, Color(0.28, 0.14, 0.02, 0.45))
	draw_circle(center, radius, Color(0.98, 0.76, 0.12, 1.0))
	draw_circle(center + Vector2(-radius * 0.22, -radius * 0.28), radius * 0.38, Color(1.0, 0.92, 0.42, 0.5))
	draw_arc(center, radius * 0.52, -1.1, 1.1, 20, Color(0.82, 0.5, 0.06, 0.95), 4.0, true)
	draw_arc(center, radius + 2.0, 0.0, TAU, 48, Color(0.92, 0.62, 0.08, 0.85), 2.5, true)
