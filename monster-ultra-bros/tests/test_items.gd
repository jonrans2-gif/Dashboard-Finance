extends TestCase
## Collectibles and blocks.


func test_token_pickup() -> void:
	var lv := await make_level(flat(30, "S..ooo" + ".".repeat(24)))
	lv.player.external_input = {"right": true}
	await seconds(1.0)
	eq(lv.stats.tokens, 3, "three tokens collected")
	eq(GameState.tokens, 3, "token counter")
	eq(GameState.score, 30, "10 points each")


func test_hundred_tokens_give_a_life() -> void:
	var lv := await make_level(flat(30, "S.o" + ".".repeat(27)))
	GameState.tokens = 99
	var lives := GameState.lives
	lv.player.external_input = {"right": true}
	await seconds(0.6)
	eq(GameState.lives, lives + 1, "extra life at 100 tokens")
	eq(GameState.tokens, 0, "counter wraps")


func test_energy_block_gives_token_and_turns_used() -> void:
	var rows := flat(20, "S" + ".".repeat(19))
	put(rows, 0, 9, "?")
	var lv := await make_level(rows)
	lv.player.external_input = {"jump": true, "jump_pressed": true}
	await seconds(0.7)
	eq(lv.atlas_at(Vector2i(0, 9)), Tiles.USED, "block is used up")
	eq(lv.stats.tokens, 1, "token released")


func test_power_block_spawns_powerup() -> void:
	var rows := flat(20, "S" + ".".repeat(19))
	put(rows, 0, 9, "!")
	var lv := await make_level(rows, {"powerups": "shield"})
	lv.player.external_input = {"jump": true, "jump_pressed": true}
	await seconds(0.5)
	var item: Node = null
	for c in lv.entities.get_children():
		if c.get_script() == preload("res://scripts/items/powerup_item.gd"):
			item = c
	check(item != null and item.kind == "shield", "power-up emerges from the block")
	await seconds(0.5)
	lv.player.external_input = {}
	lv.player.global_position = Vector2(8, 9 * 16)   # climb onto the block
	await seconds(0.3)
	check(lv.player.has_power("shield"), "touching it collects it")


func test_brick_only_breaks_when_mega() -> void:
	var rows := flat(20, "S" + ".".repeat(19))
	put(rows, 0, 8, "=")
	var lv := await make_level(rows)
	var p := lv.player
	p.external_input = {"jump": true, "jump_pressed": true}
	await seconds(0.8)
	eq(lv.atlas_at(Vector2i(0, 8)), Tiles.BRICK, "small can only bumps bricks")
	p.add_power("mega")
	await frames(3)
	check(p.is_mega(), "mega active")
	p.external_input = {"jump": true, "jump_pressed": true}
	await seconds(0.8)
	eq(lv.atlas_at(Vector2i(0, 8)), Vector2i(-1, -1), "mega can breaks the brick")


func test_hidden_block_appears_from_below() -> void:
	var rows := flat(20, "S" + ".".repeat(19))
	put(rows, 0, 9, "H")
	var lv := await make_level(rows)
	eq(lv.atlas_at(Vector2i(0, 9)), Vector2i(-1, -1), "invisible at first")
	lv.player.external_input = {"jump": true, "jump_pressed": true}
	await seconds(0.5)
	eq(lv.atlas_at(Vector2i(0, 9)), Tiles.USED, "revealed and used by a head bump")


func test_magnet_pulls_tokens() -> void:
	var lv := await make_level(flat(30, "S....o" + ".".repeat(24)))
	lv.player.add_power("magnet")
	await seconds(0.8)
	eq(lv.stats.tokens, 1, "token flew to the standing player")


func test_shard_and_core_recorded_for_attempt() -> void:
	var lv := await make_level(flat(30, "S.$.@" + ".".repeat(25)))
	lv.player.external_input = {"right": true}
	await seconds(0.8)
	eq(GameState.attempt_shards, [0], "shard 0 recorded")
	eq(GameState.attempt_cores, [0], "core 0 recorded")
	check(GameState.score >= 3000, "shard + core points")


func test_secret_wall_reveals() -> void:
	var rows := flat(30, "S...%%%" + ".".repeat(23))
	put(rows, 4, 11, "%"); put(rows, 5, 11, "%"); put(rows, 6, 11, "%")
	var lv := await make_level(rows)
	lv.player.external_input = {"right": true}
	await seconds(0.7)
	eq(lv.stats.secrets_revealed, 1, "walking into the fake wall reveals the secret")
	check(lv.secret_groups[0].layer.modulate.a < 0.9, "wall turns see-through")
