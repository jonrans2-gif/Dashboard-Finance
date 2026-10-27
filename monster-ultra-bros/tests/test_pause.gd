extends TestCase
## Pausing freezes gameplay (enemies, timers, platforms) and releases touch input.


func test_pause_freezes_everything() -> void:
	var rows := []
	for y in 10:
		rows.append(".".repeat(40))
	rows.append(".".repeat(40))
	rows.append(".".repeat(20) + "m-----" + ".".repeat(14))
	rows.append("S..........e" + ".".repeat(28))
	for y in 4:
		rows.append("#".repeat(40))
	var lv := await make_level(rows)
	await frames(10)
	var e: Enemy = enemies_of(lv)[0]
	var plat: Node2D = null
	for c in lv.entities.get_children():
		if c is AnimatableBody2D:
			plat = c
	get_tree().paused = true
	var ex := e.global_position.x
	var px := plat.position.x
	var t := lv.time_left
	await frames(45)
	eq(e.global_position.x, ex, "enemy frozen")
	eq(plat.position.x, px, "moving platform frozen")
	eq(lv.time_left, t, "level timer frozen")
	get_tree().paused = false
	await frames(30)
	check(e.global_position.x != ex, "enemy moves again after resume")
	check(lv.time_left < t, "timer runs again")


func test_pause_menu_runs_while_paused() -> void:
	var pm: CanvasLayer = load("res://scripts/ui/pause_menu.gd").new()
	add_child(pm)
	eq(pm.process_mode, Node.PROCESS_MODE_ALWAYS, "pause menu processes while the tree is paused")
	pm.open()
	check(pm.visible, "menu opens")
	var resumed := [false]
	pm.resume_requested.connect(func(): resumed[0] = true)
	pm.back()   # Android back button
	check(resumed[0], "back button resumes")


func test_touch_released_on_pause() -> void:
	Settings.values.touch_controls = "always"
	var tc: CanvasLayer = load("res://scripts/ui/touch_controls.gd").new()
	add_child(tc)
	await frames(1)
	var ev := InputEventScreenTouch.new()
	ev.index = 0
	ev.pressed = true
	ev.position = get_viewport().get_final_transform() * tc.buttons.right.center
	get_viewport().push_input(ev)
	await frames(2)
	check(Input.is_action_pressed("move_right"), "held before pausing")
	get_tree().paused = true
	await frames(2)
	check(not Input.is_action_pressed("move_right"), "released when paused (no runaway can on resume)")
	get_tree().paused = false
	Settings.values.touch_controls = "auto"
