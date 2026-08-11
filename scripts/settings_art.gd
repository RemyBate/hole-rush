class_name SettingsArt
extends RefCounted

## Procedural settings toggle icons (no emoji — reliable on Android).

enum Id { MUSIC, SOUND, VIBRATION }

static var _cache: Dictionary = {}


static func icon(id: int, size: int = 128) -> Texture2D:
	if _cache.has(id):
		return _cache[id]
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	match id:
		Id.MUSIC:
			_draw_music(img, size)
		Id.SOUND:
			_draw_sound(img, size)
		Id.VIBRATION:
			_draw_vibration(img, size)
		_:
			_draw_music(img, size)
	var tex := ImageTexture.create_from_image(img)
	_cache[id] = tex
	return tex


static func _draw_music(img: Image, size: int) -> void:
	var note := Color(1.0, 0.95, 0.35)
	var stem := Color(1.0, 0.92, 0.28)
	_fill_circle(img, Vector2(size * 0.38, size * 0.68), size * 0.14, note)
	_fill_circle(img, Vector2(size * 0.58, size * 0.58), size * 0.11, note)
	_fill_rect(img, Rect2i(int(size * 0.62), int(size * 0.18), int(size * 0.08), int(size * 0.42)), stem)
	_draw_line(img, Vector2(size * 0.66, size * 0.20), Vector2(size * 0.80, size * 0.30), 5, stem)
	_draw_line(img, Vector2(size * 0.66, size * 0.28), Vector2(size * 0.82, size * 0.38), 4, stem)


static func _draw_sound(img: Image, size: int) -> void:
	var body := Color(0.92, 0.94, 0.98)
	var cone := Color(0.55, 0.82, 1.0)
	_fill_rect(img, Rect2i(int(size * 0.18), int(size * 0.38), int(size * 0.16), int(size * 0.24)), body)
	var pts: PackedVector2Array = [
		Vector2(size * 0.34, size * 0.32),
		Vector2(size * 0.34, size * 0.68),
		Vector2(size * 0.54, size * 0.50),
	]
	for i in 3:
		_draw_line(img, pts[i], pts[(i + 1) % 3], 8, cone)
	for r in [0.24, 0.34, 0.44]:
		_draw_arc(img, Vector2(size * 0.56, size * 0.50), size * r, -0.55, 0.55, 4, Color(0.75, 0.92, 1.0))


static func _draw_vibration(img: Image, size: int) -> void:
	var phone := Color(0.78, 0.84, 0.92)
	var screen := Color(0.35, 0.72, 0.98)
	_fill_rect(img, Rect2i(int(size * 0.34), int(size * 0.14), int(size * 0.32), int(size * 0.72)), phone)
	_fill_rect(img, Rect2i(int(size * 0.38), int(size * 0.22), int(size * 0.24), int(size * 0.52)), screen)
	for i in 3:
		var y := size * (0.30 + float(i) * 0.12)
		_draw_line(img, Vector2(size * 0.16, y), Vector2(size * 0.28, y), 4, Color(0.55, 0.88, 1.0))
		_draw_line(img, Vector2(size * 0.72, y), Vector2(size * 0.84, y), 4, Color(0.55, 0.88, 1.0))


static func _draw_line(img: Image, from: Vector2, to: Vector2, width: int, color: Color) -> void:
	var dist := from.distance_to(to)
	var steps := maxi(int(dist), 1)
	for i in steps + 1:
		var t := float(i) / float(steps)
		_fill_circle(img, from.lerp(to, t), float(width) * 0.5, color)


static func _draw_arc(img: Image, center: Vector2, radius: float, angle_from: float, angle_to: float, width: int, color: Color) -> void:
	var steps := maxi(int(radius * abs(angle_to - angle_from)), 8)
	for i in steps + 1:
		var t := float(i) / float(steps)
		var angle := lerpf(angle_from, angle_to, t)
		var p := center + Vector2(cos(angle), sin(angle)) * radius
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
