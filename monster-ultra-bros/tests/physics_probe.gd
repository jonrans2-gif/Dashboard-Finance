extends Node2D
## Measures real jump height / distance of the Player on flat ground.

var p: Player
var results := []


func _ready() -> void:
	var floor_body := StaticBody2D.new()
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(20000, 32)
	cs.shape = r
	cs.position = Vector2(10000, 16)
	floor_body.add_child(cs)
	add_child(floor_body)
	await _measure("walk, full hold", 100.0, false, true)
	await _measure("run, full hold", 150.0, true, true)
	await _measure("tap", 100.0, false, false)
	for line in results:
		print(line)
	get_tree().quit()


func _measure(label: String, speed: float, run: bool, hold: bool) -> void:
	if p:
		p.queue_free()
	p = Player.new()
	p.position = Vector2(100, 0)
	add_child(p)
	p.external_input = {"right": true}
	# build up speed
	for i in (90 if run else 20):
		await get_tree().physics_frame
	var x0 := p.position.x
	var y0 := p.position.y
	p.external_input = {"right": true, "jump": hold, "jump_pressed": true}
	var min_y := y0
	var frames := 0
	await get_tree().physics_frame
	if not hold:
		p.external_input = {"right": true}
	while true:
		await get_tree().physics_frame
		frames += 1
		min_y = min(min_y, p.position.y)
		if p.is_on_floor() and frames > 3:
			break
	results.append("%s: vx=%.0f height=%.1f px (%.2f tiles) distance=%.1f px (%.2f tiles) airtime=%.2fs" % [
		label, speed, y0 - min_y, (y0 - min_y) / 16.0, p.position.x - x0, (p.position.x - x0) / 16.0, frames / 60.0])
