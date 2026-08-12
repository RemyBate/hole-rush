class_name ItemCatalog
extends RefCounted

## Discovers numbered PNGs under res://assets/items/<category>/.
## No fruit-name mapping — numeric filename is the ID.

const CATEGORY_FRUITS: String = "fruits"
const BASE_DIR: String = "res://assets/items"
## Probe range when exported packs only expose .import/.ctex (no raw PNG listing).
const MAX_ID_PROBE: int = 64


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
	var ids: Array[int] = []
	var seen: Dictionary = {}

	var da := DirAccess.open(dir_path)
	if da != null:
		da.list_dir_begin()
		var file_name := da.get_next()
		while file_name != "":
			if not da.current_is_dir():
				var id := _parse_numbered_id(file_name)
				if id > 0 and not seen.has(id):
					seen[id] = true
					ids.append(id)
				elif id < 0:
					(_invalid[category] as Array).append("%s (non-numeric name)" % file_name)
			file_name = da.get_next()
		da.list_dir_end()
	else:
		# Optional theme folders (vegetables/fast_food/pizzas) fall back to fruits.
		print("[ItemCatalog] no folder for %s — probing ResourceLoader ids" % category)

	# Android export often lists only *.png.import (or nothing usable). Always probe
	# ResourceLoader so packaged .ctex remaps still register as fruits:N.
	for id in range(1, MAX_ID_PROBE + 1):
		if seen.has(id):
			continue
		var path := "%s/%s/%d.png" % [BASE_DIR, category, id]
		if ResourceLoader.exists(path) or FileAccess.file_exists(path):
			seen[id] = true
			ids.append(id)

	ids.sort()
	if ids.is_empty():
		print("[ItemCatalog] %s: no numbered textures found" % category)
		_loaded[category] = true
		return

	for id in ids:
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


## Accepts "12.png", "12.png.import", "12.PNG".
static func _parse_numbered_id(file_name: String) -> int:
	var name := file_name
	if name.ends_with(".import"):
		name = name.substr(0, name.length() - ".import".length())
	if not name.to_lower().ends_with(".png"):
		return 0
	var stem := name.get_basename()
	if stem.is_valid_int():
		var id := int(stem)
		return id if id > 0 else 0
	return -1


static func _build_entry(category: String, image_id: int) -> ItemEntry:
	var entry := ItemEntry.new()
	entry.category = category
	entry.image_id = image_id
	entry.path = "%s/%s/%d.png" % [BASE_DIR, category, image_id]

	if not ResourceLoader.exists(entry.path) and not FileAccess.file_exists(entry.path):
		entry.invalid_reason = "file missing"
		return entry

	# Prefer imported Texture2D (works on Android with .ctex remaps).
	var tex: Texture2D = load(entry.path) as Texture2D

	# Optional CPU image for size-class analysis + cropped HUD bake.
	var img: Image = null
	var abs_path := ProjectSettings.globalize_path(entry.path)
	if FileAccess.file_exists(entry.path) or FileAccess.file_exists(abs_path):
		img = Image.load_from_file(abs_path)
	if img == null and tex != null:
		img = tex.get_image()

	if tex == null and img != null:
		tex = ImageTexture.create_from_image(img)
	if tex == null:
		entry.invalid_reason = "texture load failed"
		return entry

	entry.texture = tex

	if img == null:
		# Mobile compressed textures often cannot expose CPU pixels. Keep the entry
		# valid and show the full imported texture in HUD cards.
		entry.size_class = _stable_size_class(image_id, 0.30)
		entry.visual_radius = ItemEntry.radius_for_class(entry.size_class)
		entry.score_value = ItemEntry.score_for_class(entry.size_class)
		entry.growth_bonus = ItemEntry.growth_for_class(entry.size_class)
		entry.spawn_weight = 1.25 - float(entry.size_class) * 0.1
		entry.content_fill = 0.8
		entry.hud_preview = tex
		entry.valid = true
		entry.mission_eligible = true
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

	# Bake cropped HUD ImageTexture once (desktop / when CPU pixels exist).
	entry.hud_preview = _bake_hud_preview(img, entry.content_rect, tex)

	entry.valid = true
	entry.mission_eligible = true
	return entry


static func _bake_hud_preview(img: Image, content_rect: Rect2i, fallback: Texture2D) -> Texture2D:
	if img == null:
		return fallback
	var region := content_rect
	if region.size.x < 4 or region.size.y < 4:
		region = Rect2i(0, 0, img.get_width(), img.get_height())
	region = region.intersection(Rect2i(0, 0, img.get_width(), img.get_height()))
	if region.size.x < 4 or region.size.y < 4:
		return fallback
	var cropped := img.get_region(region)
	# Normalize to a readable HUD size so TextureRect never collapses to a speck.
	var max_side := maxi(cropped.get_width(), cropped.get_height())
	if max_side > 0 and max_side < 64:
		var scale := 64.0 / float(max_side)
		cropped.resize(
			maxi(64, int(cropped.get_width() * scale)),
			maxi(64, int(cropped.get_height() * scale)),
			Image.INTERPOLATE_BILINEAR
		)
	elif max_side > 256:
		var scale_down := 256.0 / float(max_side)
		cropped.resize(
			maxi(64, int(cropped.get_width() * scale_down)),
			maxi(64, int(cropped.get_height() * scale_down)),
			Image.INTERPOLATE_BILINEAR
		)
	return ImageTexture.create_from_image(cropped)


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


static func reload_category(category: String = CATEGORY_FRUITS) -> void:
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
