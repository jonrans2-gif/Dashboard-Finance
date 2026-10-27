class_name ParallaxBG
extends CanvasLayer
## Screen-space parallax: a vertical sky gradient plus horizontally repeating
## layers that scroll at different speeds relative to the camera. Works for
## any aspect ratio because everything is laid out from the screen size.

const LAYER_W := 512.0
const SKY := {
	"hills": [Color("5ab4ff"), Color("c8ecff")],
	"cave": [Color("0a0e22"), Color("1d2a50")],
	"fortress": [Color("1a1530"), Color("463c6e")],
	"factory": [Color("1a1220"), Color("5a2e36")],
	"ice": [Color("8fcaf8"), Color("eef9ff")],
	"ultra": [Color("08041c"), Color("34104f")],
}
# layer name -> [scroll factor, vertical anchor (0 top .. 1 bottom), drift px/s]
const LAYERS := {
	"clouds": [0.08, 0.0, 6.0],
	"far": [0.18, 1.0, 0.0],
	"near": [0.42, 1.0, 0.0],
}

var camera: Camera2D
var level_bottom := 272.0
var _sky: TextureRect
var _layers: Array = []   # [Sprite2D, factor, anchor, drift]
var _time := 0.0
var _snow: CPUParticles2D


func setup(bg: String, cam: Camera2D) -> void:
	layer = -10
	camera = cam
	var grad := Gradient.new()
	var cols: Array = SKY.get(bg, SKY.hills)
	grad.set_color(0, cols[0])
	grad.set_color(1, cols[1])
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.fill_from = Vector2(0, 0)
	gt.fill_to = Vector2(0, 1)
	gt.width = 4
	gt.height = 128
	_sky = TextureRect.new()
	_sky.texture = gt
	_sky.stretch_mode = TextureRect.STRETCH_SCALE
	_sky.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_sky)
	for lname in ["clouds", "far", "near"]:
		var path := "res://assets/bg/%s_%s.png" % [bg, lname]
		if not ResourceLoader.exists(path):
			continue
		var s := Sprite2D.new()
		s.texture = load(path)
		s.centered = false
		s.region_enabled = true
		s.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		add_child(s)
		_layers.append([s, LAYERS[lname][0], LAYERS[lname][1], LAYERS[lname][2]])
	if bg == "ice":
		_snow = CPUParticles2D.new()
		_snow.amount = 40
		_snow.lifetime = 6.0
		_snow.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		_snow.direction = Vector2(-0.3, 1)
		_snow.spread = 15
		_snow.gravity = Vector2(0, 8)
		_snow.initial_velocity_min = 12
		_snow.initial_velocity_max = 24
		_snow.scale_amount_min = 1.0
		_snow.scale_amount_max = 2.0
		_snow.color = Color(1, 1, 1, 0.8)
		_snow.preprocess = 6.0
		add_child(_snow)


func _process(delta: float) -> void:
	_time += delta
	if camera == null or not is_instance_valid(camera):
		return
	var screen := get_viewport().get_visible_rect().size
	var cam_x := camera.global_position.x
	var cam_y := camera.global_position.y
	for entry in _layers:
		var s: Sprite2D = entry[0]
		var factor: float = entry[1]
		var anchor: float = entry[2]
		var drift: float = entry[3]
		var h := float(s.texture.get_height())
		s.region_rect = Rect2(0, 0, screen.x + LAYER_W * 2.0, h)
		var off := fposmod(cam_x * factor + _time * drift, LAYER_W)
		# Screen-space y of the level's bottom edge; layers sit on that horizon.
		var lb_screen := level_bottom - cam_y + screen.y / 2.0
		var climb: float = max(0.0, lb_screen - screen.y) * factor * 0.25
		var y := 4.0 + climb
		if anchor >= 1.0:
			y = min(screen.y, lb_screen - 56.0) - h + climb   # sit on the ground line, pits show sky
		s.position = Vector2(-off, y)
	if _snow:
		_snow.position = Vector2(screen.x / 2.0, -10)
		_snow.emission_rect_extents = Vector2(screen.x * 0.6, 4)
