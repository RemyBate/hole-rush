extends Node

## Checklist that corrected Android resources are present for Release export.


const REQUIRED_SCRIPTS: Array[String] = [
	"res://scripts/booster_art.gd",
	"res://scripts/settings_art.gd",
	"res://scripts/ui_icons.gd",
	"res://scripts/item_entry.gd",
	"res://scripts/item_catalog.gd",
	"res://scripts/level_plan.gd",
	"res://scripts/home_background.gd",
	"res://scripts/hud.gd",
	"res://scripts/home_screen.gd",
	"res://scripts/game.gd",
	"res://scripts/hole.gd",
	"res://scripts/food.gd",
	"res://scripts/confirm_popup.gd",
	"res://scripts/settings_popup.gd",
	"res://scripts/level_prep_screen.gd",
]

const REQUIRED_SCENES: Array[String] = [
	"res://scenes/main.tscn",
	"res://scenes/game.tscn",
	"res://scenes/ui/home_screen.tscn",
	"res://scenes/ui/hud.tscn",
	"res://scenes/ui/level_prep_screen.tscn",
	"res://scenes/ui/settings_popup.tscn",
	"res://scenes/ui/confirm_popup.tscn",
	"res://scenes/ui/victory_screen.tscn",
	"res://scenes/ui/game_over_screen.tscn",
	"res://scenes/ui/shop_screen.tscn",
	"res://scenes/ui/map_screen.tscn",
	"res://scenes/ui/trophy_screen.tscn",
	"res://scenes/ui/collection_screen.tscn",
]

const REQUIRED_AUDIO: Array[String] = [
	"res://audio/music_loop.wav",
	"res://audio/ui_click.wav",
	"res://audio/collect_normal.wav",
	"res://audio/collect_target.wav",
	"res://audio/coin_collect.wav",
	"res://audio/win_jingle.wav",
	"res://audio/lose_tone.wav",
]


func _ready() -> void:
	var failed := 0
	failed += _check_list("script", REQUIRED_SCRIPTS)
	failed += _check_list("scene", REQUIRED_SCENES)
	failed += _check_list("audio", REQUIRED_AUDIO)
	failed += _check_fruit_pack()
	failed += _check_export_preset()
	failed += _check_android_icons()
	failed += _check_catalog_probe()
	failed += _check_control_position_movement()
	if failed > 0:
		push_error("[AEXPORT] FAILED %d" % failed)
		get_tree().quit(1)
		return
	print("[AEXPORT] PASSED — required resources present for Android Release packaging")
	get_tree().quit(0)


func _check_list(kind: String, paths: Array[String]) -> int:
	var failed := 0
	for path in paths:
		if not ResourceLoader.exists(path) and not FileAccess.file_exists(path):
			push_error("[AEXPORT] missing %s %s" % [kind, path])
			failed += 1
		else:
			print("[AEXPORT] OK %s %s" % [kind, path])
	return failed


func _check_fruit_pack() -> int:
	var failed := 0
	var found := 0
	for id in range(1, 25):
		var path := "res://assets/items/fruits/%d.png" % id
		if ResourceLoader.exists(path) or FileAccess.file_exists(path):
			found += 1
		else:
			push_error("[AEXPORT] missing fruit texture %s" % path)
			failed += 1
	print("[AEXPORT] OK fruit textures %d/24" % found)
	return failed


func _check_export_preset() -> int:
	var failed := 0
	var cfg := ConfigFile.new()
	var err := cfg.load("res://export_presets.cfg")
	if err != OK:
		push_error("[AEXPORT] cannot load export_presets.cfg")
		return 1
	var found_release := false
	for i in 8:
		var section := "preset.%d" % i
		if not cfg.has_section(section):
			continue
		var name := str(cfg.get_value(section, "name", ""))
		if name != "Android Release":
			continue
		found_release = true
		var opt := "preset.%d.options" % i
		var pkg := str(cfg.get_value(opt, "package/unique_name", ""))
		var code := int(cfg.get_value(opt, "version/code", -1))
		var ver := str(cfg.get_value(opt, "version/name", ""))
		var filt := str(cfg.get_value(section, "export_filter", ""))
		var arm64 := bool(cfg.get_value(opt, "architectures/arm64-v8a", false))
		var armv7 := bool(cfg.get_value(opt, "architectures/armeabi-v7a", false))
		print("[AEXPORT] Android Release package=", pkg, " code=", code, " name=", ver, " filter=", filt)
		if pkg != "com.holerush.game":
			push_error("[AEXPORT] package mismatch %s" % pkg)
			failed += 1
		if filt != "all_resources":
			push_error("[AEXPORT] export_filter is not all_resources")
			failed += 1
		if not arm64 or not armv7:
			push_error("[AEXPORT] expected arm64-v8a and armeabi-v7a")
			failed += 1
		if code < 1 or ver == "":
			push_error("[AEXPORT] invalid version fields")
			failed += 1
	if not found_release:
		push_error("[AEXPORT] Android Release preset missing")
		failed += 1
	return failed


