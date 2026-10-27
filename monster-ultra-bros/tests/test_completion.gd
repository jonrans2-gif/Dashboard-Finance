extends TestCase
## Reaching the goal, score tally and progress unlock.


func test_goal_completes_level() -> void:
	SaveSystem.data = SaveSystem.default_progress()
	GameState.level_id = "1-1"
	GameState.level_start_score = 0
	var lv := await make_level(flat(40, "S.....G" + ".".repeat(33)))
	var result := {}
	lv.level_completed.connect(func(r): result.merge(r))
	lv.player.external_input = {"right": true}
	for i in 400:
		await frames(1)
		if not result.is_empty():
			break
	check(lv.completed, "level marked complete")
	check(not result.is_empty(), "result emitted after the goal sequence")
	check(int(result.get("time_bonus", 0)) > 0, "time bonus counted")
	check(int(result.get("flag_bonus", 0)) >= 100, "flag bonus counted")
	eq(int(result.get("level_score", -1)), GameState.score, "level score includes bonuses")
	GameState.complete_level(result)
	check(SaveSystem.is_completed("1-1"), "level saved as completed")
	check(SaveSystem.is_unlocked("1-2"), "next level unlocked")
	eq(int(SaveSystem.data.best_score["1-1"]), int(result.level_score), "best score stored")
	eq(SaveSystem.data["continue"].get("level"), "1-2", "continue points to the next level")


func test_higher_grab_gives_bigger_bonus() -> void:
	var bonus := []
	for jump in [false, true]:
		var lv := await make_level(flat(40, "S..........G" + ".".repeat(28)))
		var result := {}
		lv.level_completed.connect(func(r): result.merge(r))
		lv.player.external_input = {"right": true}
		if jump:
			while lv.player.global_position.x < 11 * 16 - 64:
				await frames(1)
			lv.player.external_input = {"right": true, "jump": true, "jump_pressed": true}
		for i in 400:
			await frames(1)
			if not result.is_empty():
				break
		bonus.append(int(result.get("flag_bonus", 0)))
		lv.queue_free()
		await frames(2)
	check(bonus[1] > bonus[0], "jumping onto the pole scores more (%s)" % str(bonus))


func test_boss_level_goal_hidden_until_defeat() -> void:
	var rows := flat(50, "S..Y..........Q.........G" + ".".repeat(25))
	var lv := await make_level(rows, {"boss": "sugar_king"})
	check(not lv.goal.enabled, "goal hidden while the boss lives")
