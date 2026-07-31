class_name ThemeBackground
extends RefCounted


static func draw(canvas: CanvasItem, bounds: Rect2, theme: int) -> void:
	match theme:
		LevelTheme.Id.FRUIT_GARDEN:
			_draw_fruit_garden(canvas, bounds)
		LevelTheme.Id.VEGETABLE_FARM:
			_draw_vegetable_farm(canvas, bounds)
		LevelTheme.Id.FAST_FOOD:
			_draw_fast_food_floor(canvas, bounds)
		LevelTheme.Id.BAKERY:
			_draw_bakery_floor(canvas, bounds)
		LevelTheme.Id.TOY_ROOM:
			_draw_toy_room(canvas, bounds)
		LevelTheme.Id.BEACH_PARTY:
			_draw_beach_party(canvas, bounds)
		_:
			_draw_fruit_garden(canvas, bounds)
	_draw_border(canvas, bounds, theme)


static func _draw_soft_field(canvas: CanvasItem, bounds: Rect2, color_a: Color, color_b: Color) -> void:
	var steps := 12
	for row in steps:
		for col in steps:
			var cell := Vector2(bounds.size.x / steps, bounds.size.y / steps)
			var pos := bounds.position + Vector2(col, row) * cell
			var t := sin(float(col) * 0.7 + float(row) * 0.5) * 0.5 + 0.5
			canvas.draw_rect(Rect2(pos, cell), color_a.lerp(color_b, t), true)


static func _draw_edge_trees(canvas: CanvasItem, bounds: Rect2, count: int = 14) -> void:
	for i in count:
		var edge := i % 4
		var t := float(i) / float(count - 1)
		var pos := Vector2.ZERO
		match edge:
			0:
				pos = Vector2(bounds.position.x + t * bounds.size.x, bounds.position.y + 36.0)
			1:
				pos = Vector2(bounds.position.x + bounds.size.x - 36.0, bounds.position.y + t * bounds.size.y)
			2:
				pos = Vector2(bounds.position.x + t * bounds.size.x, bounds.position.y + bounds.size.y - 36.0)
			_:
				pos = Vector2(bounds.position.x + 36.0, bounds.position.y + t * bounds.size.y)
		canvas.draw_rect(Rect2(pos + Vector2(-5.0, 0.0), Vector2(10.0, 26.0)), Color(0.45, 0.32, 0.22, 0.55), true)
		canvas.draw_circle(pos + Vector2(0.0, -12.0), 20.0, Color(0.28, 0.58, 0.32, 0.6))


static func _draw_fruit_garden(canvas: CanvasItem, bounds: Rect2) -> void:
	# Soft light-green field — primary playground for numbered fruit collectibles.
	# Keep colour contrast low so the soft grid never reads as a checkerboard.
	_draw_soft_field(canvas, bounds, Color(0.50, 0.82, 0.47), Color(0.55, 0.86, 0.52))
	_draw_edge_trees(canvas, bounds)
	_draw_fruit_crates(canvas, bounds)


static func _draw_vegetable_farm(canvas: CanvasItem, bounds: Rect2) -> void:
	_draw_soft_field(canvas, bounds, Color(0.52, 0.62, 0.38), Color(0.58, 0.68, 0.42))
	# Garden rows
	var row_spacing := 140.0
	var y := bounds.position.y + 180.0
	while y < bounds.position.y + bounds.size.y - 120.0:
		canvas.draw_rect(
			Rect2(bounds.position.x + 120.0, y, bounds.size.x - 240.0, 28.0),
			Color(0.42, 0.52, 0.32, 0.45), true
		)
		y += row_spacing
	# Wooden fences on edges
	for i in 20:
		var t := float(i) / 19.0
		var top := bounds.position + Vector2(t * bounds.size.x, 24.0)
		var bot := bounds.position + Vector2(t * bounds.size.x, bounds.size.y - 24.0)
		canvas.draw_rect(Rect2(top, Vector2(8.0, 22.0)), Color(0.55, 0.38, 0.22, 0.5), true)
		canvas.draw_rect(Rect2(bot, Vector2(8.0, 22.0)), Color(0.55, 0.38, 0.22, 0.5), true)


