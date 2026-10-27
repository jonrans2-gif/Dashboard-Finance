extends Node2D
## Ceiling-mounted emitter that fires an electric beam down to the floor on
## a fixed rhythm. It flickers before firing so the timing can be read.

var level: Node
var on_time := 1.4
var off_time := 1.8
var offset := 0.0
var _t := 0.0
var _on := false
var _beam_len := 16.0
var _emitter: AnimatedSprite2D
var _beam: Node2D
var _area: Area2D
var _beam_sprites: Array = []


func _ready() -> void:
	_emitter = SpriteLib.make_sprite("zapper", "off")
	_emitter.flip_v = true
	_emitter.position = Vector2(0, 8)
	add_child(_emitter)
	# measure beam length down to the first solid tile
	var y := 16.0
	while y < 16.0 * 14.0 and level and not level.is_solid_at(global_position + Vector2(0, y + 2.0)):
		y += 16.0
	_beam_len = y - 12.0
	_beam = Node2D.new()
	add_child(_beam)
	var n := int(ceil(_beam_len / 16.0))
	for i in n:
		var s := SpriteLib.make_sprite("beam", "zap")
		s.position = Vector2(0, 12 + 8 + i * 16)
		s.frame = i % 3
		_beam.add_child(s)
		_beam_sprites.append(s)
	_area = Area2D.new()
	_area.collision_layer = 32
	_area.collision_mask = 0
	_area.add_to_group("hazard")
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(6, _beam_len)
	cs.shape = r
	cs.position = Vector2(0, 12 + _beam_len / 2.0)
	_area.add_child(cs)
	add_child(_area)
	_t = -offset
	_set_on(false)


func is_harmful() -> bool:
	return _on


func _physics_process(delta: float) -> void:
	_t += delta
	var cycle := on_time + off_time
	var p := fposmod(_t, cycle)
	var want := p < on_time
	if want != _on:
		_set_on(want)
		if want and level and level.is_near_view(global_position, 0.0):
			AudioManager.play_sfx("zap", 0.1, -6.0)
	# warning flicker during the last 0.5 s before firing
	if not _on:
		var until := cycle - p
		_emitter.play("on" if until < 0.5 and int(until * 16) % 2 == 0 else "off")
		_beam.visible = until < 0.5 and int(until * 16) % 2 == 0
		_beam.modulate.a = 0.3


func _set_on(on: bool) -> void:
	_on = on
	_beam.visible = on
	_beam.modulate.a = 1.0
	_emitter.play("on" if on else "off")
