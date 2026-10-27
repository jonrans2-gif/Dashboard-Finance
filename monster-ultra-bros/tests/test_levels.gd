extends TestCase
## All 12 shipped levels: structure, reachability and loading in the real game.


func _ids() -> Array:
	var out := []
	for lv in GameState.LEVELS:
		out.append(lv.id)
	return out


func test_level_structure() -> void:
	for id: String in _ids():
		var d := LevelData.load_file("res://levels/%s.txt" % id)
		check(d != null, "%s loads" % id)
		eq(d.find_all("S").size(), 1, "%s has one start" % id)
		eq(d.find_all("G").size(), 1, "%s has one goal" % id)
		eq(d.find_all("$").size(), 3, "%s has 3 Ultra Shards" % id)
		check(d.find_all("@").size() >= 1, "%s has a secret energy core" % id)
		check(d.find_all("C").size() >= 1, "%s has a checkpoint" % id)
		eq(d.find_all("D").size() % 2, 0, "%s doors are paired" % id)
		check(d.width >= 140, "%s is a full-length level (%d tiles)" % [id, d.width])
		var is_boss := id.ends_with("-3")
		eq(d.get_str("boss", "") != "", is_boss, "%s boss setting" % id)
		if is_boss:
			check(d.find_all("Y").size() == 1 and d.find_all("Q").size() == 1, "%s has an arena gate and boss spawn" % id)
			var gate: Vector2i = d.find_all("Y")[0]
			check((d.width - gate.x) * 16 >= 600, "%s arena is at least a screen wide" % id)


func test_levels_are_distinct() -> void:
	var seen := {}
	for id: String in _ids():
		var text := "\n".join(LevelData.load_file("res://levels/%s.txt" % id).rows)
		check(not seen.has(text.sha256_text()), "%s layout is unique" % id)
		seen[text.sha256_text()] = true


func test_levels_are_completable() -> void:
	for id: String in _ids():
		var d := LevelData.load_file("res://levels/%s.txt" % id)
		var start: Vector2i = d.find_all("S")[0]
		var r := Reachability.new(d, false, 3)
		r.run(start)
		var goal: Vector2i = d.find_all("G")[0]
		check(r.reach.has(goal) or r.item_reachable(goal), "%s goal reachable with plain 3-tile jumps" % id)
		var ri := Reachability.new(d, false, 4)
		ri.run(start)
		for s in d.find_all("$"):
			check(ri.item_reachable(s), "%s shard at %s reachable" % [id, s])
		var surge := d.get_str("powerups").contains("surge") or d.get_str("powerups").contains("overload")
		var rb := Reachability.new(d, surge, 4)
		rb.run(start)
		for c in d.find_all("@"):
			check(rb.item_reachable(c), "%s core at %s reachable" % [id, c])


func test_levels_load_and_run() -> void:
	for id: String in _ids():
		GameState.checkpoint = -1
		GameState.level_id = id
		var lv: Level = load("res://scripts/level/level.gd").new()
		lv.level_id = id
		lv.testing = true
		add_child(lv)
		await frames(30)
		check(lv.player != null and lv.player.state == Player.State.NORMAL, "%s: player alive after load" % id)
		check(lv.terrain.get_used_cells().size() > 500, "%s: terrain built" % id)
		check(enemies_of(lv).size() >= 5, "%s: at least 5 enemies placed" % id)
		check(lv.goal != null, "%s: goal placed" % id)
		lv.free()
		await frames(2)
