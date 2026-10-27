extends Node
## Runs every tests/test_*.gd suite headlessly and reports results.
##   godot --headless --path . --fixed-fps 60 res://tests/test_runner.tscn
## Exit code = number of failed checks (0 = all green).

const SUITES := ["test_save", "test_physics", "test_collision", "test_enemies", "test_items",
	"test_powerups", "test_damage", "test_checkpoints", "test_pause", "test_completion",
	"test_bosses", "test_touch", "test_levels"]


func _ready() -> void:
	# never touch the player's real save while testing
	SaveSystem.progress_path = "user://test_progress.json"
	SaveSystem.data = SaveSystem.default_progress()
	var total_checks := 0
	var all_failures: Array = []
	var lines: Array = []
	var only := OS.get_cmdline_user_args()
	for name in SUITES:
		if only.size() > 0 and not (name in only):
			continue
		var script: GDScript = load("res://tests/%s.gd" % name)
		if script == null or not script.can_instantiate():
			all_failures.append("%s: suite failed to compile" % name)
			lines.append("FAIL %s (compile error)" % name)
			continue
		var suite: TestCase = script.new()
		add_child(suite)
		var methods: Array = []
		for m in suite.get_method_list():
			if str(m.name).begins_with("test_"):
				methods.append(str(m.name))
		methods.sort()
		for m in methods:
			suite.current = "%s.%s" % [name, m]
			print("RUN ", suite.current)
			var before := suite.failures.size()
			await suite.call(m)
			suite.reset_state()
			var ok := suite.failures.size() == before
			lines.append("%s %s" % ["PASS" if ok else "FAIL", suite.current])
		total_checks += suite.checks
		all_failures += suite.failures
		suite.queue_free()
		await get_tree().process_frame
	for l in lines:
		print(l)
	for f in all_failures:
		print("  ✗ ", f)
	var summary := "TESTS: %d test functions, %d checks, %d failed" % [lines.size(), total_checks, all_failures.size()]
	print(summary)
	var out := FileAccess.open("user://test_results.txt", FileAccess.WRITE)
	if out:
		out.store_string("\n".join(lines) + "\n" + "\n".join(all_failures) + "\n" + summary + "\n")
	get_tree().quit(all_failures.size())
