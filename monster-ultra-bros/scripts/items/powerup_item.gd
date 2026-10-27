extends CharacterBody2D
## Power-up pickup. Mega Can, Ultra Boost and Overload slide along the ground
## after emerging from a block; the others hover in place.

const MOVERS := ["mega", "boost", "overload"]

var kind := "mega"
var level: Node
var emerge := false
var _dir := 1
var _sprite: AnimatedSprite2D
var _area: Area2D
var _emerge_t := 0.0
var _hover_base := 0.0
var _t := 0.0
var _taken := false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1 | 16
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(12, 12)
	cs.shape = r
	cs.position = Vector2(0, -6)
	add_child(cs)
	_sprite = SpriteLib.make_sprite("powerups", kind)
	_sprite.position = Vector2(0, -8)
	add_child(_sprite)
	_area = Area2D.new()
	_area.collision_layer = 8
	_area.collision_mask = 2
	var acs := CollisionShape2D.new()
	var ar := RectangleShape2D.new()
	ar.size = Vector2(14, 14)
	acs.shape = ar
	acs.position = Vector2(0, -7)
	_area.add_child(acs)
	add_child(_area)
	_area.body_entered.connect(_on_body)
	_hover_base = position.y
	if emerge:
		_emerge_t = 0.6
		_area.monitoring = false
		AudioManager.play_sfx("powerup_appear")
	if level and level.player:
		_dir = 1 if level.player.global_position.x < global_position.x else -1


func _physics_process(delta: float) -> void:
	if _taken:
		return
	_t += delta
	if _emerge_t > 0.0:
		_emerge_t -= delta
		position.y -= 16.0 * delta / 0.6
		if _emerge_t <= 0.0:
			_area.monitoring = true
			_hover_base = position.y
		return
	if kind in MOVERS:
		velocity.y = min(velocity.y + 800.0 * delta, 300.0)
		velocity.x = _dir * (45.0 if kind != "overload" else 60.0)
		if kind == "overload" and is_on_floor():
			velocity.y = -220.0
		move_and_slide()
		if is_on_wall():
			_dir = -_dir
		if level and global_position.y > level.kill_y():
			queue_free()
	else:
		position.y = _hover_base + sin(_t * 3.5) * 2.0


func _on_body(b: Node) -> void:
	if _taken or not (b is Player) or b.state == Player.State.DEAD:
		return
	_taken = true
	b.add_power(kind)
	if level:
		level.on_powerup_collected(kind, global_position)
	queue_free()
