class_name Boss
extends Node2D
## Shared boss behaviour: health/phases, contact parts (body, weak point),
## hit feedback, attack helpers and the defeat sequence.
##
## Every boss has a clear weak point and windows of vulnerability; plain
## contact with the body hurts the player, so fights are about reading
## telegraphed attacks rather than soaking damage.

signal defeated
signal damaged(hp: int)

const BossPart := preload("res://scripts/bosses/boss_part.gd")
const Hazard := preload("res://scripts/bosses/boss_hazard.gd")
const Projectile := preload("res://scripts/enemies/projectile.gd")

var level: Node
var arena := Rect2()
var display_name := "BOSS"
var max_hp := 3
var hp := 3
var dead := false
var sprite: AnimatedSprite2D
var floor_y := 0.0
var _invuln := 0.0
var _flash := 0.0
var _t := 0.0


func _ready() -> void:
	hp = max_hp
	floor_y = position.y
	add_to_group("boss")


func phase() -> int:
	## 1 at full health, 2 below 2/3, 3 below 1/3.
	var ratio := float(hp) / float(max_hp)
	if ratio > 0.67:
		return 1
	if ratio > 0.34:
		return 2
	return 3


func player() -> Player:
	return level.player if level else null


func add_part(part_name: String, size: Vector2, offset: Vector2) -> Node2D:
	var part := BossPart.new()
	part.boss = self
	part.part_name = part_name
	part.position = offset
	part.size = size
	add_child(part)
	return part


func on_part_contact(_part: String, _p: Player) -> void:
	pass


func _process(delta: float) -> void:
	_invuln = max(0.0, _invuln - delta)
	if _flash > 0.0:
		_flash -= delta
		sprite.modulate = Color(3, 3, 3) if int(_flash * 20) % 2 == 0 else Color.WHITE
		if _flash <= 0.0:
			sprite.modulate = Color.WHITE


## Applies one hit. Returns false while invulnerable.
func hurt() -> bool:
	if dead or _invuln > 0.0:
		return false
	hp -= 1
	_invuln = 1.0
	_flash = 0.6
	damaged.emit(hp)
	AudioManager.play_sfx("boss_hit")
	FX.shake(4.0, 0.3)
	Settings.haptic(70, 0.9)
	if level:
		level.camera_punch(0.07)
	FX.sparkle(global_position + Vector2(0, -24), 8, 20)
	if hp <= 0:
		_die()
	return true


func _die() -> void:
	dead = true
	for c in get_children():
		if c is BossPart:
			c.queue_free()
	AudioManager.play_sfx("roar")
	var t := create_tween()
	for i in 8:
		t.tween_callback(func():
			var off := Vector2(randf_range(-24, 24), randf_range(-40, 0))
			FX.spawn("puff", global_position + off)
			FX.debris(global_position + off, Color("ffd23f"))
			AudioManager.play_sfx("explosion", 0.2, -4.0)
			FX.shake(3.0, 0.15))
		t.tween_interval(0.22)
	t.tween_property(sprite, "modulate:a", 0.0, 0.4)
	t.tween_callback(func():
		defeated.emit()
		queue_free())


# ------------------------------------------------------------------ helpers
func face_player() -> int:
	var p := player()
	if p == null:
		return -1
	return 1 if p.global_position.x > global_position.x else -1


func shoot_orb(from: Vector2, vel: Vector2, grav := 0.0, anim := "fly_red", bounces := 0) -> void:
	var o := Projectile.new()
	o.velocity = vel
	o.fall_gravity = grav
	o.color_anim = anim
	o.bounces = bounces
	o.life = 5.0
	o.global_position = from
	o.level = level
	level.entities.add_child(o)


func shockwave(dir: int, speed := 130.0) -> void:
	var h := Hazard.new()
	h.kind = "shockwave"
	h.velocity = Vector2(dir * speed, 0)
	h.life = arena.size.x / speed
	h.global_position = Vector2(global_position.x + dir * 20.0, floor_y)
	h.arena = arena
	level.entities.add_child(h)


func marker(x: float, duration: float) -> void:
	var h := Hazard.new()
	h.kind = "marker"
	h.life = duration
	h.global_position = Vector2(x, floor_y)
	level.entities.add_child(h)


func bolt(x: float, duration := 0.45) -> void:
	var h := Hazard.new()
	h.kind = "bolt"
	h.life = duration
	h.global_position = Vector2(x, floor_y)
	h.top_y = arena.position.y + 8.0
	level.entities.add_child(h)
	AudioManager.play_sfx("zap", 0.1)


func clamp_to_arena(x: float, margin := 24.0) -> float:
	return clampf(x, arena.position.x + margin + 16.0, arena.end.x - margin)
