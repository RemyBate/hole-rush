extends Node

## Verify prep screen shows mission previews and booster icons.

const _BoosterArt := preload("res://scripts/booster_art.gd")
const _SettingsArt := preload("res://scripts/settings_art.gd")


func _ready() -> void:
	await get_tree().process_frame
	var failed := 0
	failed += await _check_mission_previews()
	failed += _check_booster_icons()
	failed += await _check_settings_icons()
	if failed > 0:
		push_error("[PREPVIS] FAILED %d" % failed)
		get_tree().quit(1)
		return
	print("[PREPVIS] PASSED")
	get_tree().quit(0)


func _check_mission_previews() -> int:
	var prep := (load("res://scenes/ui/level_prep_screen.tscn") as PackedScene).instantiate() as LevelPrepScreen
	if prep == null:
		push_error("[PREPVIS] failed to instantiate LevelPrepScreen")
		return 1
	add_child(prep)
	prep.open_for_level(2)
	await get_tree().process_frame
	var box: HBoxContainer = prep.get_node("%ObjectivesBox")
	if box.get_child_count() < 2:
		push_error("[PREPVIS] expected 2 objective cards")
		prep.queue_free()
		return 1
	for child in box.get_children():
		var card := child as PanelContainer
		if card == null:
			push_error("[PREPVIS] objective not a panel")
			prep.queue_free()
			return 1
		var tex := _find_texture_rect(card)
		if tex == null or tex.texture == null:
			push_error("[PREPVIS] missing objective preview texture")
			prep.queue_free()
			return 1
	prep.queue_free()
	print("[PREPVIS] OK level 2 objective previews")
	return 0


func _check_booster_icons() -> int:
	for id in BoosterData.IDS:
		var tex: Texture2D = _BoosterArt.icon(id, 96)
		if tex == null:
			push_error("[PREPVIS] missing booster icon %d" % id)
			return 1
	print("[PREPVIS] OK booster icons")
	return 0


func _check_settings_icons() -> int:
	for id in [_SettingsArt.Id.MUSIC, _SettingsArt.Id.SOUND, _SettingsArt.Id.VIBRATION]:
		var tex: Texture2D = _SettingsArt.icon(id, 96)
		if tex == null:
			push_error("[PREPVIS] missing settings icon %d" % id)
			return 1
	var popup := (load("res://scenes/ui/settings_popup.tscn") as PackedScene).instantiate() as Control
	add_child(popup)
	await get_tree().process_frame
	for btn_name in ["MusicButton", "SoundButton", "VibrationButton"]:
		var btn := popup.get_node("%" + btn_name) as Button
		if btn == null:
			push_error("[PREPVIS] settings button missing %s" % btn_name)
			popup.queue_free()
			return 1
		if btn.text != "":
			push_error("[PREPVIS] settings button still uses emoji text: %s" % btn_name)
			popup.queue_free()
			return 1
		var icon := btn.get_node_or_null("Icon") as TextureRect
		if icon == null or icon.texture == null:
			push_error("[PREPVIS] settings button missing icon texture: %s" % btn_name)
			popup.queue_free()
			return 1
	popup.queue_free()
	print("[PREPVIS] OK settings icons")
	return 0


func _find_texture_rect(node: Node) -> TextureRect:
	if node is TextureRect:
		return node as TextureRect
	for child in node.get_children():
		var found := _find_texture_rect(child)
		if found != null:
			return found
	return null
