class_name Player
extends CharacterBody2D
## Monster Ultra White — player controller.
##
## Movement is tuned in pixels/second at 60 Hz physics. Key game-feel tools:
## momentum (walk -> run build-up), skidding, variable jump height, apex hang,
## coyote time, jump buffering, squash & stretch and landing dust.

signal died
signal hp_changed(hp: int)
signal powerups_changed

enum State { NORMAL, DASH, DEAD, GOAL, CUTSCENE }

# --- tuning -----------------------------------------------------------------
@export var walk_speed := 100.0
@export var run_speed := 150.0
@export var ground_accel := 720.0
@export var ground_decel := 900.0
@export var skid_decel := 1500.0
@export var air_accel := 520.0
@export var air_decel := 260.0
@export var run_build_time := 0.7        # seconds of running before reaching run_speed
@export var jump_velocity := 330.0
@export var run_jump_bonus := 22.0       # extra launch speed at full run
@export var double_jump_velocity := 300.0
@export var gravity_rise := 900.0        # while jump is held
@export var gravity_cut := 2300.0        # jump released early -> short hop
@export var gravity_fall := 1250.0
@export var apex_threshold := 45.0
@export var apex_gravity_mult := 0.55
@export var max_fall_speed := 390.0
@export var coyote_time := 0.1
@export var jump_buffer_time := 0.13
@export var stomp_bounce := 260.0
@export var stomp_bounce_held := 340.0
@export var dash_speed := 330.0
@export var dash_time := 0.22
@export var dash_cooldown := 0.45
@export var invuln_time := 1.4

const MAX_HP := 3
const BODY_SIZE := Vector2(10, 22)
const MEGA_SCALE := 1.5
const POWER_DURATION := {"boost": 15.0, "surge": 20.0, "mega": 20.0, "magnet": 20.0, "overload": 10.0}
const POWER_COLOR := {"boost": Color("39e6ff"), "shield": Color("8fe8ff"), "surge": Color("ff3fd8"),
	"mega": Color("ff8a5a"), "double": Color("7dff5a"), "magnet": Color("ffd23f"), "overload": Color.WHITE}

var level: Node = null
var state := State.NORMAL
var hp := MAX_HP
var facing := 1
var powerups: Dictionary = {}       # name -> seconds left (INF = until hit / level end)
var input_enabled := true
var external_input := {}            # tests can drive input: {"left":bool,...}

var _coyote := 0.0
var _jump_buffer := 0.0
var _jump_held := false
var _jumping := false
var _air_jumps_used := 0
var _run_charge := 0.0
var _invuln := 0.0
var _hurt_anim := 0.0
var _dash_t := 0.0
var _dash_cd := 0.0
var _was_on_floor := true
var _fall_peak := 0.0
var _landing_lock := 0.0
var _skidding := false
var _mega_pending := false
var _is_mega := false
var _afterimage_t := 0.0
var _glow_phase := 0.0
var _death_t := 0.0
var _last_floor_kind := ""
var _floor_tile := Vector2i(-1, -1)

var sprite: AnimatedSprite2D
var glow: Sprite2D
var shield_fx: Node2D
var shape: CollisionShape2D
var hurtbox: Area2D
var hurt_shape: CollisionShape2D
var visual_root: Node2D


func _ready() -> void:
	add_to_group("player")
	collision_layer = 2
	collision_mask = 1 | 16  # world + moving platforms
	floor_snap_length = 4.0
	floor_max_angle = deg_to_rad(50)
	safe_margin = 0.06
	floor_constant_speed = true
	platform_on_leave = CharacterBody2D.PLATFORM_ON_LEAVE_ADD_UPWARD_VELOCITY

	shape = CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = BODY_SIZE
	shape.shape = rect
	shape.position = Vector2(0, -BODY_SIZE.y / 2)
	add_child(shape)

	visual_root = Node2D.new()
	add_child(visual_root)
	glow = Sprite2D.new()
	glow.texture = SpriteLib.texture("res://assets/sprites/glow.png")
	glow.position = Vector2(0, -14)
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	glow.material = mat
	glow.visible = false
	visual_root.add_child(glow)
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = SpriteLib.frames("player")
	sprite.position = Vector2(0, -15)
	sprite.play("idle")
	visual_root.add_child(sprite)
	shield_fx = preload("res://scripts/player/shield_fx.gd").new()
	shield_fx.position = Vector2(0, -12)
	shield_fx.visible = false
	visual_root.add_child(shield_fx)

	hurtbox = Area2D.new()
	hurtbox.collision_layer = 2
	hurtbox.collision_mask = 4 | 8 | 32   # enemies, items, hazards
	hurtbox.monitorable = true
	hurt_shape = CollisionShape2D.new()
	var hr := RectangleShape2D.new()
	hr.size = BODY_SIZE - Vector2(2, 2)
	hurt_shape.shape = hr
	hurt_shape.position = shape.position
	hurtbox.add_child(hurt_shape)
	add_child(hurtbox)


