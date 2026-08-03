class_name CollectibleArt
extends RefCounted

## Fruit Garden texture-backed watermelon slots (physical field collectibles).
const FRUIT_SLOT_WATERMELON_SLICE: int = 0
const FRUIT_SLOT_WATERMELON_HALF: int = 1
const FRUIT_SLOT_WATERMELON_WHOLE: int = 2

const TEX_WATERMELON_WHOLE: Texture2D = preload("res://assets/items/fruits/1.png")
const TEX_WATERMELON_HALF: Texture2D = preload("res://assets/items/fruits/2.png")
const TEX_WATERMELON_SLICE: Texture2D = preload("res://assets/items/fruits/3.png")

## Content fill of each PNG (opaque fruit vs full frame) — keeps drawn size honest.
const _WATERMELON_CONTENT_FILL: Array[float] = [0.74, 0.90, 0.87]


static func is_textured_watermelon(theme: int, slot: int) -> bool:
	return theme == LevelTheme.Id.FRUIT_GARDEN and slot >= 0 and slot <= FRUIT_SLOT_WATERMELON_WHOLE


static func watermelon_required_hole_size(slot: int) -> int:
	match slot:
		FRUIT_SLOT_WATERMELON_SLICE:
			return 1
		FRUIT_SLOT_WATERMELON_HALF:
			return 2
		FRUIT_SLOT_WATERMELON_WHOLE:
			return 3
		_:
			return 1


static func watermelon_score_value(slot: int) -> int:
	match slot:
		FRUIT_SLOT_WATERMELON_SLICE:
			return 2
		FRUIT_SLOT_WATERMELON_HALF:
			return 5
		FRUIT_SLOT_WATERMELON_WHOLE:
			return 10
		_:
			return 2


static func watermelon_size_tier(slot: int) -> int:
	match slot:
		FRUIT_SLOT_WATERMELON_SLICE:
			return ItemSizeTier.Tier.SMALL
		FRUIT_SLOT_WATERMELON_HALF:
			return ItemSizeTier.Tier.MEDIUM
		FRUIT_SLOT_WATERMELON_WHOLE:
			return ItemSizeTier.Tier.LARGE
		_:
			return ItemSizeTier.Tier.SMALL


static func draw_item(canvas: CanvasItem, theme: int, slot: int, tier_scale: float = 1.0) -> void:
	var scale := tier_scale
	match theme:
		LevelTheme.Id.FRUIT_GARDEN:
			_draw_fruit(canvas, slot, scale)
		LevelTheme.Id.VEGETABLE_FARM:
			_draw_vegetable(canvas, slot, scale)
		LevelTheme.Id.FAST_FOOD:
			_draw_fast_food(canvas, slot, scale)
		LevelTheme.Id.BAKERY:
			_draw_bakery(canvas, slot, scale)
		LevelTheme.Id.TOY_ROOM:
			_draw_toy(canvas, slot, scale)
		LevelTheme.Id.BEACH_PARTY:
			_draw_beach(canvas, slot, scale)
		_:
			_draw_fruit(canvas, 0, scale)


## Draw a numbered catalog PNG at full colour — exact source texture, aspect preserved.
static func draw_catalog_entry(canvas: CanvasItem, entry: ItemEntry, tier_scale: float = 1.0) -> void:
	if entry == null:
		return
	draw_catalog_texture(
		canvas,
		entry.texture,
		entry.visual_radius * tier_scale,
		entry.content_fill,
		entry.content_span_px,
		entry.source_max_px
	)


