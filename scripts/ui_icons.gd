class_name UiIcons
extends RefCounted

## Procedural UI chrome icons (no emoji — reliable on Android).

enum Id {
	GEAR,
	PAUSE,
	PLAY,
	HEART,
	COIN,
	STAR,
	KEY,
	HOURGLASS,
	SHOP,
	MAP,
	HOME,
	TROPHY,
	COLLECTION,
	GEM,
}

static var _cache: Dictionary = {}


static func icon(id: int, size: int = 96) -> Texture2D:
	var key := "%d_%d" % [id, size]
	if _cache.has(key):
		return _cache[key]
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	match id:
		Id.GEAR:
			_draw_gear(img, size)
		Id.PAUSE:
			_draw_pause(img, size)
		Id.PLAY:
			_draw_play(img, size)
		Id.HEART:
			_draw_heart(img, size)
		Id.COIN:
			_draw_coin(img, size)
		Id.STAR:
			_draw_star(img, size)
		Id.KEY:
			_draw_key(img, size)
		Id.HOURGLASS:
			_draw_hourglass(img, size)
		Id.SHOP:
			_draw_shop(img, size)
		Id.MAP:
			_draw_map(img, size)
		Id.HOME:
			_draw_home(img, size)
		Id.TROPHY:
			_draw_trophy(img, size)
		Id.COLLECTION:
			_draw_collection(img, size)
		Id.GEM:
			_draw_gem(img, size)
		_:
			_draw_gear(img, size)
	var tex := ImageTexture.create_from_image(img)
	_cache[key] = tex
	return tex


static func mount_button_icon(btn: Button, id: int, size: int = 48, keep_text: String = "") -> void:
	if btn == null:
		return
	btn.icon = icon(id, size)
	btn.expand_icon = true
	btn.add_theme_constant_override("icon_max_width", size)
	btn.text = keep_text


static func replace_label_with_icon(label: Label, id: int, size: int = 40) -> TextureRect:
	if label == null:
		return null
	var parent := label.get_parent()
	if parent == null:
		return null
	var existing := parent.get_node_or_null("UiIcon_%s" % label.name) as TextureRect
	if existing != null:
		existing.texture = icon(id, size)
		label.hide()
		return existing
	var tex := TextureRect.new()
	tex.name = "UiIcon_%s" % label.name
	tex.custom_minimum_size = Vector2(size, size)
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex.texture = icon(id, size)
	tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(tex)
	parent.move_child(tex, label.get_index())
	label.hide()
	return tex


static func _draw_gear(img: Image, size: int) -> void:
	var c := Color(0.96, 0.97, 1.0)
	var cx := size * 0.5
	var cy := size * 0.5
	_fill_circle(img, Vector2(cx, cy), size * 0.22, c)
	_fill_circle(img, Vector2(cx, cy), size * 0.10, Color(0.18, 0.28, 0.45))
	for i in 8:
		var a := float(i) / 8.0 * TAU
		var p := Vector2(cx + cos(a) * size * 0.34, cy + sin(a) * size * 0.34)
		_fill_circle(img, p, size * 0.08, c)


static func _draw_pause(img: Image, size: int) -> void:
	var c := Color(1, 1, 1)
	_fill_rect(img, Rect2i(int(size * 0.28), int(size * 0.22), int(size * 0.16), int(size * 0.56)), c)
	_fill_rect(img, Rect2i(int(size * 0.56), int(size * 0.22), int(size * 0.16), int(size * 0.56)), c)


static func _draw_play(img: Image, size: int) -> void:
	var c := Color(1, 1, 1)
	var pts: PackedVector2Array = [
		Vector2(size * 0.32, size * 0.20),
		Vector2(size * 0.32, size * 0.80),
		Vector2(size * 0.78, size * 0.50),
	]
	_fill_triangle(img, pts[0], pts[1], pts[2], c)


static func _draw_heart(img: Image, size: int) -> void:
	var c := Color(0.95, 0.28, 0.42)
	_fill_circle(img, Vector2(size * 0.34, size * 0.38), size * 0.20, c)
	_fill_circle(img, Vector2(size * 0.66, size * 0.38), size * 0.20, c)
	_fill_triangle(
		img,
		Vector2(size * 0.16, size * 0.42),
		Vector2(size * 0.84, size * 0.42),
		Vector2(size * 0.50, size * 0.86),
		c
	)


