extends Node

## Control-position hole movement + swallow animation regression tests.
## Desktop mouse and Android touch both drive the same absolute control-position model.


const RESOLUTIONS: Array[Vector2i] = [
	Vector2i(720, 1280),
	Vector2i(1080, 1920),
	Vector2i(1080, 2340),
	Vector2i(1080, 2400),
	Vector2i(1440, 3200),
]

const FPS_SAMPLES: Array[int] = [30, 60, 90, 120]


func _ready() -> void:
	await get_tree().process_frame
	var failed := 0
	failed += _check_control_api()
	failed += _check_anchor_offset_math()
	failed += _check_100px_move_ratio()
	failed += _check_no_drift_over_repeated_moves()
	failed += _check_multi_touch_ignored()
	failed += _check_clamp_with_offset()
	failed += await _check_hud_input_ignored()
	failed += await _check_movement_consistency()
	failed += await _check_swallow_sequence()
	failed += await _check_oversized_not_swallowed()
	failed += await _check_level2_still_counts()
	if failed > 0:
		push_error("[MOVE] FAILED %d" % failed)
		get_tree().quit(1)
		return
	print("[MOVE] PASSED")
	get_tree().quit(0)


func _check_control_api() -> int:
	var hole := (load("res://scenes/hole.tscn") as PackedScene).instantiate() as Hole
	add_child(hole)
	var failed := 0
	if not hole.uses_absolute_control_position():
		push_error("[MOVE] uses_absolute_control_position expected true")
		failed += 1
	if not hole.has_method("set_from_control_position"):
		push_error("[MOVE] missing set_from_control_position")
		failed += 1
	if not hole.has_method("control_position_to_world"):
		push_error("[MOVE] missing control_position_to_world")
		failed += 1
	if not hole.has_method("compute_visibility_offset_world"):
		push_error("[MOVE] missing compute_visibility_offset_world")
		failed += 1
	# Structural: no legacy relative-delta / smoothing API.
	if hole.get("move_sensitivity") != null or hole.get("move_drag_smoothing") != null:
		push_error("[MOVE] legacy relative/smoothing exports still present")
		failed += 1
	if failed == 0:
		print("[MOVE] OK control-position API")
	hole.queue_free()
	return failed


func _check_anchor_offset_math() -> int:
	var hole := (load("res://scenes/hole.tscn") as PackedScene).instantiate() as Hole
	add_child(hole)
	hole.global_position = Vector2(400, 800)
	hole._target_position = hole.global_position
	hole.radius = 48.0
	hole.pointer_visibility_offset = Vector2.ZERO
	hole.touch_visibility_margin = 14.0
	hole.touch_contact_radius_screen = 34.0
	hole.set_play_bounds(Rect2(0, 0, 3200, 3200))

	var offset := hole.compute_visibility_offset_world(true)
	if offset.x != 0.0:
		push_error("[MOVE] expected visibility offset.x 0, got %s" % offset.x)
		hole.queue_free()
		return 1
	if offset.y >= -hole.radius:
		push_error("[MOVE] offset too small; control position would cover hole centre: %s" % offset)
		hole.queue_free()
		return 1

	var control_world := Vector2(500, 900)
	hole.set_from_control_position(hole.get_canvas_transform() * control_world, true)
	var gap := hole.global_position - control_world
	if absf(gap.x - offset.x) > 1.5:
		push_error("[MOVE] X gap drifted from offset: gap=%s offset=%s" % [gap, offset])
		hole.queue_free()
		return 1
	if gap.y >= 0.0:
		push_error("[MOVE] hole is not above control position: gap.y=%s" % gap.y)
		hole.queue_free()
		return 1
	var dist := hole.global_position.distance_to(control_world)
	if dist < hole.radius * 0.6:
		push_error("[MOVE] control position intersects hole centre dist=%s radius=%s" % [dist, hole.radius])
		hole.queue_free()
		return 1

	print("[MOVE] OK anchor offset=", offset, " gap=", gap, " dist=", snappedf(dist, 0.01))
	hole.queue_free()
	return 0