static func draw_catalog_texture(
	canvas: CanvasItem,
	texture: Texture2D,
	visual_radius: float,
	content_fill: float = 0.85,
	content_span_px: float = 0.0,
	source_max_px: float = 0.0
) -> void:
	if texture == null or visual_radius <= 0.0:
		return
	var target_diam: float = visual_radius * 2.0
	var tex_size: Vector2 = texture.get_size()
	if tex_size.x <= 0.0 or tex_size.y <= 0.0:
		return
	# Map opaque fruit span (not full canvas) onto target_diam; keep aspect ratio.
	var tex_max: float = maxf(tex_size.x, tex_size.y)
	var span: float = content_span_px
	if span >= 4.0 and source_max_px >= 4.0:
		# Convert source-image span into texture pixel space if sizes differ.
		span = content_span_px * (tex_max / source_max_px)
	else:
		span = tex_max * clampf(content_fill, 0.18, 0.92)
	# Nudge up slightly so soft alpha fringe does not leave fruit undersized.
	span *= 0.92
	var uniform: float = target_diam / maxf(span, 1.0)
	var draw_w: float = tex_size.x * uniform
	var draw_h: float = tex_size.y * uniform
	canvas.draw_texture_rect(
		texture,
		Rect2(-draw_w * 0.5, -draw_h * 0.5, draw_w, draw_h),
		false,
		Color.WHITE
	)


static func visual_radius(theme: int, slot: int) -> float:
	if theme == LevelTheme.Id.FRUIT_GARDEN:
		match slot:
			FRUIT_SLOT_WATERMELON_SLICE:
				return 26.0 # start hole (38) can swallow immediately
			FRUIT_SLOT_WATERMELON_HALF:
				return 46.0 # needs a little growth
			FRUIT_SLOT_WATERMELON_WHOLE:
				return 58.0 # needs more growth; matches visible size
			3:
				return 16.0
			4:
				return 17.0
			_:
				return 18.0
	match slot:
		0:
			return 16.0
		1:
			return 17.0
		2:
			return 22.0
		3:
			return 28.0
		4:
			return 26.0
		_:
			return 18.0


static func item_color(theme: int, slot: int) -> Color:
	var colors: Array[Color] = []
	match theme:
		LevelTheme.Id.FRUIT_GARDEN:
			colors = [
				Color(0.92, 0.28, 0.35), Color(0.88, 0.22, 0.28), Color(0.28, 0.72, 0.38),
				Color(0.98, 0.62, 0.2), Color(0.92, 0.22, 0.35),
			]
		LevelTheme.Id.VEGETABLE_FARM:
			colors = [
				Color(0.38, 0.72, 0.42), Color(0.95, 0.48, 0.18), Color(0.55, 0.88, 0.48),
				Color(0.98, 0.85, 0.32), Color(0.92, 0.52, 0.18),
			]
		LevelTheme.Id.FAST_FOOD:
			colors = [
				Color(0.88, 0.45, 0.28), Color(0.96, 0.82, 0.42), Color(0.98, 0.78, 0.22),
				Color(0.95, 0.42, 0.32), Color(0.92, 0.62, 0.35),
			]
		LevelTheme.Id.BAKERY:
			colors = [
				Color(0.82, 0.58, 0.34), Color(0.95, 0.58, 0.74), Color(0.88, 0.52, 0.72),
				Color(0.92, 0.72, 0.42), Color(0.98, 0.82, 0.48),
			]
		LevelTheme.Id.TOY_ROOM:
			colors = [
				Color(0.35, 0.55, 0.95), Color(0.95, 0.35, 0.35), Color(0.95, 0.72, 0.25),
				Color(0.72, 0.48, 0.32), Color(0.55, 0.82, 0.95),
			]
		LevelTheme.Id.BEACH_PARTY:
			colors = [
				Color(0.95, 0.88, 0.78), Color(0.98, 0.62, 0.28), Color(0.35, 0.75, 0.98),
				Color(0.55, 0.82, 0.95), Color(0.98, 0.55, 0.72),
			]
		_:
			return Color.WHITE
	return colors[clampi(slot, 0, colors.size() - 1)]


# --- Fruit Garden ---