# ------------------------------------------------------------------ input
func _input_dir() -> float:
	if not input_enabled:
		return 0.0
	if not external_input.is_empty():
		return float(external_input.get("right", false)) - float(external_input.get("left", false))
	return Input.get_axis("move_left", "move_right")


func _jump_pressed_now() -> bool:
	if not input_enabled:
		return false
	if not external_input.is_empty():
		return external_input.get("jump_pressed", false)
	return Input.is_action_just_pressed("jump")


func _jump_is_held() -> bool:
	if not input_enabled:
		return false
	if not external_input.is_empty():
		return external_input.get("jump", false)
	return Input.is_action_pressed("jump")


func _dash_pressed_now() -> bool:
	if not input_enabled:
		return false
	if not external_input.is_empty():
		return external_input.get("dash_pressed", false)
	return Input.is_action_just_pressed("dash")


# ------------------------------------------------------------------ main loop
func _physics_process(delta: float) -> void:
	match state:
		State.DEAD:
			_process_death(delta)
			return
		State.GOAL, State.CUTSCENE:
			_process_cutscene(delta)
			return
	_tick_timers(delta)
	_update_powerups(delta)
	if state == State.DASH:
		_process_dash(delta)
	else:
		_process_movement(delta)
	_check_contacts()
	_check_tiles_overlap()
	_update_animation(delta)
	if not external_input.is_empty():
		external_input["jump_pressed"] = false
		external_input["dash_pressed"] = false
	if level and global_position.y > level.kill_y():
		die("pit")


func _tick_timers(delta: float) -> void:
	_coyote = max(0.0, _coyote - delta)
	_jump_buffer = max(0.0, _jump_buffer - delta)
	_dash_cd = max(0.0, _dash_cd - delta)
	_landing_lock = max(0.0, _landing_lock - delta)
	_hurt_anim = max(0.0, _hurt_anim - delta)
	if _invuln > 0.0:
		_invuln -= delta
		visual_root.modulate.a = 0.25 if int(_invuln * 16.0) % 2 == 0 else 1.0
		if _invuln <= 0.0:
			visual_root.modulate.a = 1.0


func current_max_speed() -> float:
	var m := 1.0
	if has_power("boost"):
		m *= 1.4
	if has_power("overload"):
		m *= 1.3
	return lerp(walk_speed, run_speed, _run_charge) * m