func _check_100px_move_ratio() -> int:
	var hole := (load("res://scenes/hole.tscn") as PackedScene).instantiate() as Hole
	add_child(hole)
	hole.set_play_bounds(Rect2(0, 0, 4000, 4000))
	hole.radius = 48.0
	var p0 := Vector2(600, 1000)
	var p1 := p0 + Vector2(100, 0)
	var p2 := p1 + Vector2(0, -100)
	hole.set_from_control_position(hole.get_canvas_transform() * p0, false)
	var h0 := hole.global_position
	hole.set_from_control_position(hole.get_canvas_transform() * p1, false)
	var h1 := hole.global_position
	hole.set_from_control_position(hole.get_canvas_transform() * p2, false)
	var h2 := hole.global_position

	var dx := h1 - h0
	var dy := h2 - h1
	var failed := 0
	if absf(dx.x - 100.0) > 1.0 or absf(dx.y) > 1.0:
		push_error("[MOVE] 100px right failed: hole moved %s" % dx)
		failed += 1
	if absf(dy.y + 100.0) > 1.0 or absf(dy.x) > 1.0:
		push_error("[MOVE] 100px up failed: hole moved %s" % dy)
		failed += 1
	var gap0 := h0 - p0
	var gap1 := h1 - p1
	var gap2 := h2 - p2
	if gap0.distance_to(gap1) > 0.5 or gap0.distance_to(gap2) > 0.5:
		push_error("[MOVE] offset not constant gaps=%s %s %s" % [gap0, gap1, gap2])
		failed += 1
	else:
		print(
			"[MOVE] OK 100px ratio dx=",
			snappedf(dx.x, 0.01),
			" dy=",
			snappedf(dy.y, 0.01),
			" gap=",
			gap0
		)
	hole.queue_free()
	return failed


func _check_no_drift_over_repeated_moves() -> int:
	var hole := (load("res://scenes/hole.tscn") as PackedScene).instantiate() as Hole
	add_child(hole)
	hole.set_play_bounds(Rect2(0, 0, 5000, 5000))
	var base := Vector2(800, 1200)
	hole.set_from_control_position(hole.get_canvas_transform() * base, true)
	var expected_gap := hole.global_position - base
	for i in 100:
		var p := base + Vector2(float(i) * 5.0, float(i % 7) * -2.0)
		hole.set_from_control_position(hole.get_canvas_transform() * p, true)
		if hole.global_position.distance_to(hole._target_position) > 0.01:
			push_error("[MOVE] smoothing lag detected")
			hole.queue_free()
			return 1
		var gap := hole.global_position - p
		if gap.distance_to(expected_gap) > 0.75:
			push_error("[MOVE] drift at step %d gap=%s expected=%s" % [i, gap, expected_gap])
			hole.queue_free()
			return 1
	print("[MOVE] OK no drift over 100 steps gap=", expected_gap)
	hole.queue_free()
	return 0


func _check_multi_touch_ignored() -> int:
	var hole := (load("res://scenes/hole.tscn") as PackedScene).instantiate() as Hole
	add_child(hole)
	hole.set_play_bounds(Rect2(0, 0, 4000, 4000))
	var p0 := Vector2(700, 1100)
	hole.set_from_control_position(hole.get_canvas_transform() * p0, true)
	hole._control_is_touch = true
	hole._active_touch_index = 0
	hole._is_dragging = true
	var before := hole.global_position

	# Second finger drag must be ignored.
	var drag := InputEventScreenDrag.new()
	drag.index = 1
	drag.position = hole.get_canvas_transform() * (p0 + Vector2(200, 0))
	drag.relative = Vector2(200, 0)
	hole._handle_screen_drag(drag)
	if hole.global_position.distance_to(before) > 0.01:
		push_error("[MOVE] second touch moved the hole")
		hole.queue_free()
		return 1

	# Emulated mouse must not duplicate while touch is active.
	var motion := InputEventMouseMotion.new()
	motion.position = hole.get_canvas_transform() * (p0 + Vector2(150, 50))
	motion.relative = Vector2(150, 50)
	hole._handle_mouse_motion(motion)
	if hole.global_position.distance_to(before) > 0.01:
		push_error("[MOVE] emulated mouse duplicated touch movement")
		hole.queue_free()
		return 1

	print("[MOVE] OK multi-touch / emulated-mouse ignored")
	hole.queue_free()
	return 0


func _check_clamp_with_offset() -> int:
	var hole := (load("res://scenes/hole.tscn") as PackedScene).instantiate() as Hole
	add_child(hole)
	hole.radius = 48.0
	var bounds := Rect2(100, 200, 600, 900)
	hole.set_play_bounds(bounds)
	var outside := Vector2(bounds.position.x + 50, bounds.position.y - 200)
	hole.set_from_control_position(hole.get_canvas_transform() * outside, true)
	var top := hole.global_position.y - hole.radius
	if top < bounds.position.y - 0.5:
		push_error("[MOVE] hole entered HUD/top after offset clamp")
		hole.queue_free()
		return 1
	var left := hole.global_position.x - hole.radius
	if left < bounds.position.x - 0.5:
		push_error("[MOVE] hole left bound violated")
		hole.queue_free()
		return 1
	var centre := bounds.position + bounds.size * 0.5
	hole.set_from_control_position(hole.get_canvas_transform() * centre, true)
	var expected := hole.compute_visibility_offset_world(true)
	var gap := hole.global_position - centre
	if gap.distance_to(expected) > 1.0:
		push_error("[MOVE] offset did not resume after clamp gap=%s expected=%s" % [gap, expected])
		hole.queue_free()
		return 1
	print("[MOVE] OK clamp+resume")
	hole.queue_free()
	return 0


