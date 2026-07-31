extends SceneTree

## Verify L1–3 numbered plans + image-only missions.


func _initialize() -> void:
	print("=== L1+ numbered progression verify ===")
	ItemCatalog.ensure_loaded(ItemCatalog.CATEGORY_FRUITS)
	assert(ItemCatalog.valid_entries().size() == 24)

	for level in [1, 2, 3, 4]:
		var plan := LevelPlan.for_level(level)
		var want := LevelPlan.target_count_for_level(level)
		print("L", level, " ", plan.summary())
		assert(plan.field_entries.size() == 10)
		assert(plan.targets.size() == want)
		var plan2 := LevelPlan.for_level(level)
		assert(plan.summary() == plan2.summary())
		var missions := MissionFactory.create_missions(LevelTheme.Id.FRUIT_GARDEN, level, plan)
		assert(missions.size() == want)
		for m in missions:
			var mission := m as Mission
			assert(mission.icon_texture != null)
			assert(mission.hide_name)
			assert(str(mission.display_name).is_empty())

	assert(LevelPlan.for_level(1).summary() != LevelPlan.for_level(2).summary())
	print("=== PASSED ===")
	quit(0)
