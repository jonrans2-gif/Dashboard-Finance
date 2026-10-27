extends Area2D
## Warp door. Doors are paired in the order they appear in the level file
## (1st<->2nd, 3rd<->4th...). The level shows an ENTER button while the
## player stands in front of one.

var partner: Area2D
var is_secret := false
var _sprite: AnimatedSprite2D


func _ready() -> void:
	collision_layer = 8
	collision_mask = 2
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(12, 28)
	cs.shape = r
	cs.position = Vector2(0, -14)
	add_child(cs)
	_sprite = SpriteLib.make_sprite("door", "closed")
	_sprite.position = Vector2(0, -16)
	_sprite.z_index = -1
	add_child(_sprite)
	add_to_group("doors")


func player_inside(p: Node2D) -> bool:
	return p in get_overlapping_bodies()


func open_anim() -> void:
	_sprite.play("open")
	var t := create_tween()
	t.tween_interval(0.5)
	t.tween_callback(func(): _sprite.play("closed"))
