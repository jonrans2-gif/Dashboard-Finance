extends Node
## Entry point: loads settings/progress (autoloads) and opens the title
## screen. `--run-tests` (after `--`) starts the automated test suite instead.


func _ready() -> void:
	if "--run-tests" in OS.get_cmdline_user_args():
		get_tree().change_scene_to_file.call_deferred("res://tests/test_runner.tscn")
		return
	GameState.change_scene.call_deferred(GameState.MENU_SCENE, 0.2)
