class_name ItemEntry
extends RefCounted

## One numbered collectible image from a category folder (e.g. fruits:4).

enum SizeClass { EXTRA_SMALL, SMALL, MEDIUM, LARGE, EXTRA_LARGE }

var category: String = "fruits"
var image_id: int = 0
var path: String = ""
var texture: Texture2D = null
var size_class: int = SizeClass.MEDIUM
## Half of on-field visual diameter (world px).
var visual_radius: float = 38.0
var collision_scale: float = 0.82
var score_value: int = 5
var growth_bonus: float = 0.06
var spawn_weight: float = 1.0
var mission_eligible: bool = true
var content_fill: float = 0.8
var valid: bool = false
var invalid_reason: String = ""


func catalog_key() -> String:
	return "%s:%d" % [category, image_id]


func collision_radius() -> float:
	return visual_radius * collision_scale


func visual_diameter() -> float:
	return visual_radius * 2.0


static func radius_for_class(size_class: int) -> float:
	match clampi(size_class, 0, SizeClass.EXTRA_LARGE):
		SizeClass.EXTRA_SMALL:
			return 22.0 # ~44 px diameter
		SizeClass.SMALL:
			return 32.0 # ~64 px
		SizeClass.MEDIUM:
			return 46.0 # ~92 px
		SizeClass.LARGE:
			return 62.0 # ~124 px
		_:
			return 76.0 # ~152 px EXTRA_LARGE


static func score_for_class(size_class: int) -> int:
	match clampi(size_class, 0, SizeClass.EXTRA_LARGE):
		SizeClass.EXTRA_SMALL:
			return 2
		SizeClass.SMALL:
			return 3
		SizeClass.MEDIUM:
			return 6
		SizeClass.LARGE:
			return 10
		_:
			return 14


static func growth_for_class(size_class: int) -> float:
	match clampi(size_class, 0, SizeClass.EXTRA_LARGE):
		SizeClass.EXTRA_SMALL:
			return 0.04
		SizeClass.SMALL:
			return 0.05
		SizeClass.MEDIUM:
			return 0.06
		SizeClass.LARGE:
			return 0.07
		_:
			return 0.08
