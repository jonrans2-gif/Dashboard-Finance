extends Node
## Builds the global pixel-art UI theme and offers widget helpers used by all
## menus, so every screen shares one look.

const C_BG := Color("23252d")
const C_PANEL := Color("1a1b22")
const C_LINE := Color("c8ccd6")
const C_ACCENT := Color("7dff5a")
const C_GOLD := Color("ffd23f")
const C_TEXT := Color("ffffff")
const C_DIM := Color("8d94a3")

var theme: Theme
var font: FontFile


func _ready() -> void:
	font = load("res://assets/fonts/ultrapixel.ttf")
	font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	font.hinting = TextServer.HINTING_NONE
	font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	theme = _build()
	get_tree().root.theme = theme


func _box(bg: Color, border: Color, bw := 2, pad := 6) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(bw)
	s.set_corner_radius_all(0)
	s.content_margin_left = pad + 2
	s.content_margin_right = pad + 2
	s.content_margin_top = pad - 2
	s.content_margin_bottom = pad - 2
	s.anti_aliasing = false
	return s


func _build() -> Theme:
	var t := Theme.new()
	t.default_font = font
	t.default_font_size = 10
	# Buttons
	t.set_stylebox("normal", "Button", _box(Color(C_BG, 0.92), C_LINE))
	t.set_stylebox("hover", "Button", _box(Color("30333e"), C_ACCENT))
	t.set_stylebox("focus", "Button", _box(Color(0, 0, 0, 0), C_ACCENT))
	t.set_stylebox("pressed", "Button", _box(C_LINE, C_TEXT))
	t.set_stylebox("disabled", "Button", _box(Color(C_BG, 0.6), Color("4a4f5c")))
	t.set_color("font_color", "Button", C_TEXT)
	t.set_color("font_hover_color", "Button", C_ACCENT)
	t.set_color("font_focus_color", "Button", C_ACCENT)
	t.set_color("font_pressed_color", "Button", C_BG)
	t.set_color("font_disabled_color", "Button", Color("5f6676"))
	t.set_constant("h_separation", "Button", 4)
	# Labels
	t.set_color("font_color", "Label", C_TEXT)
	t.set_color("font_outline_color", "Label", Color("101018"))
	t.set_constant("outline_size", "Label", 0)
	# Panels
	t.set_stylebox("panel", "PanelContainer", _box(Color(C_PANEL, 0.94), C_LINE, 2, 8))
	t.set_stylebox("panel", "Panel", _box(Color(C_PANEL, 0.94), C_LINE, 2, 8))
	# Sliders
	var track := _box(Color("101018"), Color("5f6676"), 1, 0)
	track.content_margin_top = 3
	track.content_margin_bottom = 3
	var fill := _box(C_ACCENT, C_ACCENT, 0, 0)
	fill.content_margin_top = 3
	fill.content_margin_bottom = 3
	t.set_stylebox("slider", "HSlider", track)
	t.set_stylebox("grabber_area", "HSlider", fill)
	t.set_stylebox("grabber_area_highlight", "HSlider", fill)
	var grab := _grabber_tex(C_TEXT)
	t.set_icon("grabber", "HSlider", grab)
	t.set_icon("grabber_highlight", "HSlider", _grabber_tex(C_ACCENT))
	# Scroll bars
	var sb := _box(Color("101018", 0.6), Color(0, 0, 0, 0), 0, 0)
	sb.content_margin_left = 3
	sb.content_margin_right = 3
	var grabber := _box(Color(C_LINE, 0.7), Color(0, 0, 0, 0), 0, 0)
	grabber.content_margin_left = 3
	grabber.content_margin_right = 3
	t.set_stylebox("scroll", "VScrollBar", sb)
	t.set_stylebox("grabber", "VScrollBar", grabber)
	t.set_stylebox("grabber_highlight", "VScrollBar", grabber)
	t.set_stylebox("grabber_pressed", "VScrollBar", grabber)
	return t


func _grabber_tex(col: Color) -> Texture2D:
	var img := Image.create(8, 12, false, Image.FORMAT_RGBA8)
	img.fill(Color("101018"))
	for y in range(1, 11):
		for x in range(1, 7):
			img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)


# ------------------------------------------------------------------ helpers
func label(text: String, size := 10, color := C_TEXT, align := HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = align
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_shadow_color", Color(0.06, 0.06, 0.1, 0.9))
	l.add_theme_constant_override("shadow_offset_x", 2 if size >= 20 else 1)
	l.add_theme_constant_override("shadow_offset_y", 2 if size >= 20 else 1)
	if size >= 20:
		l.add_theme_constant_override("outline_size", 2)
	return l


func button(text: String, callback: Callable, min_w := 120) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(min_w, 21)
	b.focus_mode = Control.FOCUS_ALL
	b.pressed.connect(func():
		AudioManager.play_sfx("ui_select")
		Settings.haptic(12, 0.3)
		callback.call())
	b.focus_entered.connect(func(): AudioManager.play_sfx("ui_move", 0.0, -6.0))
	return b


func dim_background(parent: Control, alpha := 0.6) -> ColorRect:
	var r := ColorRect.new()
	r.color = Color(0.03, 0.03, 0.05, alpha)
	r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_STOP
	parent.add_child(r)
	return r


## A horizontal "< value >" selector cycling through `options`.
func cycler(options: Array, labels: Array, current, on_change: Callable) -> HBoxContainer:
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	var idx: int = maxi(0, options.find(current))
	var val := Label.new()
	val.custom_minimum_size = Vector2(76, 0)
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	val.text = str(labels[idx])
	var state := {"i": idx}
	var step := func(d: int):
		state.i = (state.i + d + options.size()) % options.size()
		val.text = str(labels[state.i])
		on_change.call(options[state.i])
	var l := button("<", func(): step.call(-1), 22)
	var r := button(">", func(): step.call(1), 22)
	box.add_child(l)
	box.add_child(val)
	box.add_child(r)
	return box


func slider(min_v: float, max_v: float, step: float, value: float, on_change: Callable) -> HSlider:
	var s := HSlider.new()
	s.min_value = min_v
	s.max_value = max_v
	s.step = step
	s.value = value
	s.custom_minimum_size = Vector2(110, 16)
	s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	s.value_changed.connect(func(v): on_change.call(v))
	return s