func _check_android_icons() -> int:
	var failed := 0
	var UiIcons = load("res://scripts/ui_icons.gd")
	var SettingsArt = load("res://scripts/settings_art.gd")
	var BoosterArt = load("res://scripts/booster_art.gd")
	if UiIcons == null or SettingsArt == null or BoosterArt == null:
		push_error("[AEXPORT] icon script load failed")
		return 1
	for id in range(0, 14):
		var tex: Texture2D = UiIcons.icon(id, 64)
		if tex == null:
			push_error("[AEXPORT] UiIcons id %d null" % id)
			failed += 1
	for id in range(0, 3):
		if SettingsArt.icon(id, 64) == null:
			push_error("[AEXPORT] SettingsArt id %d null" % id)
			failed += 1
	for id in range(0, 4):
		if BoosterArt.icon(id, 64) == null:
			push_error("[AEXPORT] BoosterArt id %d null" % id)
			failed += 1
	if failed == 0:
		print("[AEXPORT] OK procedural icon generators")
	return failed


func _check_catalog_probe() -> int:
	ItemCatalog.reload_category(ItemCatalog.CATEGORY_FRUITS)
	if ItemCatalog._parse_numbered_id("3.png.import") != 3:
		push_error("[AEXPORT] import-name id parse broken")
		return 1
	var entries := ItemCatalog.valid_entries(ItemCatalog.CATEGORY_FRUITS)
	if entries.size() < 20:
		push_error("[AEXPORT] fruit catalog too small %d" % entries.size())
		return 1
	var with_hud := 0
	for e in entries:
		var tex: Texture2D = (e as ItemEntry).hud_texture()
		if tex != null and tex.get_width() >= 16 and tex.get_height() >= 16:
			with_hud += 1
	if with_hud < 20:
		push_error("[AEXPORT] too few usable HUD textures %d" % with_hud)
		return 1
	print("[AEXPORT] OK catalog probe entries=", entries.size(), " hud=", with_hud)
	return 0


## Behavioural / structural proof of absolute control-position movement (not string-name sniffing).
func _check_control_position_movement() -> int:
	var failed := 0
	if not ResourceLoader.exists("res://scripts/hole.gd") and not FileAccess.file_exists("res://scripts/hole.gd"):
		push_error("[AEXPORT] hole.gd missing")
		return 1
	var hole := (load("res://scenes/hole.tscn") as PackedScene).instantiate() as Hole
	if hole == null:
		push_error("[AEXPORT] hole scene instantiate failed")
		return 1
	add_child(hole)
	hole.set_play_bounds(Rect2(0, 0, 4000, 4000))
	hole.radius = 48.0
	hole.pointer_visibility_offset = Vector2.ZERO
	hole.touch_visibility_margin = 14.0

	if not hole.uses_absolute_control_position():
		push_error("[AEXPORT] hole does not report absolute control-position mode")
		failed += 1
	if not hole.has_method("set_from_control_position") or not hole.has_method("control_position_to_world"):
		push_error("[AEXPORT] control-position API missing")
		failed += 1
	if hole.get("move_sensitivity") != null or hole.get("move_drag_smoothing") != null:
		push_error("[AEXPORT] legacy relative/smoothing movement still present")
		failed += 1

	var offset := hole.compute_visibility_offset_world(true)
	if offset.y >= -hole.radius:
		push_error("[AEXPORT] visibility offset too small: %s" % offset)
		failed += 1

	var c0 := Vector2(900, 1400)
	var c1 := c0 + Vector2(100, 0)
	hole.set_from_control_position(hole.get_canvas_transform() * c0, true)
	var h0 := hole.global_position
	var gap0 := h0 - c0
	hole.set_from_control_position(hole.get_canvas_transform() * c1, true)
	var h1 := hole.global_position
	var gap1 := h1 - c1
	var moved := h1 - h0
	if absf(moved.x - 100.0) > 1.0 or absf(moved.y) > 1.0:
		push_error("[AEXPORT] control-position 100px move failed: %s" % moved)
		failed += 1
	if gap0.distance_to(gap1) > 0.75:
		push_error("[AEXPORT] control-position gap not constant")
		failed += 1
	if h0.y >= c0.y or h1.y >= c1.y:
		push_error("[AEXPORT] hole not above control position")
		failed += 1
	if hole.global_position.distance_to(hole._target_position) > 0.01:
		push_error("[AEXPORT] smoothing lag present")
		failed += 1

	# Source-level markers that survive packaging intent (readable before compile).
	var src := FileAccess.get_file_as_string("res://scripts/hole.gd")
	for marker in [
		"set_from_control_position",
		"control_position_to_world",
		"compute_visibility_offset_world",
		"pointer_visibility_offset",
		"touch_visibility_margin",
		"uses_absolute_control_position",
		"hole_control_position_absolute_v2",
	]:
		if not src.contains(marker):
			push_error("[AEXPORT] hole.gd missing marker %s" % marker)
			failed += 1

	hole.queue_free()
	if failed == 0:
		print(
			"[AEXPORT] OK control-position movement gap=",
			gap0,
			" moved=",
			moved,
			" absolute=true"
		)
	return failed