static func _draw_fruit(canvas: CanvasItem, slot: int, s: float) -> void:
	match slot:
		FRUIT_SLOT_WATERMELON_SLICE, FRUIT_SLOT_WATERMELON_HALF, FRUIT_SLOT_WATERMELON_WHOLE:
			_draw_watermelon_texture(canvas, slot, s)
		3:
			canvas.draw_circle(Vector2.ZERO, 15.0 * s, Color(0.98, 0.62, 0.18))
			for i in 8:
				var a := float(i) / 8.0 * TAU
				canvas.draw_line(Vector2.ZERO, Vector2(cos(a), sin(a)) * 14.0 * s, Color(0.92, 0.52, 0.12), 1.5 * s)
		4:
			for i in 3:
				var off := Vector2(-8.0 + i * 8.0, 0.0) * s
				canvas.draw_circle(off + Vector2(0.0, 2.0 * s), 7.0 * s, Color(0.92, 0.2, 0.35))
		_:
			pass


static func _watermelon_texture(slot: int) -> Texture2D:
	match slot:
		FRUIT_SLOT_WATERMELON_SLICE:
			return TEX_WATERMELON_SLICE
		FRUIT_SLOT_WATERMELON_HALF:
			return TEX_WATERMELON_HALF
		_:
			return TEX_WATERMELON_WHOLE


static func _draw_watermelon_texture(canvas: CanvasItem, slot: int, s: float) -> void:
	var tex := _watermelon_texture(slot)
	if tex == null:
		return
	var target_diam: float = visual_radius(LevelTheme.Id.FRUIT_GARDEN, slot) * 2.0 * s
	var tex_size := tex.get_size()
	var fill: float = _WATERMELON_CONTENT_FILL[clampi(slot, 0, _WATERMELON_CONTENT_FILL.size() - 1)]
	var frame_max: float = maxf(tex_size.x, tex_size.y) * fill
	if frame_max <= 0.0:
		return
	var uniform: float = target_diam / frame_max
	var draw_w: float = tex_size.x * uniform
	var draw_h: float = tex_size.y * uniform
	canvas.draw_texture_rect(
		tex,
		Rect2(-draw_w * 0.5, -draw_h * 0.5, draw_w, draw_h),
		false
	)


# --- Vegetable Farm ---

static func _draw_vegetable(canvas: CanvasItem, slot: int, s: float) -> void:
	match slot:
		0:
			canvas.draw_rect(Rect2(-6.0 * s, -18.0 * s, 12.0 * s, 36.0 * s), Color(0.38, 0.72, 0.42), true, 6.0 * s)
			canvas.draw_circle(Vector2.ZERO, 8.0 * s, Color(0.48, 0.82, 0.48))
		1:
			canvas.draw_rect(Rect2(-5.0 * s, -16.0 * s, 10.0 * s, 32.0 * s), Color(0.95, 0.48, 0.18), true, 5.0 * s)
			canvas.draw_circle(Vector2(0.0, -18.0 * s), 8.0 * s, Color(0.38, 0.72, 0.38))
		2:
			var leaf := PackedVector2Array([
				Vector2(-18.0, 8.0) * s, Vector2(18.0, 8.0) * s, Vector2(0.0, -16.0) * s,
			])
			canvas.draw_colored_polygon(leaf, Color(0.48, 0.82, 0.42))
		3:
			canvas.draw_rect(Rect2(-8.0 * s, -14.0 * s, 16.0 * s, 28.0 * s), Color(0.98, 0.85, 0.32), true, 4.0 * s)
			for i in 6:
				canvas.draw_circle(Vector2(-6.0 + i * 2.4, 0.0) * s, 3.0 * s, Color(0.92, 0.78, 0.28))
		4:
			canvas.draw_circle(Vector2(0.0, 4.0 * s), 18.0 * s, Color(0.92, 0.52, 0.18))
			var stem := PackedVector2Array([Vector2(0.0, -14.0) * s, Vector2(8.0, -22.0) * s, Vector2(-2.0, -12.0) * s])
			canvas.draw_colored_polygon(stem, Color(0.38, 0.62, 0.32))
		_:
			pass


