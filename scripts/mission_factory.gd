class_name MissionFactory
extends RefCounted


static func create_missions(theme: int) -> Array:
	var missions: Array = []
	for i in 3:
		var slot: int = LevelTheme.MISSION_SLOTS[i]
		var mission := Mission.new()
		mission.item_type = slot
		mission.display_name = LevelTheme.collectible_name(theme, slot)
		mission.icon = LevelTheme.collectible_icon(theme, slot)
		mission.target = LevelTheme.MISSION_TARGETS[i]
		missions.append(mission)
	return missions
