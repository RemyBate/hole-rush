class_name CurrencySpawner
extends Node2D

const PickupScene: PackedScene = preload("res://scenes/currency_pickup.tscn")

signal pickup_collected(pickup: CurrencyPickup)

var _pickups: Array[CurrencyPickup] = []
var _placed_positions: Array[Vector2] = []
var _placed_padding: Array[float] = []
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func spawn_level(bounds: Rect2, level: int, food_spawner: FoodSpawner) -> void:
	clear_pickups()
	_rng.seed = level * 13337 + 9001
	_placed_positions.clear()
	_placed_padding.clear()
	if food_spawner != null:
		for pos in food_spawner.get_placed_positions():
			_placed_positions.append(pos)
		for pad in food_spawner.get_placed_paddings():
			_placed_padding.append(pad)

	var margin := 48.0
	var inner := bounds.grow(-margin)
	var coin_count := clampi(10 + level / 3, 10, 28)
	var gem_count := clampi(2 + level / 12, 2, 6)
	var key_count := 1 if level % 4 == 0 else 0
	if level >= 10 and level % 5 == 0:
		key_count += 1
	var trophy_count := 1 if level % 8 == 0 else 0

	_spawn_kind(inner, CurrencyArt.Kind.COIN, coin_count, 14.0)
	_spawn_kind(inner, CurrencyArt.Kind.GEM, gem_count, 16.0)
	_spawn_kind(inner, CurrencyArt.Kind.KEY, key_count, 17.0)
	_spawn_kind(inner, CurrencyArt.Kind.TROPHY, trophy_count, 18.0)


func _spawn_kind(bounds: Rect2, kind: CurrencyArt.Kind, count: int, pad: float) -> void:
	var placed := 0
	var attempts := 0
	while placed < count and attempts < count * 20:
		attempts += 1
		var pos := Vector2(
			_rng.randf_range(bounds.position.x, bounds.position.x + bounds.size.x),
			_rng.randf_range(bounds.position.y, bounds.position.y + bounds.size.y)
		)
		if not _is_position_valid(pos, pad):
			continue
		var pickup := PickupScene.instantiate() as CurrencyPickup
		var gem_idx := _rng.randi_range(0, 3) if kind == CurrencyArt.Kind.GEM else 0
		pickup.setup(pos, kind, gem_idx)
		pickup.collected.connect(_on_pickup_collected)
		add_child(pickup)
		_pickups.append(pickup)
		_placed_positions.append(pos)
		_placed_padding.append(pad)
		placed += 1


func _is_position_valid(pos: Vector2, pad: float) -> bool:
	for i in _placed_positions.size():
		var needed := _placed_padding[i] + pad + LevelLayout.ITEM_GAP
		if pos.distance_to(_placed_positions[i]) < needed:
			return false
	return true


func clear_pickups() -> void:
	for pickup in _pickups:
		if is_instance_valid(pickup):
			pickup.queue_free()
	_pickups.clear()
	_placed_positions.clear()
	_placed_padding.clear()


func _on_pickup_collected(pickup: CurrencyPickup) -> void:
	var idx := _pickups.find(pickup)
	if idx >= 0:
		_placed_positions.remove_at(idx)
		_placed_padding.remove_at(idx)
	_pickups.erase(pickup)
	pickup_collected.emit(pickup)
