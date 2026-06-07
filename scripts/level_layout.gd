class_name LevelLayout
extends RefCounted

const ITEM_GAP: float = 16.0
const OBSTACLE_CLEAR_RADIUS: float = 0.0
const HUB_LANE: float = 58.0

## Twelve open zones — fewer clusters, more travel space.
const ZONES: Array[Vector2] = [
	Vector2(700.0, 520.0),
	Vector2(1600.0, 520.0),
	Vector2(2500.0, 520.0),
	Vector2(700.0, 1200.0),
	Vector2(1600.0, 1200.0),
	Vector2(2500.0, 1200.0),
	Vector2(700.0, 1880.0),
	Vector2(1600.0, 1880.0),
	Vector2(2500.0, 1880.0),
	Vector2(1150.0, 860.0),
	Vector2(2050.0, 860.0),
	Vector2(1600.0, 1540.0),
]


static func build_level(spawner: FoodSpawner, origin: Vector2, _theme: int) -> void:
	for i in ZONES.size():
		_build_zone(spawner, origin + ZONES[i], i)
	_build_connector_accent(spawner, origin)


static func _build_zone(spawner: FoodSpawner, center: Vector2, variant: int) -> void:
	var lane := HUB_LANE
	var v := variant % 4

	# Mission groups (slots 0, 1, 3).
	match v:
		0:
			spawner.spawn_grid(center + Vector2(-lane * 2.0, -lane * 1.4), 4, 3, 58.0, 0, Vector2.ZERO, true)
			spawner.spawn_circle(center + Vector2(lane * 1.8, -lane * 1.0), 7, 74.0, 1, true)
			spawner.spawn_rows(center + Vector2(-lane * 1.2, lane * 1.8), 5, 64.0, 3, true)
		1:
			spawner.spawn_rows(center + Vector2(-lane * 1.8, -lane * 1.6), 5, 56.0, 0, true)
			spawner.spawn_rows(center + Vector2(lane * 1.4, -lane * 1.4), 5, 56.0, 1, true)
			spawner.spawn_grid(center + Vector2(-lane * 1.0, lane * 1.6), 4, 2, 66.0, 3, Vector2.ZERO, true)
		2:
			spawner.spawn_grid(center + Vector2(-lane * 1.8, lane * 1.2), 3, 4, 60.0, 0, Vector2.ZERO, true)
			spawner.spawn_arc(center + Vector2(lane * 2.0, -lane * 0.4), 6, 80.0, -0.7, 0.7, 1, true)
			spawner.spawn_rows(center + Vector2(0.0, lane * 2.0), 5, 60.0, 3, true)
		3:
			spawner.spawn_circle(center + Vector2(-lane * 1.8, -lane * 0.6), 8, 70.0, 0, true)
			spawner.spawn_grid(center + Vector2(lane * 1.4, -lane * 1.4), 4, 3, 58.0, 1, Vector2.ZERO, true)
			spawner.spawn_rows(center + Vector2(lane * 0.4, lane * 1.8), 4, 68.0, 3, true)

	# Supporting collectibles — lighter fill.
	spawner.spawn_scatter(center + Vector2(-lane * 2.4, lane * 0.2), 3, 24.0, 2, v)
	spawner.spawn_scatter(center + Vector2(lane * 2.2, lane * 0.4), 3, 24.0, 4, v + 3)
	spawner.spawn_rows(center + Vector2(lane * 0.2, -lane * 2.2), 4, 52.0, 2)


static func _build_connector_accent(spawner: FoodSpawner, origin: Vector2) -> void:
	var points: Array[Vector2] = [
		origin + Vector2(1150.0, 700.0),
		origin + Vector2(2050.0, 700.0),
		origin + Vector2(1150.0, 1700.0),
		origin + Vector2(2050.0, 1700.0),
	]
	for i in points.size():
		spawner.spawn_scatter(points[i], 2, 26.0, 2, 50 + i)
		spawner.spawn_scatter(points[i] + Vector2(40.0, 50.0), 2, 22.0, 4, 60 + i)
