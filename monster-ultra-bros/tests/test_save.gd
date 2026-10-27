extends TestCase
## Save/load: atomic writes, checksum validation, backup recovery, progress rules.

const P := "user://test_tmp_save.json"


func _clean() -> void:
	for f in [P, P + ".bak", P + ".tmp"]:
		if FileAccess.file_exists(f):
			DirAccess.remove_absolute(f)


func test_roundtrip() -> void:
	_clean()
	check(SaveSystem.write_json_atomic(P, {"a": 1, "list": [1, 2, 3], "s": "x"}), "write succeeds")
	var r := SaveSystem.read_json_verified(P)
	eq(int(r.get("a", 0)), 1, "int value restored")
	eq((r.get("list", []) as Array).size(), 3, "array restored")
	eq(r.get("s", ""), "x", "string restored")
	check(not FileAccess.file_exists(P + ".tmp"), "no temp file left behind")


func test_corrupt_main_falls_back_to_backup() -> void:
	_clean()
	SaveSystem.write_json_atomic(P, {"v": 1})
	SaveSystem.write_json_atomic(P, {"v": 2})   # previous file becomes .bak
	var f := FileAccess.open(P, FileAccess.WRITE)
	f.store_string("MUB-SAVE-1\ngarbage\n{\"v\": 99")
	f.close()
	eq(SaveSystem.read_json_verified(P), {}, "corrupted main file is rejected")
	eq(int(SaveSystem.read_json_with_backup(P).get("v", -1)), 1, "backup copy is used instead")


func test_truncated_and_tampered_files_rejected() -> void:
	_clean()
	SaveSystem.write_json_atomic(P, {"level": "2-1", "score": 12345})
	var text := FileAccess.get_file_as_string(P)
	var f := FileAccess.open(P, FileAccess.WRITE)
	f.store_string(text.substr(0, text.length() / 2))   # simulated power loss mid-write
	f.close()
	eq(SaveSystem.read_json_verified(P), {}, "truncated file rejected")
	f = FileAccess.open(P, FileAccess.WRITE)
	f.store_string(text.replace("12345", "99999"))
	f.close()
	eq(SaveSystem.read_json_verified(P), {}, "checksum catches edited body")
	_clean()


func test_progress_rules() -> void:
	SaveSystem.data = SaveSystem.default_progress()
	check(SaveSystem.is_unlocked("1-1") and not SaveSystem.is_unlocked("1-2"), "only 1-1 unlocked at start")
	check(SaveSystem.record_completion("1-1", 500, 20, [0, 2], [0]), "first clear is a new best")
	check(not SaveSystem.record_completion("1-1", 300, 30, [1], []), "lower score is not a best")
	eq(int(SaveSystem.data.best_score["1-1"]), 500, "best score kept")
	eq(int(SaveSystem.data.best_tokens["1-1"]), 30, "best token count tracked")
	eq(SaveSystem.shard_count("1-1"), 3, "shards merged across runs")
	eq(SaveSystem.core_count("1-1"), 1, "core remembered")
	SaveSystem.unlock("1-2")
	check(SaveSystem.is_unlocked("1-2"), "unlock works")


func test_progress_persists_to_disk() -> void:
	SaveSystem.data = SaveSystem.default_progress()
	SaveSystem.unlock("3-2")
	SaveSystem.record_completion("3-1", 4321, 10, [], [])
	check(SaveSystem.save_progress(), "save ok")
	SaveSystem.data = {}
	SaveSystem.load_progress()
	check(SaveSystem.is_unlocked("3-2"), "unlock survives reload")
	eq(int(SaveSystem.data.best_score.get("3-1", 0)), 4321, "best score survives reload")


func test_game_state_continue_point() -> void:
	SaveSystem.data = SaveSystem.default_progress()
	GameState.level_id = "2-2"
	GameState.checkpoint = 1
	GameState.lives = 3
	GameState.save_continue()
	SaveSystem.data = {}
	SaveSystem.load_progress()
	var c: Dictionary = SaveSystem.data["continue"]
	eq(c.get("level"), "2-2", "continue level saved")
	eq(int(c.get("checkpoint", -1)), 1, "continue checkpoint saved")
	eq(int(c.get("lives", 0)), 3, "lives saved")
