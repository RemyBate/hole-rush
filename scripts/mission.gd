class_name Mission
extends RefCounted

var item_type: int = 0
var display_name: String = ""
var icon: String = ""
var target: int = 0
var progress: int = 0
## Catalog key e.g. "fruits:4" — when set, progress matches Food.catalog_key.
var catalog_key: String = ""
var icon_texture: Texture2D = null
## When true, HUD shows image + counter only (no fruit names).
var hide_name: bool = false


func is_complete() -> bool:
	return progress >= target


func add_progress(amount: int = 1) -> void:
	progress = mini(progress + amount, target)


func matches_food(food: Food) -> bool:
	if catalog_key != "":
		return food.catalog_key == catalog_key
	return int(item_type) == int(food.item_type)