func _process_movement(delta: float) -> void:
	var dir := _input_dir()
	var on_floor := is_on_floor()
	if _jump_pressed_now():
		_jump_buffer = jump_buffer_time
	_jump_held = _jump_is_held()

	# --- floor material
	var friction_mult := 1.0
	var push := 0.0
	var floor_kind := ""
	if on_floor and level:
		floor_kind = level.floor_kind_at(global_position + Vector2(0, 3))
		if floor_kind == "ice":
			friction_mult = 0.16
		elif floor_kind == "conveyor_left":
			push = -60.0
		elif floor_kind == "conveyor_right":
			push = 60.0
	_last_floor_kind = floor_kind

	# --- horizontal
	if dir != 0.0:
		facing = 1 if dir > 0 else -1
	var max_speed := current_max_speed()
	var target := dir * max_speed
	_skidding = false
	if on_floor:
		if dir != 0.0 and sign(velocity.x) != 0 and sign(velocity.x) != sign(dir) and abs(velocity.x) > 60.0:
			velocity.x = move_toward(velocity.x, target, skid_decel * delta * max(friction_mult, 0.35))
			_skidding = true
			_run_charge = max(0.0, _run_charge - delta * 3.0)
		elif dir != 0.0:
			var accel := ground_accel * (1.3 if has_power("boost") else 1.0)
			velocity.x = move_toward(velocity.x, target, accel * delta * max(friction_mult, 0.25))
		else:
			velocity.x = move_toward(velocity.x, 0.0, ground_decel * delta * friction_mult)
		# run build-up: keeps growing while running in one direction
		if dir != 0.0 and abs(velocity.x) >= walk_speed * 0.9 and not is_on_wall():
			_run_charge = min(1.0, _run_charge + delta / run_build_time)
		elif dir == 0.0 or is_on_wall():
			_run_charge = max(0.0, _run_charge - delta * 2.5)
	else:
		if dir != 0.0:
			velocity.x = move_toward(velocity.x, target, air_accel * delta)
		else:
			velocity.x = move_toward(velocity.x, 0.0, air_decel * delta)

	# --- jumping
	if on_floor:
		_coyote = coyote_time
		_air_jumps_used = 0
		_jumping = false
	if _jump_buffer > 0.0:
		if _coyote > 0.0:
			_do_jump(false)
		elif has_power("double") and _air_jumps_used == 0 and not on_floor:
			_air_jumps_used = 1
			_do_jump(true)

	# --- gravity
	var g := gravity_fall
	if velocity.y < 0.0:
		g = gravity_rise if (_jump_held or not _jumping) else gravity_cut
		if _jump_held and abs(velocity.y) < apex_threshold:
			g *= apex_gravity_mult
	elif _jump_held and velocity.y < apex_threshold:
		g = gravity_fall * apex_gravity_mult
	if not on_floor:
		velocity.y = min(velocity.y + g * delta, max_fall_speed)
		_fall_peak = max(_fall_peak, velocity.y)

	# --- dash
	if _dash_pressed_now() and can_dash() and _dash_cd <= 0.0:
		_start_dash()
		return

	_reveal_hidden_blocks(delta)
	var vy_before := velocity.y
	velocity.x += push
	move_and_slide()
	velocity.x -= push
	_after_move(vy_before)


func _do_jump(double: bool) -> void:
	_jump_buffer = 0.0
	_coyote = 0.0
	_jumping = true
	var v: float = jump_velocity + run_jump_bonus * clampf(absf(velocity.x) / run_speed, 0.0, 1.0)
	if double:
		v = double_jump_velocity
		FX.sparkle(global_position + Vector2(0, -4), 4, 6)
		AudioManager.play_sfx("jump2")
	else:
		AudioManager.play_sfx("jump", 0.04)
		FX.dust(global_position, 2)
	if has_power("overload"):
		v *= 1.08
	velocity.y = -v
	_squash(Vector2(0.82, 1.18))
	sprite.play("jump")


func _after_move(vy_before: float) -> void:
	var on_floor := is_on_floor()
	# Landing
	if on_floor and not _was_on_floor:
		if _fall_peak > 140.0:
			_squash(Vector2(1.25, 0.78))
			FX.dust(global_position + Vector2(-5, 0), 1)
			FX.dust(global_position + Vector2(5, 0), 1)
			AudioManager.play_sfx("land", 0.1, -4.0)
			_landing_lock = 0.12
			sprite.play("land")
		_fall_peak = 0.0
	_was_on_floor = on_floor
	# Head bump into blocks
	if is_on_ceiling() and vy_before < 0.0 and level:
		var head_y := global_position.y - body_height() - 2.0
		var hit := false
		for ox in [0.0, -body_width() * 0.45, body_width() * 0.45]:
			if level.hit_block_at(Vector2(global_position.x + ox, head_y), self):
				hit = true
				break
		if hit:
			velocity.y = max(velocity.y, 40.0)


func _reveal_hidden_blocks(delta: float) -> void:
	if velocity.y >= 0.0 or level == null:
		return
	var head_now := global_position.y - body_height()
	var head_next := head_now + velocity.y * delta
	for ox in [-body_width() * 0.4, body_width() * 0.4]:
		level.try_reveal_hidden(Vector2(global_position.x + ox, head_next), head_now)


func body_height() -> float:
	return BODY_SIZE.y * (MEGA_SCALE if _is_mega else 1.0)


