class_name ItemEntry
extends RefCounted

## One numbered collectible image from a category folder (e.g. fruits:4).

enum SizeClass { EXTRA_SMALL, SMALL, MEDIUM, LARGE, EXTRA_LARGE }

var category: String = "fruits"
var image_id: int = 0
var path: String = ""
var texture: Texture2D = null
## Baked/cropped HUD preview when CPU image data is available; otherwise equals texture.
var hud_preview: Texture2D = null
var size_class: int = SizeClass.MEDIUM
## Half of on-field visual diameter (world px).
var visual_radius: float = 38.0
var collision_scale: float = 0.88
var score_value: int = 5
var growth_bonus: float = 0.06
var spawn_weight: float = 1.0
var mission_eligible: bool = true
var content_fill: float = 0.8
## Opaque pixel bounds in source image space (for HUD atlas / padding reports).
var content_rect: Rect2i = Rect2i()
## Longest opaque side in source pixels; used to scale draw to target diameter.
var content_span_px: float = 0.0
var source_max_px: float = 0.0
var valid: bool = false
var invalid_reason: String = ""


func catalog_key() -> String:
	return "%s:%d" % [category, image_id]


func collision_radius() -> float:
	return visual_radius * collision_scale


func visual_diameter() -> float:
	return visual_radius * 2.0


## Runtime HUD preview — prefer baked ImageTexture; never emoji / AtlasTexture.
func hud_texture() -> Texture2D:
	if hud_preview != null:
		return hud_preview
	return texture


static func radius_for_class(size_class: int) -> float:
	# Diameters after 405×720 testing: XS≈78, S≈90, M≈112, L≈140, XL≈168.
	# XS raised above the starting suggestion so berries/slices stay recognisable.
	match clampi(size_class, 0, SizeClass.EXTRA_LARGE):
		SizeClass.EXTRA_SMALL:
			return 39.0
		SizeClass.SMALL:
			return 45.0
		SizeClass.MEDIUM:
			return 56.0
		SizeClass.LARGE:
			return 70.0
		_:
			return 84.0


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
