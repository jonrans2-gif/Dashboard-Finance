extends Control
## Ending sequence after the final boss: the machine powers down, the sun
## rises over White Hills, the can celebrates, then the credits roll.

const Backdrop := preload("res://scripts/ui/menu_backdrop.gd")

var _root: Control
var _flash: ColorRect
var _text: VBoxContainer
var _credits: VBoxContainer
var _buttons: HBoxContainer
var _backdrop: Node
var _scrolling := false


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var ui := CanvasLayer.new()
	ui.layer = 10
	add_child(ui)
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.add_child(_root)
	var dark := ColorRect.new()
	dark.color = Color("08041c")
	dark.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(dark)
	var core := TextureRect.new()
	core.texture = SpriteLib.frame_texture("boss_overload_core", "dead")
	core.set_anchors_preset(Control.PRESET_CENTER)
	core.position = Vector2(-48, -60)
	_root.add_child(core)
	_flash = ColorRect.new()
	_flash.color = Color(1, 1, 1, 0)
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_text = VBoxContainer.new()
	_text.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_text.position = Vector2(-160, 24)
	_text.custom_minimum_size = Vector2(320, 0)
	_root.add_child(_text)
	_credits = VBoxContainer.new()
	_credits.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_credits.custom_minimum_size = Vector2(320, 0)
	_credits.position = Vector2(-160, 300)
	_credits.visible = false
	_root.add_child(_credits)
	for l in preload("res://scripts/ui/credits.gd").LINES:
		_credits.add_child(UITheme.label(l[0], l[1], Color.WHITE if l[1] == 10 else Color("ffd23f")))
	_buttons = HBoxContainer.new()
	_buttons.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_buttons.position = Vector2(-130, -36)
	_buttons.custom_minimum_size = Vector2(260, 0)
	_buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	_buttons.add_theme_constant_override("separation", 8)
	_buttons.visible = false
	_root.add_child(_buttons)
	_root.add_child(_flash)
	AudioManager.stop_music(0.5)
	_sequence(core, dark)


func _sequence(core: TextureRect, dark: ColorRect) -> void:
	for i in 6:
		await get_tree().create_timer(0.35).timeout
		AudioManager.play_sfx("explosion", 0.2)
		core.position += Vector2(randf_range(-3, 3), randf_range(-2, 2))
		core.modulate = Color(2, 2, 2) if i % 2 == 0 else Color.WHITE
	var t := create_tween()
	t.tween_property(_flash, "color:a", 1.0, 0.4)
	await t.finished
	core.visible = false
	dark.visible = false
	_backdrop = Backdrop.new()
	_backdrop.speed = 0.0
	add_child(_backdrop)
	move_child(_backdrop, 0)
	_backdrop.runner.play("victory")
	AudioManager.play_music("credits", 1.0)
	var t2 := create_tween()
	t2.tween_property(_flash, "color:a", 0.0, 1.2)
	await t2.finished
	_text.add_child(UITheme.label("THE ULTRA DIMENSION IS SAFE!", 20, Color.WHITE))
	_text.add_child(UITheme.label("The overload is over. Stay ultra, stay white.", 10, Color("ffd23f")))
	_text.add_child(UITheme.label("FINAL SCORE %d" % GameState.score, 10, Color("7dff5a")))
	await get_tree().create_timer(3.5).timeout
	var t3 := create_tween()
	t3.tween_property(_text, "modulate:a", 0.0, 0.8)
	await t3.finished
	_credits.visible = true
	_scrolling = true


func _process(delta: float) -> void:
	if _backdrop and is_instance_valid(_backdrop) and randf() < delta * 2.0:
		var screen := get_viewport().get_visible_rect().size
		FX.set_root(_backdrop)
		FX.sparkle(_backdrop.cam.global_position + Vector2(randf_range(-screen.x / 2, screen.x / 2), randf_range(-100, 0)), 4, 12)
	if _scrolling:
		_credits.position.y -= delta * 22.0
		if _credits.position.y + _credits.size.y < 40.0 and not _buttons.visible:
			_show_buttons()


func _show_buttons() -> void:
	_buttons.visible = true
	var again := UITheme.button("PLAY AGAIN", GameState.new_game, 120)
	_buttons.add_child(again)
	_buttons.add_child(UITheme.button("MAIN MENU", GameState.go_to_menu, 120))
	again.grab_focus()


func _input(event: InputEvent) -> void:
	# tap to speed through the credits
	if _scrolling and not _buttons.visible and (event is InputEventScreenTouch or event is InputEventMouseButton) and event.pressed:
		_credits.position.y -= 60.0
