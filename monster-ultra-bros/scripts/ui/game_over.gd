extends CanvasLayer
## Game over screen (all lives lost).


func _ready() -> void:
	layer = 70
	process_mode = Node.PROCESS_MODE_ALWAYS
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	var bg := UITheme.dim_background(root, 0.0)
	var t := create_tween()
	t.tween_property(bg, "color:a", 0.85, 0.6)
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_CENTER)
	v.position = Vector2(-90, -60)
	v.custom_minimum_size = Vector2(180, 0)
	v.add_theme_constant_override("separation", 8)
	root.add_child(v)
	v.add_child(UITheme.label("GAME OVER", 30, Color("ff6a6a")))
	v.add_child(UITheme.label("The can ran out of energy...", 10, UITheme.C_DIM))
	v.add_child(UITheme.label("SCORE %d" % GameState.score, 10, Color.WHITE))
	var retry := UITheme.button("RETRY LEVEL", GameState.retry_after_game_over, 160)
	v.add_child(retry)
	v.add_child(UITheme.button("MAIN MENU", GameState.go_to_menu, 160))
	retry.grab_focus.call_deferred()


func back() -> void:
	GameState.go_to_menu()
