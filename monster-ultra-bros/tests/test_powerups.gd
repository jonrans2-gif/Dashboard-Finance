extends TestCase
## Power-up effects and expiry.


func test_ultra_boost_raises_top_speed() -> void:
	var lv := await make_level(flat(30))
	var p := lv.player
	var base := p.current_max_speed()
	p.add_power("boost")
	check(p.current_max_speed() > base * 1.35, "boost makes the can faster")


func test_white_shield_absorbs_one_hit() -> void:
	var lv := await make_level(flat(30))
	var p := lv.player
	p.add_power("shield")
	check(p.take_damage(p.global_position + Vector2(10, 0)), "hit registered")
	eq(p.hp, Player.MAX_HP, "no energy lost")
	check(not p.has_power("shield"), "shield is used up")


func test_mega_can_absorbs_hit_by_shrinking() -> void:
	var lv := await make_level(flat(30))
	var p := lv.player
	p.add_power("mega")
	await frames(2)
	check(p.is_mega(), "grew")
	p.take_damage(p.global_position + Vector2(10, 0))
	check(not p.is_mega(), "shrinks instead of losing energy")
	eq(p.hp, Player.MAX_HP, "energy unchanged")


func test_double_jump() -> void:
	var lv := await make_level(flat(30))
	var p := lv.player
	p.external_input = {"jump": true, "jump_pressed": true}
	await frames(20)
	p.external_input = {"jump": true, "jump_pressed": true}
	await frames(2)
	check(p.velocity.y > -100.0, "no air jump without the power")
	await seconds(1.0)
	p.add_power("double")
	p.external_input = {"jump": true, "jump_pressed": true}
	await frames(20)
	p.external_input = {"jump": true, "jump_pressed": true}
	await frames(2)
	check(p.velocity.y < -250.0, "second jump in mid-air with Double Jump")


func test_energy_surge_dash_breaks_barrier() -> void:
	var rows := flat(30)
	for y in range(10, 13):
		put(rows, 6, y, "X")
	var lv := await make_level(rows)
	var p := lv.player
	check(not p.can_dash(), "no dash without surge")
	p.add_power("surge")
	check(p.can_dash(), "surge unlocks the dash")
	p.external_input = {"right": true}
	await frames(10)
	p.external_input = {"right": true, "dash_pressed": true}
	await seconds(0.5)
	eq(lv.atlas_at(Vector2i(6, 12)), Vector2i(-1, -1), "barrier destroyed by the dash")
	check(p.global_position.x > 7 * 16, "dashed through")


func test_overload_is_invincible_and_defeats_enemies() -> void:
	var lv := await make_level(flat(30, "S.....e" + ".".repeat(23)))
	var p := lv.player
	p.add_power("overload")
	p.external_input = {"right": true}
	await seconds(1.0)
	eq(p.hp, Player.MAX_HP, "no damage while overloaded")
	check(enemies_of(lv).all(func(e): return e.dead) or enemies_of(lv).is_empty(), "enemy knocked out on contact")


func test_timed_powers_expire() -> void:
	var lv := await make_level(flat(30))
	var p := lv.player
	p.add_power("boost")
	p.powerups["boost"] = 0.3
	await seconds(0.5)
	check(not p.has_power("boost"), "boost expired")
	p.add_power("double")
	await seconds(1.0)
	check(p.has_power("double"), "double jump lasts until hit / level end")


func test_powerup_pickup_from_level() -> void:
	var lv := await make_level(flat(30, "S...p" + ".".repeat(25)), {"items": "magnet"})
	lv.player.external_input = {"right": true}
	await seconds(1.0)
	check(lv.player.has_power("magnet"), "free-standing power-up collected")
