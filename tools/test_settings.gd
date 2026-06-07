extends SceneTree

func _initialize() -> void:
	var path := "res://scenes/ui/settings_popup.tscn"
	var packed: PackedScene = load(path)
	print("packed=", packed)
	if packed:
		var node = packed.instantiate()
		print("node=", node)
		if node:
			node.free()
	quit(0)
