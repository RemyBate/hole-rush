class_name BoosterData
extends RefCounted

enum Id { LIGHTNING, FREEZE_TIME, MAGNET, DOUBLE_COINS }

const IDS: Array[int] = [Id.LIGHTNING, Id.FREEZE_TIME, Id.MAGNET, Id.DOUBLE_COINS]
const MAX_SELECTED: int = 2

const LABELS: Dictionary = {
	Id.LIGHTNING: "Lightning",
	Id.FREEZE_TIME: "Freeze Time",
	Id.MAGNET: "Magnet",
	Id.DOUBLE_COINS: "Double Coins",
}

const ICONS: Dictionary = {
	Id.LIGHTNING: "⚡",
	Id.FREEZE_TIME: "⏳",
	Id.MAGNET: "🧲",
	Id.DOUBLE_COINS: "🪙×2",
}

const SAVE_KEYS: Dictionary = {
	Id.LIGHTNING: "booster_lightning",
	Id.FREEZE_TIME: "booster_freeze",
	Id.MAGNET: "booster_magnet",
	Id.DOUBLE_COINS: "booster_double_coins",
}


static func save_key(id: int) -> String:
	return SAVE_KEYS.get(id, "booster_unknown")
