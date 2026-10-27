extends Control
## Settings panel, used from the main menu and the pause menu. Every change
## applies immediately; the file is written when the panel closes.

signal closed

var allow_reset := false
var _confirm: Control
var _first: Control


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()


func _build_ui() -> void:
	UITheme.dim_background(self, 0.75)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(330, 236)
	panel.position = Vector2(-165, -118)
	add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	panel.add_child(v)
	v.add_child(UITheme.label("SETTINGS", 20))
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(310, 160)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.scroll_deadzone = 8
	v.add_child(scroll)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 5)
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(rows)

	_slider_row(rows, "MUSIC VOLUME", "music_volume", 0.0, 1.0, 0.05)
	_slider_row(rows, "SOUND EFFECTS", "sfx_volume", 0.0, 1.0, 0.05, func(_v): AudioManager.play_sfx("token"))
	_cycle_row(rows, "VIBRATION", "haptics", [true, false], ["ON", "OFF"], func(v): if v: Settings.haptic(60, 0.8))
	_slider_row(rows, "BUTTON SIZE", "button_scale", 0.7, 1.5, 0.05)
	_slider_row(rows, "BUTTON OPACITY", "button_opacity", 0.2, 1.0, 0.05)
	_cycle_row(rows, "BUTTON LAYOUT", "layout", ["standard", "swapped"], ["STANDARD", "SWAPPED"])
	_slider_row(rows, "BUTTONS INWARD", "offset_x", 0.0, 60.0, 2.0)
	_slider_row(rows, "BUTTONS HIGHER", "offset_y", 0.0, 60.0, 2.0)
	_slider_row(rows, "TOUCH SENSITIVITY", "sensitivity", 0.9, 1.6, 0.05)
	_cycle_row(rows, "TOUCH CONTROLS", "touch_controls", ["auto", "always", "never"], ["AUTO", "ALWAYS", "HIDDEN"])
	_cycle_row(rows, "SCREEN", "orientation", ["landscape", "auto", "portrait"], ["LANDSCAPE", "ROTATE", "PORTRAIT"])
	_cycle_row(rows, "SCREEN SHAKE", "screen_shake", [true, false], ["ON", "OFF"])
	var reset_defaults := UITheme.button("RESTORE DEFAULTS", func():
		Settings.reset_to_defaults()
		_rebuild(), 160)
	rows.add_child(_center(reset_defaults))
	if allow_reset:
		var reset := UITheme.button("RESET PROGRESS", _ask_reset, 160)
		rows.add_child(_center(reset))
	var back := UITheme.button("BACK", close, 120)
	v.add_child(_center(back))
	_first = back
	back.grab_focus.call_deferred()


func _center(c: Control) -> CenterContainer:
	var cc := CenterContainer.new()
	cc.add_child(c)
	return cc


func _row(parent: Control, title: String) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	var l := UITheme.label(title, 10, UITheme.C_DIM, HORIZONTAL_ALIGNMENT_LEFT)
	l.custom_minimum_size = Vector2(150, 0)
	h.add_child(l)
	parent.add_child(h)
	return h


func _slider_row(parent: Control, title: String, key: String, lo: float, hi: float, step: float, extra := Callable()) -> void:
	var h := _row(parent, title)
	var s := UITheme.slider(lo, hi, step, float(Settings.get_value(key)), func(v):
		Settings.set_value(key, float(v))
		if extra.is_valid():
			extra.call(v))
	h.add_child(s)


func _cycle_row(parent: Control, title: String, key: String, opts: Array, labels: Array, extra := Callable()) -> void:
	var h := _row(parent, title)
	h.add_child(UITheme.cycler(opts, labels, Settings.get_value(key), func(v):
		Settings.set_value(key, v)
		if extra.is_valid():
			extra.call(v)))


func _rebuild() -> void:
	for c in get_children():
		c.queue_free()
	_build_ui.call_deferred()


func _ask_reset() -> void:
	_confirm = Control.new()
	_confirm.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_confirm)
	UITheme.dim_background(_confirm, 0.8)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-120, -50)
	panel.custom_minimum_size = Vector2(240, 100)
	_confirm.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	panel.add_child(v)
	v.add_child(UITheme.label("ERASE ALL PROGRESS?", 10, Color("ff6a6a")))
	v.add_child(UITheme.label("Unlocked levels, scores and shards", 10, UITheme.C_DIM))
	var h := HBoxContainer.new()
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_theme_constant_override("separation", 8)
	var no := UITheme.button("KEEP", func(): _confirm.queue_free(), 80)
	h.add_child(no)
	h.add_child(UITheme.button("ERASE", func():
		SaveSystem.reset_progress()
		_confirm.queue_free(), 80))
	v.add_child(h)
	no.grab_focus.call_deferred()


func close() -> void:
	Settings.save()
	closed.emit()
	queue_free()


func back() -> void:
	if _confirm and is_instance_valid(_confirm):
		_confirm.queue_free()
	else:
		close()
