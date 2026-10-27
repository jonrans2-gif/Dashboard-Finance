extends Boss
## Final boss — THE OVERLOAD CORE (The Final Overload).
##
## A giant, damaged energy machine anchored at the right side of the arena.
## * Laser sweep across the arena, LOW (jump) or HIGH (stay down), shown by a
##   thin aiming line before it fires.
## * Energy orb volleys that bounce once.
## * Phase 2+: launches Energy Drones. Phase 3: double lasers, faster.
## After two attacks it overheats: the central core opens. Jump (or dash)
## into the open green core to damage it. Touching the hull hurts.

enum S { INTRO, PICK, CHARGE_LASER, LASER, ORBS, DRONES, OVERHEAT, HURT }
const Drone := preload("res://scripts/enemies/energy_drone.gd")

var state := S.INTRO
var attacks_done := 0
var laser_low := true
var lasers_left := 1
var hull: Node2D
var core: Node2D
var _beam: Line2D
var _beam_on := false
var _core_open := false


func _ready() -> void:
	display_name = "THE OVERLOAD CORE"
	max_hp = 6
	super._ready()
	sprite = SpriteLib.make_sprite("boss_overload_core", "idle")
	sprite.position = Vector2(0, -48)
	add_child(sprite)
	hull = add_part("hull", Vector2(56, 92), Vector2(17, -46))
	core = add_part("core", Vector2(30, 30), Vector2(-26, -38))
	_beam = Line2D.new()
	_beam.width = 1.0
	_beam.default_color = Color(1, 0.3, 0.8, 0.8)
	_beam.visible = false
	_beam.top_level = true
	add_child(_beam)
	_t = 1.6


func _physics_process(delta: float) -> void:
	if dead:
		return
	_t -= delta
	match state:
		S.INTRO:
			sprite.play("idle")
			if _t <= 0.0:
				AudioManager.play_sfx("roar")
				FX.shake(4.0, 0.5)
				state = S.PICK
				_t = 0.4
		S.PICK:
			sprite.play("idle")
			if _t <= 0.0:
				_pick()
		S.CHARGE_LASER:
			sprite.play("charge")
			_beam.visible = int(_t * 14) % 2 == 0
			if _t <= 0.0:
				_fire_laser()
		S.LASER:
			sprite.play("charge")
			_check_beam_hit()
			if _t <= 0.0:
				_stop_laser()
				lasers_left -= 1
				if lasers_left > 0:
					laser_low = not laser_low
					_aim_laser()
				else:
					_attack_finished()
		S.ORBS:
			if _t <= 0.0:
				_attack_finished()
		S.DRONES:
			if _t <= 0.0:
				_attack_finished()
		S.OVERHEAT:
			sprite.play("open")
			if int(_t * 6) % 2 == 0:
				FX.spawn("dust", global_position + Vector2(randf_range(-30, 30), -92))
			if _t <= 0.0:
				_core_open = false
				state = S.PICK
				_t = 0.6
		S.HURT:
			sprite.play("hurt")
			if _t <= 0.0:
				_core_open = false
				state = S.PICK
				_t = 0.8


func _pick() -> void:
	var options := [0, 1]
	if phase() >= 2:
		options.append(2)
	match options[attacks_done % options.size()]:
		0:
			lasers_left = 2 if phase() == 3 else 1
			laser_low = randf() < 0.5
			_aim_laser()
		1:
			state = S.ORBS
			_t = 1.2
			var n := 2 + phase()
			for i in n:
				var a := deg_to_rad(-160.0 + i * (50.0 / max(1, n - 1)))
				shoot_orb(global_position + Vector2(-40, -60), Vector2(cos(a), sin(a)) * randf_range(140, 190), 260.0, "fly_pink", 1)
			AudioManager.play_sfx("shoot")
		2:
			state = S.DRONES
			_t = 1.0
			var alive := 0
			for e in get_tree().get_nodes_in_group("enemies"):
				if e is Enemy and not e.dead:
					alive += 1
			if alive < 2:
				var d: Enemy = Drone.new()
				d.level = level
				d.position = Vector2(arena.get_center().x - 40.0, arena.position.y + 60.0)
				level.entities.add_child(d)
				AudioManager.play_sfx("powerup_appear")


func _aim_laser() -> void:
	state = S.CHARGE_LASER
	_t = 0.85 if phase() < 3 else 0.65
	var y := _beam_y()
	_beam.points = PackedVector2Array([Vector2(arena.position.x, y), Vector2(global_position.x - 40.0, y)])
	_beam.width = 1.0
	_beam.default_color = Color(1, 0.4, 0.85, 0.9)
	_beam.visible = true
	AudioManager.play_sfx("charge")


func _beam_y() -> float:
	return floor_y - (8.0 if laser_low else 32.0)


func _fire_laser() -> void:
	state = S.LASER
	_t = 0.55
	_beam.visible = true
	_beam.width = 6.0
	_beam.default_color = Color(1, 0.75, 0.95)
	_beam_on = true
	AudioManager.play_sfx("zap")
	FX.shake(2.5, 0.5)


func _check_beam_hit() -> void:
	var p := player()
	if p == null:
		return
	var y := _beam_y()
	var top := p.global_position.y - p.body_height()
	if p.global_position.x < global_position.x - 40.0 and top < y + 3.0 and p.global_position.y > y - 3.0:
		p.take_damage(Vector2(p.global_position.x + 10.0, y))


func _stop_laser() -> void:
	_beam.visible = false
	_beam_on = false


func _attack_finished() -> void:
	attacks_done += 1
	if attacks_done % 2 == 0:
		state = S.OVERHEAT
		_core_open = true
		_t = [2.8, 2.4, 2.0][phase() - 1]
		AudioManager.play_sfx("shield_break")
	else:
		state = S.PICK
		_t = 0.5


func on_part_contact(part: String, p: Player) -> void:
	if part == "core" and _core_open:
		if hurt():
			p.velocity = Vector2(-220.0, -240.0)
			if not dead:
				state = S.HURT
				_t = 1.0
				_stop_laser()
		return
	if part == "hull" or (part == "core" and not _core_open):
		if p.is_dashing() or p.has_power("overload"):
			p.velocity.x = -200.0
			return
		p.take_damage(global_position + Vector2(0, -40))
