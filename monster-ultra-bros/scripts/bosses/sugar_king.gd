extends Boss
## World 1 boss — SUGAR KING (The White Fortress).
##
## Pattern: a few hops toward the player, then a telegraphed big jump that
## slams down and sends shockwaves along the floor (jump over them). After
## the slam he is dizzy: that is the moment to stomp his head.
## Phase 2 adds sugar-cube minions, phase 3 chains two slams.

enum S { INTRO, IDLE, SQUAT, HOP, BIG_SQUAT, BIG_JUMP, STUNNED, HURT }
const SugarCube := preload("res://scripts/enemies/sugar_cube.gd")

var state := S.INTRO
var vel := Vector2.ZERO
var hops_left := 2
var slams_left := 1
var body: Node2D


func _ready() -> void:
	display_name = "SUGAR KING"
	max_hp = 3
	super._ready()
	sprite = SpriteLib.make_sprite("boss_sugar_king", "idle")
	sprite.position = Vector2(0, -24)
	add_child(sprite)
	body = add_part("body", Vector2(34, 32), Vector2(0, -17))
	position.y = arena.position.y - 40.0
	_t = 0.0


func _physics_process(delta: float) -> void:
	if dead:
		return
	_t -= delta
	var p := player()
	match state:
		S.INTRO:
			# fall into the arena
			vel.y = min(vel.y + 900.0 * delta, 500.0)
			position.y += vel.y * delta
			if position.y >= floor_y:
				position.y = floor_y
				vel = Vector2.ZERO
				FX.shake(4.0, 0.4)
				AudioManager.play_sfx("roar")
				state = S.IDLE
				_t = 1.0
		S.IDLE:
			sprite.play("idle")
			if _t <= 0.0:
				hops_left = 2 if phase() == 1 else 3
				state = S.SQUAT
				_t = 0.35 if phase() == 1 else 0.25
		S.SQUAT:
			sprite.play("squat")
			if _t <= 0.0:
				var dir := face_player()
				vel = Vector2(dir * (90.0 + 25.0 * phase()), -250.0)
				state = S.HOP
				sprite.play("jump")
		S.HOP, S.BIG_JUMP:
			vel.y = min(vel.y + 900.0 * delta, 600.0)
			position += vel * delta
			position.x = clamp_to_arena(position.x, 26.0)
			if position.y >= floor_y and vel.y > 0.0:
				position.y = floor_y
				_land(state == S.BIG_JUMP)
		S.BIG_SQUAT:
			sprite.play("squat")
			sprite.position.x = sin(_t * 70.0) * 1.5
			if _t <= 0.0:
				sprite.position.x = 0
				var target_x: float = p.global_position.x if p else position.x
				var air_time := 2.0 * 430.0 / 900.0
				vel = Vector2((clamp_to_arena(target_x, 26.0) - position.x) / air_time, -430.0)
				state = S.BIG_JUMP
				sprite.play("jump")
		S.STUNNED:
			sprite.play("stunned")
			if _t <= 0.0:
				_after_stun()
		S.HURT:
			sprite.play("hurt")
			vel.y = min(vel.y + 900.0 * delta, 600.0)
			position += vel * delta
			position.x = clamp_to_arena(position.x, 26.0)
			if position.y >= floor_y and vel.y > 0.0:
				position.y = floor_y
				vel = Vector2.ZERO
				if _t <= 0.0:
					state = S.IDLE
					_t = 0.5
	if p:
		sprite.flip_h = p.global_position.x > global_position.x


func _land(big: bool) -> void:
	vel = Vector2.ZERO
	FX.dust(global_position + Vector2(-16, 0), 2)
	FX.dust(global_position + Vector2(16, 0), 2)
	if big:
		AudioManager.play_sfx("slam")
		FX.shake(5.0, 0.4)
		Settings.haptic(80, 1.0)
		shockwave(-1, 120.0 + 20.0 * phase())
		shockwave(1, 120.0 + 20.0 * phase())
		slams_left -= 1
		if slams_left > 0:
			state = S.BIG_SQUAT
			_t = 0.45
		else:
			state = S.STUNNED
			_t = [1.9, 1.6, 1.3][phase() - 1]
			AudioManager.play_sfx("bump")
		return
	AudioManager.play_sfx("land", 0.1)
	FX.shake(1.5, 0.12)
	hops_left -= 1
	if hops_left > 0:
		state = S.SQUAT
		_t = 0.3 if phase() == 1 else 0.2
	else:
		slams_left = 2 if phase() == 3 else 1
		state = S.BIG_SQUAT
		_t = 0.75
		AudioManager.play_sfx("roar", 0.0, -4.0)


func _after_stun() -> void:
	if phase() >= 2:
		var cubes := 0
		for e in get_tree().get_nodes_in_group("enemies"):
			if e is Enemy and not e.dead:
				cubes += 1
		for i in range(min(2, 3 - cubes)):
			var c: Enemy = SugarCube.new()
			c.level = level
			c.position = Vector2(clamp_to_arena(position.x + (i * 2 - 1) * 40.0), arena.position.y + 20.0)
			level.entities.add_child(c)
	state = S.IDLE
	_t = 0.4


func on_part_contact(_part: String, p: Player) -> void:
	var top := global_position.y - 32.0
	if p.is_stomping(top):
		p.bounce_off_enemy()
		p.velocity.y = -330.0
		if state == S.STUNNED and hurt():
			if not dead:
				state = S.HURT
				_t = 0.6
				vel = Vector2(-face_player() * 140.0, -260.0)
		return
	if state == S.STUNNED:
		return   # walking into a dizzy king is harmless
	p.take_damage(global_position + Vector2(0, -16))
