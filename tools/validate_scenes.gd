extends SceneTree

const SCENES := [
	"res://scenes/main.tscn",
	"res://scenes/ui/home_screen.tscn",
	"res://scenes/ui/level_prep_screen.tscn",
	"res://scenes/ui/shop_screen.tscn",
	"res://scenes/ui/hud.tscn",
	"res://scenes/ui/victory_screen.tscn",
	"res://scenes/ui/game_over_screen.tscn",
	"res://scenes/ui/settings_popup.tscn",
	"res://scenes/ui/info_popup.tscn",
	"res://scenes/game.tscn",
]

func _initialize() -> void:
	var failed: Array[String] = []
	for path in SCENES:
		if not ResourceLoader.exists(path):
			failed.append("%s (missing)" % path)
			continue
		var packed: PackedScene = load(path)
		if packed == null:
			failed.append("%s (load failed)" % path)
			continue
		var node := packed.instantiate()
		if node == null:
			failed.append("%s (instantiate failed)" % path)
			print("FAIL: ", path, " instantiate failed")
			continue
		node.free()
		print("OK: ", path)
	if failed.is_empty():
		print("VALIDATE_OK: all scenes load")
	else:
		for line in failed:
			push_error(line)
		print("VALIDATE_FAIL: %d scene(s)" % failed.size())
	quit(0 if failed.is_empty() else 1)
