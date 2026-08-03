class_name LevelPlan
extends RefCounted

## Deterministic per-level selection of field images + mission targets.
## Starts at Level 1: ~10 field types; L1→1 target, L2→2, L3+→3.

const MIXED_START_LEVEL: int = 1
const FIELD_TYPE_COUNT: int = 10

var level: int = 1
var category: String = ItemCatalog.CATEGORY_FRUITS
## Array[ItemEntry] — ~10 field types
var field_entries: Array = []
## Array[Dictionary] { entry: ItemEntry, target: int, margin: int }
var targets: Array = []
var seed_value: int = 0


static func is_mixed_level(level: int) -> bool:
	return level >= MIXED_START_LEVEL


static func target_count_for_level(level: int) -> int:
	if level <= 1:
		return 1
	if level <= 2:
		return 2
	return 3


static func for_level(level: int, category: String = ItemCatalog.CATEGORY_FRUITS) -> LevelPlan:
	var plan := LevelPlan.new()
	plan.level = level
	plan.category = category
	plan.seed_value = level * 7919 + category.hash()
	if not is_mixed_level(level):
		return plan

	var rng := RandomNumberGenerator.new()
	rng.seed = plan.seed_value

	var pool: Array = ItemCatalog.valid_entries(category)
	if pool.is_empty() and category != ItemCatalog.CATEGORY_FRUITS:
		pool = ItemCatalog.valid_entries(ItemCatalog.CATEGORY_FRUITS)
		plan.category = ItemCatalog.CATEGORY_FRUITS
	if pool.is_empty():
		push_warning("LevelPlan: no valid entries in %s" % category)
		return plan

	var shuffled: Array = pool.duplicate()
	_shuffle(shuffled, rng)

	var take := mini(FIELD_TYPE_COUNT, shuffled.size())
	for i in take:
		plan.field_entries.append(shuffled[i])

	var want_targets := mini(target_count_for_level(level), plan.field_entries.size())
	var candidates: Array = plan.field_entries.duplicate()
	_shuffle(candidates, rng)
	var chosen: Array = []
	var used_keys: Dictionary = {}

	# Prefer mixed size classes when selecting multiple targets.
	if want_targets >= 3:
		for size_want in [ItemEntry.SizeClass.SMALL, ItemEntry.SizeClass.MEDIUM, ItemEntry.SizeClass.LARGE]:
			for e in candidates:
				var entry := e as ItemEntry
				if entry == null or used_keys.has(entry.catalog_key()):
					continue
				if entry.size_class == size_want:
					chosen.append(entry)
					used_keys[entry.catalog_key()] = true
					break
			if chosen.size() >= want_targets:
				break

	for e in candidates:
		if chosen.size() >= want_targets:
			break
		var entry := e as ItemEntry
		if entry == null or used_keys.has(entry.catalog_key()):
			continue
		chosen.append(entry)
		used_keys[entry.catalog_key()] = true

	for entry in chosen:
		var qty := _target_quantity(entry as ItemEntry, rng)
		var margin := _spawn_margin(entry as ItemEntry)
		plan.targets.append({
			"entry": entry,
			"target": qty,
			"margin": margin,
			"catalog_key": (entry as ItemEntry).catalog_key(),
		})

	return plan


static func _target_quantity(entry: ItemEntry, rng: RandomNumberGenerator) -> int:
	match entry.size_class:
		ItemEntry.SizeClass.EXTRA_SMALL, ItemEntry.SizeClass.SMALL:
			return rng.randi_range(10, 18)
		ItemEntry.SizeClass.MEDIUM:
			return rng.randi_range(7, 13)
		ItemEntry.SizeClass.LARGE:
			return rng.randi_range(3, 8)
		_:
			return rng.randi_range(3, 6)


static func _spawn_margin(entry: ItemEntry) -> int:
	match entry.size_class:
		ItemEntry.SizeClass.EXTRA_SMALL, ItemEntry.SizeClass.SMALL:
			return 3
		ItemEntry.SizeClass.MEDIUM:
			return 2
		_:
			return 1


## Per-level visual scale in [0.98, 1.10], stable for (level, image_id).
## Floor kept high so variation never pushes items below readable size.
static func visual_scale_for(level: int, image_id: int) -> float:
	var bucket: int = absi(level * 13 + image_id * 7) % 13
	return 0.98 + float(bucket) / 100.0


static func _shuffle(arr: Array, rng: RandomNumberGenerator) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp


func is_empty() -> bool:
	return field_entries.is_empty()


func target_keys() -> Array[String]:
	var keys: Array[String] = []
	for t in targets:
		keys.append(str(t.get("catalog_key", "")))
	return keys


func summary() -> String:
	var field_ids: Array[int] = []
	for e in field_entries:
		field_ids.append((e as ItemEntry).image_id)
	var tgt: Array[String] = []
	for t in targets:
		var entry: ItemEntry = t.get("entry")
		tgt.append("%d×%d" % [entry.image_id, int(t.get("target", 0))])
	return "field=%s targets=%s" % [str(field_ids), str(tgt)]
