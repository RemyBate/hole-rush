extends Control


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _draw() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.38

	for ring in range(5, 0, -1):
		var glow_r := radius + float(ring) * 7.0
		var alpha := 0.08 + float(ring) * 0.05
		draw_circle(center, glow_r, Color(0.2, 0.55, 1.0, alpha))

	draw_circle(center, radius + 10.0, Color(0.12, 0.32, 0.72, 0.35))
	draw_arc(center, radius + 8.0, 0.0, TAU, 64, Color(0.45, 0.78, 1.0, 0.95), 4.0, true)
	draw_circle(center, radius * 0.94, Color(0.04, 0.06, 0.12, 1.0))
	draw_circle(center, radius * 0.72, Color(0.0, 0.0, 0.02, 1.0))
	draw_arc(center, radius * 0.82, -0.6, 2.4, 28, Color(0.18, 0.28, 0.5, 0.55), 3.0, true)
	draw_circle(center + Vector2(-radius * 0.28, -radius * 0.32), radius * 0.14, Color(0.55, 0.82, 1.0, 0.4))
