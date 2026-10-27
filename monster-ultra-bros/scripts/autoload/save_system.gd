extends Node
## Persistent progress (user://progress.json).
##
## Writes are atomic: data goes to a temp file first, is flushed, then renamed
## over the real file. The previous good file is kept as a .bak copy, and a
## checksum detects partially written or corrupted saves on load.

signal progress_changed

const SAVE_VERSION := 1
const HEADER := "MUB-SAVE-1"
const PROGRESS_PATH := "user://progress.json"

var data: Dictionary = {}
var progress_path := PROGRESS_PATH   # tests redirect this to a scratch file


func _ready() -> void:
	load_progress()


# ------------------------------------------------------------------ generic IO
static func write_json_atomic(path: String, payload: Dictionary) -> bool:
	# File layout: header line, sha256 of the body, then the JSON body itself.
	var body := JSON.stringify(payload, "\t", true)
	var text := "%s\n%s\n%s" % [HEADER, body.sha256_text(), body]
	var tmp_path := path + ".tmp"
	var f := FileAccess.open(tmp_path, FileAccess.WRITE)
	if f == null:
		push_warning("Save: cannot open %s (%s)" % [tmp_path, FileAccess.get_open_error()])
		return false
	f.store_string(text)
	f.flush()
	f.close()
	# Verify what actually landed on disk before replacing the good file.
	if read_json_verified(tmp_path).is_empty() and not payload.is_empty():
		push_warning("Save: verification of %s failed" % tmp_path)
		return false
	if FileAccess.file_exists(path):
		DirAccess.copy_absolute(path, path + ".bak")
	var err := DirAccess.rename_absolute(tmp_path, path)
	if err != OK:
		push_warning("Save: rename failed (%s)" % err)
		return false
	return true


static func read_json_verified(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var text := FileAccess.get_file_as_string(path)
	var first := text.find("\n")
	var second := text.find("\n", first + 1)
	if first < 0 or second < 0 or text.substr(0, first) != HEADER:
		return {}
	var checksum := text.substr(first + 1, second - first - 1)
	var body := text.substr(second + 1)
	if body.sha256_text() != checksum:
		return {}
	var parsed = JSON.parse_string(body)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed


## Loads `path`, falling back to the backup if the main file is damaged.
static func read_json_with_backup(path: String) -> Dictionary:
	var d := read_json_verified(path)
	if d.is_empty():
		d = read_json_verified(path + ".bak")
	return d


# ------------------------------------------------------------------ progress
func default_progress() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"unlocked": ["1-1"],
		"completed": [],
		"best_score": {},
		"best_tokens": {},
		"shards": {},       # level id -> array of shard indices collected (ever)
		"cores": {},        # level id -> array of core indices found (ever)
		"continue": {},     # {level, checkpoint, lives, score, tokens}
		"game_cleared": false,
		"total_tokens": 0,
	}


func load_progress() -> void:
	var d := read_json_with_backup(progress_path)
	data = default_progress()
	for k in d.keys():
		data[k] = d[k]
	data.version = SAVE_VERSION


func save_progress() -> bool:
	var ok := write_json_atomic(progress_path, data)
	progress_changed.emit()
	return ok


func reset_progress() -> void:
	data = default_progress()
	save_progress()


func is_unlocked(level_id: String) -> bool:
	return level_id in data.unlocked


func is_completed(level_id: String) -> bool:
	return level_id in data.completed


func unlock(level_id: String) -> void:
	if level_id != "" and not is_unlocked(level_id):
		data.unlocked.append(level_id)


func record_completion(level_id: String, score: int, tokens: int, shards: Array, cores: Array) -> bool:
	## Returns true when `score` is a new best for this level.
	if not is_completed(level_id):
		data.completed.append(level_id)
	var best := int(data.best_score.get(level_id, 0))
	var new_best := score > best
	if new_best:
		data.best_score[level_id] = score
	data.best_tokens[level_id] = max(int(data.best_tokens.get(level_id, 0)), tokens)
	data.shards[level_id] = _union(data.shards.get(level_id, []), shards)
	data.cores[level_id] = _union(data.cores.get(level_id, []), cores)
	return new_best


func set_continue(state: Dictionary) -> void:
	data["continue"] = state


func clear_continue() -> void:
	data["continue"] = {}


func has_continue() -> bool:
	return not (data.get("continue", {}) as Dictionary).is_empty()


func shard_count(level_id: String) -> int:
	return (data.shards.get(level_id, []) as Array).size()


func core_count(level_id: String) -> int:
	return (data.cores.get(level_id, []) as Array).size()


static func _union(a: Array, b: Array) -> Array:
	var out: Array = []
	for v in a + b:
		var iv := int(v)
		if iv not in out:
			out.append(iv)
	out.sort()
	return out