func _check_hud_input_ignored() -> int:
	await _set_window(Vector2i(720, 1280))
	var game := (load("res://scenes/game.tscn") as PackedScene).instantiate() as Node2D
	add_child(game)
	game.begin_level(2, [])
	for _i in 12:
		await get_tree().process_frame
	var hole: Hole = game.get_node("Hole") as Hole
	var before := hole.global_position
	var hud := game.find_child("HUD", true, false)
	if hud == null:
		push_error("[MOVE] HUD missing")
		await _teardown(game)
		return 1
	# Simulate a press that the HUD consumes (handled) — hole must not move.
	var btn := hud.find_child("PauseButton", true, false)
	if btn == null:
		btn = hud.find_child("MenuButton", true, false)
	if btn is BaseButton:
		(btn as BaseButton).emit_signal("pressed")
	await get_tree().process_frame
	if hole.global_position.distance_to(before) > 1.0 and not hole._is_dragging:
		# Pause may freeze hole; position must still not jump from a HUD click.
		push_error("[MOVE] HUD interaction moved hole unexpectedly")
		await _teardown(game)
		return 1
	print("[MOVE] OK HUD interaction does not drive hole")
	await _teardown(game)
	return 0


func _check_movement_consistency() -> int:
	var failed := 0
	var ratios: Array[float] = []
	for res in RESOLUTIONS:
		await _set_window(res)
		for fps in FPS_SAMPLES:
			var game := (load("res://scenes/game.tscn") as PackedScene).instantiate() as Node2D
			add_child(game)
			game.begin_level(2, [])
			for _i in 12:
				await get_tree().process_frame
			var hole: Hole = game.get_node("Hole") as Hole
			var start_control := hole.global_position - hole.compute_visibility_offset_world(false)
			var screen0 := hole.get_canvas_transform() * start_control
			hole.set_from_control_position(screen0, false)
			var h0 := hole.global_position
			var gap0 := h0 - start_control

			var steps := maxi(1, int(float(fps) * 0.25))
			var per_step := 100.0 / float(steps)
			var control := start_control
			for _s in steps:
				control += Vector2(per_step, 0.0)
				hole.set_from_control_position(hole.get_canvas_transform() * control, false)
				hole._physics_process(1.0 / float(fps))
			var moved := hole.global_position.x - h0.x
			var ratio := moved / 100.0
			ratios.append(ratio)
			var gap1 := hole.global_position - control
			if gap0.distance_to(gap1) > 2.0:
				push_error("[MOVE] gap changed during drag res=%s fps=%d" % [str(res), fps])
				failed += 1
			if absf(ratio - 1.0) > 0.08:
				push_error("[MOVE] bad 100px ratio=%.3f res=%s fps=%d" % [ratio, str(res), fps])
				failed += 1
			if hole.global_position.y >= control.y:
				push_error("[MOVE] control position not below hole res=%s" % str(res))
				failed += 1
			var play: Rect2 = game.call("get_play_bounds")
			if hole.global_position.y - hole.radius < play.position.y - 1.0:
				push_error("[MOVE] hole entered HUD strip at %s fps=%d" % [str(res), fps])
				failed += 1
			await _teardown(game)
		print("[MOVE] OK movement sample res=", res, " ratios=", ratios.slice(ratios.size() - FPS_SAMPLES.size()))
	if ratios.size() >= 2:
		var mn := ratios[0]
		var mx := ratios[0]
		for r in ratios:
			mn = minf(mn, r)
			mx = maxf(mx, r)
		if mx - mn > 0.12:
			push_error("[MOVE] movement ratio unstable across fps/res mn=%.3f mx=%.3f" % [mn, mx])
			failed += 1
		else:
			print("[MOVE] OK ratio span=", snappedf(mx - mn, 0.001), " mean~", snappedf((mn + mx) * 0.5, 0.001))
	return failed


