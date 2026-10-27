extends Area2D
## Energy rail boost pad: running over it grants a short Ultra Boost.


func _ready() -> void:
	collision_layer = 8
	collision_mask = 2
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(16, 8)
	cs.shape = r
	cs.position = Vector2(8, -4)
	add_child(cs)
	var s := SpriteLib.make_sprite("boost_pad", "idle", false)
	s.position = Vector2(0, -8)
	add_child(s)
	body_entered.connect(func(b):
		if b is Player and b.state == Player.State.NORMAL:
			var had: bool = b.has_power("boost")
			b.powerups["boost"] = max(b.power_time_left("boost"), 3.0)
			b.velocity.x = b.facing * 220.0
			b.powerups_changed.emit()
			if not had:
				AudioManager.play_sfx("dash", 0.1, -4.0))
