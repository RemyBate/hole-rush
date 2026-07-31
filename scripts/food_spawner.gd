class_name FoodSpawner
extends Node2D

const FoodScene: PackedScene = preload("res://scenes/food.tscn")
const START_HOLE_CLEAR_RADIUS: float = 170.0

signal food_collected(food: Food)

var _foods: Array[Food] = []
var _placed_positions: Array[Vector2] = []
var _placed_padding: Array[float] = []
var _theme: int = LevelTheme.Id.FRUIT_GARDEN
var _level: int = 1
var _spawn_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _spawn_bounds: Rect2 = Rect2()
var _hole_start: Vector2 = Vector2.ZERO
var _plan: LevelPlan = null


func spawn_level(
	bounds: Rect2,
	theme: int = LevelTheme.Id.FRUIT_GARDEN,
	level: int = 1,
	plan: LevelPlan = null
) -> void:
	clear_food()
	_theme = theme
	_level = clampi(level, 1, LevelTheme.MAX_LEVEL)
	_spawn_bounds = bounds
	_hole_start = bounds.position + bounds.size * 0.5
	_plan = plan
	_spawn_rng.seed = _level * 7919 + theme * 104729
	_placed_positions.clear()
	_placed_padding.clear()
	if plan != null and not plan.is_empty():
		LevelLayout.build_mixed_level(self, bounds.position, plan)
	else:
		LevelLayout.build_level(self, bounds.position, theme, _level)


func spawn_food(_count: int, bounds: Rect2) -> void:
	spawn_level(bounds, _theme, _level, _plan)


func spawn_item(pos: Vector2, slot: int, mission_highlight: bool = false) -> bool:
	return _try_spawn(pos, slot, mission_highlight)


func spawn_catalog_item(pos: Vector2, entry: ItemEntry, mission_highlight: bool = false) -> bool:
	return _try_spawn_catalog(pos, entry, mission_highlight)


func spawn_grid(
	center: Vector2,
	cols: int,
	rows: int,
	spacing: float,
	slot: int,
	offset: Vector2 = Vector2.ZERO,
	mission_highlight: bool = false
) -> void:
	var start := center - Vector2(cols - 1, rows - 1) * spacing * 0.5 + offset
	for row in rows:
		for col in cols:
			_try_spawn(start + Vector2(col, row) * spacing, slot, mission_highlight)


func spawn_catalog_grid(
	center: Vector2,
	cols: int,
	rows: int,
	spacing: float,
	entry: ItemEntry,
	mission_highlight: bool = false
) -> void:
	var start := center - Vector2(cols - 1, rows - 1) * spacing * 0.5
	for row in rows:
		for col in cols:
			_try_spawn_catalog(start + Vector2(col, row) * spacing, entry, mission_highlight)


func spawn_rows(
	center: Vector2,
	count: int,
	spacing: float,
	slot: int,
	mission_highlight: bool = false
) -> void:
	var start_x := center.x - (count - 1) * spacing * 0.5
	for i in count:
		_try_spawn(Vector2(start_x + i * spacing, center.y), slot, mission_highlight)


func spawn_catalog_rows(
	center: Vector2,
	count: int,
	spacing: float,
	entry: ItemEntry,
	mission_highlight: bool = false
) -> void:
	var start_x := center.x - (count - 1) * spacing * 0.5
	for i in count:
		_try_spawn_catalog(Vector2(start_x + i * spacing, center.y), entry, mission_highlight)


func spawn_circle(
	center: Vector2,
	count: int,
	radius: float,
	slot: int,
	mission_highlight: bool = false
) -> void:
	for i in count:
		var angle := float(i) / float(count) * TAU
		_try_spawn(center + Vector2(cos(angle), sin(angle)) * radius, slot, mission_highlight)


func spawn_catalog_circle(
	center: Vector2,
	count: int,
	radius: float,
	entry: ItemEntry,
	mission_highlight: bool = false
) -> void:
	for i in count:
		var angle := float(i) / float(count) * TAU
		_try_spawn_catalog(center + Vector2(cos(angle), sin(angle)) * radius, entry, mission_highlight)


func spawn_arc(
	center: Vector2,
	count: int,
	radius: float,
	angle_start: float,
	angle_end: float,
	slot: int,
	mission_highlight: bool = false
) -> void:
	for i in count:
		var t := float(i) / float(maxi(count - 1, 1))
		var angle := lerpf(angle_start, angle_end, t)
		_try_spawn(center + Vector2(cos(angle), sin(angle)) * radius, slot, mission_highlight)


