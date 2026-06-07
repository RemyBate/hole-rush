extends SceneTree
func _initialize() -> void:
  for p in ['res://scenes/ui/info_popup.tscn','res://scenes/ui/settings_popup.tscn']:
    var n = load(p).instantiate()
    print(p, ' -> ', n)
    if n: n.free()
  quit(0)
