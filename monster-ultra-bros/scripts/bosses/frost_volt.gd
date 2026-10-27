extends Boss
## World 3 boss — FROST VOLT (The Storm Bridge).
##
## A flying storm cloud with an electric core.
## * Swoop: crosses the arena either LOW (jump over it) or HIGH (stay on the
##   ground). Its eye colour and the height it lines up at announce which.
## * Lightning: target markers blink on the floor, then bolts strike them.
##   Afterwards it is drained and sinks low with its core exposed — stomp it!
## * Phase 2+: icicle rain between attacks.

enum S { FLOAT, SWOOP_PREP, SWOOP, LIGHTNING, STRIKE, DRAINED, HURT, ICICLES }
const Icicle := preload("res://scripts/level/objects/icicle.gd")

var state := S.FLOAT
var home := Vector2.ZERO
var swoop_low := true
var swoop_dir := 1
var targets: Array = []
var attack_i := 0
var body: Node2D


func _ready() -> void:
	display_name = "FROST VOLT"
	max_hp = 4
	super._ready()
	home = Vector2(arena.get_center().x, arena.position.y + 70.0)
	position = Vector2(arena.end.x + 40.0, home.y)
	sprite = SpriteLib.make_sprite("boss_frost_volt", "idle")
	sprite.position = Vector2(0, -20)
	add_child(sprite)
	body = add_part("body", Vector2(36, 24), Vector2(0, -20))
	_t = 1.2


func _physics_process(delta: float) -> void:
	if dead:
		return
	_t -= delta
	var p := player()
	match state:
		S.FLOAT:
			sprite.play("idle")
			var goal := home + Vector2(sin(Time.get_ticks_msec() / 700.0) * 60.0, sin(Time.get_ticks_msec() / 400.0) * 6.0)
			position = position.lerp(goal, 1.0 - exp(-delta * 2.5))
			if _t <= 0.0:
				_next_attack()
		S.SWOOP_PREP:
			sprite.play("charge")
			var side_x := arena.position.x + 40.0 if swoop_dir > 0 else arena.end.x - 24.0
			var y := floor_y + 2.0 if swoop_low else floor_y - 54.0
			position = position.lerp(Vector2(side_x, y), 1.0 - exp(-delta * 4.0))
			sprite.modulate = Color(0.6, 1.2, 1.6) if swoop_low else Color(1.6, 1.3, 0.6)
			if _t <= 0.0:
				sprite.modulate = Color.WHITE
				state = S.SWOOP
				AudioManager.play_sfx("dash")
		S.SWOOP:
			position.x += swoop_dir * (190.0 + 30.0 * phase()) * delta
			if (swoop_dir > 0 and position.x > arena.end.x - 20.0) or (swoop_dir < 0 and position.x < arena.position.x + 36.0):
				state = S.FLOAT
				_t = 0.8
		S.LIGHTNING:
			sprite.play("charge")
			position = position.lerp(Vector2(arena.get_center().x, arena.position.y + 52.0), 1.0 - exp(-delta * 3.0))
			if _t <= 0.0:
				for x in targets:
					bolt(x, 0.45)
				state = S.STRIKE
				_t = 0.5
		S.STRIKE:
			if _t <= 0.0:
				state = S.DRAINED
				_t = [2.0, 1.7, 1.4][phase() - 1]
				AudioManager.play_sfx("shrink")
		S.DRAINED:
			sprite.play("stunned")
			var low := Vector2(position.x, floor_y - 30.0)
			position = position.lerp(low, 1.0 - exp(-delta * 4.0))
			if _t <= 0.0:
				state = S.FLOAT
				_t = 0.8
		S.HURT:
			sprite.play("hurt")
			position = position.lerp(home, 1.0 - exp(-delta * 3.0))
			if _t <= 0.0:
				state = S.FLOAT
				_t = 0.6
		S.ICICLES:
			sprite.play("charge")
			if _t <= 0.0:
				state = S.FLOAT
				_t = 1.0
	if p and state != S.SWOOP:
		sprite.flip_h = p.global_position.x > global_position.x


func _next_attack() -> void:
	var p := player()
	attack_i += 1
	var seq := [0, 0, 1] if phase() == 1 else [0, 2, 1]
	match seq[attack_i % seq.size()]:
		0:
			swoop_low = randf() < 0.5
			swoop_dir = 1 if (p and p.global_position.x > arena.get_center().x) else -1
			swoop_dir = -swoop_dir if randf() < 0.3 else swoop_dir
			state = S.SWOOP_PREP
			_t = 0.9
			AudioManager.play_sfx("charge")
		1:
			targets.clear()
			var n := 1 + phase()
			if p:
				targets.append(clamp_to_arena(p.global_position.x))
			while targets.size() < n:
				targets.append(randf_range(arena.position.x + 40.0, arena.end.x - 24.0))
			for x in targets:
				marker(x, 1.0)
			state = S.LIGHTNING
			_t = 1.0
			AudioManager.play_sfx("charge")
		2:
			for i in 4 + phase():
				var ic := Icicle.new()
				ic.level = level
				var x := randf_range(arena.position.x + 32.0, arena.end.x - 20.0)
				ic.position = Vector2(x, arena.position.y + 4.0)
				level.entities.add_child(ic)
				marker(x, 1.2)
			state = S.ICICLES
			_t = 1.6


func on_part_contact(_part: String, p: Player) -> void:
	if p.is_stomping(global_position.y - 30.0):
		p.bounce_off_enemy()
		p.velocity.y = -340.0
		if state == S.DRAINED and hurt() and not dead:
			state = S.HURT
			_t = 1.0
		return
	if state != S.DRAINED and state != S.HURT:
		p.take_damage(global_position + Vector2(0, -20))
