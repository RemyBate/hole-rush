extends Node

## Runtime verify: catalog mission stages + spawn sufficiency for L1–3.


func _ready() -> void:
	await get_tree().process_frame
	var failed := 0

	failed += _check_mission_stages()
	failed += await _check_level_spawns()

	if failed > 0:
		push_error("[PROG] FAILED issues=%d" % failed)
		get_tree().quit(1)
	else:
		print("[PROG] PASSED")
		get_tree().quit(0)


func _fail(msg: String) -> int:
	push_error("[PROG] " + msg)
	return 1


func _ok(msg: String) -> void:
	print("[PROG] OK ", msg)


func _check_mission_stages() -> int:
	var failed := 0
	for level in [1, 2, 3]:
		var plan := LevelPlan.for_level(level)
		var want := LevelPlan.target_count_for_level(level)
		var missions := MissionFactory.create_missions(LevelTheme.Id.FRUIT_GARDEN, level, plan)
		if missions.size() != want:
			failed += _fail("L%d expected %d missions, got %d" % [level, want, missions.size()])
			continue
		var stage_ok := true
		for m in missions:
			var mission := m as Mission
			if mission.icon_texture == null or not mission.hide_name:
				failed += _fail("L%d mission missing image-only HUD setup" % level)
				stage_ok = false
				break
		if stage_ok:
			_ok("L%d has %d image missions" % [level, want])
	return failed


func _check_level_spawns() -> int:
	var failed := 0
	for level in [1, 2, 3]:
		var plan := LevelPlan.for_level(level)
		var spawner := FoodSpawner.new()
		add_child(spawner)
		spawner.spawn_level(Rect2(Vector2.ZERO, GameConstants.PLAY_AREA_SIZE), LevelTheme.Id.FRUIT_GARDEN, level, plan)
		await get_tree().process_frame
		var missions := MissionFactory.create_missions(LevelTheme.Id.FRUIT_GARDEN, level, plan)
		for m in missions:
			var mission := m as Mission
			var have := spawner.count_catalog_key(mission.catalog_key)
			if have < mission.target:
				failed += _fail(
					"L%d %s need %d spawned %d" % [level, mission.catalog_key, mission.target, have]
				)
			else:
				_ok("L%d %s spawned=%d target=%d" % [level, mission.catalog_key, have, mission.target])
		spawner.queue_free()
	return failed
