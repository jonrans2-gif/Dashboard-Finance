extends Control
## Level progress strip: start -> checkpoints -> goal, with the can's position.

var level: Node


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var w := size.x
	var y := size.y / 2.0
	draw_rect(Rect2(0, y - 1, w, 3), Color("101018"))
	draw_rect(Rect2(1, y, w - 2, 1), Color("5f6676"))
	if level == null or level.player == null or level.goal == null:
		return
	var start_x: float = level.start_pos.x
	var end_x: float = level.goal.global_position.x
	var span: float = max(1.0, end_x - start_x)
	for cp in level.checkpoints:
		var cx: float = clamp((cp.position.x - start_x) / span, 0.0, 1.0) * w
		draw_rect(Rect2(cx - 1, y - 2, 2, 5), Color("7dff5a") if cp.active else Color("8d94a3"))
	draw_rect(Rect2(w - 2, y - 3, 2, 7), Color("ffd23f"))
	var px: float = clamp((level.player.global_position.x - start_x) / span, 0.0, 1.0)
	draw_rect(Rect2(1, y, (w - 2) * px, 1), Color("ffffff"))
	draw_rect(Rect2(px * (w - 4), y - 3, 4, 7), Color("101018"))
	draw_rect(Rect2(px * (w - 4) + 1, y - 2, 2, 5), Color("ffffff"))
