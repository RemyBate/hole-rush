extends Node

## Graphical verify: size classes + transparent padding compensation.


func _ready() -> void:
	await get_tree().process_frame
	ItemCatalog.reload()
	ItemCatalog.ensure_loaded(ItemCatalog.CATEGORY_FRUITS)
	_report_padding()
	var failed := await _showcase_classes()
	failed += await _check_level(1)
	if failed > 0:
		push_error("[SIZEPAD] FAILED %d" % failed)
		get_tree().quit(1)
	else:
		print("[SIZEPAD] PASSED")
		get_tree().quit(0)


func _vp_size() -> Vector2:
	return get_viewport().get_visible_rect().size


func _report_padding() -> void:
	print("[SIZEPAD] --- content_fill by image id ---")
	var padded: Array[String] = []
	for e in ItemCatalog.valid_entries():
		var entry := e as ItemEntry
		print(
			"[SIZEPAD] id=", entry.image_id,
			" class=", entry.size_class,
			" diam=", entry.visual_diameter(),
			" fill=", snappedf(entry.content_fill, 0.01),
			" rect=", entry.content_rect
		)
		if entry.content_fill < 0.55:
			padded.append("%d(fill=%.2f)" % [entry.image_id, entry.content_fill])
	if padded.is_empty():
		print("[SIZEPAD] no large transparent padding (all fill>=0.55)")
	else:
		print("[SIZEPAD] large padding IDs: ", ", ".join(padded))


func _showcase_classes() -> int:
	var failed := 0
	var vp := _vp_size()
	var sx := vp.x / 405.0
	var sy := vp.y / 720.0

	var bg := ColorRect.new()
	bg.color = Color(0.55, 0.82, 0.48, 1.0)
	bg.size = vp
	bg.z_index = -10
	add_child(bg)

	var root := Node2D.new()
	add_child(root)

	var by_class: Dictionary = {}
	for e in ItemCatalog.valid_entries():
		var entry := e as ItemEntry
		if not by_class.has(entry.size_class):
			by_class[entry.size_class] = entry

	var labels := {
		ItemEntry.SizeClass.EXTRA_SMALL: "XS",
		ItemEntry.SizeClass.SMALL: "S",
		ItemEntry.SizeClass.MEDIUM: "M",
		ItemEntry.SizeClass.LARGE: "L",
		ItemEntry.SizeClass.EXTRA_LARGE: "XL",
	}
	var order: Array[int] = [
		ItemEntry.SizeClass.EXTRA_SMALL,
		ItemEntry.SizeClass.SMALL,
		ItemEntry.SizeClass.MEDIUM,
		ItemEntry.SizeClass.LARGE,
		ItemEntry.SizeClass.EXTRA_LARGE,
	]

	# Mission-style HUD row
	var hx := 10.0 * sx
	for sc in order:
		if not by_class.has(sc):
			continue
		var entry_hud: ItemEntry = by_class[sc]
		var panel := ColorRect.new()
		panel.color = Color(0.18, 0.42, 0.86, 0.95)
		panel.position = Vector2(hx, 8.0 * sy)
		panel.size = Vector2(72.0 * sx, 92.0 * sy)
		add_child(panel)
		var tr := TextureRect.new()
		tr.texture = entry_hud.hud_texture()
		tr.position = Vector2(hx + 8.0 * sx, 12.0 * sy)
		tr.size = Vector2(56.0 * sx, 56.0 * sy)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		add_child(tr)
		var cnt := Label.new()
		cnt.text = "0/3"
		cnt.position = Vector2(hx + 14.0 * sx, 70.0 * sy)
		cnt.add_theme_font_size_override("font_size", int(16.0 * sy))
		cnt.add_theme_color_override("font_color", Color.WHITE)
		add_child(cnt)
		hx += 78.0 * sx

	var hole := _ShowcaseHole.new()
	hole.position = Vector2(vp.x * 0.78, vp.y * 0.42)
	hole.radius = GameConstants.INITIAL_HOLE_RADIUS * sx
	root.add_child(hole)
	var hole_lbl := Label.new()
	hole_lbl.text = "hole Ø%.0f" % (GameConstants.INITIAL_HOLE_RADIUS * 2.0)
	hole_lbl.position = hole.position + Vector2(-40.0 * sx, hole.radius + 8.0 * sy)
	hole_lbl.add_theme_font_size_override("font_size", int(16.0 * sy))
	hole_lbl.add_theme_color_override("font_color", Color(0.1, 0.15, 0.1))
	add_child(hole_lbl)

	var y := 130.0 * sy
	var x := 100.0 * sx
	for sc in order:
		if not by_class.has(sc):
			push_error("[SIZEPAD] missing size class %d" % sc)
			failed += 1
			continue
		var entry: ItemEntry = by_class[sc]
		var r := entry.visual_radius * sx
		var fruit := _ShowcaseFruit.new()
		fruit.position = Vector2(x, y)
		fruit.texture = entry.texture
		fruit.visual_radius = r
		fruit.content_fill = entry.content_fill
		fruit.content_span_px = entry.content_span_px
		fruit.source_max_px = entry.source_max_px
		root.add_child(fruit)

		var lbl := Label.new()
		lbl.text = "%s id=%d  Ø%.0f" % [labels[sc], entry.image_id, entry.visual_diameter()]
		lbl.position = Vector2(x + r + 14.0 * sx, y - 12.0 * sy)
		lbl.add_theme_font_size_override("font_size", int(18.0 * sy))
		lbl.add_theme_color_override("font_color", Color(0.08, 0.18, 0.08))
		add_child(lbl)

		print(
			"[SIZEPAD] showcase ", labels[sc],
			" id=", entry.image_id,
			" diam=", entry.visual_diameter(),
			" fill=", snappedf(entry.content_fill, 0.01)
		)
		if entry.visual_diameter() < 70.0:
			push_error("[SIZEPAD] diameter below readable min")
			failed += 1

		y += maxf(r * 2.0, 78.0 * sy) + 18.0 * sy

	for _i in 10:
		await get_tree().process_frame
	RenderingServer.force_draw()
	await get_tree().process_frame
	var img: Image = get_viewport().get_texture().get_image()
	if img:
		var path := ProjectSettings.globalize_path("res://tools/sizepad_classes_verify.png")
		img.save_png(path)
		print("[SIZEPAD] screenshot=", path)

	for c in get_children():
		c.queue_free()
	await get_tree().process_frame
	return failed


