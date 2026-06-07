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
	var hole_size := _hole.get_hole_size()

	draw_circle(Vector2.ZERO, r + 16.0, Color(0.75, 0.88, 1.0, 0.2))
	draw_arc(Vector2.ZERO, r + 3.0, 0.0, TAU, 64, Color(0.98, 0.99, 1.0), 6.0)
	draw_arc(Vector2.ZERO, r - 4.0, 0.0, TAU, 64, Color(0.4, 0.72, 0.98), 5.0)

	if _hole._swallow_pulse > 0.0:
		var sp: float = _hole._swallow_pulse
		var inner_r := r * 0.72
		draw_arc(Vector2.ZERO, inner_r + 6.0 + sp * 10.0, 0.0, TAU, 40, Color(0.55, 0.92, 1.0, 0.45 * sp), 3.0)

	_draw_size_indicator(hole_size, r)


func _draw_size_indicator(hole_size: int, r: float) -> void:
	var label_pos := Vector2(0.0, -r - 14.0)
	var bg_w := 12.0 + float(GameConstants.MAX_HOLE_SIZE) * 8.0
	var bg := Rect2(label_pos + Vector2(-bg_w * 0.5, -10.0), Vector2(bg_w, 20.0))
	draw_rect(bg, Color(0.12, 0.22, 0.38, 0.75), true, 8.0)
	var dot_count := GameConstants.MAX_HOLE_SIZE
	var span := float(dot_count - 1) * 8.0
	for i in dot_count:
		var filled := i < hole_size
		var c := Color(0.4, 0.85, 1.0, 0.95) if filled else Color(1.0, 1.0, 1.0, 0.25)
		draw_circle(label_pos + Vector2(-span * 0.5 + i * 8.0, 0.0), 3.0, c)
