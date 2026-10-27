extends AnimatableBody2D
## Mega Crusher: a heavy machine that slams down on a fixed rhythm.
## It shakes and its eyes turn red before every slam. The top is safe to
## stand on; being underneath while it falls hurts.

enum Phase { WAIT, WARN, SLAM, STUCK, RISE }
var level: Node
var phase := Phase.WAIT
var wait_time := 1.6
var offset := 0.0
var _t := 0.0
var _top := Vector2.ZERO
var _floor_y := 0.0
var _vy := 0.0
var _sprite: AnimatedSprite2D
var _hazard: Area2D
var _piston: Sprite2D


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	sync_to_physics = false
	_top = position
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(30, 28)
	cs.shape = r
	cs.position = Vector2(16, 16)
	add_child(cs)
	_piston = Sprite2D.new()
	_piston.texture = SpriteLib.texture("res://assets/sprites/piston.png")
	_piston.region_enabled = true
	_piston.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	_piston.centered = false
	_piston.z_index = -1
	add_child(_piston)
	_sprite = SpriteLib.make_sprite("mega_crusher", "idle", false)
	add_child(_sprite)
	_hazard = Area2D.new()
	_hazard.collision_layer = 32
	_hazard.collision_mask = 0
	_hazard.add_to_group("hazard")
	var hs := CollisionShape2D.new()
	var hr := RectangleShape2D.new()
	hr.size = Vector2(26, 8)
	hs.shape = hr
	hs.position = Vector2(16, 30)
	_hazard.add_child(hs)
	add_child(_hazard)
	# find the floor under the crusher
	var y := 32.0
	while y < 16.0 * 16.0 and level and not level.is_solid_at(global_position + Vector2(16, y + 1.0)):
		y += 4.0
	_floor_y = _top.y + y - 32.0
	_t = wait_time - offset


func is_harmful() -> bool:
	return phase == Phase.SLAM


func _physics_process(delta: float) -> void:
	_t -= delta
	match phase:
		Phase.WAIT:
			_sprite.play("idle")
			if _t <= 0.0:
				phase = Phase.WARN
				_t = 0.55
		Phase.WARN:
			_sprite.play("warn")
			_sprite.position.x = sin(_t * 70.0) * 1.0
			if _t <= 0.0:
				_sprite.position.x = 0
				phase = Phase.SLAM
				_vy = 60.0
		Phase.SLAM:
			_sprite.play("slam")
			_vy = min(_vy + 1400.0 * delta, 520.0)
			position.y = min(position.y + _vy * delta, _floor_y)
			if position.y >= _floor_y:
				phase = Phase.STUCK
				_t = 0.7
				if level and level.is_near_view(global_position, 32.0):
					AudioManager.play_sfx("slam")
					FX.shake(3.0, 0.25)
					Settings.haptic(40, 0.6)
				FX.dust(global_position + Vector2(4, 32), 1)
				FX.dust(global_position + Vector2(28, 32), 1)
		Phase.STUCK:
			if _t <= 0.0:
				phase = Phase.RISE
		Phase.RISE:
			_sprite.play("idle")
			position.y = max(position.y - 45.0 * delta, _top.y)
			if position.y <= _top.y:
				phase = Phase.WAIT
				_t = wait_time
	var ext := position.y - _top.y
	_piston.region_rect = Rect2(0, 0, 8, ext + 8.0)
	_piston.position = Vector2(12, -ext - 8.0 + 2.0)
