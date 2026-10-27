extends Area2D
## Energy orb fired by drones and bosses. Hurts the player, vanishes on walls.

var level: Node                 # set by the shooter; used for reliable tile collisions
var velocity := Vector2.ZERO
var fall_gravity := 0.0
var life := 4.0
var bounces := 0
var color_anim := "fly"
var _sprite: AnimatedSprite2D


func _ready() -> void:
	collision_layer = 32
	collision_mask = 1 | 2
	monitorable = false
	var cs := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 3.0
	cs.shape = c
	add_child(cs)
	_sprite = SpriteLib.make_sprite("orb", color_anim)
	add_child(_sprite)
	area_entered.connect(_on_area)
	body_entered.connect(_on_body)


func _physics_process(delta: float) -> void:
	velocity.y += fall_gravity * delta
	position += velocity * delta
	life -= delta
	if life <= 0.0:
		queue_free()
		return
	if level and level.is_solid_at(global_position):
		_hit_solid()


func _on_area(a: Area2D) -> void:
	var p := a.get_parent()
	if p is Player:
		p.take_damage(global_position)
		queue_free()


func _on_body(b: Node) -> void:
	if level == null and (b is TileMapLayer or b is StaticBody2D or b is AnimatableBody2D):
		_hit_solid()


func _hit_solid() -> void:
	if bounces > 0 and velocity.y > 0.0:
		bounces -= 1
		velocity.y = -abs(velocity.y) * 0.8
		position.y -= 4.0
		return
	FX.spawn("puff", global_position)
	queue_free()
