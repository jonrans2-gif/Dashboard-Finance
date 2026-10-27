extends Area2D
## Energy Token, Ultra Shard, hidden Energy Core or Silver Can (1-up).
## Tokens are pulled toward the player while Ultra Magnet is active.

var kind := "token"      # token / shard / core / life
var index := 0           # shard/core index within the level
var level: Node
var _sprite: AnimatedSprite2D
var _base := Vector2.ZERO
var _t := 0.0
var _taken := false
var _magnet := false

const SHEETS := {"token": ["token", "spin"], "shard": ["shard", "idle"],
	"core": ["energy_core", "idle"], "life": ["silver_can", "idle"]}


func _ready() -> void:
	collision_layer = 8
	collision_mask = 2
	monitorable = false
	var cs := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 6.0 if kind == "token" else 8.0
	cs.shape = c
	add_child(cs)
	_sprite = SpriteLib.make_sprite(SHEETS[kind][0], SHEETS[kind][1])
	add_child(_sprite)
	_base = position
	_t = randf() * TAU
	body_entered.connect(_on_body)
	if kind != "token":
		add_to_group("special_items")


func _physics_process(delta: float) -> void:
	if _taken:
		return
	_t += delta
	var p: Player = level.player if level else null
	if kind == "token" and p and p.has_power("magnet") and p.state != Player.State.DEAD:
		var target := p.global_position + Vector2(0, -12)
		if _magnet or global_position.distance_to(target) < 96.0:
			_magnet = true
			global_position = global_position.move_toward(target, 260.0 * delta)
			return
	if kind != "token":
		position.y = _base.y + sin(_t * 3.0) * 2.0


func _on_body(b: Node) -> void:
	if _taken or not (b is Player) or b.state == Player.State.DEAD:
		return
	_taken = true
	set_deferred("monitoring", false)
	if level:
		level.on_collect(kind, index, global_position)
	match kind:
		"token":
			FX.spawn("sparkle", global_position)
			queue_free()
		_:
			var t := create_tween()
			t.tween_property(self, "position:y", position.y - 16.0, 0.3).set_ease(Tween.EASE_OUT)
			t.parallel().tween_property(self, "scale", Vector2(1.6, 1.6), 0.3)
			t.tween_property(self, "modulate:a", 0.0, 0.2)
			t.tween_callback(queue_free)
			FX.sparkle(global_position, 6, 10)
