extends AnimatableBody2D
## Platform that travels back and forth along a straight path (ping-pong
## with eased turns). The player rides it via CharacterBody2D platform logic.

var travel := Vector2(64, 0)   # offset from the start position to the far end
var speed := 40.0              # pixels per second along the path
var theme := "hills"
var _start := Vector2.ZERO
var _t := 0.0
var _duration := 1.0


func _ready() -> void:
	collision_layer = 16
	collision_mask = 0
	sync_to_physics = true
	_start = position
	_duration = max(0.5, travel.length() / speed)
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(48, 8)
	cs.shape = r
	cs.position = Vector2(24, 4)
	cs.one_way_collision = true
	cs.one_way_collision_margin = 4.0
	add_child(cs)
	var s := Sprite2D.new()
	s.texture = SpriteLib.texture("res://assets/sprites/platform_%s.png" % theme)
	s.centered = false
	add_child(s)


func _physics_process(delta: float) -> void:
	_t += delta
	var phase := fmod(_t / _duration, 2.0)
	var k := phase if phase <= 1.0 else 2.0 - phase
	k = k * k * (3.0 - 2.0 * k)   # smoothstep: slows down at the ends
	position = _start + travel * k
