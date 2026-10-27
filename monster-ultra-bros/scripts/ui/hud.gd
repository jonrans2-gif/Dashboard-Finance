extends CanvasLayer
## In-game HUD: score, tokens, lives, energy cells, timer, active power-ups
## (with expiry warning), level progress, shards, boss health and banners.

var level: Node
var _root: Control
var _score: Label
var _tokens: Label
var _lives: Label
var _time: Label
var _cells: Array = []
var _shards: Array = []
var _power_box: HBoxContainer
var _power_widgets: Dictionary = {}
var _progress: Control
var _boss_box: Control
var _boss_bar: ProgressBar
var _boss_name: Label
var _boss: Node
var _banner: VBoxContainer
var _message: Label
var _fade: ColorRect
var _tex := {}


func _ready() -> void:
	layer = 40
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	for n in ["cell_full", "cell_empty", "life", "token", "shard_full", "shard_empty", "clock", "core"]:
		_tex[n] = SpriteLib.frame_texture("ui/icons", n)

	# --- top-left: lives, energy cells, tokens
	var left := HBoxContainer.new()
	left.position = Vector2(8, 5)
	left.add_theme_constant_override("separation", 3)
	_root.add_child(left)
	left.add_child(_icon("life"))
	_lives = _label("x5")
	left.add_child(_lives)
	left.add_child(_spacer(6))
	for i in Player.MAX_HP:
		var c := _icon("cell_full")
		_cells.append(c)
		left.add_child(c)
	left.add_child(_spacer(6))
	left.add_child(_icon("token"))
	_tokens = _label("x00")
	left.add_child(_tokens)

	# --- top-center: score + progress + shards
	var center := VBoxContainer.new()
	center.set_anchors_preset(Control.PRESET_CENTER_TOP)
	center.position = Vector2(-70, 3)
	center.custom_minimum_size = Vector2(140, 0)
	center.add_theme_constant_override("separation", 1)
	_root.add_child(center)
	_score = _label("00000000")
	_score.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(_score)
	var prow := HBoxContainer.new()
	prow.alignment = BoxContainer.ALIGNMENT_CENTER
	prow.add_theme_constant_override("separation", 2)
	center.add_child(prow)
	_progress = preload("res://scripts/ui/progress_bar.gd").new()
	_progress.level = level
	_progress.custom_minimum_size = Vector2(84, 8)
	prow.add_child(_progress)
	prow.add_child(_spacer(3))
	for i in 3:
		var s := _icon("shard_empty")
		s.custom_minimum_size = Vector2(8, 8)
		s.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		s.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_shards.append(s)
		prow.add_child(s)

	# --- top-right: timer (leaves room for the pause button)
	var right := HBoxContainer.new()
	right.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	right.position = Vector2(-96, 5)
	right.add_theme_constant_override("separation", 3)
	_root.add_child(right)
	right.add_child(_icon("clock"))
	_time = _label("300")
	right.add_child(_time)

	# --- active power-ups (below the left block)
	_power_box = HBoxContainer.new()
	_power_box.position = Vector2(8, 20)
	_power_box.add_theme_constant_override("separation", 4)
	_root.add_child(_power_box)

	# --- boss bar
	_boss_box = VBoxContainer.new()
	_boss_box.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_boss_box.position = Vector2(-80, 30)
	_boss_box.custom_minimum_size = Vector2(160, 0)
	_boss_box.visible = false
	_root.add_child(_boss_box)
	_boss_name = _label("BOSS")
	_boss_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boss_name.add_theme_color_override("font_color", Color("ff6a8a"))
	_boss_box.add_child(_boss_name)
	_boss_bar = ProgressBar.new()
	_boss_bar.show_percentage = false
	_boss_bar.custom_minimum_size = Vector2(160, 6)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color("101018")
	bg.border_color = Color("c8ccd6")
	bg.set_border_width_all(1)
	var fg := StyleBoxFlat.new()
	fg.bg_color = Color("ff3048")
	_boss_bar.add_theme_stylebox_override("background", bg)
	_boss_bar.add_theme_stylebox_override("fill", fg)
	_boss_box.add_child(_boss_bar)

	# --- banner + messages + fade
	_banner = VBoxContainer.new()
	_banner.set_anchors_preset(Control.PRESET_CENTER)
	_banner.position = Vector2(-120, -40)
	_banner.custom_minimum_size = Vector2(240, 0)
	_banner.visible = false
	_root.add_child(_banner)
	_message = UITheme.label("", 20, Color("7dff5a"))
	_message.set_anchors_preset(Control.PRESET_CENTER)
	_message.position = Vector2(-120, -20)
	_message.custom_minimum_size = Vector2(240, 0)
	_message.visible = false
	_root.add_child(_message)
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_fade)

	GameState.stats_changed.connect(refresh)
	if level and level.player:
		level.player.hp_changed.connect(func(_hp): refresh())
		level.player.powerups_changed.connect(_rebuild_powers)
	refresh()


