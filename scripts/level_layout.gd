class_name LevelLayout
extends RefCounted

const ITEM_GAP: float = 48.0
const OBSTACLE_CLEAR_RADIUS: float = 0.0
const HUB_LANE: float = 70.0
## Extra items beyond mission targets so levels stay completable.
const SPAWN_MARGIN: int = 2

## Twelve open zones — fewer clusters, more travel space.
const ZONES: Array[Vector2] = [
	Vector2(700.0, 540.0),
	Vector2(1600.0, 540.0),
	Vector2(2500.0, 540.0),
	Vector2(700.0, 1220.0),
	Vector2(1600.0, 1220.0),
	Vector2(2500.0, 1220.0),
	Vector2(700.0, 1900.0),
	Vector2(1600.0, 1900.0),
	Vector2(2500.0, 1900.0),
	Vector2(1150.0, 880.0),
	Vector2(2050.0, 880.0),
	Vector2(1600.0, 1560.0),
]


static func build_level(spawner: FoodSpawner, origin: Vector2, theme: int, level: int = 1) -> void:
	if theme == LevelTheme.Id.FRUIT_GARDEN:
		_build_fruit_garden_level(spawner, origin, level)
		return
	for i in ZONES.size():
		_build_zone(spawner, origin + ZONES[i], i)
	_build_connector_accent(spawner, origin)


## Mixed numbered-image levels (Level 4+): varied formations for ~10 types.
static func build_mixed_level(spawner: FoodSpawner, origin: Vector2, plan: LevelPlan) -> void:
	if plan == null or plan.is_empty():
		return

	var target_map: Dictionary = {}
	for t in plan.targets:
		var key: String = str(t.get("catalog_key", ""))
		target_map[key] = t

	# Zone centers for formations (avoid HUD top strip / hole center).
	var zones: Array[Vector2] = [
		origin + Vector2(700.0, 640.0),
		origin + Vector2(1600.0, 540.0),
		origin + Vector2(2500.0, 640.0),
		origin + Vector2(700.0, 1320.0),
		origin + Vector2(2500.0, 1320.0),
		origin + Vector2(700.0, 2020.0),
		origin + Vector2(1600.0, 2120.0),
		origin + Vector2(2500.0, 2020.0),
		origin + Vector2(1100.0, 980.0),
		origin + Vector2(2100.0, 980.0),
	]

	var entries: Array = plan.field_entries.duplicate()
	# Largest first for placement stability.
	entries.sort_custom(func(a, b): return (a as ItemEntry).visual_radius > (b as ItemEntry).visual_radius)

	var pattern_names: Array[String] = []
	for i in entries.size():
		var entry: ItemEntry = entries[i]
		var zone: Vector2 = zones[i % zones.size()]
		var is_target := target_map.has(entry.catalog_key())
		var count := _mixed_spawn_count(entry, target_map, is_target)
		var pattern := (i + plan.level) % 10
		_place_mixed_pattern(spawner, zone, entry, count, pattern, is_target, pattern_names)

	# Near-hole mix: small for early swallow + medium/large so sizes are obvious at start.
	var smalls: Array = []
	var mediums: Array = []
	var larges: Array = []
	for e in plan.field_entries:
		var entry: ItemEntry = e
		match entry.size_class:
			ItemEntry.SizeClass.EXTRA_SMALL, ItemEntry.SizeClass.SMALL:
				smalls.append(entry)
			ItemEntry.SizeClass.MEDIUM:
				mediums.append(entry)
			_:
				larges.append(entry)
	if smalls.is_empty():
		var sorted_small: Array = plan.field_entries.duplicate()
		sorted_small.sort_custom(
			func(a, b): return (a as ItemEntry).visual_radius < (b as ItemEntry).visual_radius
		)
		smalls.append(sorted_small[0])
	var hole_c := origin + Vector2(1600.0, 1600.0)
	var near_small: Array[Vector2] = [
		hole_c + Vector2(270.0, -55.0),
		hole_c + Vector2(-260.0, 110.0),
		hole_c + Vector2(90.0, 280.0),
		hole_c + Vector2(-100.0, -270.0),
		hole_c + Vector2(290.0, 210.0),
		hole_c + Vector2(-280.0, -165.0),
	]
	for i in near_small.size():
		spawner.spawn_catalog_item(near_small[i], smalls[i % smalls.size()], false)
	var near_medium: Array[Vector2] = [
		hole_c + Vector2(400.0, -195.0),
		hole_c + Vector2(-390.0, 240.0),
		hole_c + Vector2(220.0, 400.0),
		hole_c + Vector2(-240.0, -400.0),
	]
	if not mediums.is_empty():
		for i in near_medium.size():
			spawner.spawn_catalog_item(near_medium[i], mediums[i % mediums.size()], false)
	var near_large: Array[Vector2] = [
		hole_c + Vector2(500.0, 100.0),
		hole_c + Vector2(-480.0, -80.0),
	]
	if not larges.is_empty():
		for i in near_large.size():
			spawner.spawn_catalog_item(near_large[i], larges[i % larges.size()], false)

	# Guarantee target quantities after pattern placement rejections.
	_ensure_mixed_target_counts(spawner, origin, plan, target_map)

	print("[LevelLayout] mixed L", plan.level, " patterns=", pattern_names, " ", plan.summary())

