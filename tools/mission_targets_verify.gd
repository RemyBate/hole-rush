extends Node

## Verify L1/L2/L3 catalog mission targets are distinct and correctly counted.


func _ready() -> void:
	await get_tree().process_frame
	if GameSettings.get("_session_play_level") != null:
		GameSettings._session_play_level = 0

	var failed := 0
	failed += _check_catalog_levels()
	if failed > 0:
		push_error("[MISS] FAILED %d" % failed)
		get_tree().quit(1)
		return
	print("[MISS] PASSED")
	get_tree().quit(0)


func _check_catalog_levels() -> int:
	var failed := 0
	for level in [1, 2, 3]:
		var want := LevelPlan.target_count_for_level(level)
		var missions: Array = MissionFactory.create_missions(LevelTheme.Id.FRUIT_GARDEN, level)
		if missions.size() != want:
			push_error("[MISS] L%d expected %d missions got %d" % [level, want, missions.size()])
			failed += 1
			continue
		var keys: Dictionary = {}
		for m in missions:
			var mission := m as Mission
			if mission == null or str(mission.catalog_key).is_empty():
				push_error("[MISS] L%d mission missing catalog_key" % level)
				failed += 1
				continue
			if keys.has(mission.catalog_key):
				push_error("[MISS] L%d duplicate catalog_key %s" % [level, mission.catalog_key])
				failed += 1
			keys[mission.catalog_key] = true
			if mission.target <= 0:
				push_error("[MISS] L%d bad target for %s" % [level, mission.catalog_key])
				failed += 1
		print("[MISS] OK L%d missions=%d keys=%s" % [level, missions.size(), str(keys.keys())])
	return failed