func _icon(n: String) -> TextureRect:
	var t := TextureRect.new()
	t.texture = _tex[n]
	t.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	return t


func _label(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_constant_override("outline_size", 3)
	l.add_theme_color_override("font_outline_color", Color("101018"))
	return l


func _spacer(w: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(w, 0)
	return c


func refresh() -> void:
	_score.text = "%08d" % GameState.score
	_tokens.text = "x%02d" % GameState.tokens
	_lives.text = "x%d" % GameState.lives
	var hp: int = level.player.hp if level and level.player else Player.MAX_HP
	for i in _cells.size():
		_cells[i].texture = _tex["cell_full"] if i < hp else _tex["cell_empty"]
	for i in _shards.size():
		_shards[i].texture = _tex["shard_full"] if i in GameState.attempt_shards else _tex["shard_empty"]
		_shards[i].visible = level == null or i < level.shards_total


func _process(_delta: float) -> void:
	if level == null:
		return
	var t := int(ceil(level.time_left))
	_time.text = "%03d" % t
	_time.add_theme_color_override("font_color", Color("ff6a6a") if t <= 60 and int(level.time_left * 3) % 2 == 0 else Color.WHITE)
	# power-up timers
	var p: Player = level.player
	if p:
		for k in _power_widgets.keys():
			var w: Dictionary = _power_widgets[k]
			var left: float = p.power_time_left(k)
			var bar: ProgressBar = w.bar
			if left == INF:
				bar.value = 100
			else:
				bar.value = 100.0 * left / Player.POWER_DURATION.get(k, 15.0)
			# blink when about to expire
			(w.box as Control).modulate.a = 0.35 if left < 3.0 and int(left * 8) % 2 == 0 else 1.0
	if _boss and is_instance_valid(_boss):
		_boss_bar.max_value = _boss.max_hp
		_boss_bar.value = lerp(_boss_bar.value, float(_boss.hp), 0.2)


func _rebuild_powers() -> void:
	for c in _power_box.get_children():
		c.queue_free()
	_power_widgets.clear()
	var p: Player = level.player
	for k in p.powerups.keys():
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 1)
		var icon := TextureRect.new()
		icon.texture = SpriteLib.frame_texture("powerups", k)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		box.add_child(icon)
		var bar := ProgressBar.new()
		bar.show_percentage = false
		bar.custom_minimum_size = Vector2(16, 3)
		var bg := StyleBoxFlat.new()
		bg.bg_color = Color("101018")
		var fg := StyleBoxFlat.new()
		fg.bg_color = Player.POWER_COLOR.get(k, Color.WHITE)
		bar.add_theme_stylebox_override("background", bg)
		bar.add_theme_stylebox_override("fill", fg)
		box.add_child(bar)
		_power_box.add_child(box)
		_power_widgets[k] = {"box": box, "bar": bar}


func show_boss(boss: Node) -> void:
	_boss = boss
	_boss_name.text = str(boss.display_name)
	_boss_bar.max_value = boss.max_hp
	_boss_bar.value = 0
	_boss_box.visible = true


func hide_boss() -> void:
	_boss_box.visible = false
	_boss = null


func show_banner(top: String, bottom: String) -> void:
	for c in _banner.get_children():
		c.queue_free()
	_banner.add_child(UITheme.label(top, 20, Color.WHITE))
	_banner.add_child(UITheme.label(bottom, 10, Color("ffd23f")))
	_banner.visible = true
	_banner.modulate.a = 0.0
	var t := create_tween()
	t.tween_property(_banner, "modulate:a", 1.0, 0.3)
	t.tween_interval(1.8)
	t.tween_property(_banner, "modulate:a", 0.0, 0.5)
	t.tween_callback(func(): _banner.visible = false)


func flash_message(text: String, color := Color("7dff5a")) -> void:
	_message.text = text
	_message.add_theme_color_override("font_color", color)
	_message.visible = true
	_message.modulate.a = 1.0
	var t := create_tween()
	t.tween_interval(0.9)
	t.tween_property(_message, "modulate:a", 0.0, 0.4)
	t.tween_callback(func(): _message.visible = false)


func fade_out(d: float) -> void:
	var t := create_tween()
	t.tween_property(_fade, "color:a", 1.0, d)
	await t.finished


func fade_in(d: float) -> void:
	var t := create_tween()
	t.tween_property(_fade, "color:a", 0.0, d)
	await t.finished