static func _draw_coin(img: Image, size: int) -> void:
	_fill_circle(img, Vector2(size * 0.52, size * 0.54), size * 0.30, Color(0.78, 0.52, 0.08))
	_fill_circle(img, Vector2(size * 0.48, size * 0.48), size * 0.30, Color(1.0, 0.84, 0.18))
	_fill_circle(img, Vector2(size * 0.48, size * 0.48), size * 0.18, Color(1.0, 0.94, 0.45))


static func _draw_star(img: Image, size: int) -> void:
	var c := Color(1.0, 0.86, 0.22)
	var cx := size * 0.5
	var cy := size * 0.52
	for i in 5:
		var a := -PI * 0.5 + float(i) * TAU / 5.0
		var outer := Vector2(cx + cos(a) * size * 0.36, cy + sin(a) * size * 0.36)
		_draw_line(img, Vector2(cx, cy), outer, int(size * 0.10), c)
	_fill_circle(img, Vector2(cx, cy), size * 0.12, c)


static func _draw_key(img: Image, size: int) -> void:
	var c := Color(1.0, 0.84, 0.28)
	_fill_circle(img, Vector2(size * 0.34, size * 0.36), size * 0.16, c)
	_fill_circle(img, Vector2(size * 0.34, size * 0.36), size * 0.07, Color(0.35, 0.22, 0.08))
	_fill_rect(img, Rect2i(int(size * 0.42), int(size * 0.30), int(size * 0.40), int(size * 0.12)), c)
	_fill_rect(img, Rect2i(int(size * 0.68), int(size * 0.42), int(size * 0.10), int(size * 0.16)), c)
	_fill_rect(img, Rect2i(int(size * 0.78), int(size * 0.42), int(size * 0.10), int(size * 0.22)), c)


static func _draw_hourglass(img: Image, size: int) -> void:
	var c := Color(0.75, 0.88, 1.0)
	_fill_rect(img, Rect2i(int(size * 0.28), int(size * 0.16), int(size * 0.44), int(size * 0.10)), c)
	_fill_rect(img, Rect2i(int(size * 0.28), int(size * 0.74), int(size * 0.44), int(size * 0.10)), c)
	_fill_triangle(
		img,
		Vector2(size * 0.30, size * 0.26),
		Vector2(size * 0.70, size * 0.26),
		Vector2(size * 0.50, size * 0.50),
		Color(0.55, 0.78, 0.98)
	)
	_fill_triangle(
		img,
		Vector2(size * 0.30, size * 0.74),
		Vector2(size * 0.70, size * 0.74),
		Vector2(size * 0.50, size * 0.50),
		Color(0.45, 0.70, 0.95)
	)


static func _draw_shop(img: Image, size: int) -> void:
	var c := Color(1.0, 0.82, 0.28)
	_fill_rect(img, Rect2i(int(size * 0.22), int(size * 0.38), int(size * 0.56), int(size * 0.42)), c)
	_fill_triangle(
		img,
		Vector2(size * 0.18, size * 0.40),
		Vector2(size * 0.82, size * 0.40),
		Vector2(size * 0.50, size * 0.18),
		Color(0.95, 0.55, 0.18)
	)
	_fill_rect(img, Rect2i(int(size * 0.42), int(size * 0.52), int(size * 0.16), int(size * 0.28)), Color(0.45, 0.28, 0.12))


static func _draw_map(img: Image, size: int) -> void:
	var c := Color(0.45, 0.82, 0.55)
	_fill_rect(img, Rect2i(int(size * 0.18), int(size * 0.22), int(size * 0.64), int(size * 0.56)), c)
	_fill_rect(img, Rect2i(int(size * 0.28), int(size * 0.30), int(size * 0.44), int(size * 0.08)), Color(0.95, 0.95, 0.9))
	_fill_rect(img, Rect2i(int(size * 0.28), int(size * 0.46), int(size * 0.30), int(size * 0.08)), Color(0.95, 0.95, 0.9))
	_fill_circle(img, Vector2(size * 0.62, size * 0.58), size * 0.08, Color(0.92, 0.28, 0.32))


