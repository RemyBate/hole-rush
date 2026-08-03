class_name ItemCatalog
extends RefCounted

## Discovers numbered PNGs under res://assets/items/<category>/.
## No fruit-name mapping — numeric filename is the ID.

const CATEGORY_FRUITS: String = "fruits"
const BASE_DIR: String = "res://assets/items"

## category -> Array[ItemEntry]
static var _entries: Dictionary = {}
static var _invalid: Dictionary = {}
static var _loaded: Dictionary = {}


static func ensure_loaded(category: String = CATEGORY_FRUITS) -> void:
	if bool(_loaded.get(category, false)):
		return
	_entries[category] = []
	_invalid[category] = []
	var dir_path := "%s/%s" % [BASE_DIR, category]
	var da := DirAccess.open(dir_path)
	if da == null:
		push_warning("ItemCatalog: cannot open %s" % dir_path)
		_loaded[category] = true
		return

	var ids: Array[int] = []
	da.list_dir_begin()
	var file_name := da.get_next()
	while file_name != "":
		if not da.current_is_dir() and file_name.ends_with(".png") and not file_name.ends_with(".import"):
			var stem := file_name.get_basename()
			if stem.is_valid_int():
				var id := int(stem)
				if id > 0:
					ids.append(id)
			else:
				(_invalid[category] as Array).append("%s (non-numeric name)" % file_name)
		file_name = da.get_next()
	da.list_dir_end()
	ids.sort()

	var seen: Dictionary = {}
	for id in ids:
		if seen.has(id):
			(_invalid[category] as Array).append("%d.png (duplicate id)" % id)
			continue
		seen[id] = true
		var entry := _build_entry(category, id)
		if entry.valid:
			(_entries[category] as Array).append(entry)
		else:
			(_invalid[category] as Array).append("%d.png (%s)" % [id, entry.invalid_reason])
			print("[ItemCatalog] excluded ", entry.path, " — ", entry.invalid_reason)

	_loaded[category] = true
	print(
		"[ItemCatalog] ", category, ": valid=", (_entries[category] as Array).size(),
		" invalid=", (_invalid[category] as Array).size()
	)


static func _build_entry(category: String, image_id: int) -> ItemEntry:
	var entry := ItemEntry.new()
	entry.category = category
	entry.image_id = image_id
	entry.path = "%s/%s/%d.png" % [BASE_DIR, category, image_id]

	if not ResourceLoader.exists(entry.path) and not FileAccess.file_exists(entry.path):
		entry.invalid_reason = "file missing"
		return entry

	var img := Image.load_from_file(ProjectSettings.globalize_path(entry.path))
	if img == null:
		# Fallback via resource load after import.
		var tex_try: Texture2D = load(entry.path) as Texture2D
		if tex_try == null:
			entry.invalid_reason = "failed to load"
			return entry
		img = tex_try.get_image()
		if img == null:
			entry.invalid_reason = "no image data"
			return entry

	if img.get_format() != Image.FORMAT_RGBA8:
		img.convert(Image.FORMAT_RGBA8)

	var w := img.get_width()
	var h := img.get_height()
	if w < 8 or h < 8:
		entry.invalid_reason = "image too small"
		return entry

	var corner := img.get_pixel(0, 0)
	if corner.a > 0.15:
		# Opaque corner often means baked background.
		var avg := (corner.r + corner.g + corner.b) / 3.0
		if avg < 0.12 or avg > 0.92 or absf(corner.r - corner.g) < 0.04:
			entry.invalid_reason = "opaque corner (possible baked background)"
			return entry

	var transparent := 0
	var opaque := 0
	var total := w * h
	var step := maxi(1, int(sqrt(float(total) / 8000.0)))
	var sampled := 0
	for y in range(0, h, step):
		for x in range(0, w, step):
			var a := img.get_pixel(x, y).a
			sampled += 1
			if a <= 0.02:
				transparent += 1
			elif a >= 0.98:
				opaque += 1

	var transparent_ratio := float(transparent) / float(maxi(sampled, 1))
	if transparent_ratio < 0.08:
		entry.invalid_reason = "too few transparent pixels (%.0f%%)" % (transparent_ratio * 100.0)
		return entry

	var bbox := _opaque_content_rect(img, 0.22)
	var fill := 0.75
	if bbox.size.x > 0 and bbox.size.y > 0:
		fill = maxf(float(bbox.size.x) / float(w), float(bbox.size.y) / float(h))
		entry.content_rect = bbox
		entry.content_span_px = float(maxi(bbox.size.x, bbox.size.y))
	entry.source_max_px = float(maxi(w, h))
	# Slightly under-report fill so soft fringe does not leave fruits looking undersized.
	entry.content_fill = clampf(fill * 0.88, 0.18, 0.92)
	if entry.content_span_px < 4.0:
		entry.content_span_px = entry.source_max_px * entry.content_fill
	if entry.content_fill < 0.55:
		print(
			"[ItemCatalog] large transparent padding: ", entry.path,
			" content_fill=", snappedf(entry.content_fill, 0.01),
			" bbox=", bbox, " / ", w, "x", h
		)

	# Stable size class: deterministic ID spread + content-density bias (no fruit names).
	var content_ratio := 1.0 - transparent_ratio
	var size_class := _stable_size_class(image_id, content_ratio)
	entry.size_class = size_class
	entry.visual_radius = ItemEntry.radius_for_class(size_class)
	entry.score_value = ItemEntry.score_for_class(size_class)
	entry.growth_bonus = ItemEntry.growth_for_class(size_class)
	entry.spawn_weight = 1.25 - float(size_class) * 0.1

	var tex: Texture2D = load(entry.path) as Texture2D
	if tex == null:
		var img_tex := ImageTexture.create_from_image(img)
		tex = img_tex
	if tex == null:
		entry.invalid_reason = "texture load failed"
		return entry

	entry.texture = tex
	entry.valid = true
	entry.mission_eligible = true
	return entry