# --- Fast Food ---

static func _draw_fast_food(canvas: CanvasItem, slot: int, s: float) -> void:
	match slot:
		0:
			canvas.draw_circle(Vector2.ZERO, 16.0 * s, Color(0.88, 0.45, 0.28))
			canvas.draw_rect(Rect2(-18.0 * s, 10.0 * s, 36.0 * s, 8.0 * s), Color(0.92, 0.72, 0.42), true, 4.0 * s)
		1:
			canvas.draw_rect(Rect2(-26.0 * s, -8.0 * s, 52.0 * s, 16.0 * s), Color(0.96, 0.82, 0.45), true, 8.0 * s)
			canvas.draw_rect(Rect2(-22.0 * s, -2.0 * s, 44.0 * s, 6.0 * s), Color(0.35, 0.7, 0.35), true, 4.0 * s)
			canvas.draw_rect(Rect2(-26.0 * s, 6.0 * s, 52.0 * s, 10.0 * s), Color(0.92, 0.72, 0.4), true, 6.0 * s)
		2:
			for i in 4:
				canvas.draw_rect(
					Rect2(Vector2(-16.0 + i * 8.0, -12.0) * s, Vector2(5.0, 24.0) * s),
					Color(0.98, 0.78, 0.22), true, 2.0 * s
				)
		3:
			canvas.draw_circle(Vector2.ZERO, 18.0 * s, Color(0.95, 0.42, 0.32))
			canvas.draw_circle(Vector2.ZERO, 12.0 * s, Color(0.98, 0.72, 0.38))
		4:
			canvas.draw_rect(Rect2(-20.0 * s, -6.0 * s, 40.0 * s, 12.0 * s), Color(0.92, 0.62, 0.35), true, 6.0 * s)
			canvas.draw_circle(Vector2(18.0 * s, 0.0), 6.0 * s, Color(0.98, 0.85, 0.55))
		_:
			pass


# --- Bakery ---

static func _draw_bakery(canvas: CanvasItem, slot: int, s: float) -> void:
	match slot:
		0:
			canvas.draw_circle(Vector2.ZERO, 14.0 * s, Color(0.82, 0.58, 0.34))
			for p in [Vector2(-6.0, 2.0), Vector2(4.0, -5.0), Vector2(6.0, 4.0)]:
				canvas.draw_circle(p * s, 2.5 * s, Color(0.45, 0.28, 0.18))
		1:
			var cup := PackedVector2Array([
				Vector2(-14.0, 6.0) * s, Vector2(14.0, 6.0) * s,
				Vector2(10.0, 20.0) * s, Vector2(-10.0, 20.0) * s,
			])
			canvas.draw_colored_polygon(cup, Color(0.7, 0.46, 0.3))
			canvas.draw_circle(Vector2(0.0, -2.0 * s), 16.0 * s, Color(0.96, 0.58, 0.74))
		2:
			canvas.draw_circle(Vector2.ZERO, 14.0 * s, Color(0.88, 0.52, 0.72))
			canvas.draw_circle(Vector2.ZERO, 6.0 * s, Color(0.98, 0.85, 0.55))
		3:
			canvas.draw_rect(Rect2(-24.0 * s, -12.0 * s, 48.0 * s, 24.0 * s), Color(0.92, 0.72, 0.42), true, 12.0 * s)
		4:
			var c := PackedVector2Array([
				Vector2(-8.0, 12.0) * s, Vector2(8.0, 12.0) * s, Vector2(0.0, -16.0) * s,
			])
			canvas.draw_colored_polygon(c, Color(0.98, 0.82, 0.48))
		_:
			pass


# --- Toy Room ---

