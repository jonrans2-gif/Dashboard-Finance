extends Control
## Title screen: Play, Continue, Level Select, Settings, Credits.

const SettingsMenu := preload("res://scripts/ui/settings_menu.gd")
const Credits := preload("res://scripts/ui/credits.gd")
const Backdrop := preload("res://scripts/ui/menu_backdrop.gd")

var _buttons: VBoxContainer
var _overlay: Control
var _continue: Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var world := Backdrop.new()
	add_child(world)
	var ui := CanvasLayer.new()
	ui.layer = 10
	add_child(ui)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.add_child(root)
	var logo := TextureRect.new()
	logo.texture = load("res://assets/ui/logo.png")
	logo.set_anchors_preset(Control.PRESET_CENTER_TOP)
	logo.position = Vector2(-logo.texture.get_width() / 2.0, 6)
	root.add_child(logo)
	var bob := create_tween().set_loops()
	bob.tween_property(logo, "position:y", 9.0, 1.2).set_trans(Tween.TRANS_SINE)
	bob.tween_property(logo, "position:y", 6.0, 1.2).set_trans(Tween.TRANS_SINE)
	_buttons = VBoxContainer.new()
	_buttons.set_anchors_preset(Control.PRESET_CENTER)
	_buttons.position = Vector2(-70, -36)
	_buttons.custom_minimum_size = Vector2(140, 0)
	_buttons.add_theme_constant_override("separation", 3)
	root.add_child(_buttons)
	var play := UITheme.button("PLAY", _play, 140)
	_buttons.add_child(play)
	_continue = UITheme.button("CONTINUE", GameState.continue_game, 140)
	_continue.disabled = not SaveSystem.has_continue()
	_buttons.add_child(_continue)
	_buttons.add_child(UITheme.button("LEVEL SELECT", func(): GameState.change_scene("res://scenes/level_select.tscn"), 140))
	_buttons.add_child(UITheme.button("SETTINGS", _settings, 140))
	_buttons.add_child(UITheme.button("CREDITS", _credits, 140))
	var foot := UITheme.label("v%s   %d/12 levels cleared" % [ProjectSettings.get_setting("application/config/version"),
		(SaveSystem.data.completed as Array).size()], 10, UITheme.C_DIM, HORIZONTAL_ALIGNMENT_RIGHT)
	foot.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	foot.position = Vector2(-220, -16)
	foot.custom_minimum_size = Vector2(212, 0)
	root.add_child(foot)
	_overlay = root
	(_continue if not _continue.disabled else play).grab_focus.call_deferred()
	AudioManager.play_music("menu")


func _play() -> void:
	GameState.new_game()


func _settings() -> void:
	var s := SettingsMenu.new()
	s.allow_reset = true
	_overlay.add_child(s)
	s.closed.connect(func():
		_continue.disabled = not SaveSystem.has_continue()
		_buttons.get_child(0).grab_focus())


func _credits() -> void:
	var c := Credits.new()
	_overlay.add_child(c)
	c.closed.connect(func(): _buttons.get_child(4).grab_focus())


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		for c in _overlay.get_children():
			if c.has_method("back"):
				c.back()
				return
		_ask_quit()


func _ask_quit() -> void:
	var q: Control = preload("res://scripts/ui/confirm_dialog.gd").new()
	q.text = "QUIT THE GAME?"
	q.on_yes = func(): get_tree().quit()
	_overlay.add_child(q)
