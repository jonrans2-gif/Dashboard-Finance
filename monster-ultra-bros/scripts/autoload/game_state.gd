extends Node
## Run state (lives, score, tokens), level catalogue and scene transitions.

signal stats_changed
signal life_gained

const START_LIVES := 5
const MAX_LIVES := 99
const TOKENS_PER_LIFE := 100

const GAME_SCENE := "res://scenes/game.tscn"
const MENU_SCENE := "res://scenes/main_menu.tscn"
const LEVEL_SELECT_SCENE := "res://scenes/level_select.tscn"
const ENDING_SCENE := "res://scenes/ending.tscn"

const LEVELS := [
	{"id": "1-1", "name": "The Beginning", "world": 1, "file": "res://levels/1-1.txt"},
	{"id": "1-2", "name": "Underground Energy", "world": 1, "file": "res://levels/1-2.txt"},
	{"id": "1-3", "name": "The White Fortress", "world": 1, "file": "res://levels/1-3.txt"},
	{"id": "2-1", "name": "Factory Run", "world": 2, "file": "res://levels/2-1.txt"},
	{"id": "2-2", "name": "Energy Storage", "world": 2, "file": "res://levels/2-2.txt"},
	{"id": "2-3", "name": "The Machine Core", "world": 2, "file": "res://levels/2-3.txt"},
	{"id": "3-1", "name": "Frozen Peaks", "world": 3, "file": "res://levels/3-1.txt"},
	{"id": "3-2", "name": "Ice Caverns", "world": 3, "file": "res://levels/3-2.txt"},
	{"id": "3-3", "name": "The Storm Bridge", "world": 3, "file": "res://levels/3-3.txt"},
	{"id": "4-1", "name": "Ultra Highway", "world": 4, "file": "res://levels/4-1.txt"},
	{"id": "4-2", "name": "Energy Reactor", "world": 4, "file": "res://levels/4-2.txt"},
	{"id": "4-3", "name": "The Final Overload", "world": 4, "file": "res://levels/4-3.txt"},
]
const WORLD_NAMES := {1: "White Hills", 2: "Neon Factory", 3: "Frozen Voltage", 4: "Ultra Dimension"}

var lives := START_LIVES
var score := 0
var tokens := 0
var level_id := "1-1"
var checkpoint := -1           # index of the last activated checkpoint in this level
var level_start_score := 0     # score when the level was (re)started from scratch
var level_start_tokens := 0
var attempt_shards: Array = [] # shard indices collected during the current attempt
var attempt_cores: Array = []
var last_result: Dictionary = {}

var _fade_layer: CanvasLayer
var _fade_rect: ColorRect
var _busy := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_fade_layer = CanvasLayer.new()
	_fade_layer.layer = 100
	add_child(_fade_layer)
	_fade_rect = ColorRect.new()
	_fade_rect.color = Color(0.05, 0.05, 0.08, 0.0)
	_fade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_layer.add_child(_fade_rect)


# ---------------------------------------------------------------- catalogue
func level_index(id: String) -> int:
	for i in LEVELS.size():
		if LEVELS[i].id == id:
			return i
	return -1


func level_info(id: String) -> Dictionary:
	var i := level_index(id)
	return LEVELS[i] if i >= 0 else {}


func next_level_id(id: String) -> String:
	var i := level_index(id)
	return LEVELS[i + 1].id if i >= 0 and i + 1 < LEVELS.size() else ""


# ---------------------------------------------------------------- flow
func new_game() -> void:
	lives = START_LIVES
	score = 0
	tokens = 0
	start_level("1-1")


func continue_game() -> void:
	var c: Dictionary = SaveSystem.data.get("continue", {})
	if c.is_empty():
		new_game()
		return
	lives = max(1, int(c.get("lives", START_LIVES)))
	score = int(c.get("score", 0))
	tokens = int(c.get("tokens", 0))
	attempt_shards = Array(c.get("shards", []))
	attempt_cores = Array(c.get("cores", []))
	_start(str(c.get("level", "1-1")), int(c.get("checkpoint", -1)), false)


