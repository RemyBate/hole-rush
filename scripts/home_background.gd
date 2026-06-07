extends Node2D

var _phase: float = 0.0


func _process(delta: float) -> void:
	_phase += delta
	queue_redraw()


func _draw() -> void:
	var w := get_viewport_rect().size.x
	var h := get_viewport_rect().size.y

	# Deep ocean gradient.
	for i in 32:
		var t := float(i) / 31.0
		var y0 := t * h
		var y1 := (float(i + 1) / 31.0) * h
		var top := Color(0.18, 0.58, 0.88, 1.0)
		var mid := Color(0.08, 0.32, 0.62, 1.0)
		var bot := Color(0.03, 0.14, 0.34, 1.0)
		var col := top.lerp(mid, clampf(t * 2.0, 0.0, 1.0)).lerp(bot, clampf((t - 0.5) * 2.0, 0.0, 1.0))
		draw_rect(Rect2(0, y0, w, y1 - y0 + 1.0), col)

	# God rays.
	for i in 6:
		var x := w * (0.1 + float(i) * 0.15)
		var alpha := 0.05 + sin(_phase * 0.35 + float(i)) * 0.02
		draw_colored_polygon(
			PackedVector2Array([
				Vector2(x - 50, 0), Vector2(x + 50, 0),
				Vector2(x + 140, h * 0.7), Vector2(x - 140, h * 0.7),
			]),
			Color(1, 1, 1, alpha)
		)

	# Distant volcano silhouette.
	var vol_x := w * 0.78
	var vol_y := h * 0.28
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(vol_x, vol_y + 80), Vector2(vol_x - 90, vol_y + 80), Vector2(vol_x - 20, vol_y),
			Vector2(vol_x + 40, vol_y - 30), Vector2(vol_x + 100, vol_y + 80),
		]),
		Color(0.02, 0.08, 0.18, 0.5)
	)

	# Pirate ship (mid-depth).
	_draw_ship(Vector2(w * 0.58, h * 0.38), 1.0)

	# Coral clusters.
	_draw_coral(Vector2(w * 0.12, h * 0.68), Color(0.95, 0.35, 0.45))
	_draw_coral(Vector2(w * 0.88, h * 0.64), Color(0.55, 0.82, 0.95))
	_draw_coral(Vector2(w * 0.72, h * 0.72), Color(0.98, 0.55, 0.32))

	# Sandy seabed with depth.
	var sand_y := h * 0.74
	draw_rect(Rect2(0, sand_y, w, h - sand_y), Color(0.86, 0.72, 0.5, 1.0))
	draw_rect(Rect2(0, sand_y, w, 36), Color(0.7, 0.55, 0.36, 0.9), true, 10.0)
	for i in 10:
		var rx := w * (0.05 + float(i) * 0.1)
		draw_circle(Vector2(rx, sand_y + 28 + sin(float(i)) * 8), 14 + float(i % 4) * 4, Color(0.55, 0.48, 0.4, 0.65))

	# Treasure chest + coins pile.
	_draw_treasure(Vector2(w * 0.5, sand_y + 62))

	# Floating coins in water.
	for i in 8:
		var cx := w * (0.15 + float(i) * 0.1) + sin(_phase * 1.2 + i) * 12.0
		var cy := h * (0.55 + float(i) * 0.02) + cos(_phase + i * 0.7) * 8.0
		_draw_coin_icon(Vector2(cx, cy), 10.0 + float(i % 3) * 2.0)

	# Bubbles (many layers).
	for i in 35:
		var bx := fmod(float(i) * 83.0 + _phase * (18.0 + float(i % 5)), w)
		var by := h - fmod(float(i) * 47.0 + _phase * (14.0 + float(i % 4)), h * 0.75)
		var br := 2.0 + float(i % 6)
		var ba := 0.12 + float(i % 3) * 0.06
		draw_circle(Vector2(bx, by), br, Color(1, 1, 1, ba))
		draw_arc(Vector2(bx, by), br, -0.5, 2.0, 10, Color(1, 1, 1, ba + 0.15), 1.2)

	# Fish schools.
	for i in 5:
		var fx := w * (0.18 + float(i) * 0.16) + sin(_phase * 0.9 + i * 1.3) * 40.0
		var fy := h * (0.32 + float(i) * 0.07)
		_draw_fish(Vector2(fx, fy), Color(1.0, 0.45 + float(i) * 0.08, 0.25, 0.8), 12.0 + float(i) * 2.0)


