extends Boss
## World 2 boss — CRUSHER PRIME (The Machine Core).
##
## Hovers under the ceiling tracking the player, flashes red, then slams
## down. While it is stuck in the floor its top hatch opens and exposes the
## green core: jump on top of it and stomp the core.
## Phase 2: shockwaves on impact. Phase 3: fires an orb spread when rising.

enum S { TRACK, WARN, SLAM, STUCK, RISE }

var state := S.TRACK
var hover_y := 0.0
var vy := 0.0
var solid: AnimatableBody2D
var core: Node2D
var body: Node2D
var shadow: Sprite2D
const W := 60.0
const H := 50.0


func _ready() -> void:
	display_name = "CRUSHER PRIME"
	max_hp = 3
	super._ready()
	hover_y = arena.position.y + 72.0
	position.y = hover_y
	sprite = SpriteLib.make_sprite("boss_crusher_prime", "idle")
	sprite.position = Vector2(0, -28)
	add_child(sprite)
	# solid body so the player can stand on it while it is stuck
	solid = AnimatableBody2D.new()
	solid.collision_layer = 16
	solid.sync_to_physics = false
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(54, 38)
	cs.shape = r
	cs.position = Vector2(0, -19)
	cs.one_way_collision = true
	solid.add_child(cs)
	add_child(solid)
	body = add_part("body", Vector2(56, 36), Vector2(0, -19))
	core = add_part("core", Vector2(22, 10), Vector2(0, -43))
	shadow = Sprite2D.new()
	shadow.texture = SpriteLib.frame_texture("marker", "blink", 0)
	shadow.scale = Vector2(3.0, 1.0)
	shadow.top_level = true
	shadow.visible = false
	add_child(shadow)
	_t = 1.5


func _physics_process(delta: float) -> void:
	if dead:
		return
	_t -= delta
	var p := player()
	match state:
		S.TRACK:
			sprite.play("idle")
			if p:
				var target := clamp_to_arena(p.global_position.x, 34.0)
				position.x = move_toward(position.x, target, (55.0 + 20.0 * phase()) * delta)
			position.y = hover_y + sin(_t * 4.0) * 2.0
			if _t <= 0.0:
				state = S.WARN
				_t = 0.75 if phase() < 3 else 0.55
				AudioManager.play_sfx("charge", 0.0, -4.0)
		S.WARN:
			sprite.play("warn")
			sprite.position.x = sin(_t * 80.0) * 1.5
			shadow.visible = true
			shadow.global_position = Vector2(global_position.x, floor_y - 2.0)
			if _t <= 0.0:
				sprite.position.x = 0
				state = S.SLAM
				vy = 80.0
		S.SLAM:
			sprite.play("slam")
			vy = min(vy + 1700.0 * delta, 640.0)
			position.y = min(position.y + vy * delta, floor_y)
			if position.y >= floor_y:
				_impact()
		S.STUCK:
			sprite.play("open")
			if _t <= 0.0:
				state = S.RISE
				sprite.play("idle")
				if phase() == 3:
					for i in 5:
						var a := deg_to_rad(-150.0 + i * 30.0)
						shoot_orb(global_position + Vector2(0, -40), Vector2(cos(a), sin(a)) * 120.0, 160.0, "fly_green", 1)
		S.RISE:
			position.y = max(position.y - 70.0 * delta, hover_y)
			if position.y <= hover_y:
				state = S.TRACK
				_t = 1.4 if phase() == 1 else 1.0
	solid.position = Vector2.ZERO


func _impact() -> void:
	shadow.visible = false
	state = S.STUCK
	_t = [2.1, 1.8, 1.5][phase() - 1]
	AudioManager.play_sfx("slam")
	FX.shake(5.0, 0.4)
	Settings.haptic(80, 1.0)
	FX.dust(global_position + Vector2(-26, 0), 2)
	FX.dust(global_position + Vector2(26, 0), 2)
	if phase() >= 2:
		shockwave(-1, 140.0)
		shockwave(1, 140.0)


func on_part_contact(part: String, p: Player) -> void:
	if part == "core":
		if state == S.STUCK and p.is_stomping(global_position.y - 42.0):
			p.bounce_off_enemy()
			p.velocity.y = -360.0
			if hurt() and not dead:
				_t = 0.0   # rise right away after a hit
		return
	# body: only dangerous while slamming down, or from the side while moving
	if state == S.SLAM:
		p.take_damage(global_position + Vector2(0, -10))
	elif state in [S.TRACK, S.WARN, S.RISE] and not p.is_stomping(global_position.y - 40.0):
		p.take_damage(global_position + Vector2(0, -20))
