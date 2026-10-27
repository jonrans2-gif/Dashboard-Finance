extends SceneTree
## Dev helper: godot --headless --path . --script tests/dev_reach.gd [-- 1-2]
## Prints reachability of goal/shards/cores for every level. For failures it
## prints a map window (R = reachable standing cell) around the problem.

func _init() -> void:
	var only := OS.get_cmdline_user_args()
	for i in range(1, 5):
		for j in range(1, 4):
			var id := "%d-%d" % [i, j]
			if only.size() > 0 and not (id in only):
				continue
			_check(id, only.size() > 0)
	quit()


func _check(id: String, verbose: bool) -> void:
	var d := LevelData.load_file("res://levels/%s.txt" % id)
	var surge := d.get_str("powerups").contains("surge") or d.get_str("powerups").contains("overload")
	var start: Vector2i = d.find_all("S")[0]
	var r := Reachability.new(d, false)
	r.run(start)
	var ri := Reachability.new(d, false, 4)
	ri.run(start)
	var rb := Reachability.new(d, surge, 4)
	rb.run(start)
	var goal: Vector2i = d.find_all("G")[0]
	var gate := d.find_all("Y")
	var goal_ok := r.reach.has(goal) or r.item_reachable(goal)
	var problems := []
	if not goal_ok:
		var fx := 0
		for c in r.reach.keys():
			fx = max(fx, c.x)
		problems.append(["route stops", Vector2i(fx, 12), r])
	if gate.size() > 0 and not r.any_reached(func(c): return c.x > gate[0].x):
		problems.append(["gate", gate[0], r])
	var shards := []
	for s in d.find_all("$"):
		var ok := ri.item_reachable(s)
		shards.append(ok)
		if not ok:
			problems.append(["shard", s, ri])
	var cores := []
	for c in d.find_all("@"):
		var ok := rb.item_reachable(c)
		cores.append(ok)
		if not ok:
			problems.append(["core", c, rb])
	print("%s  goal=%s shards=%s cores=%s" % [id, goal_ok, shards, cores])
	if verbose:
		for p in problems:
			print("  -> %s at %s" % [p[0], p[1]])
			_window(d, p[2], p[1].x)


func _window(d: LevelData, r: Reachability, cx: int) -> void:
	var x0 := maxi(0, cx - 30)
	var x1 := mini(d.width, cx + 30)
	var ruler := ""
	for x in range(x0, x1):
		ruler += str(x % 10) if x % 10 != 0 else "|"
	print("     x=%d.." % x0)
	print("     " + ruler)
	for y in d.height:
		var line := "%3d  " % y
		for x in range(x0, x1):
			line += "R" if r.reach.has(Vector2i(x, y)) else d.at(x, y)
		print(line)
