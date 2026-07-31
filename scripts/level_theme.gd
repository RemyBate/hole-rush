class_name LevelTheme
extends RefCounted

## Level theme ids (named Id to avoid shadowing Godot's Theme class).
enum Id {
	FRUIT_GARDEN,
	VEGETABLE_FARM,
	FAST_FOOD,
	BAKERY,
	TOY_ROOM,
	BEACH_PARTY,
}

const COLLECTIBLE_COUNT: int = 5
const MAX_LEVEL: int = 60

## Legacy defaults (non-family callers). Prefer family_* helpers for missions.
const MISSION_TARGETS: Array[int] = [12, 20, 10]
const MISSION_SLOTS: Array[int] = [0, 1, 3]

## Fruit Garden family pack: slice / half / whole.
const FRUIT_FAMILY_SLOTS: Array[int] = [0, 1, 2]
## Level 1–3 targets: each active mission needs 10 of that type.
const FRUIT_FAMILY_TARGETS: Array[int] = [10, 10, 10]

## Generic family pack for other themes: small / medium / large mission items.
const DEFAULT_FAMILY_SLOTS: Array[int] = [0, 1, 3]
const DEFAULT_FAMILY_TARGETS: Array[int] = [10, 8, 6]


static func theme_for_level(level: int) -> int:
	var clamped := clampi(level, 1, MAX_LEVEL)
	var index := (clamped - 1) / 10
	return clampi(index, 0, Id.BEACH_PARTY)


## 1–10 within the current theme decade.
static func level_in_theme(level: int) -> int:
	return ((clampi(level, 1, MAX_LEVEL) - 1) % 10) + 1


## Progressive mission stage: L1→1 goal, L2→2 goals, L3+→3 goals (per theme decade).
static func mission_stage_for_level(level: int) -> int:
	var local := level_in_theme(level)
	if local <= 1:
		return 1
	if local <= 2:
		return 2
	return 3


## Small / medium / large slots for the active collectible family pack.
static func family_slots(theme: int) -> Array[int]:
	if theme == Id.FRUIT_GARDEN:
		return FRUIT_FAMILY_SLOTS
	return DEFAULT_FAMILY_SLOTS


static func family_targets(theme: int) -> Array[int]:
	if theme == Id.FRUIT_GARDEN:
		return FRUIT_FAMILY_TARGETS
	return DEFAULT_FAMILY_TARGETS


## Back-compat wrappers used by older call sites.
static func mission_slots(theme: int) -> Array[int]:
	return family_slots(theme)


static func mission_targets(theme: int) -> Array[int]:
	return family_targets(theme)


static func theme_display_name(theme: int) -> String:
	match theme:
		Id.FRUIT_GARDEN:
			return "Fruit Garden"
		Id.VEGETABLE_FARM:
			return "Vegetable Farm"
		Id.FAST_FOOD:
			return "Fast Food"
		Id.BAKERY:
			return "Bakery"
		Id.TOY_ROOM:
			return "Toy Room"
		Id.BEACH_PARTY:
			return "Beach Party"
		_:
			return "Level"


static func collectible_name(theme: int, slot: int) -> String:
	var names := _collectible_names(theme)
	if slot >= 0 and slot < names.size():
		return names[slot]
	return "Item"


static func collectible_icon(theme: int, slot: int) -> String:
	var icons := _collectible_icons(theme)
	if slot >= 0 and slot < icons.size():
		return icons[slot]
	return "⭐"


static func _collectible_names(theme: int) -> Array[String]:
	match theme:
		Id.FRUIT_GARDEN:
			return ["Watermelon Slices", "Half Watermelons", "Whole Watermelons", "Oranges", "Cherries"]
		Id.VEGETABLE_FARM:
			return ["Cucumbers", "Carrots", "Lettuce", "Corn", "Pumpkins"]
		Id.FAST_FOOD:
			return ["Burgers", "Sandwiches", "Fries", "Pizza", "Hotdogs"]
		Id.BAKERY:
			return ["Cookies", "Cupcakes", "Donuts", "Bread", "Croissants"]
		Id.TOY_ROOM:
			return ["Toy Cars", "Balls", "Blocks", "Teddy Bears", "Puzzles"]
		Id.BEACH_PARTY:
			return ["Shells", "Starfish", "Beach Balls", "Buckets", "Popsicles"]
		_:
			return ["A", "B", "C", "D", "E"]


static func _collectible_icons(theme: int) -> Array[String]:
	match theme:
		Id.FRUIT_GARDEN:
			# Distinct per family size so mission cards are not identical.
			return ["🔺", "◐", "🍉", "🍊", "🍒"]
		Id.VEGETABLE_FARM:
			return ["🥒", "🥕", "🥬", "🌽", "🎃"]
		Id.FAST_FOOD:
			return ["🍔", "🥪", "🍟", "🍕", "🌭"]
		Id.BAKERY:
			return ["🍪", "🧁", "🍩", "🍞", "🥐"]
		Id.TOY_ROOM:
			return ["🚗", "⚽", "🧱", "🧸", "🧩"]
		Id.BEACH_PARTY:
			return ["🐚", "⭐", "🏐", "🪣", "🍦"]
		_:
			return ["⭐", "⭐", "⭐", "⭐", "⭐"]
