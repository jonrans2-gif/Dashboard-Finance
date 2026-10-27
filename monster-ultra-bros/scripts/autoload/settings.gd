extends Node
## Player settings, input actions and haptics. Stored in user://settings.json.

signal changed

const PATH := "user://settings.json"
const SaveIO := preload("res://scripts/autoload/save_system.gd")

const DEFAULTS := {
	"music_volume": 0.8,
	"sfx_volume": 0.9,
	"haptics": true,
	"button_scale": 1.0,      # 0.7 .. 1.5
	"button_opacity": 0.7,    # 0.2 .. 1.0
	"layout": "standard",     # standard: move left / actions right, swapped: mirrored
	"offset_x": 0.0,          # extra inset from the screen sides (base px)
	"offset_y": 0.0,          # extra lift from the bottom (base px)
	"sensitivity": 1.15,      # touch hit-area multiplier (0.9 .. 1.6)
	"touch_controls": "auto", # auto / always / never
	"orientation": "landscape", # landscape / auto / portrait
	"screen_shake": true,
}

var values: Dictionary = DEFAULTS.duplicate()


func _enter_tree() -> void:
	_register_actions()
	var stored := SaveIO.read_json_with_backup(PATH)
	for k in stored.keys():
		if not DEFAULTS.has(k):
			continue
		var want := typeof(DEFAULTS[k])
		if typeof(stored[k]) == want:
			values[k] = stored[k]
		elif want == TYPE_FLOAT and typeof(stored[k]) == TYPE_INT:
			values[k] = float(stored[k])


func _ready() -> void:
	apply()


func get_value(key: String):
	return values.get(key, DEFAULTS.get(key))


func set_value(key: String, v) -> void:
	if values.get(key) == v:
		return
	values[key] = v
	apply()
	changed.emit()


func save() -> void:
	SaveIO.write_json_atomic(PATH, values)


func reset_to_defaults() -> void:
	values = DEFAULTS.duplicate()
	apply()
	changed.emit()
	save()


func apply() -> void:
	_set_bus("Music", float(values.music_volume))
	_set_bus("SFX", float(values.sfx_volume))
	if OS.has_feature("mobile"):
		match str(values.orientation):
			"portrait":
				DisplayServer.screen_set_orientation(DisplayServer.SCREEN_SENSOR_PORTRAIT)
			"auto":
				DisplayServer.screen_set_orientation(DisplayServer.SCREEN_SENSOR)
			_:
				DisplayServer.screen_set_orientation(DisplayServer.SCREEN_SENSOR_LANDSCAPE)


func _set_bus(bus_name: String, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx < 0:
		return
	AudioServer.set_bus_mute(idx, linear <= 0.001)
	AudioServer.set_bus_volume_db(idx, linear_to_db(max(linear, 0.001)))


func touch_controls_visible() -> bool:
	match str(values.touch_controls):
		"always":
			return true
		"never":
			return false
	return DisplayServer.is_touchscreen_available() or OS.has_feature("mobile")


## Short vibration for important events (respects the haptics setting).
func haptic(duration_ms: int = 30, amplitude: float = 0.5) -> void:
	if values.haptics and OS.has_feature("mobile"):
		Input.vibrate_handheld(duration_ms, amplitude)


func _register_actions() -> void:
	var map := {
		"move_left": [KEY_LEFT, KEY_A],
		"move_right": [KEY_RIGHT, KEY_D],
		"jump": [KEY_SPACE, KEY_UP, KEY_W, KEY_Z],
		"dash": [KEY_SHIFT, KEY_X],
		"interact": [KEY_E, KEY_DOWN, KEY_S],
		"pause": [KEY_ESCAPE, KEY_P],
	}
	var pads := {
		"move_left": [JOY_BUTTON_DPAD_LEFT], "move_right": [JOY_BUTTON_DPAD_RIGHT],
		"jump": [JOY_BUTTON_A], "dash": [JOY_BUTTON_X], "interact": [JOY_BUTTON_DPAD_DOWN],
		"pause": [JOY_BUTTON_START],
	}
	for action in map.keys():
		if not InputMap.has_action(action):
			InputMap.add_action(action, 0.3)
		for key in map[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = key
			InputMap.action_add_event(action, ev)
		for b in pads.get(action, []):
			var jb := InputEventJoypadButton.new()
			jb.button_index = b
			InputMap.action_add_event(action, jb)
	for pair in [["move_left", -1.0], ["move_right", 1.0]]:
		var jm := InputEventJoypadMotion.new()
		jm.axis = JOY_AXIS_LEFT_X
		jm.axis_value = pair[1]
		InputMap.action_add_event(pair[0], jm)
