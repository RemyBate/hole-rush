extends Node2D

var _hole: Hole


func _ready() -> void:
	_hole = get_parent() as Hole


func _process(_delta: float) -> void:
	if _hole != null:
		queue_redraw()


func _draw() -> void:
	if _hole == null:
		return
	var pulse := sin(_hole._pulse) * 2.5
	var r := _hole.radius + pulse

	DrawUtils.draw_soft_shadow(self, Vector2.ZERO, Vector2(r * 1.5, r * 0.65), 0.32, Vector2(6.0, 10.0))

	if _hole._blocked_flash > 0.0:
		var flash_a: float = _hole._blocked_flash / 0.35
		draw_arc(Vector2.ZERO, r + 12.0, 0.0, TAU, 48, Color(1.0, 0.38, 0.4, 0.6 * flash_a), 5.0)

	var inner_r := r * 0.72
	# Layered pit rings — deep hole illusion (items draw above this node).
	draw_circle(Vector2.ZERO, inner_r + 6.0, Color(0.12, 0.16, 0.22, 0.55))
	draw_circle(Vector2.ZERO, inner_r + 2.0, Color(0.08, 0.10, 0.14, 0.75))
	draw_circle(Vector2.ZERO, inner_r, Color(0.04, 0.05, 0.09, 0.92))
	draw_circle(Vector2.ZERO, inner_r * 0.78, Color(0.02, 0.025, 0.04, 0.96))
	draw_circle(Vector2.ZERO, inner_r * 0.52, Color(0.0, 0.0, 0.0, 0.98))

	if _hole._swallow_pulse > 0.0:
		var sp: float = _hole._swallow_pulse
		draw_arc(Vector2.ZERO, inner_r * 0.6, 0.0, TAU, 36, Color(0.15, 0.22, 0.32, 0.4 * sp), 4.0)