func _check_level(level: int) -> int:
	var failed := 0
	var packed: PackedScene = load("res://scenes/game.tscn")
	var game: Node2D = packed.instantiate() as Node2D
	add_child(game)
	game.begin_level(level, [])

	for _i in 14:
		await get_tree().process_frame
	await get_tree().create_timer(0.35).timeout

	var foods := get_tree().get_nodes_in_group("food")
	var radii: Array[float] = []
	var classes: Dictionary = {}
	var min_readable := ItemEntry.radius_for_class(ItemEntry.SizeClass.EXTRA_SMALL) * 0.98
	for food in foods:
		var f := food as Food
		if f == null or f.catalog_entry == null:
			continue
		var r := f.get_visual_radius()
		radii.append(r)
		var sc := f.catalog_entry.size_class
		classes[sc] = int(classes.get(sc, 0)) + 1
		if r + 0.01 < min_readable:
			push_error("[SIZEPAD] below min readable radius=%s id=%d" % [r, f.catalog_entry.image_id])
			failed += 1
		var col := f.get_collision_radius()
		if absf(col - r * f.catalog_entry.collision_scale) > 0.5:
			push_error("[SIZEPAD] collision mismatch id=%d" % f.catalog_entry.image_id)
			failed += 1

	radii.sort()
	print("[SIZEPAD] L", level, " foods=", foods.size(), " classes=", classes)
	if radii.size() > 0:
		print(
			"[SIZEPAD] radius min=", radii[0],
			" med=", radii[radii.size() / 2],
			" max=", radii[radii.size() - 1]
		)

	RenderingServer.force_draw()
	await get_tree().process_frame
	var img: Image = get_viewport().get_texture().get_image()
	if img:
		var path := ProjectSettings.globalize_path("res://tools/sizepad_l%d_verify.png" % level)
		img.save_png(path)
		print("[SIZEPAD] screenshot=", path)

	game.queue_free()
	await get_tree().process_frame
	return failed


class _ShowcaseFruit extends Node2D:
	var texture: Texture2D
	var visual_radius: float = 39.0
	var content_fill: float = 0.85
	var content_span_px: float = 0.0
	var source_max_px: float = 0.0

	func _draw() -> void:
		CollectibleArt.draw_catalog_texture(
			self, texture, visual_radius, content_fill, content_span_px, source_max_px
		)
		draw_arc(Vector2.ZERO, visual_radius, 0.0, TAU, 40, Color(1, 1, 1, 0.4), 1.5)


class _ShowcaseHole extends Node2D:
	var radius: float = 48.0

	func _draw() -> void:
		draw_circle(Vector2.ZERO, radius, Color(0.05, 0.05, 0.08, 0.95))
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, Color(0.9, 0.9, 1.0, 0.75), 2.5)
