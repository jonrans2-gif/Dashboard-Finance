extends TestCase
## Damage, invulnerability frames, hazards and death.


func test_invulnerability_after_hit() -> void:
	var lv := await make_level(flat(30))
	var p := lv.player
	check(p.take_damage(p.global_position), "first hit applies")
	check(not p.take_damage(p.global_position), "second hit during blink is ignored")
	eq(p.hp, Player.MAX_HP - 1, "only one cell lost")
	await seconds(p.invuln_time + 0.1)
	check(p.take_damage(p.global_position), "hits apply again afterwards")
	eq(p.hp, Player.MAX_HP - 2, "second cell lost")


func test_three_hits_kill() -> void:
	var lv := await make_level(flat(30))
	var p := lv.player
	var died := [false]
	p.died.connect(func(): died[0] = true)
	for i in 3:
		p.set("_invuln", 0.0)
		p.take_damage(p.global_position)
	eq(p.state, Player.State.DEAD, "dead after 3 hits")
	check(died[0], "died signal emitted")
	await seconds(2.5)
	check(p.death_finished(), "death animation finishes")


func test_spikes_hurt() -> void:
	var lv := await make_level(flat(30, "S...^^^" + ".".repeat(23)))
	var p := lv.player
	p.external_input = {"right": true}
	for i in 90:
		await frames(1)
		if p.hp < Player.MAX_HP:
			break
	check(p.hp < Player.MAX_HP, "spikes cost energy")


func test_goo_is_deadly() -> void:
	var rows := flat(30)
	for x in range(5, 12):
		put(rows, x, 13, "."); put(rows, x, 14, "~"); put(rows, x, 15, "~"); put(rows, x, 16, "~")
	var lv := await make_level(rows)
	lv.player.external_input = {"right": true}
	await seconds(1.5)
	eq(lv.player.state, Player.State.DEAD, "falling into energy goo is fatal")


func test_pit_is_deadly() -> void:
	var rows := flat(30)
	for x in range(5, 12):
		for y in range(13, 17):
			put(rows, x, y, ".")
	var lv := await make_level(rows)
	lv.player.external_input = {"right": true}
	await seconds(2.0)
	eq(lv.player.state, Player.State.DEAD, "falling into a pit costs a life")


func test_timer_runs_out() -> void:
	var lv := await make_level(flat(30), {"time": "1"})
	await seconds(1.3)
	eq(lv.player.state, Player.State.DEAD, "time up kills the can")
