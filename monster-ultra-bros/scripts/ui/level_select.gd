extends Control
## World / level picker with best scores, shards and secrets per level.

const Backdrop := preload("res://scripts/ui/menu_backdrop.gd")
const WORLD_THEME := {1: "hills", 2: "factory", 3: "ice", 4: "ultra"}

var world := 1
var _title: Label
var _cards: HBoxContainer
var _root: Control
var _backdrop: Node


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# start on the furthest unlocked world
	for lv in GameState.LEVELS:
		if SaveSystem.is_unlocked(lv.id):
			world = lv.world
	var ui := CanvasLayer.new()
	ui.layer = 10
	add_child(ui)
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.add_child(_root)
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_CENTER)
	v.position = Vector2(-215, -110)
	v.custom_minimum_size = Vector2(430, 0)
	v.add_theme_constant_override("separation", 8)
	_root.add_child(v)
	v.add_child(UITheme.label("LEVEL SELECT", 20))
	var nav := HBoxContainer.new()
	nav.alignment = BoxContainer.ALIGNMENT_CENTER
	nav.add_theme_constant_override("separation", 10)
	nav.add_child(UITheme.button("<", func(): _set_world(world - 1), 26))
	_title = UITheme.label("", 10, Color("ffd23f"))
	_title.custom_minimum_size = Vector2(200, 0)
	nav.add_child(_title)
	nav.add_child(UITheme.button(">", func(): _set_world(world + 1), 26))
	v.add_child(nav)
	_cards = HBoxContainer.new()
	_cards.alignment = BoxContainer.ALIGNMENT_CENTER
	_cards.add_theme_constant_override("separation", 8)
	v.add_child(_cards)
	var back := UITheme.button("BACK", GameState.go_to_menu, 100)
	var cc := CenterContainer.new()
	cc.add_child(back)
	v.add_child(cc)
	_set_world(world)
	AudioManager.play_music("menu")


func _set_world(w: int) -> void:
	world = clampi(w, 1, 4)
	_title.text = "WORLD %d - %s" % [world, GameState.WORLD_NAMES[world].to_upper()]
	if _backdrop:
		_backdrop.queue_free()
	_backdrop = Backdrop.new()
	_backdrop.theme = WORLD_THEME[world]
	_backdrop.speed = 30.0
	add_child(_backdrop)
	move_child(_backdrop, 0)
	for c in _cards.get_children():
		c.queue_free()
	var first: Control = null
	for lv in GameState.LEVELS:
		if lv.world != world:
			continue
		var card := _card(lv)
		_cards.add_child(card)
		if first == null and not card.disabled:
			first = card
	if first:
		first.grab_focus.call_deferred()


func _card(lv: Dictionary) -> Button:
	var unlocked := SaveSystem.is_unlocked(lv.id)
	var b := Button.new()
	b.custom_minimum_size = Vector2(132, 118)
	b.disabled = not unlocked
	b.focus_mode = Control.FOCUS_ALL
	var v := VBoxContainer.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_theme_constant_override("separation", 3)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	b.add_child(v)
	v.add_child(_mute(UITheme.label(lv.id, 20, Color.WHITE if unlocked else UITheme.C_DIM)))
	var name_l := UITheme.label(lv.name.to_upper() if unlocked else "LOCKED", 10, Color("ffd23f") if unlocked else UITheme.C_DIM)
	name_l.autowrap_mode = TextServer.AUTOWRAP_WORD
	name_l.custom_minimum_size = Vector2(120, 0)
	v.add_child(_mute(name_l))
	if unlocked:
		var best := int(SaveSystem.data.best_score.get(lv.id, 0))
		v.add_child(_mute(UITheme.label("BEST %d" % best if best > 0 else "NOT CLEARED", 10, Color.WHITE if best > 0 else UITheme.C_DIM)))
		var icons := HBoxContainer.new()
		icons.alignment = BoxContainer.ALIGNMENT_CENTER
		icons.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var shards := SaveSystem.shard_count(lv.id)
		for i in 3:
			var t := TextureRect.new()
			t.texture = SpriteLib.frame_texture("ui/icons", "shard_full" if i < shards else "shard_empty")
			t.mouse_filter = Control.MOUSE_FILTER_IGNORE
			icons.add_child(t)
		var core := TextureRect.new()
		core.texture = SpriteLib.frame_texture("ui/icons", "core")
		core.modulate = Color.WHITE if SaveSystem.core_count(lv.id) > 0 else Color(0.2, 0.2, 0.25)
		core.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icons.add_child(core)
		v.add_child(icons)
		b.pressed.connect(func():
			AudioManager.play_sfx("ui_select")
			GameState.play_selected_level(lv.id))
	else:
		var lock := TextureRect.new()
		lock.texture = SpriteLib.frame_texture("ui/icons", "lock")
		lock.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		lock.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(lock)
	return b


func _mute(c: Control) -> Control:
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		GameState.go_to_menu()
