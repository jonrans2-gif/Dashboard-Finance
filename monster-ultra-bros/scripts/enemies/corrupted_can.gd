extends Enemy
## Corrupted Can: faster than an Empty Can, never walks off ledges and
## charges at the player after a short, visible "spotted you" pause.

enum Mode { PATROL, SPOT, CHARGE }
var mode := Mode.PATROL
var _t := 0.0


func _ready() -> void:
	setup("corrupted_can", Vector2(10, 16), "walk")
	speed = 48.0
	turn_at_ledges = true
	score_value = 200


func ai(delta: float) -> void:
	var p: Node2D = level.player if level else null
	match mode:
		Mode.PATROL:
			speed = 48.0
			if p and abs(p.global_position.y - global_position.y) < 28.0 \
					and abs(p.global_position.x - global_position.x) < 120.0 and is_on_floor():
				mode = Mode.SPOT
				_t = 0.3
				dir = 1 if p.global_position.x > global_position.x else -1
			walk(delta)
		Mode.SPOT:
			_t -= delta
			sprite.modulate = Color(1, 0.5, 0.5) if int(_t * 20) % 2 == 0 else Color.WHITE
			velocity.x = 0.0
			if not is_on_floor():
				velocity.y = min(velocity.y + gravity * delta, max_fall)
			move_and_slide()
			sprite.flip_h = dir > 0
			if _t <= 0.0:
				sprite.modulate = Color.WHITE
				mode = Mode.CHARGE
				_t = 1.6
		Mode.CHARGE:
			_t -= delta
			speed = 92.0
			sprite.speed_scale = 2.0
			walk(delta)
			if _t <= 0.0:
				sprite.speed_scale = 1.0
				mode = Mode.PATROL