func _draw_ship(pos: Vector2, scale: float) -> void:
	var hull := Color(0.42, 0.22, 0.12, 0.92)
	draw_rect(Rect2(pos.x - 90 * scale, pos.y, 180 * scale, 28 * scale), hull, true, 6.0)
	draw_colored_polygon(
		PackedVector2Array([
			pos + Vector2(-95 * scale, 0),
			pos + Vector2(-70 * scale, -55 * scale),
			pos + Vector2(20 * scale, -70 * scale),
			pos + Vector2(95 * scale, 0),
		]),
		Color(0.55, 0.28, 0.14, 0.9)
	)
	draw_rect(Rect2(pos.x + 30 * scale, pos.y - 85 * scale, 12 * scale, 90 * scale), Color(0.38, 0.2, 0.1, 0.85), true, 3.0)
	draw_rect(Rect2(pos.x + 55 * scale, pos.y - 70 * scale, 10 * scale, 75 * scale), Color(0.38, 0.2, 0.1, 0.8), true, 3.0)
	# Sail.
	draw_colored_polygon(
		PackedVector2Array([
			pos + Vector2(10 * scale, -68 * scale),
			pos + Vector2(10 * scale, -140 * scale),
			pos + Vector2(55 * scale, -95 * scale),
		]),
		Color(0.95, 0.95, 0.98, 0.75)
	)


func _draw_coral(pos: Vector2, col: Color) -> void:
	for i in 4:
		var angle := float(i) * 0.8 - 1.2
		var tip := pos + Vector2(cos(angle), sin(angle)) * (28.0 + float(i) * 6.0)
		draw_line(pos, tip, col.darkened(0.1), 6.0)
		draw_circle(tip, 7.0, col)
	draw_circle(pos, 10.0, col.lightened(0.15))


func _draw_treasure(pos: Vector2) -> void:
	# Chest.
	draw_rect(Rect2(pos.x - 58, pos.y - 6, 116, 52), Color(0.5, 0.3, 0.12, 1.0), true, 8.0)
	draw_rect(Rect2(pos.x - 62, pos.y - 40, 124, 36), Color(0.62, 0.38, 0.15, 1.0), true, 10.0)
	draw_arc(pos + Vector2(0, -22), 32, PI, 0.0, 28, Color(0.72, 0.45, 0.18), 7.0)
	draw_rect(Rect2(pos.x - 8, pos.y - 18, 16, 22), Color(0.35, 0.2, 0.08), true, 3.0)
	# Coin pile.
	for i in 10:
		_draw_coin_icon(pos + Vector2(-48 + i * 11 + (i % 2) * 4, 8 - (i % 3) * 5), 11.0)


func _draw_coin_icon(center: Vector2, radius: float) -> void:
	draw_circle(center + Vector2(2, 3), radius, Color(0, 0, 0, 0.2))
	draw_circle(center, radius, Color(0.92, 0.68, 0.12, 1.0))
	draw_circle(center, radius - 2.0, Color(1.0, 0.88, 0.28, 1.0))
	draw_arc(center, radius - 1.0, -0.6, 0.5, 14, Color(1.0, 0.98, 0.7, 0.7), 2.0)


func _draw_fish(pos: Vector2, col: Color, size: float) -> void:
	draw_set_transform(pos, 0, Vector2(1.4, 0.8))
	draw_circle(Vector2.ZERO, size, col)
	draw_circle(Vector2(size * 0.7, 0), size * 0.35, col.darkened(0.1))
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