static func _draw_home(img: Image, size: int) -> void:
	var wall := Color(0.92, 0.94, 0.98)
	_fill_rect(img, Rect2i(int(size * 0.28), int(size * 0.42), int(size * 0.44), int(size * 0.38)), wall)
	_fill_triangle(
		img,
		Vector2(size * 0.18, size * 0.46),
		Vector2(size * 0.82, size * 0.46),
		Vector2(size * 0.50, size * 0.18),
		Color(0.95, 0.42, 0.35)
	)
	_fill_rect(img, Rect2i(int(size * 0.44), int(size * 0.54), int(size * 0.14), int(size * 0.26)), Color(0.35, 0.55, 0.85))


static func _draw_trophy(img: Image, size: int) -> void:
	var c := Color(1.0, 0.82, 0.22)
	_fill_circle(img, Vector2(size * 0.50, size * 0.38), size * 0.22, c)
	_fill_rect(img, Rect2i(int(size * 0.42), int(size * 0.52), int(size * 0.16), int(size * 0.16)), c)
	_fill_rect(img, Rect2i(int(size * 0.32), int(size * 0.68), int(size * 0.36), int(size * 0.10)), Color(0.85, 0.65, 0.18))
	_draw_line(img, Vector2(size * 0.28, size * 0.32), Vector2(size * 0.18, size * 0.48), 5, c)
	_draw_line(img, Vector2(size * 0.72, size * 0.32), Vector2(size * 0.82, size * 0.48), 5, c)


static func _draw_collection(img: Image, size: int) -> void:
	var c := Color(0.55, 0.82, 1.0)
	_fill_rect(img, Rect2i(int(size * 0.22), int(size * 0.28), int(size * 0.56), int(size * 0.48)), c)
	_fill_rect(img, Rect2i(int(size * 0.30), int(size * 0.36), int(size * 0.16), int(size * 0.16)), Color(1, 1, 1, 0.85))
	_fill_rect(img, Rect2i(int(size * 0.54), int(size * 0.36), int(size * 0.16), int(size * 0.16)), Color(1, 1, 1, 0.85))
	_fill_rect(img, Rect2i(int(size * 0.30), int(size * 0.56), int(size * 0.40), int(size * 0.10)), Color(1, 1, 1, 0.75))


static func _draw_gem(img: Image, size: int) -> void:
	var c := Color(0.45, 0.82, 1.0)
	_fill_triangle(
		img,
		Vector2(size * 0.50, size * 0.16),
		Vector2(size * 0.82, size * 0.42),
		Vector2(size * 0.18, size * 0.42),
		c
	)
	_fill_triangle(
		img,
		Vector2(size * 0.18, size * 0.42),
		Vector2(size * 0.82, size * 0.42),
		Vector2(size * 0.50, size * 0.86),
		Color(0.28, 0.62, 0.95)
	)


static func _fill_triangle(img: Image, a: Vector2, b: Vector2, c: Vector2, color: Color) -> void:
	var min_x := int(floor(minf(a.x, minf(b.x, c.x))))
	var max_x := int(ceil(maxf(a.x, maxf(b.x, c.x))))
	var min_y := int(floor(minf(a.y, minf(b.y, c.y))))
	var max_y := int(ceil(maxf(a.y, maxf(b.y, c.y))))
	for y in range(min_y, max_y + 1):
		for x in range(min_x, max_x + 1):
			if _point_in_triangle(Vector2(x, y), a, b, c):
				if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
					img.set_pixel(x, y, color)


static func _point_in_triangle(p: Vector2, a: Vector2, b: Vector2, c: Vector2) -> bool:
	var v0 := c - a
	var v1 := b - a
	var v2 := p - a
	var dot00 := v0.dot(v0)
	var dot01 := v0.dot(v1)
	var dot02 := v0.dot(v2)
	var dot11 := v1.dot(v1)
	var dot12 := v1.dot(v2)
	var inv := 1.0 / (dot00 * dot11 - dot01 * dot01)
	var u := (dot11 * dot02 - dot01 * dot12) * inv
	var v := (dot00 * dot12 - dot01 * dot02) * inv
	return u >= 0.0 and v >= 0.0 and (u + v) <= 1.0


static func _draw_line(img: Image, from: Vector2, to: Vector2, width: int, color: Color) -> void:
	var dist := from.distance_to(to)
	var steps := maxi(int(dist), 1)
	for i in steps + 1:
		var t := float(i) / float(steps)
		_fill_circle(img, from.lerp(to, t), float(width) * 0.5, color)


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
