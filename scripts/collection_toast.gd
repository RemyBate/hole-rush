extends CanvasLayer

## Brief first-discovery toast during gameplay — does not pause the match.

@onready var _root: Control = $Root
@onready var _panel: PanelContainer = %Panel
@onready var _title: Label = %TitleLabel
@onready var _tex: TextureRect = %ItemTex
@onready var _continue: Button = %ContinueButton

var _hide_tween: Tween = null


func _ready() -> void:
	layer = 90
	_root.hide()
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_theme_stylebox_override("panel", UIStyles.popup_panel())
	UIStyles.apply_cartoon_label(_title, 22, 5)
	UIStyles.style_primary_button(_continue, 18)
	_continue.pressed.connect(_hide_toast)
	if not GameSettings.collectible_discovered.is_connected(_on_discovered):
		GameSettings.collectible_discovered.connect(_on_discovered)


func _on_discovered(catalog_key: String) -> void:
	# Avoid stacking toasts over the Collection page itself.
	var tree := get_tree()
	if tree:
		for n in tree.get_nodes_in_group("collection_screen"):
			if n is Control and (n as Control).visible:
				return
	var entry := ItemCatalog.get_by_key(catalog_key)
	_title.text = "New Collection Item!"
	if entry != null and entry.texture != null:
		_tex.texture = entry.hud_texture()
		_tex.visible = true
	else:
		_tex.texture = null
		_tex.visible = false
	_show_toast()


func _show_toast() -> void:
	if _hide_tween and _hide_tween.is_valid():
		_hide_tween.kill()
	_root.show()
	# Do not hard-block the whole viewport — only the panel is interactive.
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.modulate.a = 0.0
	_panel.scale = Vector2(0.9, 0.9)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_panel, "modulate:a", 1.0, 0.18)
	tween.tween_property(_panel, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK)
	GameSettings.play_coin_collect_sfx()
	_hide_tween = create_tween()
	_hide_tween.tween_interval(2.2)
	_hide_tween.tween_callback(_hide_toast)


func _hide_toast() -> void:
	if _hide_tween and _hide_tween.is_valid():
		_hide_tween.kill()
	_hide_tween = null
	if not _root.visible:
		return
	var tween := create_tween()
	tween.tween_property(_panel, "modulate:a", 0.0, 0.14)
	tween.tween_callback(func():
		_root.hide()
		_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	)
