extends Node
## Pooled visual effects. The active level registers a root node via
## set_root(); effects are recycled instead of being instanced per event.

signal shake_requested(strength: float, duration: float)

const POOL_SIZE := {"dust": 10, "sparkle": 12, "puff": 8, "popup": 8, "debris": 6}
const MAX_ACTIVE_PARTICLES := 6

var _root: Node2D
var _pools: Dictionary = {}
var _font: Font


func set_root(root: Node2D) -> void:
	_root = root
	_pools.clear()
	_font = load("res://assets/fonts/ultrapixel.ttf")


func _take(kind: String) -> Node:
	if _root == null or not is_instance_valid(_root):
		return null
	var pool: Array = _pools.get(kind, [])
	_pools[kind] = pool
	for n in pool:
		if is_instance_valid(n) and not n.visible:
			return n
	if pool.size() >= POOL_SIZE.get(kind, 8):
		# Recycle the oldest effect rather than growing without bound.
		var oldest = pool.pop_front()
		pool.append(oldest)
		return oldest
	var node: Node
	match kind:
		"dust", "sparkle", "puff":
			var s := AnimatedSprite2D.new()
			s.sprite_frames = SpriteLib.frames(kind)
			s.animation_finished.connect(func(): s.visible = false)
			node = s
		"popup":
			var l := Label.new()
			l.add_theme_font_override("font", _font)
			l.add_theme_font_size_override("font_size", 10)
			l.add_theme_color_override("font_outline_color", Color(0.1, 0.1, 0.14))
			l.add_theme_constant_override("outline_size", 3)
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			l.size = Vector2(60, 12)
			l.z_index = 50
			node = l
		"debris":
			var p := CPUParticles2D.new()
			p.one_shot = true
			p.emitting = false
			p.amount = 8
			p.lifetime = 0.9
			p.explosiveness = 1.0
			p.direction = Vector2(0, -1)
			p.spread = 70.0
			p.initial_velocity_min = 90.0
			p.initial_velocity_max = 170.0
			p.gravity = Vector2(0, 600)
			p.angular_velocity_min = -400
			p.angular_velocity_max = 400
			p.texture = SpriteLib.texture("res://assets/sprites/debris.png")
			p.finished.connect(func(): p.visible = false)
			node = p
	node.visible = false
	_root.add_child(node)
	pool.append(node)
	return node


func spawn(kind: String, pos: Vector2, flip := false) -> void:
	var s = _take(kind)
	if s == null:
		return
	s.visible = true
	s.global_position = pos
	s.z_index = 20
	s.flip_h = flip
	s.frame = 0
	var anim: String = {"dust": "puff", "sparkle": "twinkle", "puff": "pop"}[kind]
	s.play(anim)


func dust(pos: Vector2, count := 1) -> void:
	for i in count:
		spawn("dust", pos + Vector2(randf_range(-6, 6), randf_range(-2, 1)))


func sparkle(pos: Vector2, count := 3, radius := 8.0) -> void:
	for i in count:
		spawn("sparkle", pos + Vector2(randf_range(-radius, radius), randf_range(-radius, radius)))


func debris(pos: Vector2, color := Color.WHITE) -> void:
	var p = _take("debris")
	if p == null:
		return
	p.visible = true
	p.global_position = pos
	p.modulate = color
	p.z_index = 20
	p.restart()
	p.emitting = true


func popup(pos: Vector2, text: String, color := Color.WHITE) -> void:
	var l = _take("popup")
	if l == null:
		return
	l.visible = true
	l.text = text
	l.modulate = color
	l.position = pos - Vector2(30, 14)
	var t := l.create_tween()
	t.tween_property(l, "position:y", l.position.y - 18, 0.7).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(l, "modulate:a", 0.0, 0.7).set_delay(0.3)
	t.tween_callback(func(): l.visible = false)


func shake(strength := 3.0, duration := 0.25) -> void:
	if Settings.get_value("screen_shake"):
		shake_requested.emit(strength, duration)
