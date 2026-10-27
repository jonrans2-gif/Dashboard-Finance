extends Node2D
## Short-lived boss attack objects: ground shockwave, lightning target marker
## and lightning bolt column.

var kind := "shockwave"
var velocity := Vector2.ZERO
var life := 1.0
var top_y := 0.0
var arena := Rect2()
var _area: Area2D
var _active := true


func _ready() -> void:
	match kind:
		"shockwave":
			var s := SpriteLib.make_sprite("shockwave", "wave")
			s.position = Vector2(0, -6)
			add_child(s)
			_make_area(Vector2(12, 10), Vector2(0, -5))
			AudioManager.play_sfx("slam", 0.1, -6.0)
		"marker":
			var s := SpriteLib.make_sprite("marker", "blink")
			s.position = Vector2(0, -2)
			add_child(s)
			_active = false
		"bolt":
			var h := position.y - top_y
			var n := int(ceil(h / 64.0))
			for i in n:
				var b := SpriteLib.make_sprite("bolt", "zap")
				b.position = Vector2(0, -32 - i * 64)
				add_child(b)
			_make_area(Vector2(10, h), Vector2(0, -h / 2.0))
			FX.shake(2.0, 0.15)


func _make_area(size: Vector2, offset: Vector2) -> void:
	_area = Area2D.new()
	_area.collision_layer = 32
	_area.collision_mask = 0
	_area.add_to_group("hazard")
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = size
	cs.shape = r
	cs.position = offset
	_area.add_child(cs)
	add_child(_area)


func is_harmful() -> bool:
	return _active


func _physics_process(delta: float) -> void:
	position += velocity * delta
	life -= delta
	if kind == "shockwave" and arena.size != Vector2.ZERO:
		if position.x < arena.position.x + 18 or position.x > arena.end.x - 4:
			life = 0.0
	if life <= 0.0:
		queue_free()
