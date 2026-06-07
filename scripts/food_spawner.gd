class_name FoodSpawner
extends Node2D

const FoodScene: PackedScene = preload("res://scenes/food.tscn")

signal food_collected(food: Food)

var _foods: Array[Food] = []
var _placed_positions: Array[Vector2] = []
var _placed_padding: Array[float] = []
var _theme: int = LevelTheme.Id.FRUIT_GARDEN
var _level: int = 1
var _spawn_rng: RandomNumberGenerator = RandomNumberGenerator.new()


func spawn_level(bounds: Rect2, theme: int = LevelTheme.Id.FRUIT_GARDEN, level: int = 1) -> void:
	clear_food()
	_theme = theme
	_level = clampi(level, 1, LevelTheme.MAX_LEVEL)
	_spawn_rng.seed = _level * 7919 + theme * 104729
	_placed_positions.clear()
	_placed_padding.clear()
	LevelLayout.build_level(self, bounds.position, theme)


func spawn_food(_count: int, bounds: Rect2) -> void:
	spawn_level(bounds, _theme, _level)


func spawn_item(pos: Vector2, slot: int, mission_highlight: bool = false) -> bool:
	return _try_spawn(pos, slot, mission_highlight)


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


func _try_spawn(
	pos: Vector2,
	slot: int,
	mission_highlight: bool,
	rng: RandomNumberGenerator = null
) -> bool:
	var roll_rng := rng if rng != null else _spawn_rng
	var tier := ItemSizeTier.roll_tier(_level, _theme, roll_rng, mission_highlight)
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


func _is_position_valid(pos: Vector2, pad: float) -> bool:
	for i in _placed_positions.size():
		var needed := _placed_padding[i] + pad + LevelLayout.ITEM_GAP
		if pos.distance_to(_placed_positions[i]) < needed:
			return false
	return true


func _padding_for_slot(slot: int, tier: int) -> float:
	var base := CollectibleArt.visual_radius(_theme, slot)
	return base * ItemSizeTier.visual_scale(tier) * 0.85


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