func body_width() -> float:
	return BODY_SIZE.x * (MEGA_SCALE if _is_mega else 1.0)


func is_mega() -> bool:
	return _is_mega


# ------------------------------------------------------------------ dash
func can_dash() -> bool:
	return has_power("surge") or has_power("overload")


func _start_dash() -> void:
	state = State.DASH
	_dash_t = dash_time
	_dash_cd = dash_cooldown + dash_time
	velocity = Vector2(facing * dash_speed, 0)
	AudioManager.play_sfx("dash")
	Settings.haptic(25, 0.5)
	FX.dust(global_position, 2)
	sprite.play("dash")


func _process_dash(delta: float) -> void:
	_dash_t -= delta
	velocity.y = 0.0
	velocity.x = facing * dash_speed
	if level:
		var front := global_position.x + facing * (body_width() * 0.5 + 4.0)
		for oy in [-2.0, -body_height() * 0.5, -body_height() + 2.0]:
			level.dash_break_at(Vector2(front, global_position.y + oy))
	move_and_slide()
	_afterimage_t -= delta
	if _afterimage_t <= 0.0:
		_afterimage_t = 0.04
		_spawn_afterimage()
	if _dash_t <= 0.0 or is_on_wall():
		state = State.NORMAL
		velocity.x = facing * current_max_speed()
		_run_charge = 1.0
	_was_on_floor = is_on_floor()


func is_dashing() -> bool:
	return state == State.DASH


func _spawn_afterimage() -> void:
	if level == null:
		return
	var s := Sprite2D.new()
	s.texture = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	s.flip_h = sprite.flip_h
	s.global_position = sprite.global_position
	s.scale = sprite.scale * visual_root.scale
	s.modulate = Color(POWER_COLOR.get("surge"), 0.55)
	s.z_index = -1
	level.fx_root.add_child(s)
	var t := s.create_tween()
	t.tween_property(s, "modulate:a", 0.0, 0.22)
	t.tween_callback(s.queue_free)


# ------------------------------------------------------------------ contacts
func _check_contacts() -> void:
	for area in hurtbox.get_overlapping_areas():
		var owner_node := area.get_parent()
		if owner_node == null or not is_instance_valid(owner_node):
			continue
		if area.is_in_group("enemy_hitbox") and owner_node.has_method("on_player_contact"):
			owner_node.on_player_contact(self)
			if state == State.DEAD:
				return
		elif area.is_in_group("hazard") and owner_node.has_method("is_harmful"):
			if owner_node.is_harmful():
				take_damage(area.global_position)
		elif area.is_in_group("hazard"):
			take_damage(area.global_position)


func _check_tiles_overlap() -> void:
	if level == null or state == State.DEAD:
		return
	var r := Rect2(global_position.x - body_width() * 0.4, global_position.y - body_height() * 0.9,
		body_width() * 0.8, body_height() * 0.9)
	var hazard: String = level.hazard_in_rect(r)
	if hazard == "goo":
		AudioManager.play_sfx("splash")
		die("goo")
	elif hazard == "spikes":
		if take_damage(Vector2(global_position.x, global_position.y + 8)):
			velocity.y = -280.0
	level.update_secret_walls(r)


## Called by enemies when the player lands on them from above.
func is_stomping(enemy_top_y: float) -> bool:
	return velocity.y > -20.0 and global_position.y - 4.0 <= enemy_top_y + 4.0 + max(velocity.y, 0.0) / 60.0


func bounce_off_enemy() -> void:
	velocity.y = -(stomp_bounce_held if _jump_is_held() else stomp_bounce)
	_jumping = _jump_is_held()   # releasing jump later still cuts the bounce short
	_air_jumps_used = 0
	_squash(Vector2(1.15, 0.85))
	Settings.haptic(18, 0.4)


func is_invulnerable() -> bool:
	return _invuln > 0.0 or has_power("overload") or state != State.NORMAL and state != State.DASH


