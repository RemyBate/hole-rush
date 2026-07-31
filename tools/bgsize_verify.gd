extends Node

## Graphical verify: light-green field + larger sized catalog fruits at 405×720.


func _ready() -> void:
	await get_tree().process_frame
	ItemCatalog.reload()
	ItemCatalog.ensure_loaded(ItemCatalog.CATEGORY_FRUITS)

	var failed := 0
	# Force a high level that previously used Fast Food checkerboard.
	failed += await _check(23)
	failed += await _check(1)

	if failed > 0:
		push_error("[BGSIZE] FAILED %d" % failed)
		get_tree().quit(1)
	else:
		print("[BGSIZE] PASSED")
		get_tree().quit(0)


func _check(level: int) -> int:
	var failed := 0
	var packed: PackedScene = load("res://scenes/game.tscn")
	var game: Node2D = packed.instantiate() as Node2D
	add_child(game)
	game.begin_level(level, [])

	for _i in 14:
		await get_tree().process_frame
	await get_tree().create_timer(0.35).timeout

	var play_area: Node2D = game.get_node("PlayArea")
	var theme: int = int(play_area.get("_theme"))
	print("[BGSIZE] L", level, " play_area theme=", theme, " (0=FruitGarden)")
	if theme != LevelTheme.Id.FRUIT_GARDEN:
		push_error("[BGSIZE] expected Fruit Garden green field")
		failed += 1

	var foods := get_tree().get_nodes_in_group("food")
	var radii: Array[float] = []
	var classes: Dictionary = {}
	for food in foods:
		var f := food as Food
		if f == null or f.catalog_entry == null:
			continue
		var r := f.get_visual_radius()
		radii.append(r)
		var sc := f.catalog_entry.size_class
		classes[sc] = int(classes.get(sc, 0)) + 1
		if r < 15.0:
			push_error("[BGSIZE] still tiny radius=%s id=%d" % [r, f.catalog_entry.image_id])
			failed += 1
		# Collision should track visual.
		var col := f.get_collision_radius()
		if absf(col - r * f.catalog_entry.collision_scale) > 0.5:
			push_error("[BGSIZE] collision mismatch")
			failed += 1

	radii.sort()
	print("[BGSIZE] L", level, " foods=", foods.size(), " classes=", classes)
	if radii.size() > 0:
		print("[BGSIZE] radius min=", radii[0], " med=", radii[radii.size() / 2], " max=", radii[radii.size() - 1])
		if radii[radii.size() - 1] < 40.0:
			push_error("[BGSIZE] no large items visible")
			failed += 1
		if radii[0] > 35.0 and classes.size() < 2:
			push_error("[BGSIZE] missing small variation")
			failed += 1

	RenderingServer.force_draw()
	await get_tree().process_frame
	var img: Image = get_viewport().get_texture().get_image()
	if img:
		var path := ProjectSettings.globalize_path("res://tools/bgsize_l%d_verify.png" % level)
		img.save_png(path)
		print("[BGSIZE] screenshot=", path)

	game.queue_free()
	await get_tree().process_frame
	return failed
