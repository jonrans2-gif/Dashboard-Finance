extends Area2D
## Goal pole. The higher the can grabs it, the bigger the flag bonus.

signal touched(height_ratio: float)

const POLE_H := 144.0
var enabled := true
var _flag: AnimatedSprite2D
var _done := false


func _ready() -> void:
	collision_layer = 8
	collision_mask = 2
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(8, POLE_H)
	cs.shape = r
	cs.position = Vector2(0, -POLE_H / 2.0 - 16.0)
	add_child(cs)
	var pole := Sprite2D.new()
	pole.texture = SpriteLib.texture("res://assets/sprites/goal_pole.png")
	pole.centered = false
	pole.position = Vector2(-8, -16 - 160)
	add_child(pole)
	var base := Sprite2D.new()
	base.texture = SpriteLib.texture("res://assets/sprites/goal_base.png")
	base.position = Vector2(0, -8)
	add_child(base)
	_flag = SpriteLib.make_sprite("goal_flag", "wave", false)
	_flag.position = Vector2(1, -16 - POLE_H + 4)
	add_child(_flag)
	body_entered.connect(_on_body)
	set_enabled(enabled)


func set_enabled(on: bool) -> void:
	enabled = on
	visible = on
	set_deferred("monitoring", on)


func flag_drop(duration: float) -> void:
	var t := create_tween()
	t.tween_property(_flag, "position:y", -16.0 - 20.0, duration)


func _on_body(b: Node) -> void:
	if _done or not enabled or not (b is Player) or b.state == Player.State.DEAD:
		return
	_done = true
	var top := global_position.y - 16.0 - POLE_H
	var ratio: float = clamp(1.0 - (b.global_position.y - top) / POLE_H, 0.0, 1.0)
	touched.emit(ratio)