## Returns true if damage was applied (or absorbed by a power-up).
func take_damage(from: Vector2, amount := 1) -> bool:
	if state == State.DEAD or state == State.GOAL or state == State.CUTSCENE:
		return false
	if _invuln > 0.0 or has_power("overload"):
		return false
	var away: float = signf(global_position.x - from.x)
	if away == 0:
		away = -facing
	velocity = Vector2(away * 140.0, -190.0)
	_hurt_anim = 0.35
	Settings.haptic(60, 0.8)
	FX.shake(2.5, 0.2)
	if has_power("shield"):
		remove_power("shield")
		AudioManager.play_sfx("shield_break")
		FX.sparkle(global_position + Vector2(0, -12), 6, 12)
		_invuln = 1.0
		return true
	if _is_mega:
		remove_power("mega")
		_invuln = invuln_time
		return true
	hp -= amount
	hp_changed.emit(hp)
	AudioManager.play_sfx("hurt")
	if hp <= 0:
		die("hit")
	else:
		_invuln = invuln_time
	return true


func heal_full() -> void:
	hp = MAX_HP
	hp_changed.emit(hp)


func die(reason := "") -> void:
	if state == State.DEAD:
		return
	state = State.DEAD
	hp = 0
	hp_changed.emit(hp)
	_death_t = 0.0
	velocity = Vector2(0, -300.0 if reason != "pit" else 0.0)
	collision_mask = 0
	hurtbox.set_deferred("monitoring", false)
	visual_root.modulate.a = 1.0
	glow.visible = false
	shield_fx.visible = false
	sprite.play("death")
	sprite.scale = Vector2.ONE * (MEGA_SCALE if _is_mega else 1.0)
	AudioManager.stop_music(0.2)
	AudioManager.play_sfx("death")
	Settings.haptic(120, 1.0)
	FX.shake(3.0, 0.3)
	died.emit()


func _process_death(delta: float) -> void:
	_death_t += delta
	if _death_t < 0.45:
		return   # freeze-frame, Mario style
	velocity.y = min(velocity.y + 900.0 * delta, 500.0)
	global_position += velocity * delta
	visual_root.rotation += delta * 4.0 * facing


func death_finished() -> bool:
	return state == State.DEAD and _death_t > 2.2


# ------------------------------------------------------------------ cutscenes
func enter_goal_state() -> void:
	state = State.GOAL
	velocity = Vector2.ZERO
	_invuln = 0.0
	visual_root.modulate.a = 1.0


func enter_cutscene() -> void:
	state = State.CUTSCENE
	velocity.x = 0.0


func leave_cutscene() -> void:
	if state == State.CUTSCENE or state == State.GOAL:
		state = State.NORMAL


var cutscene_walk := 0.0   # set by scripted sequences (goal walk, doors)


func _process_cutscene(delta: float) -> void:
	velocity.x = cutscene_walk
	if cutscene_walk != 0.0:
		facing = 1 if cutscene_walk > 0 else -1
	if not is_on_floor():
		velocity.y = min(velocity.y + gravity_fall * delta, max_fall_speed)
	move_and_slide()
	_update_animation(delta)


func play_victory() -> void:
	sprite.play("victory")


# ------------------------------------------------------------------ power-ups
func has_power(p: String) -> bool:
	return powerups.has(p)


func add_power(p: String) -> void:
	match p:
		"shield", "double":
			powerups[p] = INF
		"mega":
			powerups[p] = POWER_DURATION[p]
			_mega_pending = true
		_:
			powerups[p] = POWER_DURATION.get(p, 15.0)
	if p == "overload":
		AudioManager.set_music_pitch(1.08)
	AudioManager.play_sfx("grow" if p == "mega" else "powerup")
	Settings.haptic(40, 0.6)
	FX.sparkle(global_position + Vector2(0, -14), 8, 14)
	if level:
		level.camera_punch(0.06)
	powerups_changed.emit()


func remove_power(p: String) -> void:
	if not powerups.has(p):
		return
	powerups.erase(p)
	if p == "mega":
		_set_mega(false)
	if p == "overload":
		AudioManager.set_music_pitch(1.0)
	powerups_changed.emit()


func clear_powers(keep_permanent := false) -> void:
	for p in powerups.keys():
		if keep_permanent and powerups[p] == INF:
			continue
		remove_power(p)


func power_time_left(p: String) -> float:
	return powerups.get(p, 0.0)


