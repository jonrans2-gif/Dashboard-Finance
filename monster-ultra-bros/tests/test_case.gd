class_name TestCase
extends Node
## Base class for tests. Test methods start with `test_` and may await.

var failures: Array = []
var checks := 0
var current := ""


func check(cond: bool, msg: String) -> void:
	checks += 1
	if not cond:
		failures.append("%s: %s" % [current, msg])


func eq(a, b, msg: String) -> void:
	check(a == b, "%s (got %s, expected %s)" % [msg, str(a), str(b)])


func near(a: float, b: float, tol: float, msg: String) -> void:
	check(abs(a - b) <= tol, "%s (got %.2f, expected %.2f±%.2f)" % [msg, a, b, tol])


func frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func seconds(s: float) -> void:
	await frames(int(s * 60.0))


## Builds a Level from map rows (ground etc. as in level files) in test mode.
func make_level(rows: Array, header := {}) -> Level:
	var text := ""
	var h := {"name": "Test", "theme": "hills", "time": "300"}
	for k in header.keys():
		h[k] = header[k]
	for k in h.keys():
		text += "%s=%s\n" % [k, h[k]]
	text += "---\n" + "\n".join(rows) + "\n---\n"
	var d := LevelData.new()
	d.id = "test"
	d.parse(text)
	var lv: Level = load("res://scripts/level/level.gd").new()
	lv.level_id = "1-1"
	lv.testing = true
	lv.data_override = d
	add_child(lv)
	await frames(2)
	return lv


func reset_state() -> void:
	get_tree().paused = false
	GameState.lives = GameState.START_LIVES
	GameState.score = 0
	GameState.tokens = 0
	GameState.checkpoint = -1
	GameState.attempt_shards = []
	GameState.attempt_cores = []
	for a in ["move_left", "move_right", "jump", "dash", "interact"]:
		Input.action_release(a)
	for c in get_children():
		c.free()


## Standard flat test floor: rows 0..11 air, 12 standing row, 13..16 ground.
static func flat(width := 60, standing_row := "") -> Array:
	var rows := []
	for y in 12:
		rows.append(".".repeat(width))
	rows.append(standing_row if standing_row != "" else "S" + ".".repeat(width - 1))
	for y in 4:
		rows.append("#".repeat(width))
	return rows
