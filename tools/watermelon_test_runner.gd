extends Node

## Scene-based watermelon collectible validation (autoload-safe).

var _failed: int = 0


func _ready() -> void:
	_check_textures()
	_check_constants()
	_check_food_instances()
	_check_spawn()
	_check_missions()
	await _check_game_level()

	if _failed > 0:
		push_error("VALIDATION FAILED: %d issue(s)" % _failed)
		get_tree().quit(1)
	else:
		print("VALIDATION PASSED")
		get_tree().quit(0)


func _fail(msg: String) -> void:
	push_error(msg)
	_failed += 1


func _ok(cond: bool, msg: String) -> void:
	if cond:
		print("OK ", msg)
	else:
		_fail(msg)


func _check_textures() -> void:
	for path in [
		"res://assets/items/fruits/1.png",
		"res://assets/items/fruits/2.png",
		"res://assets/items/fruits/3.png",
	]:
		var tex: Texture2D = load(path)
		_ok(tex != null, "texture loads %s" % path)
		var img := Image.load_from_file(ProjectSettings.globalize_path(path))
		if img:
			if img.get_format() != Image.FORMAT_RGBA8:
				img.convert(Image.FORMAT_RGBA8)
			_ok(img.get_pixel(0, 0).a <= 0.01, "transparent corner %s" % path)


func _check_constants() -> void:
	_ok(CollectibleArt.watermelon_required_hole_size(0) == 1, "slice hole=1")
	_ok(CollectibleArt.watermelon_required_hole_size(1) == 2, "half hole=2")
	_ok(CollectibleArt.watermelon_required_hole_size(2) == 3, "whole hole=3")
	_ok(CollectibleArt.watermelon_score_value(0) == 2, "slice score=2")
	_ok(CollectibleArt.watermelon_score_value(1) == 5, "half score=5")
	_ok(CollectibleArt.watermelon_score_value(2) == 10, "whole score=10")
	var a := CollectibleArt.visual_radius(LevelTheme.Id.FRUIT_GARDEN, 0)
	var b := CollectibleArt.visual_radius(LevelTheme.Id.FRUIT_GARDEN, 1)
	var c := CollectibleArt.visual_radius(LevelTheme.Id.FRUIT_GARDEN, 2)
	_ok(a < b and b < c, "visual size order")


func _check_food_instances() -> void:
	var scene: PackedScene = load("res://scenes/food.tscn")
	_ok(scene != null, "food.tscn loads")
	if scene == null:
		return
	var food: Food = scene.instantiate() as Food
	add_child(food)
	food.setup(Vector2(200, 200), Food.Collectible.A, LevelTheme.Id.FRUIT_GARDEN, 0, true)
	_ok(food.get_required_hole_size() == 1 and food.score_value == 2, "slice setup")
	_ok(food.can_be_collected_by_hole_size(1), "slice swallowable at hole 1")
	food.setup(Vector2(300, 300), Food.Collectible.B, LevelTheme.Id.FRUIT_GARDEN, 0, true)
	_ok(food.get_required_hole_size() == 2 and food.score_value == 5, "half setup")
	_ok(not food.can_be_collected_by_hole_size(1), "half blocked at hole 1")
	_ok(food.can_be_collected_by_hole_size(2), "half ok at hole 2")
	food.setup(Vector2(400, 400), Food.Collectible.C, LevelTheme.Id.FRUIT_GARDEN, 0, true)
	_ok(food.get_required_hole_size() == 3 and food.score_value == 10, "whole setup")
	_ok(not food.can_be_collected_by_hole_size(2), "whole blocked at hole 2")
	_ok(food.can_be_collected_by_hole_size(3), "whole ok at hole 3")
	food.queue_free()


func _check_spawn() -> void:
	var spawner := FoodSpawner.new()
	add_child(spawner)
	spawner.spawn_level(Rect2(Vector2.ZERO, GameConstants.PLAY_AREA_SIZE), LevelTheme.Id.FRUIT_GARDEN, 1)
	var counts := {0: 0, 1: 0, 2: 0, 3: 0, 4: 0}
	var hole := Vector2(GameConstants.PLAY_AREA_SIZE) * 0.5
	for child in spawner.get_children():
		if child is Food:
			var f := child as Food
			var slot := int(f.item_type)
			counts[slot] = int(counts.get(slot, 0)) + 1
			if CollectibleArt.is_textured_watermelon(LevelTheme.Id.FRUIT_GARDEN, slot):
				if f.global_position.distance_to(hole) < FoodSpawner.START_HOLE_CLEAR_RADIUS:
					_fail("watermelon in start hole clear zone")
	print("SPAWN_COUNTS=", counts)
	_ok(int(counts[0]) >= 8, "slices spawned (~10) got %s" % counts[0])
	_ok(int(counts[1]) >= 4, "halves spawned (~5) got %s" % counts[1])
	_ok(int(counts[2]) >= 2, "wholes spawned (2) got %s" % counts[2])
	_ok(int(counts[3]) + int(counts[4]) >= 10, "growth fruits spawned")
	spawner.queue_free()


func _check_missions() -> void:
	var m := MissionFactory.create_missions(LevelTheme.Id.FRUIT_GARDEN, 3)
	_ok(m.size() == 3, "3 missions")
	_ok(m[0].target == 10 and m[1].target == 10 and m[2].target == 10, "fruit targets 10/10/10")
	var ff := MissionFactory.create_missions(LevelTheme.Id.FAST_FOOD, 23)
	_ok(ff[0].display_name == "Burgers", "fast food preserved")
	var m1 := MissionFactory.create_missions(LevelTheme.Id.FRUIT_GARDEN, 1)
	_ok(m1.size() == 1, "L1 single mission")


func _check_game_level() -> void:
	var packed: PackedScene = load("res://scenes/game.tscn")
	_ok(packed != null, "game.tscn loads")
	if packed == null:
		return
	var game := packed.instantiate()
	add_child(game)
	game.begin_level(1, [])
	await get_tree().process_frame
	await get_tree().process_frame
	var foods := get_tree().get_nodes_in_group("food")
	var counts := {0: 0, 1: 0, 2: 0, 3: 0, 4: 0}
	for food in foods:
		counts[int(food.item_type)] = int(counts.get(int(food.item_type), 0)) + 1
	print("GAME_LEVEL1_COUNTS=", counts, " total=", foods.size())
	_ok(int(counts[0]) >= 8, "game level has slices")
	_ok(int(counts[1]) >= 4, "game level has halves")
	_ok(int(counts[2]) >= 2, "game level has wholes")
	game.queue_free()
