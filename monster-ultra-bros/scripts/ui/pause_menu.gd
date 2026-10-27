extends CanvasLayer
## Pause menu. The scene tree is paused while it is open, which freezes
## enemies, timers, moving platforms and bosses.

signal resume_requested

const SettingsMenu := preload("res://scripts/ui/settings_menu.gd")

var _root: Control
var _settings: Control
var _resume: Button
var _confirm: Control


func _ready() -> void:
	layer = 60
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	UITheme.dim_background(_root, 0.65)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(180, 150)
	panel.position = Vector2(-90, -75)
	_root.add_child(panel)
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 6)
	panel.add_child(v)
	v.add_child(UITheme.label("PAUSED", 20))
	_resume = UITheme.button("RESUME", func(): resume_requested.emit(), 150)
	v.add_child(_resume)
	v.add_child(UITheme.button("RESTART LEVEL", _restart, 150))
	v.add_child(UITheme.button("SETTINGS", _open_settings, 150))
	v.add_child(UITheme.button("MAIN MENU", _menu, 150))
	visible = false


func open() -> void:
	visible = true
	_resume.grab_focus.call_deferred()


func close() -> void:
	if _settings and is_instance_valid(_settings):
		_settings.close()
	visible = false


func back() -> void:
	if _settings and is_instance_valid(_settings):
		_settings.back()
	else:
		resume_requested.emit()


func _open_settings() -> void:
	_settings = SettingsMenu.new()
	_root.add_child(_settings)
	_settings.closed.connect(func(): _resume.grab_focus.call_deferred())


func _restart() -> void:
	get_tree().paused = false
	AudioManager.duck_music(1.0)
	GameState.restart_level()


func _menu() -> void:
	GameState.save_continue()
	AudioManager.duck_music(1.0)
	GameState.go_to_menu()