func spawn_catalog_arc(
	center: Vector2,
	count: int,
	radius: float,
	angle_start: float,
	angle_end: float,
	entry: ItemEntry,
	mission_highlight: bool = false
) -> void:
	for i in count:
		var t := float(i) / float(maxi(count - 1, 1))
		var angle := lerpf(angle_start, angle_end, t)
		_try_spawn_catalog(center + Vector2(cos(angle), sin(angle)) * radius, entry, mission_highlight)


func spawn_scatter(
	center: Vector2,
	count: int,
	spread: float,
	slot: int,
	seed_offset: int = 0,
	mission_highlight: bool = false
) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(center.x + center.y + slot + seed_offset + _level)
	var placed := 0
	var attempts := 0
	while placed < count and attempts < count * 12:
		attempts += 1
		var offset := Vector2(
			rng.randf_range(-spread, spread),
			rng.randf_range(-spread, spread)
		)
		if _try_spawn(center + offset, slot, mission_highlight, rng):
			placed += 1


func spawn_catalog_scatter(
	center: Vector2,
	count: int,
	spread: float,
	entry: ItemEntry,
	seed_offset: int = 0,
	mission_highlight: bool = false
) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(center.x + center.y + entry.image_id + seed_offset + _level)
	var placed := 0
	var attempts := 0
	while placed < count and attempts < count * 12:
		attempts += 1
		var offset := Vector2(
			rng.randf_range(-spread, spread),
			rng.randf_range(-spread, spread)
		)
		if _try_spawn_catalog(center + offset, entry, mission_highlight):
			placed += 1


func _try_spawn(
	pos: Vector2,
	slot: int,
	mission_highlight: bool,
	rng: RandomNumberGenerator = null
) -> bool:
	var roll_rng := rng if rng != null else _spawn_rng
	var tier: int
	if CollectibleArt.is_textured_watermelon(_theme, slot):
		tier = CollectibleArt.watermelon_size_tier(slot)
	else:
		tier = ItemSizeTier.roll_tier(_level, _theme, roll_rng, mission_highlight)
	var pad := _padding_for_slot(slot, tier)
	if not _is_position_valid(pos, pad):
		return false
	var food: Food = FoodScene.instantiate() as Food
	food.setup(pos, slot as Food.Collectible, _theme, tier, mission_highlight)
	food.collected.connect(_on_food_collected)
	add_child(food)
	_foods.append(food)
	_placed_positions.append(pos)
	_placed_padding.append(pad)
	return true


func _try_spawn_catalog(pos: Vector2, entry: ItemEntry, mission_highlight: bool) -> bool:
	if entry == null or not entry.valid:
		return false
	var scale := LevelPlan.visual_scale_for(_level, entry.image_id)
	var visual_r := entry.visual_radius * scale
	var pad := visual_r * 0.88
	if not _is_position_valid(pos, pad):
		return false
	var food: Food = FoodScene.instantiate() as Food
	food.setup_catalog(pos, entry, _theme, mission_highlight, scale)
	food.collected.connect(_on_food_collected)
	add_child(food)
	_foods.append(food)
	_placed_positions.append(pos)
	_placed_padding.append(pad)
	return true


func _is_position_valid(pos: Vector2, pad: float) -> bool:
	if _spawn_bounds.size != Vector2.ZERO:
		var margin := GameConstants.FOOD_MARGIN + pad
		if not Rect2(
			_spawn_bounds.position + Vector2(margin, margin),
			_spawn_bounds.size - Vector2(margin, margin) * 2.0
		).has_point(pos):
			return false
	if pos.distance_to(_hole_start) < START_HOLE_CLEAR_RADIUS + pad:
		return false
	for i in _placed_positions.size():
		var needed := _placed_padding[i] + pad + LevelLayout.ITEM_GAP
		if pos.distance_to(_placed_positions[i]) < needed:
			return false
	return true


func _padding_for_slot(slot: int, tier: int) -> float:
	var base := CollectibleArt.visual_radius(_theme, slot)
	var scale := 1.0 if CollectibleArt.is_textured_watermelon(_theme, slot) else ItemSizeTier.visual_scale(tier)
	return base * scale * 0.85


func count_catalog_key(catalog_key: String) -> int:
	var n := 0
	for food in _foods:
		if is_instance_valid(food) and food.catalog_key == catalog_key:
			n += 1
	return n


func get_placed_positions() -> Array[Vector2]:
	return _placed_positions.duplicate()


func get_placed_paddings() -> Array[float]:
	return _placed_padding.duplicate()


func clear_food() -> void:
	for food in _foods:
		if is_instance_valid(food):
			food.queue_free()
	_foods.clear()
	_placed_positions.clear()
	_placed_padding.clear()


func _on_food_collected(food: Food) -> void:
	var idx := _foods.find(food)
	if idx >= 0:
		_placed_positions.remove_at(idx)
		_placed_padding.remove_at(idx)
	_foods.erase(food)
	food_collected.emit(food)
