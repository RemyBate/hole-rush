class_name Mission
extends RefCounted

var item_type: int = 0
var display_name: String = ""
var icon: String = ""
var target: int = 0
var progress: int = 0


func is_complete() -> bool:
	return progress >= target


func add_progress(amount: int = 1) -> void:
	progress = mini(progress + amount, target)
