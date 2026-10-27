extends AnimatableBody2D
## Wooden platform that shakes briefly when stepped on, then falls.
## It respawns at its origin a few seconds later.

enum Phase { IDLE, SHAKE, FALL, GONE }
var phase := Phase.IDLE
var level: Node
var _origin := Vector2.ZERO
var _t := 0.0
var _vy := 0.0
var _sprite: AnimatedSprite2D
var _shape: CollisionShape2D


func _ready() -> void:
	collision_layer = 16
	collision_mask = 0
	sync_to_physics = false
	_origin = position
	_shape = CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(32, 8)
	_shape.shape = r
	_shape.position = Vector2(16, 4)
	_shape.one_way_collision = true
	add_child(_shape)
	_sprite = SpriteLib.make_sprite("falling_platform", "idle", false)
	add_child(_sprite)


func _physics_process(delta: float) -> void:
	match phase:
		Phase.IDLE:
			var p: Player = level.player if level else null
			if p and p.is_on_floor() and abs(p.global_position.y - global_position.y) < 3.0 \
					and p.global_position.x > global_position.x - 4 and p.global_position.x < global_position.x + 36:
				phase = Phase.SHAKE
				_t = 0.45
				_sprite.play("shake")
		Phase.SHAKE:
			_t -= delta
			_sprite.position.x = sin(_t * 80.0) * 1.0
			if _t <= 0.0:
				_sprite.position.x = 0
				phase = Phase.FALL
				_vy = 0.0
		Phase.FALL:
			_vy = min(_vy + 700.0 * delta, 300.0)
			position.y += _vy * delta
			if level and position.y > level.kill_y():
				phase = Phase.GONE
				_t = 3.0
				_shape.set_deferred("disabled", true)
				visible = false
		Phase.GONE:
			_t -= delta
			if _t <= 0.0:
				position = _origin
				phase = Phase.IDLE
				visible = true
				_sprite.play("idle")
				_shape.set_deferred("disabled", false)
				FX.spawn("puff", global_position + Vector2(16, 4))
