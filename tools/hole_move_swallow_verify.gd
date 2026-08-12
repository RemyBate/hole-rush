extends Node

## Hole anchored-pointer movement + swallow animation regression tests.


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
	failed += _check_anchor_offset_math()
	failed += _check_100px_move_ratio()
	failed += _check_no_drift_over_repeated_moves()
	failed += _check_clamp_with_offset()
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


func _check_anchor_offset_math() -> int:
	var hole := (load("res://scenes/hole.tscn") as PackedScene).instantiate() as Hole
	add_child(hole)
	hole.global_position = Vector2(400, 800)
	hole._target_position = hole.global_position
	hole.radius = 48.0
	hole.pointer_offset_x = 0.0
	hole.pointer_offset_y = 0.0
	hole.finger_visibility_margin = 14.0
	hole.finger_contact_radius_screen = 34.0
	hole.set_play_bounds(Rect2(0, 0, 3200, 3200))

	var offset := hole.compute_pointer_offset_world(true)
	if offset.x != 0.0:
		push_error("[MOVE] expected pointer_offset_x 0, got %s" % offset.x)
		hole.queue_free()
		return 1
	# Hole must sit above the pointer (negative Y in Godot 2D).
	if offset.y >= -hole.radius:
		push_error("[MOVE] offset too small; pointer would cover hole centre: %s" % offset)
		hole.queue_free()
		return 1

	var pointer_world := Vector2(500, 900)
	hole._set_from_screen_pointer(
		hole.get_canvas_transform() * pointer_world,
		true
	)
	# After set, hole should be above the world pointer by ~offset (clamped).
	var gap := hole.global_position - pointer_world
	if absf(gap.x - offset.x) > 1.5:
		push_error("[MOVE] X gap drifted from offset: gap=%s offset=%s" % [gap, offset])
		hole.queue_free()
		return 1
	if gap.y >= 0.0:
		push_error("[MOVE] hole is not above pointer: gap.y=%s" % gap.y)
		hole.queue_free()
		return 1
	# Pointer must not intersect the central visible area (inside ~60% of radius).
	var dist := hole.global_position.distance_to(pointer_world)
	if dist < hole.radius * 0.6:
		push_error("[MOVE] pointer intersects hole centre dist=%s radius=%s" % [dist, hole.radius])
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
	# Place via absolute screen coords derived from canvas.
	var p0 := Vector2(600, 1000)
	var p1 := p0 + Vector2(100, 0)
	var p2 := p1 + Vector2(0, -100)
	hole._set_from_screen_pointer(hole.get_canvas_transform() * p0, false)
	var h0 := hole.global_position
	hole._set_from_screen_pointer(hole.get_canvas_transform() * p1, false)
	var h1 := hole.global_position
	hole._set_from_screen_pointer(hole.get_canvas_transform() * p2, false)
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
	# Gap must stay constant (no sensitivity multiply / no growing distance).
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
	hole._set_from_screen_pointer(hole.get_canvas_transform() * base, true)
	var expected_gap := hole.global_position - base
	for i in 40:
		var p := base + Vector2(float(i) * 7.0, float(i % 5) * -3.0)
		hole._set_from_screen_pointer(hole.get_canvas_transform() * p, true)
		# No lag: position equals clamped target immediately.
		if hole.global_position.distance_to(hole._target_position) > 0.01:
			push_error("[MOVE] smoothing lag detected")
			hole.queue_free()
			return 1
		var gap := hole.global_position - p
		if gap.distance_to(expected_gap) > 0.75:
			push_error("[MOVE] drift at step %d gap=%s expected=%s" % [i, gap, expected_gap])
			hole.queue_free()
			return 1
	print("[MOVE] OK no drift over 40 steps gap=", expected_gap)
	hole.queue_free()
	return 0


func _check_clamp_with_offset() -> int:
	var hole := (load("res://scenes/hole.tscn") as PackedScene).instantiate() as Hole
	add_child(hole)
	hole.radius = 48.0
	var bounds := Rect2(100, 200, 600, 900)
	hole.set_play_bounds(bounds)
	# Pointer far above / outside — hole must stay fully inside playable rect.
	var outside := Vector2(bounds.position.x + 50, bounds.position.y - 200)
	hole._set_from_screen_pointer(hole.get_canvas_transform() * outside, true)
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
	# Return pointer to centre — offset resumes without sticking to a wrong gap.
	var centre := bounds.position + bounds.size * 0.5
	hole._set_from_screen_pointer(hole.get_canvas_transform() * centre, true)
	var expected := hole.compute_pointer_offset_world(true)
	var gap := hole.global_position - centre
	if gap.distance_to(expected) > 1.0:
		push_error("[MOVE] offset did not resume after clamp gap=%s expected=%s" % [gap, expected])
		hole.queue_free()
		return 1
	print("[MOVE] OK clamp+resume")
	hole.queue_free()
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
			var start_pointer := hole.global_position - hole.compute_pointer_offset_world(false)
			var screen0 := hole.get_canvas_transform() * start_pointer
			hole._set_from_screen_pointer(screen0, false)
			var h0 := hole.global_position
			var gap0 := h0 - start_pointer

			# Move pointer 100 screen/world units right (canvas identity-ish in game world).
			var steps := maxi(1, int(float(fps) * 0.25))
			var per_step := 100.0 / float(steps)
			var pointer := start_pointer
			for _s in steps:
				pointer += Vector2(per_step, 0.0)
				hole._set_from_screen_pointer(hole.get_canvas_transform() * pointer, false)
				hole._physics_process(1.0 / float(fps))
			var moved := hole.global_position.x - h0.x
			var ratio := moved / 100.0
			ratios.append(ratio)
			var gap1 := hole.global_position - pointer
			if gap0.distance_to(gap1) > 2.0:
				push_error("[MOVE] gap changed during drag res=%s fps=%d" % [str(res), fps])
				failed += 1
			if absf(ratio - 1.0) > 0.08:
				push_error("[MOVE] bad 100px ratio=%.3f res=%s fps=%d" % [ratio, str(res), fps])
				failed += 1
			# Pointer stays below hole.
			if hole.global_position.y >= pointer.y:
				push_error("[MOVE] pointer not below hole res=%s" % str(res))
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
