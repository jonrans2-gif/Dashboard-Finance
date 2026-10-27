extends Node2D
## Animated menu background: the can runs endlessly through White Hills
## while the parallax scrolls. Used by the main menu, level select and ending.

var cam: Camera2D
var bg: ParallaxBG
var runner: AnimatedSprite2D
var ground: TileMapLayer
var theme := "hills"
var speed := 60.0
var _x := 0.0
var _tiles := 0
var _jump_t := 2.0
var _vy := 0.0
var _y := 0.0


func _ready() -> void:
	cam = Camera2D.new()
	add_child(cam)
	cam.make_current()
	bg = ParallaxBG.new()
	add_child(bg)
	bg.setup(theme, cam)
	ground = TileMapLayer.new()
	ground.tile_set = Tiles.tileset(theme)
	ground.collision_enabled = false
	add_child(ground)
	runner = SpriteLib.make_sprite("player", "run")
	add_child(runner)
	_extend_ground()


func _extend_ground() -> void:
	var need := int((_x + 1200.0) / 16.0)
	while _tiles < need:
		for y in range(13, 22):
			ground.set_cell(Vector2i(_tiles, y), 0, Tiles.GROUND_T if y == 13 else Tiles.FILL)
		if _tiles % 11 == 3:
			ground.set_cell(Vector2i(_tiles, 12), 0, Tiles.BUSH)
		if _tiles % 17 == 9:
			ground.set_cell(Vector2i(_tiles, 12), 0, Tiles.FLOWER)
		_tiles += 1


func _process(delta: float) -> void:
	_x += speed * delta
	var screen := get_viewport().get_visible_rect().size
	cam.global_position = Vector2(_x, 208.0 - screen.y / 2.0 + 64.0)
	bg.level_bottom = 272.0
	_jump_t -= delta
	if _jump_t <= 0.0 and _y == 0.0:
		_vy = -230.0
		_jump_t = randf_range(2.0, 4.0)
		runner.play("jump")
	if _y < 0.0 or _vy < 0.0:
		_vy += 900.0 * delta
		_y = min(0.0, _y + _vy * delta)
		if _y == 0.0:
			_vy = 0.0
			runner.play("run")
		elif _vy > 0.0:
			runner.play("fall")
	runner.global_position = Vector2(_x - screen.x * 0.28, 208.0 - 15.0 + _y)
	_extend_ground()
