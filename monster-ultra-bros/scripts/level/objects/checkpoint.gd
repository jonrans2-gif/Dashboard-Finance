extends Area2D
## Mid-level checkpoint flag. Activating it saves the respawn point and
## refills the can's energy.

signal reached(index: int)

var index := 0
var active := false
var _sprite: AnimatedSprite2D


func _ready() -> void:
	collision_layer = 8
	collision_mask = 2
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(14, 32)
	cs.shape = r
	cs.position = Vector2(0, -16)
	add_child(cs)
	_sprite = SpriteLib.make_sprite("checkpoint", "active" if active else "inactive")
	_sprite.position = Vector2(4, -16)
	add_child(_sprite)
	body_entered.connect(_on_body)


func set_active(on: bool, silent := true) -> void:
	active = on
	if _sprite:
		_sprite.play("active" if on else "inactive")
	if on and not silent:
		AudioManager.play_sfx("checkpoint")
		FX.sparkle(global_position + Vector2(6, -24), 6, 10)
		Settings.haptic(30, 0.4)


func _on_body(b: Node) -> void:
	if b is Player and not active and b.state != Player.State.DEAD:
		set_active(true, false)
		reached.emit(index)
