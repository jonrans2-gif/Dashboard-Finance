class_name GameCamera
extends Camera2D
## Follows the player with a horizontal dead zone + look-ahead, smooths
## movement, never leaves the level bounds and supports shake/zoom punches.
## When the screen is taller than the level (portrait, tablets) the level is
## framed in the upper part so the touch controls sit on the ground filler.

var target: Node2D
var bounds := Rect2(0, 0, 480, 272)     # level rect in pixels
var lock_rect := Rect2()                # boss arena lock (empty = none)
var dead_zone := 22.0
var look_ahead := 34.0
var smooth := 7.0
var vertical_dead := 36.0

var _look := 0.0
var _focus := Vector2.ZERO
var _shake := 0.0
var _shake_time := 0.0
var _zoom_tween: Tween


func _ready() -> void:
	process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	position_smoothing_enabled = false
	FX.shake_requested.connect(shake)


func view_size() -> Vector2:
	return get_viewport_rect().size / zoom


func snap_to_target() -> void:
	if target:
		_focus = target.global_position
		_look = 0.0
		global_position = _clamped(_desired())


func _desired() -> Vector2:
	return Vector2(_focus.x + _look, _focus.y - 24.0)


func _physics_process(delta: float) -> void:
	if target == null or not is_instance_valid(target):
		return
	var tp := target.global_position
	# horizontal dead zone around the focus point
	if tp.x > _focus.x + dead_zone:
		_focus.x = tp.x - dead_zone
	elif tp.x < _focus.x - dead_zone:
		_focus.x = tp.x + dead_zone
	# vertical: stay within a comfort band, re-centre smoothly when grounded
	var grounded: bool = target.has_method("is_on_floor") and target.is_on_floor()
	if abs(tp.y - _focus.y) > vertical_dead:
		_focus.y = tp.y - sign(tp.y - _focus.y) * vertical_dead
	elif grounded:
		_focus.y = lerp(_focus.y, tp.y, 1.0 - exp(-delta * 5.0))
	# look-ahead in the movement direction
	var vx: float = target.velocity.x if "velocity" in target else 0.0
	var want_look: float = clamp(vx / 150.0, -1.0, 1.0) * look_ahead
	_look = lerp(_look, want_look, 1.0 - exp(-delta * 1.8))
	var goal := _clamped(_desired())
	global_position = global_position.lerp(goal, 1.0 - exp(-delta * smooth))
	global_position = _clamped(global_position)
	# shake
	if _shake_time > 0.0:
		_shake_time -= delta
		offset = Vector2(randf_range(-_shake, _shake), randf_range(-_shake, _shake))
		if _shake_time <= 0.0:
			offset = Vector2.ZERO
	else:
		offset = Vector2.ZERO


func _clamped(p: Vector2) -> Vector2:
	var r := lock_rect if lock_rect.size != Vector2.ZERO else bounds
	var v := view_size()
	var out := p
	if r.size.x <= v.x:
		out.x = r.position.x + r.size.x / 2.0
	else:
		out.x = clamp(p.x, r.position.x + v.x / 2.0, r.end.x - v.x / 2.0)
	if bounds.size.y >= v.y:
		out.y = clamp(p.y, bounds.position.y + v.y / 2.0, bounds.end.y - v.y / 2.0)
	else:
		# Screen taller than the level: keep the level ground above the controls.
		var extra: float = clamp(v.y - bounds.size.y, 0.0, v.y * 0.34)
		out.y = bounds.end.y + extra - v.y / 2.0
	return out


func shake(strength: float, duration: float) -> void:
	_shake = max(_shake if _shake_time > 0.0 else 0.0, strength)
	_shake_time = max(_shake_time, duration)


## Short zoom-in pulse to emphasise an event (power-up, boss hit...).
func punch(amount := 0.08, duration := 0.35) -> void:
	if _zoom_tween:
		_zoom_tween.kill()
	zoom = Vector2.ONE * (1.0 + amount)
	_zoom_tween = create_tween()
	_zoom_tween.tween_property(self, "zoom", Vector2.ONE, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func visible_rect() -> Rect2:
	var v := view_size()
	return Rect2(global_position - v / 2.0, v)
