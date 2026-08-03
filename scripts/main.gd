extends Node

const HomeScene: PackedScene = preload("res://scenes/ui/home_screen.tscn")
const GameScene: PackedScene = preload("res://scenes/game.tscn")
const SceneTransitionScript: Script = preload("res://scripts/scene_transition.gd")

var _home: HomeScreen = null
var _game: Node2D = null
var _transition: CanvasLayer = null


func _ready() -> void:
	_setup_transition()
	_show_home_with_reward({})
	await get_tree().process_frame
	_fade_in(0.42)


func _setup_transition() -> void:
	_transition = SceneTransitionScript.new() as CanvasLayer
	if _transition == null:
		push_error("Main: failed to create scene transition layer.")
		return
	add_child(_transition)


func _fade_out(duration: float = 0.28) -> void:
	if _transition and _transition.has_method("fade_out"):
		_transition.fade_out(duration)


func _fade_in(duration: float = 0.32) -> void:
	if _transition and _transition.has_method("fade_in"):
		_transition.fade_in(duration)


func _show_home() -> void:
	if _game != null and is_instance_valid(_game):
		_game.queue_free()
		_game = null
	if _home == null or not is_instance_valid(_home):
		_home = HomeScene.instantiate() as HomeScreen
		add_child(_home)
		_home.play_level.connect(_on_play_level)
	else:
		_home.show()


func _show_home_with_reward(reward_payload: Dictionary) -> void:
	_show_home()
	if reward_payload.get("coins_earned", 0) > 0:
		_home.play_coin_collection_animation(reward_payload)
	else:
		_home.refresh_ui()


func _on_play_level(level: int, boosters: Array) -> void:
	if not GameSettings.can_play():
		push_warning("[MAIN] start level blocked — no lives")
		return
	var resolved := GameSettings.resolve_play_level(level)
	print("[MAIN] start level received level=", resolved, " boosters=", boosters)
	_transition_to_game(resolved, boosters)


func _transition_to_game(level: int, boosters: Array) -> void:
	level = GameSettings.resolve_play_level(level)
	_fade_out(0.26)
	await get_tree().create_timer(0.28).timeout
	if _home != null and is_instance_valid(_home):
		_home.hide()
	_game = GameScene.instantiate() as Node2D
	add_child(_game)
	if _game.has_method("begin_level"):
		print("[GAME] begin_level called level=", level, " boosters=", boosters)
		_game.begin_level(level, boosters)
	else:
		push_error("[MAIN] Game scene missing begin_level")
	if _game.has_signal("exit_to_home"):
		_game.exit_to_home.connect(_return_home)
	_fade_in(0.34)


func _return_home(reward_payload: Dictionary = {}) -> void:
	_fade_out(0.24)
	await get_tree().create_timer(0.26).timeout
	_show_home_with_reward(reward_payload)
	_fade_in(0.32)