func play_selected_level(id: String) -> void:
	## From level select: keep score/lives sane for a standalone run.
	lives = max(lives, START_LIVES)
	start_level(id)


func start_level(id: String) -> void:
	attempt_shards = []
	attempt_cores = []
	_start(id, -1, true)


func _start(id: String, cp: int, fresh: bool) -> void:
	level_id = id
	checkpoint = cp
	if fresh:
		level_start_score = score
		level_start_tokens = tokens
	save_continue()
	change_scene(GAME_SCENE)


func restart_level() -> void:
	## Restart from the beginning of the level (from the pause menu).
	score = level_start_score
	tokens = level_start_tokens
	attempt_shards = []
	attempt_cores = []
	checkpoint = -1
	change_scene(GAME_SCENE)


func respawn_after_death() -> void:
	## Called after the death animation: reload at the last checkpoint.
	change_scene(GAME_SCENE)


func lose_life() -> bool:
	## Returns true if the player still has lives left.
	lives -= 1
	stats_changed.emit()
	if lives <= 0:
		SaveSystem.set_continue({"level": level_id, "checkpoint": -1, "lives": START_LIVES,
			"score": 0, "tokens": 0, "shards": [], "cores": []})
		SaveSystem.save_progress()
		return false
	save_continue()
	return true


func retry_after_game_over() -> void:
	lives = START_LIVES
	score = 0
	tokens = 0
	start_level(level_id)


func set_checkpoint(index: int) -> void:
	if index > checkpoint:
		checkpoint = index
		save_continue()


func save_continue() -> void:
	SaveSystem.set_continue({"level": level_id, "checkpoint": checkpoint, "lives": lives,
		"score": score, "tokens": tokens, "shards": attempt_shards, "cores": attempt_cores})
	SaveSystem.save_progress()


func complete_level(result: Dictionary) -> void:
	## result: {score, tokens, shards:Array, cores:Array, ...}
	last_result = result
	result["new_best"] = SaveSystem.record_completion(level_id, int(result.level_score),
		int(result.tokens), result.shards, result.cores)
	var nxt := next_level_id(level_id)
	SaveSystem.unlock(nxt)
	if nxt == "":
		SaveSystem.data.game_cleared = true
		SaveSystem.clear_continue()
	else:
		SaveSystem.set_continue({"level": nxt, "checkpoint": -1, "lives": lives,
			"score": score, "tokens": tokens, "shards": [], "cores": []})
	SaveSystem.data.total_tokens = int(SaveSystem.data.get("total_tokens", 0)) + int(result.tokens)
	SaveSystem.save_progress()


func go_next_level() -> void:
	var nxt := next_level_id(level_id)
	if nxt == "":
		change_scene(ENDING_SCENE)
	else:
		start_level(nxt)


func go_to_menu() -> void:
	change_scene(MENU_SCENE)


# ---------------------------------------------------------------- stats
func add_score(n: int) -> void:
	score += n
	stats_changed.emit()


func add_tokens(n: int) -> void:
	tokens += n
	while tokens >= TOKENS_PER_LIFE:
		tokens -= TOKENS_PER_LIFE
		add_life()
	stats_changed.emit()


func add_life() -> void:
	lives = min(MAX_LIVES, lives + 1)
	life_gained.emit()
	stats_changed.emit()


# ---------------------------------------------------------------- transitions
func change_scene(path: String, duration := 0.35) -> void:
	if _busy:
		return
	_busy = true
	var t := create_tween()
	t.tween_property(_fade_rect, "color:a", 1.0, duration)
	await t.finished
	get_tree().paused = false
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	await get_tree().process_frame
	var t2 := create_tween()
	t2.tween_property(_fade_rect, "color:a", 0.0, duration)
	_busy = false


func is_transitioning() -> bool:
	return _busy
