extends Enemy
## Static Slime: glides along platforms. Every few seconds it flickers and
## then becomes electrically charged; while charged it cannot be stomped.

enum Phase { CALM, WARN, CHARGED }
var phase := Phase.CALM
var _t := 2.2


func _ready() -> void:
	setup("static_slime", Vector2(12, 9), "move")
	speed = 34.0
	turn_at_ledges = true
	score_value = 200
	_t = randf_range(1.5, 2.6)


func ai(delta: float) -> void:
	_t -= delta
	match phase:
		Phase.CALM:
			if _t <= 0.0:
				phase = Phase.WARN
				_t = 0.6
		Phase.WARN:
			sprite.play("charged" if int(_t * 14) % 2 == 0 else "move")
			if _t <= 0.0:
				phase = Phase.CHARGED
				_t = 1.5
				sprite.play("charged")
				AudioManager.play_sfx("zap", 0.1, -10.0)
		Phase.CHARGED:
			if _t <= 0.0:
				phase = Phase.CALM
				_t = randf_range(2.0, 3.0)
				sprite.play("move")
	speed = 20.0 if phase == Phase.CHARGED else 34.0
	walk(delta)


func is_stompable_now() -> bool:
	return phase != Phase.CHARGED


func hurts_on_stomp() -> bool:
	return phase == Phase.CHARGED
