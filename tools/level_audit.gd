extends Node

## Headless audit: every level must spawn enough items for all mission targets.


func _ready() -> void:
	await get_tree().process_frame
	ItemCatalog.ensure_loaded(ItemCatalog.CATEGORY_FRUITS)
	var failed := 0
	for level in range(1, LevelTheme.MAX_LEVEL + 1):
		failed += await _audit_level(level)
	if failed > 0:
		push_error("[LevelAudit] FAILED %d level(s)" % failed)
		get_tree().quit(1)
		return
	print("[LevelAudit] PASSED all %d levels" % LevelTheme.MAX_LEVEL)
	get_tree().quit(0)


func _audit_level(level: int) -> int:
	var theme := LevelTheme.theme_for_level(level)
	var category := MissionFactory.category_for_theme(theme)
	var plan := LevelPlan.for_level(level, category)
	if plan.is_empty():
		push_error("[LevelAudit] L%d empty plan" % level)
		return 1

	var spawner := FoodSpawner.new()
	add_child(spawner)
	var bounds := Rect2(Vector2.ZERO, GameConstants.PLAY_AREA_SIZE)
	spawner.spawn_level(bounds, theme, level, plan)
	await get_tree().process_frame

	var missions := MissionFactory.create_missions(theme, level, plan)
	var want_cards := LevelPlan.target_count_for_level(level)
	if missions.size() != want_cards:
		push_error(
			"[LevelAudit] L%d mission count %d != expected %d"
			% [level, missions.size(), want_cards]
		)
		spawner.queue_free()
		return 1

	var failed := 0
	for m in missions:
		var mission := m as Mission
		var spawned := spawner.count_catalog_key(mission.catalog_key)
		if spawned < mission.target:
			push_error(
				"[LevelAudit] L%d %s need %d spawned %d"
				% [level, mission.catalog_key, mission.target, spawned]
			)
			failed += 1
		else:
			print(
				"[LevelAudit] L%d %s target=%d spawned=%d OK"
				% [level, mission.catalog_key, mission.target, spawned]
			)

	spawner.queue_free()
	return failed
