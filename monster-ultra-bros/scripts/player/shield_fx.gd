extends Node2D
## White Shield bubble drawn around the can.

var _t := 0.0


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var r := 15.0 + sin(_t * 6.0) * 0.8
	draw_circle(Vector2.ZERO, r, Color(0.75, 0.93, 1.0, 0.16))
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 32, Color(0.85, 0.97, 1.0, 0.85), 1.0)
	var a := _t * 2.5
	draw_arc(Vector2.ZERO, r - 3.0, a, a + 1.2, 8, Color(1, 1, 1, 0.9), 1.0)
