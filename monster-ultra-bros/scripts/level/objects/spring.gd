extends Area2D
## Springboard: landing on it launches the player high (higher if jump is held).

var _sprite: AnimatedSprite2D
var _cool := 0.0


func _ready() -> void:
	collision_layer = 8
	collision_mask = 2
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(14, 10)
	cs.shape = r
	cs.position = Vector2(0, -6)
	add_child(cs)
	_sprite = SpriteLib.make_sprite("spring", "idle")
	_sprite.position = Vector2(0, -8)
	add_child(_sprite)


func _physics_process(delta: float) -> void:
	_cool -= delta
	if _cool > 0.0:
		return
	for b in get_overlapping_bodies():
		if b is Player and b.velocity.y >= 0.0 and b.global_position.y <= global_position.y - 4.0:
			var held: bool = Input.is_action_pressed("jump") or b.external_input.get("jump", false)
			b.velocity.y = -(600.0 if held else 500.0)
			b.set("_jumping", false)
			b.set("_air_jumps_used", 0)
			_sprite.play("bounce")
			AudioManager.play_sfx("spring")
			Settings.haptic(30, 0.5)
			_cool = 0.25
