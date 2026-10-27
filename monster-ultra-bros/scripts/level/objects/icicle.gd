extends Area2D
## Icicle hanging from a ceiling. It trembles when the player passes below,
## then drops. Shatters on the ground.

var level: Node
var _state := 0   # 0 hanging, 1 trembling, 2 falling
var _t := 0.0
var _vy := 0.0
var _sprite: Sprite2D
var _origin := Vector2.ZERO


func _ready() -> void:
	collision_layer = 32
	collision_mask = 0
	add_to_group("hazard")
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(6, 12)
	cs.shape = r
	cs.position = Vector2(0, 8)
	add_child(cs)
	_sprite = Sprite2D.new()
	_sprite.texture = SpriteLib.texture("res://assets/sprites/icicle.png")
	_sprite.position = Vector2(0, 8)
	add_child(_sprite)
	_origin = position


func _physics_process(delta: float) -> void:
	match _state:
		0:
			var p: Node2D = level.player if level else null
			if p and abs(p.global_position.x - global_position.x) < 30.0 and p.global_position.y > global_position.y:
				_state = 1
				_t = 0.4
		1:
			_t -= delta
			_sprite.position.x = sin(_t * 90.0)
			if _t <= 0.0:
				_state = 2
				_sprite.position.x = 0
		2:
			_vy = min(_vy + 800.0 * delta, 360.0)
			position.y += _vy * delta
			if level and level.is_solid_at(global_position + Vector2(0, 16)):
				FX.debris(global_position + Vector2(0, 12), Color("bfeaff"))
				AudioManager.play_sfx("brick", 0.2, -6.0)
				queue_free()
			elif level and position.y > level.kill_y():
				queue_free()
