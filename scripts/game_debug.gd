extends Node

## Release-safe gameplay logging. Enabled in debug/editor builds only.

var enabled: bool = false


func _ready() -> void:
	enabled = OS.is_debug_build()


func log_level_start(level: int, missions: Array, plan: LevelPlan) -> void:
	if not enabled:
		return
	var targets: Array[String] = []
	for m in missions:
		var mission := m as Mission
		if mission == null:
			continue
		targets.append("%s=%d" % [mission.catalog_key, mission.target])
	print("[HoleRush] level_start L%d targets=[%s]" % [level, ", ".join(targets)])
	if plan != null and not plan.is_empty():
		print("[HoleRush] level_plan ", plan.summary())


func log_spawn_counts(spawner: FoodSpawner, missions: Array) -> void:
	if not enabled:
		return
	for m in missions:
		var mission := m as Mission
		if mission == null or mission.catalog_key == "":
			continue
		var have := spawner.count_catalog_key(mission.catalog_key)
		print(
			"[HoleRush] spawn %s need=%d have=%d"
			% [mission.catalog_key, mission.target, have]
		)


func log_collect(catalog_key: String, progress: int, target: int) -> void:
	if not enabled:
		return
	print("[HoleRush] collect %s %d/%d" % [catalog_key, progress, target])


func log_level_complete(level: int, next_unlock: int) -> void:
	if not enabled:
		return
	print("[HoleRush] level_complete L%d unlock=%d" % [level, next_unlock])


func log_save(action: String, data: Dictionary) -> void:
	if not enabled:
		return
	print(
		"[HoleRush] save_%s level=%d unlocked=%d coins=%d"
		% [
			action,
			int(data.get("current_level", 0)),
			int(data.get("highest_unlocked_level", 0)),
			int(data.get("total_coins", 0)),
		]
	)