static func _draw_fast_food_floor(canvas: CanvasItem, bounds: Rect2) -> void:
	# Soft warm floor — no grey/white checkerboard (that read as a debug grid).
	_draw_soft_field(canvas, bounds, Color(0.94, 0.90, 0.82), Color(0.90, 0.86, 0.78))
	# Subtle aisle lines only.
	var step := 160.0
	var x := bounds.position.x + 80.0
	while x < bounds.position.x + bounds.size.x - 80.0:
		canvas.draw_line(
			Vector2(x, bounds.position.y + 40.0),
			Vector2(x, bounds.position.y + bounds.size.y - 40.0),
			Color(0.82, 0.78, 0.70, 0.25), 3.0
		)
		x += step


static func _draw_bakery_floor(canvas: CanvasItem, bounds: Rect2) -> void:
	_draw_soft_field(canvas, bounds, Color(0.92, 0.82, 0.68), Color(0.96, 0.86, 0.72))
	# Counters along top and bottom edges
	for edge_y in [bounds.position.y + 90.0, bounds.position.y + bounds.size.y - 120.0]:
		canvas.draw_rect(
			Rect2(bounds.position.x + 80.0, edge_y, bounds.size.x - 160.0, 48.0),
			Color(0.62, 0.42, 0.28, 0.55), true, 10.0
		)
		canvas.draw_rect(
			Rect2(bounds.position.x + 100.0, edge_y - 8.0, bounds.size.x - 200.0, 12.0),
			Color(0.78, 0.55, 0.35, 0.4), true, 6.0
		)


static func _draw_toy_room(canvas: CanvasItem, bounds: Rect2) -> void:
	var bands := [
		Color(0.95, 0.88, 0.72),
		Color(0.88, 0.92, 0.98),
		Color(0.98, 0.85, 0.88),
		Color(0.85, 0.95, 0.88),
	]
	var band_h := bounds.size.y / bands.size()
	for i in bands.size():
		canvas.draw_rect(
			Rect2(bounds.position.x, bounds.position.y + i * band_h, bounds.size.x, band_h),
			bands[i], true
		)


static func _draw_beach_party(canvas: CanvasItem, bounds: Rect2) -> void:
	_draw_soft_field(canvas, bounds, Color(0.96, 0.88, 0.62), Color(0.98, 0.92, 0.68))
	# Umbrellas along edges
	for i in 8:
		var t := float(i) / 7.0
		for edge_y in [bounds.position.y + 70.0, bounds.position.y + bounds.size.y - 70.0]:
			var pos := Vector2(bounds.position.x + 200.0 + t * (bounds.size.x - 400.0), edge_y)
			canvas.draw_line(pos, pos + Vector2(0.0, 28.0), Color(0.55, 0.45, 0.38, 0.5), 3.0)
			var awning := PackedVector2Array([
				pos + Vector2(-28.0, -8.0), pos + Vector2(28.0, -8.0),
				pos + Vector2(0.0, -32.0),
			])
			canvas.draw_colored_polygon(awning, Color(0.95, 0.42, 0.38, 0.45))


static func _draw_fruit_crates(canvas: CanvasItem, bounds: Rect2) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 445566
	for i in 16:
		if rng.randi() % 3 != 0:
			continue
		var pos := Vector2(
			rng.randf_range(bounds.position.x + 200.0, bounds.position.x + bounds.size.x - 200.0),
			rng.randf_range(bounds.position.y + 200.0, bounds.position.y + bounds.size.y - 200.0)
		)
		canvas.draw_rect(Rect2(pos - Vector2(14.0, 10.0), Vector2(28.0, 20.0)), Color(0.62, 0.44, 0.28, 0.35), true)
		canvas.draw_rect(Rect2(pos - Vector2(12.0, -8.0), Vector2(24.0, 6.0)), Color(0.72, 0.52, 0.35, 0.3), true)


static func _draw_border(canvas: CanvasItem, bounds: Rect2, theme: int) -> void:
	var border_color := Color(0.25, 0.35, 0.28, 0.4)
	match theme:
		LevelTheme.Id.FAST_FOOD:
			border_color = Color(0.45, 0.48, 0.52, 0.35)
		LevelTheme.Id.BAKERY:
			border_color = Color(0.55, 0.42, 0.32, 0.35)
		LevelTheme.Id.TOY_ROOM:
			border_color = Color(0.55, 0.62, 0.78, 0.35)
		LevelTheme.Id.BEACH_PARTY:
			border_color = Color(0.82, 0.72, 0.45, 0.4)
	canvas.draw_rect(bounds.grow(8.0), border_color, false, 16.0, 5.0)
