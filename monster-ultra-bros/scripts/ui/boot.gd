extends Node
## Entry point: loads settings/progress (autoloads) and opens the title
## screen. Optional user args (after `--`):
##   --run-tests     run the automated test suite (development builds only)
##   --level=<id>    jump straight into a level (e.g. --level=2-3)


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if "--run-tests" in args and ResourceLoader.exists("res://tests/test_runner.tscn"):
		get_tree().change_scene_to_file.call_deferred("res://tests/test_runner.tscn")
		return
	for a in args:
		if a.begins_with("--level=") and GameState.level_index(a.substr(8)) >= 0:
			GameState.lives = GameState.START_LIVES
			GameState.start_level.call_deferred(a.substr(8))
			return
	GameState.change_scene.call_deferred(GameState.MENU_SCENE, 0.2)
