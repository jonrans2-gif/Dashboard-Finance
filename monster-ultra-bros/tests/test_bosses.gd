extends TestCase
## Boss fights: arena start, weak-point rules, phases and defeat.


func _arena(boss: String) -> Level:
	var rows := []
	rows.append("B".repeat(56)); rows.append("B".repeat(56))
	for y in 10:
		rows.append(".".repeat(56))
	rows.append(".Y....S" + ".".repeat(22) + "Q" + ".".repeat(18) + "G" + ".".repeat(7))
	for y in 4:
		rows.append("#".repeat(56))
	var lv := await make_level(rows, {"boss": boss})
	await frames(5)
	return lv


func _stomp_pose(p: Player, top_y: float, x: float) -> void:
	p.global_position = Vector2(x, top_y)
	p.velocity = Vector2(0, 60)
	p.set("_invuln", 0.0)


func _defeat_and_check_goal(lv: Level, b: Node, hit: Callable) -> void:
	var defeated := [false]
	b.defeated.connect(func(): defeated[0] = true)
	var guard := 0
	while not b.dead and guard < 20:
		guard += 1
		b.set("_invuln", 0.0)
		hit.call()
	eq(guard, b.max_hp, "takes exactly max_hp hits")
	await seconds(3.5)
	check(defeated[0], "defeated signal")
	await seconds(2.5)
	check(lv.goal.enabled, "goal appears after the boss falls")


func test_arena_locks_and_spawns_boss() -> void:
	var lv := await _arena("sugar_king")
	check(lv.arena_active, "arena started when entering")
	check(lv.boss != null and lv.boss.hp == lv.boss.max_hp, "boss spawned at full health")
	eq(lv.atlas_at(Vector2i(1, 12)), Tiles.HARD, "gate closed behind the player")
	check(lv.camera.lock_rect.size.x > 0, "camera locked to the arena")


func test_sugar_king() -> void:
	var lv := await _arena("sugar_king")
	var b = lv.boss
	await seconds(1.5)
	var p := lv.player
	b.state = b.S.IDLE
	_stomp_pose(p, b.global_position.y - 32.0, b.global_position.x)
	b.on_part_contact("body", p)
	eq(b.hp, b.max_hp, "stomping while not dizzy does no damage")
	var states := {}
	for i in 360:
		await frames(1)
		states[b.state] = true
		p.set("_invuln", 1.0)
	check(states.size() >= 4, "cycles through hop / slam / stunned attacks (%d states)" % states.size())
	await _defeat_and_check_goal(lv, b, func():
		b.state = b.S.STUNNED
		_stomp_pose(p, b.global_position.y - 32.0, b.global_position.x)
		b.on_part_contact("body", p))


func test_crusher_prime() -> void:
	var lv := await _arena("crusher_prime")
	var b = lv.boss
	var p := lv.player
	var states := {}
	for i in 360:
		await frames(1)
		states[b.state] = true
		p.set("_invuln", 1.0)
	check(states.size() >= 4, "track / warn / slam / stuck cycle (%d states)" % states.size())
	b.state = b.S.TRACK
	_stomp_pose(p, b.global_position.y - 44.0, b.global_position.x)
	b.on_part_contact("core", p)
	eq(b.hp, b.max_hp, "closed core cannot be damaged")
	await _defeat_and_check_goal(lv, b, func():
		b.state = b.S.STUCK
		_stomp_pose(p, b.global_position.y - 44.0, b.global_position.x)
		b.on_part_contact("core", p))


func test_frost_volt() -> void:
	var lv := await _arena("frost_volt")
	var b = lv.boss
	var p := lv.player
	var states := {}
	for i in 600:
		await frames(1)
		states[b.state] = true
		p.set("_invuln", 1.0)
	check(states.size() >= 4, "swoops, lightning and drained phases (%d states)" % states.size())
	b.state = b.S.FLOAT
	_stomp_pose(p, b.global_position.y - 32.0, b.global_position.x)
	b.on_part_contact("body", p)
	eq(b.hp, b.max_hp, "cannot be hurt while charged")
	await _defeat_and_check_goal(lv, b, func():
		b.state = b.S.DRAINED
		_stomp_pose(p, b.global_position.y - 32.0, b.global_position.x)
		b.on_part_contact("body", p))


func test_overload_core() -> void:
	var lv := await _arena("overload_core")
	var b = lv.boss
	var p := lv.player
	var states := {}
	for i in 600:
		await frames(1)
		states[b.state] = true
		p.set("_invuln", 1.0)
	check(states.size() >= 4, "laser / orbs / overheat cycle (%d states)" % states.size())
	b.set("_core_open", false)
	p.set("_invuln", 0.0)
	var hp_before := p.hp
	b.on_part_contact("core", p)
	eq(b.hp, b.max_hp, "closed core is armoured")
	check(p.hp < hp_before, "touching the armoured machine hurts")
	await _defeat_and_check_goal(lv, b, func():
		b.set("_core_open", true)
		p.set("_invuln", 1.0)
		b.on_part_contact("core", p))
