class_name BoosterArt
extends RefCounted

## Procedural booster icons (no emoji — reliable on Android).

static var _cache: Dictionary = {}


static func icon(id: int, size: int = 128) -> Texture2D:
	if _cache.has(id):
		return _cache[id]
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	match id:
		BoosterData.Id.LIGHTNING:
			_draw_lightning(img, size)
		BoosterData.Id.FREEZE_TIME:
			_draw_freeze(img, size)
		BoosterData.Id.MAGNET:
			_draw_magnet(img, size)
		BoosterData.Id.DOUBLE_COINS:
			_draw_double_coins(img, size)
		_:
			_draw_lightning(img, size)
	var tex := ImageTexture.create_from_image(img)
	_cache[id] = tex
	return tex


static func _draw_lightning(img: Image, size: int) -> void:
	var c := Color(1.0, 0.92, 0.2)
	var pts: PackedVector2Array = [
		Vector2(size * 0.52, size * 0.12),
		Vector2(size * 0.38, size * 0.46),
		Vector2(size * 0.56, size * 0.46),
		Vector2(size * 0.42, size * 0.88),
		Vector2(size * 0.66, size * 0.40),
		Vector2(size * 0.50, size * 0.40),
	]
	for i in pts.size():
		var a := pts[i]
		var b := pts[(i + 1) % pts.size()]
		_draw_line(img, a, b, 7, c)


static func _draw_freeze(img: Image, size: int) -> void:
	var cx := float(size) * 0.5
	var cy := float(size) * 0.5
	var c := Color(0.55, 0.88, 1.0)
	for i in 6:
		var angle := float(i) / 6.0 * TAU
		var end := Vector2(cx + cos(angle) * size * 0.32, cy + sin(angle) * size * 0.32)
		_draw_line(img, Vector2(cx, cy), end, 6, c)


static func _draw_magnet(img: Image, size: int) -> void:
	var c1 := Color(0.92, 0.25, 0.28)
	var c2 := Color(0.75, 0.78, 0.82)
	var cx := float(size) * 0.5
	_fill_circle(img, Vector2(cx - size * 0.16, size * 0.34), size * 0.12, c1)
	_fill_circle(img, Vector2(cx + size * 0.16, size * 0.34), size * 0.12, c1)
	_fill_rect(img, Rect2i(int(cx - size * 0.26), int(size * 0.34), int(size * 0.52), int(size * 0.28)), c2)
	_fill_circle(img, Vector2(cx, size * 0.72), size * 0.09, Color(0.35, 0.38, 0.42))


static func _draw_double_coins(img: Image, size: int) -> void:
	_fill_circle(img, Vector2(size * 0.38, size * 0.48), size * 0.18, Color(1.0, 0.84, 0.18))
	_fill_circle(img, Vector2(size * 0.58, size * 0.56), size * 0.18, Color(0.98, 0.72, 0.08))
	_fill_circle(img, Vector2(size * 0.38, size * 0.48), size * 0.11, Color(1.0, 0.94, 0.45))
	_fill_circle(img, Vector2(size * 0.58, size * 0.56), size * 0.11, Color(1.0, 0.88, 0.35))


static func _draw_line(img: Image, from: Vector2, to: Vector2, width: int, color: Color) -> void:
	var dist := from.distance_to(to)
	var steps := maxi(int(dist), 1)
	for i in steps + 1:
		var t := float(i) / float(steps)
		var p := from.lerp(to, t)
		_fill_circle(img, p, float(width) * 0.5, color)


static func _fill_circle(img: Image, center: Vector2, radius: float, color: Color) -> void:
	var r := int(ceil(radius))
	var cx := int(center.x)
	var cy := int(center.y)
	for y in range(cy - r, cy + r + 1):
		for x in range(cx - r, cx + r + 1):
			if Vector2(x, y).distance_to(center) <= radius:
				if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
					img.set_pixel(x, y, color)


static func _fill_rect(img: Image, rect: Rect2i, color: Color) -> void:
	for y in range(rect.position.y, rect.position.y + rect.size.y):
		for x in range(rect.position.x, rect.position.x + rect.size.x):
			if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
				img.set_pixel(x, y, color)
