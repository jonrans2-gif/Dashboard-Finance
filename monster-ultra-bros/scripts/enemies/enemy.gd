class_name Enemy
extends CharacterBody2D
## Base class for all regular enemies.
##
## Enemies stay dormant until they come near the camera view, so they never
## appear out of nowhere and the player always gets to react. Contact with
## the player is resolved here: a stomp from above defeats a stompable enemy,
## dashing / Overload knocks it out, anything else hurts the player.

signal defeated(enemy: Enemy, how: String)

var level: Node
var sprite: AnimatedSprite2D
var hitbox: Area2D
var body_size := Vector2(12, 14)
var speed := 30.0
var dir := -1
var gravity := 900.0
var max_fall := 380.0
var active := false
var dead := false
var stompable := true
var turn_at_ledges := false
var uses_gravity := true
var score_value := 100
var activation_margin := 40.0
var _anim_walk := "walk"
var _anim_squash := "squash"


func setup(sheet: String, size: Vector2, first_anim: String) -> void:
	body_size = size
	collision_layer = 0
	collision_mask = 1 | 16
	floor_snap_length = 4.0
	var cs := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	cs.shape = rect
	cs.position = Vector2(0, -size.y / 2.0)
	add_child(cs)
	sprite = SpriteLib.make_sprite(sheet, first_anim, true)
	add_child(sprite)
	var fh: float = sprite.sprite_frames.get_frame_texture(first_anim, 0).get_height()
	sprite.position = Vector2(0, -fh / 2.0 + 1)
	hitbox = Area2D.new()
	hitbox.collision_layer = 4
	hitbox.collision_mask = 0
	hitbox.add_to_group("enemy_hitbox")
	var hs := CollisionShape2D.new()
	var hr := RectangleShape2D.new()
	hr.size = size + Vector2(2, 2)
	hs.shape = hr
	hs.position = cs.position
	hitbox.add_child(hs)
	add_child(hitbox)
	add_to_group("enemies")


func top_y() -> float:
	return global_position.y - body_size.y


func _physics_process(delta: float) -> void:
	if dead:
		return
	if not active:
		if level == null or level.is_near_view(global_position, activation_margin):
			active = true
			on_activated()
		else:
			return
	elif level and level.is_far_behind(global_position):
		return
	ai(delta)
	if level and global_position.y > level.kill_y():
		queue_free()


func on_activated() -> void:
	pass


## Default behaviour: walk, turn at walls (and optionally at ledges).
func ai(delta: float) -> void:
	walk(delta)


func walk(delta: float) -> void:
	if uses_gravity and not is_on_floor():
		velocity.y = min(velocity.y + gravity * delta, max_fall)
	velocity.x = dir * speed
	if turn_at_ledges and is_on_floor() and not _ground_ahead():
		dir = -dir
		velocity.x = dir * speed
	move_and_slide()
	if is_on_wall():
		dir = -dir
	_turn_from_others()
	sprite.flip_h = dir > 0


func _ground_ahead() -> bool:
	if level == null:
		return true
	var probe := global_position + Vector2(dir * (body_size.x / 2.0 + 2.0), 4.0)
	return level.is_solid_at(probe)


func _turn_from_others() -> void:
	for a in hitbox.get_overlapping_areas():
		if a.is_in_group("enemy_hitbox") and a != hitbox:
			var other := a.get_parent()
			if other is Enemy and not other.dead and other.uses_gravity:
				var side: float = signf(other.global_position.x - global_position.x)
				if side == dir:
					dir = -dir


func is_stompable_now() -> bool:
	return stompable


func on_player_contact(player: Player) -> void:
	if dead or not active:
		return
	if player.has_power("overload") or player.is_dashing():
		defeat("knock")
		return
	if player.is_stomping(top_y()):
		if is_stompable_now():
			player.bounce_off_enemy()
			stomped(player)
			return
		elif not hurts_on_stomp():
			player.bounce_off_enemy()
			return
	player.take_damage(global_position + Vector2(0, -body_size.y / 2.0))


## Enemies that are dangerous on top (e.g. charged slime) return true.
func hurts_on_stomp() -> bool:
	return false


func stomped(_player: Player) -> void:
	defeat("squash")


func defeat(how: String) -> void:
	if dead:
		return
	dead = true
	collision_mask = 0
	hitbox.set_deferred("monitorable", false)
	defeated.emit(self, how)
	if level:
		level.on_enemy_defeated(self, how)
	if how == "squash" and sprite.sprite_frames.has_animation(_anim_squash):
		sprite.play(_anim_squash)
		AudioManager.play_sfx("stomp")
		var t := create_tween()
		t.tween_interval(0.45)
		t.tween_property(sprite, "modulate:a", 0.0, 0.2)
		t.tween_callback(queue_free)
	else:
		AudioManager.play_sfx("kick")
		FX.spawn("puff", global_position + Vector2(0, -body_size.y / 2.0))
		sprite.flip_v = true
		var t := create_tween()
		var start := position
		t.tween_property(self, "position", start + Vector2(-dir * 24.0, -28.0), 0.25).set_ease(Tween.EASE_OUT)
		t.tween_property(self, "position", start + Vector2(-dir * 48.0, 240.0), 0.8).set_ease(Tween.EASE_IN)
		t.tween_callback(queue_free)
