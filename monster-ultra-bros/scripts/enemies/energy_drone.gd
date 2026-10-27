extends Enemy
## Energy Drone: hovers on a patrol line and fires energy orbs at the player.
## Shots are announced by a red visor charge-up.

const Projectile := preload("res://scripts/enemies/projectile.gd")

var origin := Vector2.ZERO
var range_x := 48.0
var _t := 0.0
var _cooldown := 1.0
var _charging := 0.0


func _ready() -> void:
	setup("energy_drone", Vector2(16, 12), "fly")
	uses_gravity = false
	collision_mask = 0
	score_value = 200
	sprite.position.y = -8
	origin = global_position


func ai(delta: float) -> void:
	_t += delta
	var p: Node2D = level.player if level else null
	if _charging > 0.0:
		_charging -= delta
		if _charging <= 0.0 and p:
			_shoot(p)
			sprite.play("fly")
	else:
		global_position.x = origin.x + sin(_t * 0.9) * range_x
		global_position.y = origin.y + sin(_t * 2.3) * 4.0
		dir = 1 if cos(_t * 0.9) > 0 else -1
		_cooldown -= delta
		if p and _cooldown <= 0.0 and p.global_position.distance_to(global_position) < 150.0:
			_charging = 0.6
			_cooldown = 2.2
			sprite.play("charge")
			AudioManager.play_sfx("charge", 0.0, -8.0)
	if p:
		sprite.flip_h = p.global_position.x > global_position.x


func _shoot(p: Node2D) -> void:
	var from := global_position + Vector2(0, -2)
	var d := (p.global_position + Vector2(0, -10) - from).normalized()
	var orb := Projectile.new()
	orb.velocity = d * 110.0
	orb.global_position = from
	level.entities.add_child(orb)
	AudioManager.play_sfx("shoot", 0.05)


func defeat(how: String) -> void:
	sprite.play("broken")
	super.defeat("knock" if how == "squash" else how)