func _update_powerups(delta: float) -> void:
	var expired: Array = []
	for p in powerups.keys():
		if powerups[p] != INF:
			powerups[p] -= delta
			if powerups[p] <= 0.0:
				expired.append(p)
	for p in expired:
		remove_power(p)
	if _mega_pending:
		_try_grow()
	# visuals
	_glow_phase += delta
	var glow_on := not powerups.is_empty() and not (powerups.size() == 1 and has_power("shield"))
	glow.visible = glow_on
	if glow_on:
		var col := Color.WHITE
		if has_power("overload"):
			col = Color.from_hsv(fmod(_glow_phase * 1.5, 1.0), 0.6, 1.0)
		else:
			for p in ["surge", "boost", "magnet", "double", "mega"]:
				if has_power(p):
					col = POWER_COLOR[p].lerp(Color.WHITE, 0.45)
					break
		var expiring := false
		for p in powerups.keys():
			if powerups[p] != INF and powerups[p] < 3.0:
				expiring = true
		var pulse := 0.55 + 0.25 * sin(_glow_phase * (18.0 if expiring else 5.0))
		glow.modulate = Color(col, pulse)
		glow.scale = Vector2.ONE * (MEGA_SCALE if _is_mega else 1.0)
	shield_fx.visible = has_power("shield")
	if has_power("overload"):
		sprite.modulate = Color.from_hsv(fmod(_glow_phase * 2.0, 1.0), 0.25, 1.0)
	else:
		sprite.modulate = Color.WHITE


func _try_grow() -> void:
	# Grow only when there is head room, so the can never ends up inside a ceiling.
	var extra := BODY_SIZE.y * (MEGA_SCALE - 1.0)
	if test_move(global_transform, Vector2(0, -extra - 1.0)):
		return
	_mega_pending = false
	_set_mega(true)


func _set_mega(on: bool) -> void:
	if _is_mega == on:
		return
	_is_mega = on
	var s := MEGA_SCALE if on else 1.0
	(shape.shape as RectangleShape2D).size = BODY_SIZE * s
	shape.position = Vector2(0, -BODY_SIZE.y * s / 2.0)
	(hurt_shape.shape as RectangleShape2D).size = (BODY_SIZE - Vector2(2, 2)) * s
	hurt_shape.position = shape.position
	sprite.position = Vector2(0, -15 * s)
	sprite.scale = Vector2.ONE * s
	glow.position = Vector2(0, -14 * s)
	shield_fx.position = Vector2(0, -12 * s)
	shield_fx.scale = Vector2.ONE * s
	if not on:
		AudioManager.play_sfx("shrink")
	_squash(Vector2(1.2, 0.8) if on else Vector2(0.8, 1.2))


# ------------------------------------------------------------------ visuals
func _squash(amount: Vector2) -> void:
	var base := Vector2.ONE * (MEGA_SCALE if _is_mega else 1.0)
	sprite.scale = base * amount
	var t := create_tween()
	t.tween_property(sprite, "scale", base, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _update_animation(_delta: float) -> void:
	sprite.flip_h = facing < 0
	if state == State.DEAD:
		return
	if state == State.GOAL:
		if cutscene_walk == 0.0 and is_on_floor():
			if sprite.animation != "victory":
				sprite.play("victory")
		elif is_on_floor():
			sprite.play("run")
		return
	if state == State.DASH:
		sprite.play("dash")
		return
	var anim := ""
	if _hurt_anim > 0.0:
		anim = "hurt"
	elif is_on_floor():
		if _skidding:
			anim = "skid"
		elif abs(velocity.x) > 12.0:
			anim = "run"
		elif _landing_lock > 0.0:
			anim = "land"
		else:
			anim = "idle"
	else:
		anim = "jump" if velocity.y < 0.0 else "fall"
	if anim != sprite.animation:
		sprite.play(anim)
	if anim == "run":
		sprite.speed_scale = clamp(abs(velocity.x) / 110.0, 0.6, 1.8)
		# lean into the run
		visual_root.rotation = lerp_angle(visual_root.rotation, deg_to_rad(5.0 * facing * clamp(abs(velocity.x) / run_speed, 0.0, 1.0)), 0.25)
	else:
		sprite.speed_scale = 1.0
		visual_root.rotation = lerp_angle(visual_root.rotation, 0.0, 0.3)
