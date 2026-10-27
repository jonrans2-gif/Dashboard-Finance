extends Control
## Credits panel with auto-scrolling text.

signal closed

const LINES := [
	["MONSTER ULTRA BROS.", 20], ["WHITE EDITION", 10], ["", 10],
	["GAME DESIGN & PROGRAMMING", 10], ["Claude (Anthropic) for jonrans2", 10], ["", 10],
	["PIXEL ART", 10], ["Procedurally drawn, original sprites", 10], ["", 10],
	["MUSIC & SOUND", 10], ["Original chiptune score", 10], ["composed with a custom synthesizer", 10], ["", 10],
	["ENGINE", 10], ["Godot Engine 4.7 (MIT license)", 10], ["", 10],
	["INSPIRED BY", 10], ["the classic 8-bit platformers", 10], ["", 10],
	["Monster Energy and Ultra White are", 10], ["trademarks of their owner.", 10],
	["This is an unofficial fan project", 10], ["and is not affiliated with or", 10], ["endorsed by Monster Energy.", 10], ["", 10],
	["THANKS FOR PLAYING!", 20],
]

var _scroll: ScrollContainer
var _t := 0.0
var _auto := true


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	UITheme.dim_background(self, 0.8)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-150, -115)
	panel.custom_minimum_size = Vector2(300, 230)
	add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	panel.add_child(v)
	v.add_child(UITheme.label("CREDITS", 20, Color("7dff5a")))
	_scroll = ScrollContainer.new()
	_scroll.custom_minimum_size = Vector2(280, 160)
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(_scroll)
	var lines := VBoxContainer.new()
	lines.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(lines)
	for l in LINES:
		lines.add_child(UITheme.label(l[0], l[1], Color.WHITE if l[1] == 10 else Color("ffd23f")))
	var back_btn := UITheme.button("BACK", back, 100)
	var cc := CenterContainer.new()
	cc.add_child(back_btn)
	v.add_child(cc)
	back_btn.grab_focus.call_deferred()
	_scroll.gui_input.connect(func(e): if e is InputEventScreenTouch or e is InputEventMouseButton: _auto = false)


func _process(delta: float) -> void:
	if _auto:
		_t += delta * 18.0
		_scroll.scroll_vertical = int(_t)


func back() -> void:
	closed.emit()
	queue_free()
