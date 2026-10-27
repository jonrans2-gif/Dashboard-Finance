extends TestCase
## Collision: walls, floors, one-way platforms, ceilings, moving platforms, ice, conveyors.


func test_wall_stops_player_at_full_speed() -> void:
	var rows := flat(40)
	for y in range(6, 13):
		rows[y] = rows[y].substr(0, 20) + "B" + rows[y].substr(21)
	var lv := await make_level(rows)
	var p := lv.player
	p.add_power("boost")
	p.external_input = {"right": true}
	var max_x := 0.0
	for i in 150:
		await frames(1)
		max_x = max(max_x, p.global_position.x)
	check(max_x <= 20 * 16 - 4.9, "never enters the wall (max x %.1f)" % max_x)
	check(p.is_on_floor(), "still standing on the floor")


func test_dash_into_wall() -> void:
	var rows := flat(40)
	for y in range(9, 13):
		rows[y] = rows[y].substr(0, 8) + "B" + rows[y].substr(9)
	var lv := await make_level(rows)
	var p := lv.player
	p.add_power("surge")
	p.external_input = {"right": true}
	await frames(5)
	p.external_input = {"right": true, "dash_pressed": true}
	for i in 40:
		await frames(1)
	check(p.global_position.x < 8 * 16, "dash cannot tunnel through solid blocks")


func test_one_way_platform() -> void:
	var rows := flat(30)
	rows[10] = "...____" + ".".repeat(23)
	rows[12] = "....S" + ".".repeat(25)
	var lv := await make_level(rows)
	var p := lv.player
	await frames(5)
	p.external_input = {"jump": true, "jump_pressed": true}
	for i in 70:
		await frames(1)
	p.external_input = {}
	await frames(20)
	check(p.is_on_floor(), "lands on the platform")
	near(p.global_position.y, 10 * 16.0, 1.0, "jumped up through it and stands on top")


func test_ceiling_stops_jump() -> void:
	var rows := flat(30)
	rows[10] = "BBBBBBBBBB" + ".".repeat(20)
	var lv := await make_level(rows)
	var p := lv.player
	await frames(5)
	p.external_input = {"jump": true, "jump_pressed": true}
	var min_y := 999.0
	for i in 60:
		await frames(1)
		min_y = min(min_y, p.global_position.y - p.body_height())
	check(min_y >= 11 * 16 - 0.5, "head never enters the ceiling (%.1f)" % min_y)


func test_mega_waits_for_head_room() -> void:
	var rows := flat(40)
	rows[10] = "BBBBBBBB" + ".".repeat(32)
	var lv := await make_level(rows)
	var p := lv.player
	await frames(3)
	p.add_power("mega")
	await frames(5)
	check(not p.is_mega(), "does not grow into a low ceiling")
	p.external_input = {"right": true}
	await seconds(2.0)
	check(p.global_position.x > 8 * 16 + 8, "left the tunnel")
	check(p.is_mega(), "grows once there is room")
	check(p.space_free(Vector2(p.body_width(), p.body_height())), "not overlapping any solid")
	check(p.global_position.x > 9 * 16, "kept walking after growing")


func test_moving_platform_carries_player() -> void:
	var rows := []
	for y in 10:
		rows.append(".".repeat(40))
	rows.append("....S" + ".".repeat(35))
	rows.append("...m------" + ".".repeat(30))
	for y in 5:
		rows.append(".".repeat(40))
	var lv := await make_level(rows)
	var p := lv.player
	await frames(10)
	var x0 := p.global_position.x
	await seconds(1.0)
	check(p.is_on_floor(), "standing on the moving platform")
	check(p.global_position.x > x0 + 20.0, "carried along (%.1f px)" % (p.global_position.x - x0))


func test_ice_is_slippery() -> void:
	var dist := []
	for floor_ch in ["#", "I"]:
		var rows := flat(80)
		rows[13] = floor_ch.repeat(80)
		var lv := await make_level(rows)
		var p := lv.player
		p.external_input = {"right": true}
		await seconds(0.6)
		p.external_input = {}
		var x0 := p.global_position.x
		await seconds(1.5)
		dist.append(p.global_position.x - x0)
		lv.queue_free()
		await frames(2)
	check(dist[1] > dist[0] * 2.5, "stopping distance on ice is much longer (%.0f vs %.0f)" % [dist[1], dist[0]])


func test_conveyor_pushes() -> void:
	var rows := flat(60, ".".repeat(20) + "S" + ".".repeat(39))
	rows[13] = ">".repeat(60)
	var lv := await make_level(rows)
	var p := lv.player
	var x0 := p.global_position.x
	await seconds(1.0)
	check(p.global_position.x > x0 + 30.0, "conveyor moves an idle player")
