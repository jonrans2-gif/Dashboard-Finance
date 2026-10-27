extends TestCase
## Android touch controls: multi-touch, sliding, hit areas, layout settings.

var tc: CanvasLayer


func _setup() -> void:
	Settings.values.touch_controls = "always"
	Settings.values.button_scale = 1.0
	Settings.values.layout = "standard"
	Settings.values.sensitivity = 1.15
	tc = load("res://scripts/ui/touch_controls.gd").new()
	add_child(tc)
	await frames(1)


func _touch(index: int, pos: Vector2, pressed: bool) -> void:
	var ev := InputEventScreenTouch.new()
	ev.index = index
	ev.pressed = pressed
	ev.position = get_viewport().get_final_transform() * pos   # push_input takes window coordinates
	get_viewport().push_input(ev)
	await frames(1)


func _drag(index: int, pos: Vector2) -> void:
	var ev := InputEventScreenDrag.new()
	ev.index = index
	ev.position = get_viewport().get_final_transform() * pos   # push_input takes window coordinates
	get_viewport().push_input(ev)
	await frames(1)


func test_press_and_release() -> void:
	await _setup()
	await _touch(0, tc.buttons.jump.center, true)
	check(Input.is_action_pressed("jump"), "jump pressed")
	check(tc.is_button_pressed("jump"), "button shows pressed state")
	await _touch(0, tc.buttons.jump.center, false)
	check(not Input.is_action_pressed("jump"), "jump released")


func test_move_and_jump_together() -> void:
	await _setup()
	await _touch(0, tc.buttons.right.center, true)
	await _touch(1, tc.buttons.jump.center, true)
	check(Input.is_action_pressed("move_right") and Input.is_action_pressed("jump"), "two thumbs at once")
	await _touch(1, tc.buttons.jump.center, false)
	check(Input.is_action_pressed("move_right"), "releasing one keeps the other")
	await _touch(0, tc.buttons.right.center, false)


func test_slide_between_buttons() -> void:
	await _setup()
	await _touch(0, tc.buttons.left.center, true)
	check(Input.is_action_pressed("move_left"), "left held")
	await _drag(0, tc.buttons.right.center)
	check(not Input.is_action_pressed("move_left") and Input.is_action_pressed("move_right"), "slid to right")
	await _drag(0, Vector2(240, 60))
	check(not Input.is_action_pressed("move_right"), "sliding off releases")
	await _touch(0, Vector2(240, 60), false)


func test_touch_outside_buttons_ignored() -> void:
	await _setup()
	await _touch(0, Vector2(240, 120), true)
	for a in ["move_left", "move_right", "jump", "dash"]:
		check(not Input.is_action_pressed(a), "%s not triggered by a touch in the play area" % a)
	await _touch(0, Vector2(240, 120), false)


func test_hidden_dash_cannot_be_pressed() -> void:
	await _setup()
	check(not tc.buttons.dash.visible, "dash hidden without Energy Surge")
	await _touch(0, tc.buttons.dash.center, true)
	check(not Input.is_action_pressed("dash"), "hidden dash ignored")
	await _touch(0, tc.buttons.dash.center, false)


func test_size_layout_and_sensitivity_settings() -> void:
	await _setup()
	var r0: float = tc.buttons.jump.radius
	var jump_x: float = tc.buttons.jump.center.x
	Settings.set_value("button_scale", 1.4)
	check(tc.buttons.jump.radius > r0 * 1.3, "buttons grow with the size setting")
	Settings.set_value("layout", "swapped")
	check(tc.buttons.jump.center.x < jump_x, "swapped layout moves jump to the left side")
	Settings.set_value("layout", "standard")
	Settings.set_value("button_scale", 1.0)
	var edge: Vector2 = tc.buttons.jump.center + Vector2(tc.buttons.jump.radius * 1.3, 0)
	Settings.set_value("sensitivity", 0.9)
	eq(tc.hit_test(edge), "", "outside a small hit area")
	Settings.set_value("sensitivity", 1.6)
	eq(tc.hit_test(edge), "jump", "inside with high sensitivity")
	var screen := tc.get_viewport().get_visible_rect().size
	for k in ["left", "right", "jump"]:
		var b: Dictionary = tc.buttons[k]
		check(b.center.x - b.radius >= 17.0 and b.center.x + b.radius <= screen.x - 17.0, "%s keeps clear of the screen edge" % k)
	Settings.values = Settings.DEFAULTS.duplicate()


func test_pause_button() -> void:
	await _setup()
	var hit := [false]
	tc.pause_pressed.connect(func(): hit[0] = true)
	await _touch(0, tc.buttons.pause.center, true)
	await _touch(0, tc.buttons.pause.center, false)
	check(hit[0], "pause button emits")
	Settings.values.touch_controls = "auto"
