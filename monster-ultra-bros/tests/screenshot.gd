extends Node
## Dev tool: renders a level (or menu) and saves screenshots.
## xvfb-run godot --path . --fixed-fps 60 res://tests/screenshot.tscn -- <target> <out_prefix> <frame,frame,...> [walk]
## target = level id ("1-1") or a scene path.

var frames := 0
var shots: Array = []
var prefix := "/tmp/shot"
var walk := false
var tour := false
var boss := false
var marker := Node2D.new()
var level: Node


func _ready() -> void:
	var a := OS.get_cmdline_user_args()
	var target: String = a[0] if a.size() > 0 else "1-1"
	prefix = a[1] if a.size() > 1 else prefix
	for f in (a[2] if a.size() > 2 else "60").split(","):
		shots.append(int(f))
	walk = a.size() > 3 and a[3] == "walk"
	tour = a.size() > 3 and a[3] == "tour"
	boss = a.size() > 3 and a[3] == "boss"
	if a.size() > 4:
		GameState.checkpoint = int(a[4])
	if target.ends_with(".gd"):
		var layer := CanvasLayer.new()
		add_child(layer)
		var node = load(target).new()
		if target.ends_with("level_complete.gd"):
			node.result = {"level": "1-1", "tokens": 42, "enemies": 17, "shards": [0, 2], "shards_total": 3,
				"cores": [0], "cores_total": 1, "flag_bonus": 2000, "time_left": 187, "time_bonus": 1870,
				"level_score": 15230, "new_best": true}
		layer.add_child(node)
		if node.has_method("open"):
			node.open()
		if a.size() > 3 and a[3] == "settings":
			node.call_deferred("_open_settings")
	elif target.begins_with("res://"):
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
	if tour and level and level.player:
		if marker.get_parent() == null:
			level.add_child(marker)
			level.camera.target = marker
			level.player.input_enabled = false
		var i := 0
		for f in shots:
			if frames <= f:
				break
			i += 1
		var frac := (i + 0.5) / float(shots.size())
		marker.global_position = Vector2(frac * level.data.width * 16.0, level.data.height * 16.0 - 60.0)
		level.player.set("_invuln", 10.0)
	if boss and level and level.player and level.arena_gate_x >= 0:
		level.player.set("_invuln", 99.0)
		level.player.visual_root.modulate.a = 1.0
		if frames == 5:
			level.player.global_position = Vector2(level.arena_gate_x * 16 + 150, level.data.height * 16 - 64)
	if frames in shots:
		var img := get_viewport().get_texture().get_image()
		img.save_png("%s_%d.png" % [prefix, frames])
	if frames >= shots.max():
		get_tree().quit()