static func _ensure_mixed_target_counts(
	spawner: FoodSpawner,
	origin: Vector2,
	plan: LevelPlan,
	_target_map: Dictionary
) -> void:
	for t in plan.targets:
		var entry: ItemEntry = t.get("entry")
		if entry == null:
			continue
		var need := int(t.get("target", 10))
		var have := spawner.count_catalog_key(entry.catalog_key())
		if have < need:
			spawner.ensure_catalog_count(entry, need, origin, true)
		have = spawner.count_catalog_key(entry.catalog_key())
		if have < need:
			push_error(
				"[LevelLayout] L%d cannot satisfy %s need=%d have=%d"
				% [plan.level, entry.catalog_key(), need, have]
			)


static func _mixed_spawn_count(entry: ItemEntry, target_map: Dictionary, is_target: bool) -> int:
	if is_target:
		var t: Dictionary = target_map[entry.catalog_key()]
		return int(t.get("target", 10)) + int(t.get("margin", 2))
	match entry.size_class:
		ItemEntry.SizeClass.EXTRA_SMALL, ItemEntry.SizeClass.SMALL:
			return 8
		ItemEntry.SizeClass.MEDIUM:
			return 6
		ItemEntry.SizeClass.LARGE:
			return 4
		_:
			return 3


static func _place_mixed_pattern(
	spawner: FoodSpawner,
	center: Vector2,
	entry: ItemEntry,
	count: int,
	pattern: int,
	mission_highlight: bool,
	pattern_names: Array[String]
) -> void:
	if count <= 0:
		return
	var spacing := entry.visual_radius * 2.85 + ITEM_GAP
	match pattern:
		0: # singles + scatter
			pattern_names.append("scatter")
			spawner.spawn_catalog_scatter(center, count, 150.0, entry, entry.image_id, mission_highlight)
		1: # pairs
			pattern_names.append("pairs")
			var pairs := ceili(float(count) / 2.0)
			for i in pairs:
				var angle := float(i) / float(maxi(pairs, 1)) * TAU
				var base := center + Vector2(cos(angle), sin(angle)) * (120.0 + entry.visual_radius)
				spawner.spawn_catalog_item(base, entry, mission_highlight)
				if i * 2 + 1 < count:
					spawner.spawn_catalog_item(base + Vector2(spacing * 1.0, 0.0), entry, mission_highlight)
		2: # group 3–6
			pattern_names.append("group")
			var group_n := mini(count, clampi(3 + (entry.image_id % 4), 3, 6))
			spawner.spawn_catalog_circle(center, group_n, spacing * 1.2, entry, mission_highlight)
			if count > group_n:
				spawner.spawn_catalog_scatter(center + Vector2(160.0, 70.0), count - group_n, 110.0, entry, 20, mission_highlight)
		3: # circle
			pattern_names.append("circle")
			spawner.spawn_catalog_circle(center, count, maxf(spacing * float(count) / TAU, spacing * 1.5), entry, mission_highlight)
		4: # square
			pattern_names.append("square")
			var side := maxi(2, int(ceil(sqrt(float(count)))))
			spawner.spawn_catalog_grid(center, side, side, spacing, entry, mission_highlight)
		5: # rectangle
			pattern_names.append("rectangle")
			var cols := maxi(3, int(ceil(sqrt(float(count) * 1.5))))
			var rows := maxi(2, int(ceil(float(count) / float(cols))))
			spawner.spawn_catalog_grid(center, cols, rows, spacing, entry, mission_highlight)
		6: # straight row
			pattern_names.append("row")
			spawner.spawn_catalog_rows(center, count, spacing, entry, mission_highlight)
		7: # curved arc
			pattern_names.append("arc")
			spawner.spawn_catalog_arc(center, count, spacing * 2.85, -1.1, 1.1, entry, mission_highlight)
		8: # clustered zone
			pattern_names.append("zone")
			spawner.spawn_catalog_scatter(center, count, 95.0, entry, 40, mission_highlight)
		_:
			pattern_names.append("loose")
			spawner.spawn_catalog_scatter(center, count, 180.0, entry, 60, mission_highlight)


