class_name MissionFactory
extends RefCounted


## Build missions from a numbered catalog LevelPlan (preferred from Level 1).
static func create_missions(theme: int, level: int = 1, plan: LevelPlan = null) -> Array:
	if plan != null and not plan.is_empty():
		return _missions_from_plan(plan)
	var built := LevelPlan.for_level(level, category_for_theme(theme))
	if not built.is_empty():
		return _missions_from_plan(built)
	return _legacy_family_missions(theme, level)


static func category_for_theme(theme: int) -> String:
	match theme:
		LevelTheme.Id.FRUIT_GARDEN:
			return ItemCatalog.CATEGORY_FRUITS
		LevelTheme.Id.VEGETABLE_FARM:
			return "vegetables"
		LevelTheme.Id.FAST_FOOD:
			return "fast_food"
		LevelTheme.Id.BAKERY:
			return "pizzas"
		_:
			return ItemCatalog.CATEGORY_FRUITS


static func _missions_from_plan(plan: LevelPlan) -> Array:
	var missions: Array = []
	var index := 0
	for t in plan.targets:
		var entry: ItemEntry = t.get("entry")
		if entry == null:
			continue
		index += 1
		var mission := Mission.new()
		mission.item_type = -index
		mission.catalog_key = entry.catalog_key()
		mission.icon_texture = entry.texture
		mission.hide_name = true
		mission.display_name = ""
		mission.icon = ""
		mission.target = int(t.get("target", 10))
		mission.progress = 0
		missions.append(mission)
	return missions


## Fallback when no numbered images exist for a theme category.
static func _legacy_family_missions(theme: int, level: int = 1) -> Array:
	var missions: Array = []
	var stage := LevelTheme.mission_stage_for_level(level)
	var slots := LevelTheme.family_slots(theme)
	var targets := LevelTheme.family_targets(theme)
	for i in range(stage):
		if i >= slots.size() or i >= targets.size():
			break
		var slot: int = int(slots[i])
		var mission := Mission.new()
		mission.item_type = slot
		mission.display_name = ""
		mission.hide_name = true
		mission.icon = LevelTheme.collectible_icon(theme, slot)
		mission.target = int(targets[i])
		mission.progress = 0
		missions.append(mission)
	return missions


static func create_family_missions(theme: int, level: int = 1) -> Array:
	return create_missions(theme, level)
