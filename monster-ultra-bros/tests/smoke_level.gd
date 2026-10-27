extends Node
## Smoke test: boots a level with the real game scene and lets it run.
## godot --headless --path . --fixed-fps 60 res://tests/smoke_level.tscn -- 1-1

var frames := 0
var level: Node


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	GameState.level_id = args[0] if args.size() > 0 else "1-1"
	level = load("res://scenes/game.tscn").instantiate()
	add_child(level)


func _physics_process(_delta: float) -> void:
	frames += 1
	if level and level.player and frames < 200:
		Input.action_press("move_right")
		if frames % 40 == 0:
			Input.action_press("jump")
		elif frames % 40 == 20:
			Input.action_release("jump")
	if frames == 240:
		print("SMOKE OK level=%s player=%s hp=%d x=%.0f" % [GameState.level_id, level.player.state, level.player.hp, level.player.global_position.x])
		get_tree().quit()
