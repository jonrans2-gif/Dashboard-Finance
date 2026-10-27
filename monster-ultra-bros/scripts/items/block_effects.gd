class_name BlockEffects
## Small one-shot visuals for blocks: bump animation and the token that pops
## out of an energy block.


static func bump(parent: Node, tex: Texture2D, region: Rect2, pos: Vector2, on_done: Callable) -> void:
	var s := Sprite2D.new()
	s.texture = tex
	s.region_enabled = true
	s.region_rect = region
	s.position = pos
	s.z_index = 5
	parent.add_child(s)
	var t := s.create_tween()
	t.tween_property(s, "position:y", pos.y - 5.0, 0.07).set_ease(Tween.EASE_OUT)
	t.tween_property(s, "position:y", pos.y, 0.09).set_ease(Tween.EASE_IN)
	t.tween_callback(func():
		on_done.call()
		s.queue_free())


static func token_pop(parent: Node, pos: Vector2) -> void:
	var s := SpriteLib.make_sprite("token", "spin")
	s.speed_scale = 2.5
	s.position = pos
	s.z_index = 6
	parent.add_child(s)
	var t := s.create_tween()
	t.tween_property(s, "position:y", pos.y - 36.0, 0.22).set_ease(Tween.EASE_OUT)
	t.tween_property(s, "position:y", pos.y - 18.0, 0.16).set_ease(Tween.EASE_IN)
	t.tween_callback(func():
		FX.spawn("sparkle", s.global_position)
		s.queue_free())