static func _build_fruit_garden_level(spawner: FoodSpawner, origin: Vector2, level: int) -> void:
	var slice := CollectibleArt.FRUIT_SLOT_WATERMELON_SLICE
	var half := CollectibleArt.FRUIT_SLOT_WATERMELON_HALF
	var whole := CollectibleArt.FRUIT_SLOT_WATERMELON_WHOLE
	var stage := LevelTheme.mission_stage_for_level(level)
	var targets := LevelTheme.family_targets(LevelTheme.Id.FRUIT_GARDEN)
	var c := origin + Vector2(1600.0, 1600.0)

	var slice_count := int(targets[0]) + SPAWN_MARGIN
	var half_count := 0
	var whole_count := 0
	if stage >= 2:
		half_count = int(targets[1]) + SPAWN_MARGIN
	if stage >= 3:
		whole_count = int(targets[2]) + SPAWN_MARGIN

	# Place largest first so spacing rejects do not drop mission-critical items.
	_spawn_ring(spawner, c, whole_count, 520.0, -0.55, whole, true)
	_spawn_ring(spawner, c, half_count, 400.0, 0.15, half, true)
	_spawn_ring(spawner, c, slice_count, 250.0, 0.85, slice, true)

	# Near-hole slices for early growth / easy starts (Level 1 focus).
	var near_slices: Array[Vector2] = [
		c + Vector2(190.0, -20.0),
		c + Vector2(-180.0, 90.0),
		c + Vector2(50.0, 195.0),
	]
	for p in near_slices:
		spawner.spawn_item(p, slice, true)

	# Small oranges / cherries so the hole can grow before wholes on Level 3.
	var growth_zones: Array[Vector2] = [
		Vector2(950.0, 950.0),
		Vector2(2250.0, 950.0),
		Vector2(950.0, 2250.0),
		Vector2(2250.0, 2250.0),
		Vector2(1600.0, 800.0),
		Vector2(1600.0, 2400.0),
	]
	for i in growth_zones.size():
		var z := origin + growth_zones[i]
		spawner.spawn_scatter(z, 5, 55.0, 3, 100 + i)
		spawner.spawn_scatter(z + Vector2(40.0, -30.0), 4, 48.0, 4, 200 + i)


static func _spawn_ring(
	spawner: FoodSpawner,
	center: Vector2,
	count: int,
	radius: float,
	angle_offset: float,
	slot: int,
	mission_highlight: bool
) -> void:
	if count <= 0:
		return
	for i in count:
		var angle := angle_offset + (TAU * float(i) / float(count))
		var pos := center + Vector2(cos(angle), sin(angle)) * radius
		if not spawner.spawn_item(pos, slot, mission_highlight):
			# Retry slightly farther out if the first spot was blocked.
			var retry := center + Vector2(cos(angle), sin(angle)) * (radius + 70.0)
			spawner.spawn_item(retry, slot, mission_highlight)


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