## Bounding rect of pixels with alpha above threshold (ignores soft fringe).
static func _opaque_content_rect(img: Image, alpha_threshold: float) -> Rect2i:
	var w := img.get_width()
	var h := img.get_height()
	var min_x := w
	var min_y := h
	var max_x := -1
	var max_y := -1
	var step := maxi(1, int(sqrt(float(w * h) / 25000.0)))
	for y in range(0, h, step):
		for x in range(0, w, step):
			if img.get_pixel(x, y).a > alpha_threshold:
				min_x = mini(min_x, x)
				min_y = mini(min_y, y)
				max_x = maxi(max_x, x)
				max_y = maxi(max_y, y)
	if max_x < min_x:
		return img.get_used_rect()
	# Small expand only — avoid inflating fill with empty fringe.
	var pad := maxi(1, step)
	min_x = maxi(0, min_x - pad)
	min_y = maxi(0, min_y - pad)
	max_x = mini(w - 1, max_x + pad)
	max_y = mini(h - 1, max_y + pad)
	return Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)


## Spread numbered IDs across size classes with a medium/large bias for mobile readability.
static func _stable_size_class(image_id: int, content_ratio: float) -> int:
	# Prefer Medium/Large so field items are recognisable on 405×720.
	# Pattern repeats every 8 IDs: S, M, M, L, XS, M, L, XL
	var pattern: Array[int] = [
		ItemEntry.SizeClass.SMALL,
		ItemEntry.SizeClass.MEDIUM,
		ItemEntry.SizeClass.MEDIUM,
		ItemEntry.SizeClass.LARGE,
		ItemEntry.SizeClass.EXTRA_SMALL,
		ItemEntry.SizeClass.MEDIUM,
		ItemEntry.SizeClass.LARGE,
		ItemEntry.SizeClass.EXTRA_LARGE,
	]
	var base: int = pattern[(image_id - 1) % pattern.size()]
	if content_ratio >= 0.38:
		base = maxi(base, ItemEntry.SizeClass.LARGE)
	elif content_ratio >= 0.32:
		base = maxi(base, ItemEntry.SizeClass.MEDIUM)
	elif content_ratio < 0.16:
		base = mini(base, ItemEntry.SizeClass.SMALL)
	return clampi(base, ItemEntry.SizeClass.EXTRA_SMALL, ItemEntry.SizeClass.EXTRA_LARGE)


static func reload(category: String = CATEGORY_FRUITS) -> void:
	_loaded[category] = false
	_entries[category] = []
	_invalid[category] = []
	ensure_loaded(category)


static func valid_entries(category: String = CATEGORY_FRUITS) -> Array:
	ensure_loaded(category)
	return (_entries.get(category, []) as Array).duplicate()


static func invalid_reports(category: String = CATEGORY_FRUITS) -> Array:
	ensure_loaded(category)
	return (_invalid.get(category, []) as Array).duplicate()


static func get_entry(category: String, image_id: int) -> ItemEntry:
	ensure_loaded(category)
	for e in (_entries.get(category, []) as Array):
		var entry := e as ItemEntry
		if entry and entry.image_id == image_id:
			return entry
	return null


static func get_by_key(catalog_key: String) -> ItemEntry:
	var parts := catalog_key.split(":")
	if parts.size() != 2:
		return null
	return get_entry(parts[0], int(parts[1]))


static func valid_ids(category: String = CATEGORY_FRUITS) -> Array[int]:
	var out: Array[int] = []
	for e in valid_entries(category):
		out.append((e as ItemEntry).image_id)
	return out
