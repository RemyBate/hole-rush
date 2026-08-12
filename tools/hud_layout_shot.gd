extends Node
const _SafeCapture := preload("res://tools/safe_viewport_capture.gd")

## Capture a gameplay screenshot for HUD layout review.


func _ready() -> void:
	await get_tree().process_frame
	var game := (load("res://scenes/game.tscn") as PackedScene).instantiate() as Node2D
	add_child(game)
	game.begin_level(2, [])
	for _i in 30:
		await get_tree().process_frame
	var hud := game.get_node("UI/HUD") as Control
	hud.call("_refresh_header_layout")
	game.call("_refresh_play_regions")
	game.call("_enforce_hud_exclusion")
	await get_tree().process_frame
	await get_tree().process_frame
	var path := "res://tools/hud_layout_verify.png"
	if _SafeCapture.is_headless():
		print("[HUDSHOT] skip headless screenshot ", path, " header_h=", hud.call("get_header_height"))
		get_tree().quit(0)
		return
	var tex := get_viewport().get_texture()
	if tex == null:
		push_error("[HUDSHOT] missing viewport texture")
		get_tree().quit(1)
		return
	var img: Image = tex.get_image()
	if img == null:
		push_error("[HUDSHOT] missing image")
		get_tree().quit(1)
		return
	img.save_png(path)
	print("[HUDSHOT] saved ", path, " header_h=", hud.call("get_header_height"))
	get_tree().quit(0)