func _check_swallow_sequence() -> int:
	await _set_window(Vector2i(720, 1280))
	var game := (load("res://scenes/game.tscn") as PackedScene).instantiate() as Node2D
	add_child(game)
	game.begin_level(2, [])
	for _i in 16:
		await get_tree().process_frame

	var hole: Hole = game.get_node("Hole") as Hole
	var food: Food = null
	for node in get_tree().get_nodes_in_group("food"):
		var f := node as Food
		if f != null and f.can_be_swallowed_by(hole):
			food = f
			break
	if food == null:
		push_error("[MOVE] no swallowable food found")
		await _teardown(game)
		return 1

	var fx_count := {"n": 0}
	var collected_count := {"n": 0}
	var score_before: int = int(game.get("_score"))

	food.swallow_fx.connect(func(_f): fx_count.n += 1)
	food.collected.connect(func(_f): collected_count.n += 1)

	var start_scale := food._draw_scale
	if not food.try_collect(hole):
		push_error("[MOVE] try_collect failed for swallowable item")
		await _teardown(game)
		return 1
	if food.collision_layer != 0:
		push_error("[MOVE] collision not disabled while swallowing")
		await _teardown(game)
		return 1
	if not food.visible or not food.is_busy():
		push_error("[MOVE] food should remain visible/busy while swallowing")
		await _teardown(game)
		return 1

	var saw_shrink := false
	var mid_alive := false
	for _i in 45:
		await get_tree().process_frame
		if is_instance_valid(food):
			if food._draw_scale < start_scale - 0.05:
				saw_shrink = true
			if food._collect_elapsed > food._approach_duration * 0.5:
				mid_alive = true
		else:
			break

	for _i in 60:
		if not is_instance_valid(food):
			break
		await get_tree().process_frame

	var failed := 0
	if not mid_alive:
		push_error("[MOVE] food vanished before mid-swallow")
		failed += 1
	if not saw_shrink:
		push_error("[MOVE] food did not shrink during swallow")
		failed += 1
	if int(fx_count.n) != 1:
		push_error("[MOVE] swallow_fx count=%d want 1" % int(fx_count.n))
		failed += 1
	if int(collected_count.n) != 1:
		push_error("[MOVE] collected count=%d want 1" % int(collected_count.n))
		failed += 1
	var score_after: int = int(game.get("_score"))
	if score_after <= score_before:
		push_error("[MOVE] score did not increase after swallow")
		failed += 1

	if failed == 0:
		print("[MOVE] OK swallow sequence fx=1 collected=1 shrink+visible")
	await _teardown(game)
	return failed


func _check_oversized_not_swallowed() -> int:
	await _set_window(Vector2i(720, 1280))
	var game := (load("res://scenes/game.tscn") as PackedScene).instantiate() as Node2D
	add_child(game)
	game.begin_level(10, [])
	for _i in 20:
		await get_tree().process_frame
	var hole: Hole = game.get_node("Hole") as Hole
	hole.radius = GameConstants.INITIAL_HOLE_RADIUS
	hole._apply_radius(hole.radius)
	var blocked := 0
	var attempted := 0
	for node in get_tree().get_nodes_in_group("food"):
		var food := node as Food
		if food == null:
			continue
		if food.can_be_swallowed_by(hole):
			continue
		attempted += 1
		var score_before: int = int(game.get("_score"))
		var ok := food.try_collect(hole)
		if ok or food.is_busy():
			push_error("[MOVE] oversized item began swallow")
			await _teardown(game)
			return 1
		if int(game.get("_score")) != score_before:
			push_error("[MOVE] oversized item changed score")
			await _teardown(game)
			return 1
		blocked += 1
		if blocked >= 1:
			break
	if attempted == 0:
		print("[MOVE] OK oversized check skipped (no oversized on L10 sample)")
	else:
		print("[MOVE] OK oversized rejected")
	await _teardown(game)
	return 0


func _check_level2_still_counts() -> int:
	await _set_window(Vector2i(720, 1280))
	var game := (load("res://scenes/game.tscn") as PackedScene).instantiate() as Node2D
	add_child(game)
	game.begin_level(2, [])
	for _i in 16:
		await get_tree().process_frame
	var missions: Array = game.get("_missions")
	if missions.size() != 2:
		push_error("[MOVE] L2 mission count")
		await _teardown(game)
		return 1
	var hole: Hole = game.get_node("Hole") as Hole
	var failed := 0
	for m in missions:
		var mission := m as Mission
		var food: Food = null
		for node in get_tree().get_nodes_in_group("food"):
			var f := node as Food
			if f != null and mission.matches_food(f) and f.can_be_swallowed_by(hole):
				food = f
				break
		if food == null:
			push_error("[MOVE] no matching swallowable food for %s" % mission.catalog_key)
			failed += 1
			continue
		var before := mission.progress
		food.try_collect(hole)
		for _i in 90:
			if not is_instance_valid(food):
				break
			await get_tree().process_frame
		if mission.progress != before + 1:
			push_error("[MOVE] L2 counter not +1 for %s (%d→%d)" % [mission.catalog_key, before, mission.progress])
			failed += 1
		else:
			print("[MOVE] OK L2 counter ", mission.catalog_key, " -> ", mission.progress)
	await _teardown(game)
	return failed


func _set_window(res: Vector2i) -> void:
	var win := get_window()
	if win:
		win.size = res
	await get_tree().process_frame
	await get_tree().process_frame


func _teardown(game: Node) -> void:
	if game != null and is_instance_valid(game):
		game.queue_free()
	for _i in 3:
		await get_tree().process_frame
