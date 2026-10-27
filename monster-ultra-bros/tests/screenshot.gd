extends Node
## Dev tool: renders a level (or menu) and saves screenshots.
## xvfb-run godot --path . --fixed-fps 60 res://tests/screenshot.tscn -- <target> <out_prefix> <frame,frame,...> [walk]
## target = level id ("1-1") or a scene path.

var frames := 0
var shots: Array = []
var prefix := "/tmp/shot"
var walk := false
var level: Node


func _ready() -> void:
	var a := OS.get_cmdline_user_args()
	var target: String = a[0] if a.size() > 0 else "1-1"
	prefix = a[1] if a.size() > 1 else prefix
	for f in (a[2] if a.size() > 2 else "60").split(","):
		shots.append(int(f))
	walk = a.size() > 3 and a[3] == "walk"
	if a.size() > 4:
		GameState.checkpoint = int(a[4])
	if target.begins_with("res://"):
		add_child(load(target).instantiate())
	else:
		GameState.level_id = target
		level = load("res://scenes/game.tscn").instantiate()
		add_child(level)


func _process(_delta: float) -> void:
	frames += 1
	if walk and level and level.player:
		Input.action_press("move_right")
		if frames % 50 == 0:
			Input.action_press("jump")
		elif frames % 50 == 25:
			Input.action_release("jump")
	if frames in shots:
		var img := get_viewport().get_texture().get_image()
		img.save_png("%s_%d.png" % [prefix, frames])
	if frames >= shots.max():
		get_tree().quit()
