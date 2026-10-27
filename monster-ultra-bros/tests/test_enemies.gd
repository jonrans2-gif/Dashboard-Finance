extends TestCase
## Enemy AI and player/enemy interaction.


func test_empty_can_patrols_and_turns_at_walls() -> void:
	var rows := flat(30, "S" + ".".repeat(29))
	put(rows, 8, 12, "B"); put(rows, 16, 12, "B"); put(rows, 12, 12, "e")
	var lv := await make_level(rows)
	var e: Enemy = enemies_of(lv)[0]
	var dirs := {}
	for i in 300:
		await frames(1)
		dirs[e.dir] = true
		check(e.global_position.x > 8 * 16 and e.global_position.x < 16 * 16, "stays between the walls")
		if dirs.size() == 2 and i > 60:
			break
	eq(dirs.size(), 2, "walked both directions")


func test_corrupted_can_does_not_walk_off_ledges() -> void:
	var rows := []
	for y in 9:
		rows.append(".".repeat(30))
	rows.append(".".repeat(10) + "BBBBBB" + ".".repeat(14))
	rows.append(".".repeat(30)); rows.append(".".repeat(30))
	rows.append("S" + ".".repeat(29))
	for y in 4:
		rows.append("#".repeat(30))
	put(rows, 12, 8, "k")
	var lv := await make_level(rows)
	var e: Enemy = enemies_of(lv)[0]
	await seconds(3.0)
	check(not e.dead and e.global_position.y < 10 * 16, "still on its platform after 3 s")


func test_stomp_defeats_and_bounces() -> void:
	var rows := flat(30, "...e" + ".".repeat(26))
	put(rows, 3, 5, "S")
	var lv := await make_level(rows)
	var e: Enemy = enemies_of(lv)[0]
	e.speed = 0.0
	var p := lv.player
	var bounced := false
	for i in 120:
		await frames(1)
		if e.dead:
			bounced = p.velocity.y < 0.0
			break
	check(e.dead, "enemy defeated by stomp")
	check(bounced, "player bounces off")
	eq(p.hp, Player.MAX_HP, "stomping does not hurt")
	check(GameState.score >= 100, "points awarded")


func test_side_contact_hurts() -> void:
	var lv := await make_level(flat(30, "S.....e" + ".".repeat(23)))
	var p := lv.player
	p.external_input = {"right": true}
	for i in 120:
		await frames(1)
		if p.hp < Player.MAX_HP:
			break
	eq(p.hp, Player.MAX_HP - 1, "walking into an enemy costs one energy cell")
	check(p.is_invulnerable(), "brief invulnerability after the hit")


func test_charged_slime_cannot_be_stomped() -> void:
	var rows := flat(30, "...z" + ".".repeat(26))
	put(rows, 3, 6, "S")
	var lv := await make_level(rows)
	var e: Enemy = enemies_of(lv)[0]
	e.speed = 0.0
	e.phase = 2           # CHARGED
	e.set("_t", 99.0)
	var p := lv.player
	for i in 90:
		await frames(1)
		e.velocity.x = 0.0
		if p.hp < Player.MAX_HP:
			break
	check(not e.dead, "charged slime survives the stomp")
	check(p.hp < Player.MAX_HP, "and shocks the player")


func test_drone_fires_projectiles() -> void:
	var rows := flat(40, "S" + ".".repeat(39))
	put(rows, 6, 8, "d")
	var lv := await make_level(rows)
	var found := false
	for i in 240:
		await frames(1)
		for c in lv.entities.get_children():
			if c.get_script() == preload("res://scripts/enemies/projectile.gd"):
				found = true
		if found:
			break
	check(found, "drone shoots an energy orb at a nearby player")


func test_sugar_cube_hops() -> void:
	var lv := await make_level(flat(40, "S.......u" + ".".repeat(31)))
	var e: Enemy = enemies_of(lv)[0]
	var y0 := e.global_position.y
	var min_y := y0
	for i in 240:
		await frames(1)
		min_y = min(min_y, e.global_position.y)
	check(min_y < y0 - 16.0, "sugar cube jumps (rose %.0f px)" % (y0 - min_y))


func test_enemies_wait_outside_the_view() -> void:
	var lv := await make_level(flat(120, "S" + ".".repeat(110) + "e" + ".".repeat(8)))
	var e: Enemy = enemies_of(lv)[0]
	var x0 := e.global_position.x
	await seconds(1.0)
	check(not e.active, "far enemy stays dormant")
	eq(e.global_position.x, x0, "and does not move")


func test_bumping_block_knocks_out_enemy_on_top() -> void:
	var rows := flat(30, "S" + ".".repeat(29))
	put(rows, 1, 9, "="); put(rows, 0, 9, "B"); put(rows, 2, 9, "B")
	put(rows, 1, 8, "e")
	var lv := await make_level(rows)
	var e: Enemy = enemies_of(lv)[0]
	e.speed = 0.0
	var p := lv.player
	p.global_position.x = 1 * 16 + 8
	p.external_input = {"jump": true, "jump_pressed": true}
	await seconds(0.6)
	check(e.dead, "enemy standing on a bumped block is knocked out")
