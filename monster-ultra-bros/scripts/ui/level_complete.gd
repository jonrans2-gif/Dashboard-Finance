extends CanvasLayer
## End-of-level tally: tokens, enemies, secrets, shards, time and flag bonus,
## then the level score (saved as best score) and navigation.

var result: Dictionary = {}
var _rows: VBoxContainer
var _total: Label
var _buttons: HBoxContainer


func _ready() -> void:
	layer = 65
	process_mode = Node.PROCESS_MODE_ALWAYS
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	UITheme.dim_background(root, 0.55)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(280, 210)
	panel.position = Vector2(-140, -105)
	root.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	panel.add_child(v)
	var info := GameState.level_info(str(result.get("level", "")))
	v.add_child(UITheme.label("LEVEL CLEAR!", 20, Color("7dff5a")))
	v.add_child(UITheme.label("%s  %s" % [result.get("level", ""), info.get("name", "")], 10, Color("ffd23f")))
	_rows = VBoxContainer.new()
	_rows.add_theme_constant_override("separation", 2)
	v.add_child(_rows)
	_total = UITheme.label("", 10, Color.WHITE)
	v.add_child(_total)
	_buttons = HBoxContainer.new()
	_buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	_buttons.add_theme_constant_override("separation", 6)
	_buttons.modulate.a = 0.0
	v.add_child(_buttons)
	var last := GameState.next_level_id(str(result.get("level", ""))) == ""
	var next := UITheme.button("FINALE" if last else "NEXT", GameState.go_next_level, 80)
	_buttons.add_child(next)
	_buttons.add_child(UITheme.button("REPLAY", func(): GameState.start_level(str(result.level)), 80))
	_buttons.add_child(UITheme.button("MENU", GameState.go_to_menu, 80))
	_animate(next)


func _row(title: String, value: String, color := Color.WHITE) -> void:
	var h := HBoxContainer.new()
	var l := UITheme.label(title, 10, UITheme.C_DIM, HORIZONTAL_ALIGNMENT_LEFT)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(l)
	var r := UITheme.label(value, 10, color, HORIZONTAL_ALIGNMENT_RIGHT)
	h.add_child(r)
	_rows.add_child(h)
	AudioManager.play_sfx("tick")


func _animate(focus_btn: Button) -> void:
	var r := result
	var lines := [
		["ENERGY TOKENS", str(r.tokens), Color("ffd23f")],
		["ENEMIES DEFEATED", str(r.enemies), Color.WHITE],
		["ULTRA SHARDS", "%d / %d" % [r.shards.size(), r.shards_total], Color("8fe0ff")],
		["SECRET CORES", "%d / %d" % [r.cores.size(), r.cores_total], Color("7dff5a")],
		["FLAG BONUS", str(r.flag_bonus), Color.WHITE],
		["TIME BONUS  (%ds x10)" % r.time_left, str(r.time_bonus), Color.WHITE],
	]
	for line in lines:
		await get_tree().create_timer(0.22).timeout
		_row(line[0], line[1], line[2])
	await get_tree().create_timer(0.35).timeout
	var best := int(SaveSystem.data.best_score.get(str(r.level), 0))
	_total.text = "LEVEL SCORE %d%s" % [r.level_score, "   NEW BEST!" if r.get("new_best", false) else "   BEST %d" % best]
	_total.add_theme_color_override("font_color", Color("7dff5a") if r.get("new_best", false) else Color.WHITE)
	AudioManager.play_sfx("shard" if r.get("new_best", false) else "ui_select")
	var t := create_tween()
	t.tween_property(_buttons, "modulate:a", 1.0, 0.3)
	focus_btn.grab_focus()
