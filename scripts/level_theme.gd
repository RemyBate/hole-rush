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

## Mission targets (unchanged gameplay).
const MISSION_TARGETS: Array[int] = [12, 20, 10]
## Mission collectible slots: A, B, D (small, small, large mission item).
const MISSION_SLOTS: Array[int] = [0, 1, 3]


static func theme_for_level(level: int) -> int:
	var clamped := clampi(level, 1, MAX_LEVEL)
	var index := (clamped - 1) / 10
	return clampi(index, 0, Id.BEACH_PARTY)


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
			return ["Apples", "Tomatoes", "Watermelons", "Oranges", "Cherries"]
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
			return ["🍎", "🍅", "🍉", "🍊", "🍒"]
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
