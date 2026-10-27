extends CanvasLayer
## Multi-touch on-screen controls for Android.
##
## * Movement buttons bottom-left, Jump/Dash bottom-right (mirrored when the
##   "swapped" layout is selected), Pause top-right, a context ENTER button
##   appears above Jump in front of doors.
## * Any number of fingers at once; a finger can slide between buttons.
## * Buttons press real input actions, so the player code is input-agnostic.
## * Size, opacity, position offsets and hit-area sensitivity come from
##   Settings and update live. Buttons keep a margin from the screen edges so
##   touches there are less likely to collide with Android system gestures.

signal pause_pressed

const EDGE_MARGIN := 18.0
const BASE_RADIUS := 22.0

var enabled := true
var buttons: Dictionary = {}         # name -> {action, center, radius, node, fingers:{}, visible}
var _fingers: Dictionary = {}        # touch index -> button name
var _context_visible := false
var _context_tapped := false
var _root: Control
var _frames: SpriteFrames


func _ready() -> void:
	layer = 45
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	_frames = SpriteLib.frames("ui/buttons")
	for spec in [["left", "move_left"], ["right", "move_right"], ["jump", "jump"],
			["dash", "dash"], ["enter", "interact"], ["pause", ""]]:
		var tr := TextureRect.new()
		tr.texture = _frames.get_frame_texture(spec[0], 0)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_SCALE
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tr.pivot_offset = Vector2(24, 24)
		_root.add_child(tr)
		buttons[spec[0]] = {"action": spec[1], "center": Vector2.ZERO, "radius": BASE_RADIUS,
			"node": tr, "fingers": {}, "visible": true}
	get_viewport().size_changed.connect(layout)
	Settings.changed.connect(layout)
	layout()


func layout() -> void:
	var show := Settings.touch_controls_visible()
	_root.visible = show and enabled
	var screen := get_viewport().get_visible_rect().size
	var s: float = Settings.get_value("button_scale")
	var r := BASE_RADIUS * s
	var gap := 6.0 * s
	var mx := EDGE_MARGIN + float(Settings.get_value("offset_x"))
	var by := 10.0 + float(Settings.get_value("offset_y"))
	var swapped: bool = Settings.get_value("layout") == "swapped"
	var y := screen.y - by - r
	var pos := {
		"left": Vector2(mx + r, y),
		"right": Vector2(mx + 3.0 * r + gap, y),
		"jump": Vector2(screen.x - mx - r, y - 4.0 * s),
		"dash": Vector2(screen.x - mx - 3.0 * r - gap, y + 2.0 * s),
		"enter": Vector2(screen.x - mx - r, y - 2.0 * r - gap - 4.0 * s),
	}
	if swapped:
		for k in pos.keys():
			pos[k].x = screen.x - pos[k].x
		var t: Vector2 = pos.left
		pos.left = pos.right
		pos.right = t
	pos["pause"] = Vector2(screen.x - 16.0, 16.0)
	for k in buttons.keys():
		var b: Dictionary = buttons[k]
		b.center = pos[k]
		b.radius = r if k != "pause" else 12.0
		var node: TextureRect = b.node
		var d: float = b.radius * 2.0
		node.size = Vector2(d, d)
		node.pivot_offset = Vector2(d, d) / 2.0
		node.position = b.center - Vector2(d, d) / 2.0
	_apply_visibility()


func _apply_visibility() -> void:
	var alpha: float = Settings.get_value("button_opacity")
	var level := get_parent()
	var can_dash: bool = level != null and "player" in level and level.player != null and level.player.can_dash()
	for k in buttons.keys():
		var b: Dictionary = buttons[k]
		var vis := true
		if k == "dash":
			vis = can_dash
		elif k == "enter":
			vis = _context_visible
		b.visible = vis
		var node: TextureRect = b.node
		node.visible = vis
		node.modulate.a = alpha if k != "pause" else max(alpha, 0.6)
		if not vis and not b.fingers.is_empty():
			_release_button(k)


func _process(_delta: float) -> void:
	if _root.visible:
		_apply_visibility()


func set_enabled(on: bool) -> void:
	enabled = on
	if not on:
		release_all()
	layout()


func set_context_visible(on: bool) -> void:
	_context_visible = on
	if not on:
		_context_tapped = false


func consume_context() -> bool:
	var v := _context_tapped
	_context_tapped = false
	return v


func _notification(what: int) -> void:
	if what == NOTIFICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		release_all()


func release_all() -> void:
	for k in buttons.keys():
		_release_button(k)
	_fingers.clear()


# ------------------------------------------------------------------ input
func _input(event: InputEvent) -> void:
	if not (_root.visible and enabled):
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			var hit := hit_test(event.position)
			if hit != "":
				_assign(event.index, hit)
				get_viewport().set_input_as_handled()
		else:
			if _fingers.has(event.index):
				_assign(event.index, "")
				_fingers.erase(event.index)
				get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		if _fingers.has(event.index):
			var current: String = _fingers[event.index]
			if current in ["pause", "enter"]:
				return
			var hit := hit_test(event.position, current)
			if hit in ["pause", "enter"]:
				hit = ""
			if hit != current:
				_assign(event.index, hit)
			get_viewport().set_input_as_handled()


## Returns the button under `p`. The hit area grows with the sensitivity
## setting; `sticky` keeps the current button slightly larger to avoid jitter.
func hit_test(p: Vector2, sticky := "") -> String:
	var sens: float = Settings.get_value("sensitivity")
	var best := ""
	var best_d := INF
	for k in buttons.keys():
		var b: Dictionary = buttons[k]
		if not b.visible:
			continue
		var reach: float = b.radius * sens * (1.15 if k == sticky else 1.0)
		var d: float = p.distance_to(b.center)
		if d <= reach and d < best_d:
			best_d = d
			best = k
	return best


func _assign(index: int, name: String) -> void:
	var prev: String = _fingers.get(index, "")
	if prev == name:
		return
	if prev != "":
		var pb: Dictionary = buttons[prev]
		pb.fingers.erase(index)
		if pb.fingers.is_empty():
			_set_pressed(prev, false)
	if name == "":
		_fingers[index] = ""
		return
	_fingers[index] = name
	var b: Dictionary = buttons[name]
	var was_empty: bool = b.fingers.is_empty()
	b.fingers[index] = true
	if was_empty:
		_set_pressed(name, true)


func _release_button(name: String) -> void:
	var b: Dictionary = buttons[name]
	if not b.fingers.is_empty():
		b.fingers.clear()
		_set_pressed(name, false)


func _set_pressed(name: String, on: bool) -> void:
	var b: Dictionary = buttons[name]
	var node: TextureRect = b.node
	node.texture = _frames.get_frame_texture(name, 1 if on else 0)
	node.scale = Vector2.ONE * (0.92 if on else 1.0)
	if name == "pause":
		if on:
			pause_pressed.emit()
		return
	if name == "enter":
		if on:
			_context_tapped = true
		return
	if on:
		Input.action_press(b.action)
	else:
		Input.action_release(b.action)


func is_button_pressed(name: String) -> bool:
	return not (buttons[name].fingers as Dictionary).is_empty()
