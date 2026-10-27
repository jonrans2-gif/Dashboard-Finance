class_name BossPart
extends Node2D
## One contact zone of a boss (body, weak point...). The player's hurtbox
## detects the Area2D and calls on_player_contact on this node.

var boss: Node
var part_name := "body"
var size := Vector2(32, 32)
var area: Area2D
var shape: CollisionShape2D


func _ready() -> void:
	area = Area2D.new()
	area.collision_layer = 4
	area.collision_mask = 0
	area.add_to_group("enemy_hitbox")
	shape = CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = size
	shape.shape = r
	area.add_child(shape)
	add_child(area)


func set_size(s: Vector2) -> void:
	size = s
	if shape:
		(shape.shape as RectangleShape2D).size = s


func set_enabled(on: bool) -> void:
	if shape:
		shape.set_deferred("disabled", not on)


func on_player_contact(p: Player) -> void:
	if boss and not boss.dead:
		boss.on_part_contact(part_name, p)


func rect() -> Rect2:
	return Rect2(global_position - size / 2.0, size)
