class_name LevelData
## Parses the plain-text level format in res://levels/*.txt.
##
## Format:
##   key=value header lines (name, theme, bg, music, time, powerups, boss, ...)
##   a line with "---"
##   the map rows (one character per 16x16 cell, see LEGEND below)
##   optional second "---" followed by more key=value lines
##
## Keeping levels as text makes them easy to read, diff and validate in tests.

const TILE := 16

## Map legend. Tiles go to the TileMapLayers, everything else is an entity.
const LEGEND := {
	"#": "ground", "=": "brick", "?": "token_block", "!": "power_block", "B": "hard",
	"X": "barrier", "^": "spikes", "~": "goo", "_": "platform", "c": "cloud", "I": "ice",
	"<": "conveyor_left", ">": "conveyor_right", "[": "pipe_left", "]": "pipe_right",
	"%": "secret_wall", "b": "bg_wall", "|": "chain", "h": "hidden_token", "H": "hidden_life",
	"*": "bush", "f": "flower", "F": "fence", "l": "lamp", "a": "arrow", "w": "window",
	"t": "torch", "s": "sign", "y": "crystal", "n": "snowcap",
	"S": "start", "G": "goal", "C": "checkpoint", "o": "token", "$": "shard", "@": "core",
	"+": "life", "p": "powerup", "e": "empty_can", "u": "sugar_cube", "d": "drone",
	"k": "corrupted_can", "z": "slime", "K": "crusher", "m": "platform_h", "v": "platform_v",
	"-": "path_h", ":": "path_v", "x": "falling", "j": "spring", "D": "door", "Z": "zapper",
	"i": "icicle", "r": "boost_pad", "Y": "arena_gate", "Q": "boss",
}

var id := ""
var header: Dictionary = {}
var rows: PackedStringArray = []
var width := 0
var height := 0


static func load_file(path: String) -> LevelData:
	var text := FileAccess.get_file_as_string(path)
	if text.is_empty():
		push_error("Level file missing or empty: " + path)
		return null
	var d := LevelData.new()
	d.id = path.get_file().get_basename()
	d.parse(text)
	return d


func parse(text: String) -> void:
	var section := 0
	for raw in text.split("\n"):
		var line := raw.rstrip("\r")
		if line.strip_edges() == "---":
			section += 1
			continue
		if section == 1:
			rows.append(line)
		else:
			var s := line.strip_edges()
			if s.is_empty() or s.begins_with(";"):
				continue
			var eq := s.find("=")
			if eq > 0:
				header[s.substr(0, eq).strip_edges()] = s.substr(eq + 1).strip_edges()
	# Trim trailing empty rows.
	while rows.size() > 0 and rows[rows.size() - 1].strip_edges().is_empty():
		rows.remove_at(rows.size() - 1)
	height = rows.size()
	for r in rows:
		width = max(width, r.length())


func at(x: int, y: int) -> String:
	if y < 0 or y >= height or x < 0:
		return " " if y >= 0 else "."
	var r := rows[y]
	return r[x] if x < r.length() else "."


func kind_at(x: int, y: int) -> String:
	return LEGEND.get(at(x, y), "")


func get_str(key: String, default := "") -> String:
	return str(header.get(key, default))


func get_int(key: String, default := 0) -> int:
	return int(header.get(key, default))


func find_all(ch: String) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for y in height:
		var r := rows[y]
		for x in r.length():
			if r[x] == ch:
				out.append(Vector2i(x, y))
	return out


func cell_center(c: Vector2i) -> Vector2:
	return Vector2(c.x * TILE + TILE * 0.5, c.y * TILE + TILE * 0.5)


func cell_bottom(c: Vector2i) -> Vector2:
	return Vector2(c.x * TILE + TILE * 0.5, (c.y + 1) * TILE)


func pixel_size() -> Vector2:
	return Vector2(width * TILE, height * TILE)


## Ground-like cells used for auto-tiling.
static func is_ground_char(ch: String) -> bool:
	return ch == "#" or ch == "%"
