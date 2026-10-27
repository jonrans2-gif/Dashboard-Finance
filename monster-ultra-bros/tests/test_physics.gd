extends TestCase
## Jump/run physics measured on the real Player inside a real Level.


func _ledge_level() -> Array:
	var rows := []
	for y in 12:
		rows.append(".".repeat(60))
	rows.append(".S" + ".".repeat(58))
	for y in 4:
		rows.append("#".repeat(12) + ".".repeat(48))
	return rows


func _measure_jump(p: Player, hold_frames: int) -> float:
	var y0 := p.global_position.y
	var min_y := y0
	p.external_input = {"jump": true, "jump_pressed": true}
	for i in 90:
		await frames(1)
		if i == hold_frames:
			p.external_input = {"jump": false}
		min_y = min(min_y, p.global_position.y)
		if i > 5 and p.is_on_floor():
			break
	p.external_input = {}
	return y0 - min_y


func test_variable_jump_height() -> void:
	var lv := await make_level(flat(40))
	var p := lv.player
	await frames(10)
	var full := await _measure_jump(p, 999)
	await frames(10)
	var tap := await _measure_jump(p, 1)
	check(full >= 65.0 and full <= 82.0, "standing held jump clears 4 tiles (%.1f px)" % full)
	check(tap >= 12.0 and tap < full * 0.55, "short tap gives a small hop (%.1f px)" % tap)


func test_running_jump_reach() -> void:
	var lv := await make_level(flat(200))
	var p := lv.player
	p.external_input = {"right": true}
	await seconds(0.5)
	var x0 := p.global_position.x
	var y0 := p.global_position.y
	p.external_input = {"right": true, "jump": true, "jump_pressed": true}
	var min_y := y0
	for i in 90:
		await frames(1)
		min_y = min(min_y, p.global_position.y)
		if i > 5 and p.is_on_floor():
			break
	var dist := p.global_position.x - x0
	check(y0 - min_y >= 68.0, "walking jump height >= 4.25 tiles (%.1f)" % (y0 - min_y))
	check(dist >= 5.0 * 16.0, "walking jump covers >= 5 tiles (%.1f px)" % dist)


func test_acceleration_and_run_build_up() -> void:
	var lv := await make_level(flat(200))
	var p := lv.player
	await frames(5)
	p.external_input = {"right": true}
	await frames(4)
	check(p.velocity.x > 20.0 and p.velocity.x < p.walk_speed, "speed builds up gradually (%.0f)" % p.velocity.x)
	await seconds(0.35)
	check(p.velocity.x >= p.walk_speed * 0.95, "reaches walk speed quickly (%.0f)" % p.velocity.x)
	await seconds(1.2)
	check(p.velocity.x >= p.run_speed * 0.95, "keeps accelerating to run speed (%.0f)" % p.velocity.x)
	p.external_input = {"left": true}
	await frames(3)
	check(p.get("_skidding"), "turning at speed skids")
	p.external_input = {}
	await seconds(0.5)
	near(p.velocity.x, 0.0, 1.0, "stops after releasing")


func test_coyote_time() -> void:
	var lv := await make_level(_ledge_level())
	var p := lv.player
	await frames(5)
	p.external_input = {"right": true}
	while p.is_on_floor():
		await frames(1)
	await frames(4)   # 4 frames (~67 ms) after leaving the ledge
	p.external_input = {"right": true, "jump": true, "jump_pressed": true}
	await frames(2)
	check(p.velocity.y < -200.0, "jump still works just after leaving a ledge (vy=%.0f)" % p.velocity.y)


func test_no_jump_long_after_ledge() -> void:
	var lv := await make_level(_ledge_level())
	var p := lv.player
	await frames(5)
	p.external_input = {"right": true}
	while p.is_on_floor():
		await frames(1)
	await frames(14)
	p.external_input = {"right": true, "jump": true, "jump_pressed": true}
	await frames(2)
	check(p.velocity.y > 0.0, "no mid-air jump without double jump")


func test_jump_buffer() -> void:
	var rows := flat(30)
	rows[12] = ".".repeat(30)
	rows[4] = "..S" + ".".repeat(27)
	var lv := await make_level(rows)
	var p := lv.player
	while not (p.velocity.y > 0.0 and p.global_position.y > 13 * 16 - 14):
		await frames(1)
	p.external_input = {"jump": true, "jump_pressed": true}   # pressed slightly before landing
	var jumped := false
	for i in 12:
		await frames(1)
		if p.velocity.y < -200.0:
			jumped = true
			break
	check(jumped, "a jump pressed just before landing is executed on landing")


func test_fall_speed_is_capped() -> void:
	var rows := []
	for y in 40:
		rows.append("..S......." if y == 1 else "..........")
	for y in 3:
		rows.append("##########")
	var lv := await make_level(rows)
	var p := lv.player
	var maxv := 0.0
	for i in 200:
		await frames(1)
		maxv = max(maxv, p.velocity.y)
		if p.is_on_floor():
			break
	check(maxv <= p.max_fall_speed + 0.1, "fall speed capped (%.0f)" % maxv)
	check(p.is_on_floor(), "landed after a long fall")
	near(p.global_position.y, 40 * 16.0, 1.0, "standing exactly on the floor")
