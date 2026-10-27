extends TestCase
## Checkpoints, respawn position, lives and attempt persistence.


func test_checkpoint_activation() -> void:
	var lv := await make_level(flat(40, "S....C" + ".".repeat(34)))
	var p := lv.player
	p.take_damage(p.global_position)
	p.external_input = {"right": true}
	await seconds(1.0)
	eq(GameState.checkpoint, 0, "checkpoint index stored")
	check(lv.checkpoints[0].active, "flag raised")
	eq(p.hp, Player.MAX_HP, "energy refilled")
	eq(int(SaveSystem.data["continue"].get("checkpoint", -1)), 0, "continue point saved")


func test_respawn_at_checkpoint() -> void:
	GameState.checkpoint = 0
	var lv := await make_level(flat(40, "S.........C" + ".".repeat(29)))
	near(lv.player.global_position.x, lv.checkpoints[0].position.x, 0.5, "spawns at the checkpoint")
	check(lv.checkpoints[0].active, "checkpoint shown as active")


func test_collected_shards_stay_collected_after_death() -> void:
	GameState.attempt_shards = [0]
	var lv := await make_level(flat(40, "S..$...$" + ".".repeat(32)))
	var shards := 0
	for c in lv.entities.get_children():
		if c.get("kind") == "shard":
			shards += 1
	eq(shards, 1, "only the uncollected shard is placed again")


func test_lives_and_game_over() -> void:
	GameState.lives = 2
	check(GameState.lose_life(), "one life left -> continue")
	eq(GameState.lives, 1, "life lost")
	check(not GameState.lose_life(), "no lives -> game over")
	eq(int(SaveSystem.data["continue"].get("lives", 0)), GameState.START_LIVES, "continue resets lives after game over")