static func _draw_toy(canvas: CanvasItem, slot: int, s: float) -> void:
	match slot:
		0:
			canvas.draw_rect(Rect2(-18.0 * s, -8.0 * s, 36.0 * s, 16.0 * s), Color(0.35, 0.55, 0.95), true, 6.0 * s)
			canvas.draw_circle(Vector2(-14.0 * s, 12.0 * s), 5.0 * s, Color(0.2, 0.2, 0.25))
			canvas.draw_circle(Vector2(14.0 * s, 12.0 * s), 5.0 * s, Color(0.2, 0.2, 0.25))
		1:
			canvas.draw_circle(Vector2.ZERO, 16.0 * s, Color(0.95, 0.35, 0.35))
			canvas.draw_arc(Vector2.ZERO, 16.0 * s, 0.0, TAU, 24, Color.WHITE, 3.0 * s)
		2:
			canvas.draw_rect(Rect2(-14.0 * s, -14.0 * s, 28.0 * s, 28.0 * s), Color(0.95, 0.72, 0.25), true, 4.0 * s)
		3:
			canvas.draw_circle(Vector2(0.0, 4.0 * s), 18.0 * s, Color(0.72, 0.48, 0.32))
			canvas.draw_circle(Vector2(0.0, -10.0 * s), 14.0 * s, Color(0.82, 0.58, 0.38))
			canvas.draw_circle(Vector2(-10.0 * s, -14.0 * s), 4.0 * s, Color(0.15, 0.15, 0.2))
			canvas.draw_circle(Vector2(10.0 * s, -14.0 * s), 4.0 * s, Color(0.15, 0.15, 0.2))
		4:
			for row in 3:
				for col in 3:
					var c := Color(0.4 + col * 0.15, 0.55, 0.85 - row * 0.1)
					canvas.draw_rect(
						Rect2(Vector2(-16.0 + col * 11.0, -16.0 + row * 11.0) * s, Vector2(9.0, 9.0) * s),
						c, true, 2.0 * s
					)
		_:
			pass


# --- Beach Party ---

static func _draw_beach(canvas: CanvasItem, slot: int, s: float) -> void:
	match slot:
		0:
			canvas.draw_circle(Vector2.ZERO, 12.0 * s, Color(0.95, 0.88, 0.78))
			for i in 5:
				var a := float(i) / 5.0 * TAU + 0.3
				canvas.draw_line(Vector2.ZERO, Vector2(cos(a), sin(a)) * 10.0 * s, Color(0.88, 0.78, 0.68), 2.0 * s)
		1:
			canvas.draw_circle(Vector2.ZERO, 14.0 * s, Color(0.98, 0.62, 0.28))
			for i in 5:
				var a := float(i) / 5.0 * TAU
				canvas.draw_line(Vector2.ZERO, Vector2(cos(a), sin(a)) * 16.0 * s, Color(0.92, 0.52, 0.18), 2.5 * s)
		2:
			canvas.draw_circle(Vector2.ZERO, 16.0 * s, Color(0.35, 0.75, 0.98))
			canvas.draw_arc(Vector2.ZERO, 16.0 * s, 0.0, TAU, 24, Color.WHITE, 3.0 * s)
		3:
			canvas.draw_rect(Rect2(-12.0 * s, -8.0 * s, 24.0 * s, 16.0 * s), Color(0.55, 0.82, 0.95), true, 4.0 * s)
			canvas.draw_rect(Rect2(-16.0 * s, 8.0 * s, 32.0 * s, 6.0 * s), Color(0.45, 0.72, 0.88), true, 3.0 * s)
		4:
			canvas.draw_rect(Rect2(-6.0 * s, -14.0 * s, 12.0 * s, 28.0 * s), Color(0.98, 0.55, 0.72), true, 4.0 * s)
			canvas.draw_circle(Vector2(0.0, -16.0 * s), 8.0 * s, Color(0.92, 0.82, 0.55))
		_:
			pass
