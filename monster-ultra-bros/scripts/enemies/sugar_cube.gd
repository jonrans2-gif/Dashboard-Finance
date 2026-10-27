extends Enemy
## Sugar Cube: hops at the player at irregular intervals. Every hop is
## telegraphed by a visible crouch, so it is unpredictable but fair.

var _t := 1.0
var _crouching := false


func _ready() -> void:
	setup("sugar_cube", Vector2(12, 12), "idle")
	speed = 0.0
	_t = randf_range(0.6, 1.4)


func ai(delta: float) -> void:
	velocity.y = min(velocity.y + gravity * delta, max_fall)
	if is_on_floor():
		velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
		_t -= delta
		if _crouching:
			if _t <= 0.0:
				_crouching = false
				var p: Node2D = level.player if level else null
				dir = 1 if p and p.global_position.x > global_position.x else -1
				velocity = Vector2(dir * randf_range(50.0, 80.0), -randf_range(200.0, 250.0))
				sprite.play("jump")
				_t = randf_range(0.8, 1.7)
		elif _t <= 0.0:
			_crouching = true
			_t = 0.38
			sprite.play("crouch")
		elif sprite.animation == "jump":
			sprite.play("idle")
	move_and_slide()
	if is_on_wall():
		velocity.x = -velocity.x
	sprite.flip_h = dir > 0
