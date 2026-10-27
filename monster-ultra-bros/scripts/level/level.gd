class_name Level
extends Node2D
## Builds and runs one level: tiles, entities, camera, HUD, timer, blocks,
## secrets, checkpoints, doors, boss arena, death/respawn and completion.

const T := 16
const ENEMY_SCRIPTS := {
	"e": preload("res://scripts/enemies/empty_can.gd"),
	"u": preload("res://scripts/enemies/sugar_cube.gd"),
	"d": preload("res://scripts/enemies/energy_drone.gd"),
	"k": preload("res://scripts/enemies/corrupted_can.gd"),
	"z": preload("res://scripts/enemies/static_slime.gd"),
}
const BOSS_SCRIPTS := {
	"sugar_king": "res://scripts/bosses/sugar_king.gd",
	"crusher_prime": "res://scripts/bosses/crusher_prime.gd",
	"frost_volt": "res://scripts/bosses/frost_volt.gd",
	"overload_core": "res://scripts/bosses/overload_core.gd",
}
const Collectible := preload("res://scripts/items/collectible.gd")
const PowerupItem := preload("res://scripts/items/powerup_item.gd")
const MovingPlatform := preload("res://scripts/level/objects/moving_platform.gd")
const FallingPlatform := preload("res://scripts/level/objects/falling_platform.gd")
const Spring := preload("res://scripts/level/objects/spring.gd")
const Door := preload("res://scripts/level/objects/door.gd")
const Checkpoint := preload("res://scripts/level/objects/checkpoint.gd")
const Goal := preload("res://scripts/level/objects/goal.gd")
const Zapper := preload("res://scripts/level/objects/zapper.gd")
const Icicle := preload("res://scripts/level/objects/icicle.gd")
const BoostPad := preload("res://scripts/level/objects/boost_pad.gd")
const Crusher := preload("res://scripts/level/objects/crusher.gd")
const HudScript := preload("res://scripts/ui/hud.gd")
const TouchScript := preload("res://scripts/ui/touch_controls.gd")
const PauseScript := preload("res://scripts/ui/pause_menu.gd")
const CompleteScript := preload("res://scripts/ui/level_complete.gd")
const GameOverScript := preload("res://scripts/ui/game_over.gd")

signal level_completed(result: Dictionary)

var level_id := ""
var data: LevelData
var theme := "hills"
var terrain: TileMapLayer
var back: TileMapLayer
var entities: Node2D
var fx_root: Node2D
var player: Player
var camera: GameCamera
var background: ParallaxBG
var hud: Node
var touch: Node
var pause_menu: Node
var goal: Node
var boss: Node

var time_left := 300.0
var time_limit := 300.0
var stats := {"tokens": 0, "enemies": 0, "secrets_revealed": 0}
var block_contents: Dictionary = {}   # Vector2i -> "token" | "power:<kind>" | "life" | "multi:<n>"
var hidden_blocks: Dictionary = {}    # Vector2i -> content
var hazard_cells: Dictionary = {}     # Vector2i -> "spikes" | "goo"
var secret_groups: Array = []         # [{layer, rect, revealed, inside}]
var checkpoints: Array = []
var doors: Array = []
var start_pos := Vector2(48, 200)
var arena_gate_x := -1
var arena_active := false
var boss_spawn := Vector2.ZERO
var completed := false
var shards_total := 0
var cores_total := 0
var combo := 0
var testing := false                  # set by tests: no UI, no scene changes
var data_override: LevelData = null   # tests can inject a map instead of a file

var _power_queue: Array = []
var _item_queue: Array = []
var _hurry := false
var _death_started := false
var _door_cooldown := 0.0


func _ready() -> void:
	if level_id == "":
		level_id = GameState.level_id
	var info := GameState.level_info(level_id)
	data = data_override if data_override else LevelData.load_file(info.get("file", "res://levels/%s.txt" % level_id))
	theme = data.get_str("theme", "hills")
	time_limit = float(data.get_int("time", 300))
	time_left = time_limit
	_power_queue = Array(data.get_str("powerups", "mega").split(",", false))
	_item_queue = Array(data.get_str("items", "shield").split(",", false))
	_build_world()
	_spawn_entities()
	_spawn_player()
	_build_camera_and_bg()
	if not testing:
		_build_ui()
		AudioManager.play_music(data.get_str("music", "overworld"))
	FX.set_root(fx_root)
	get_tree().paused = false


# =================================================================== building
func _build_world() -> void:
	var ts := Tiles.tileset(theme)
	back = TileMapLayer.new()
	back.tile_set = ts
	back.collision_enabled = false
	back.z_index = -5
	add_child(back)
	terrain = TileMapLayer.new()
	terrain.tile_set = ts
	terrain.name = "Terrain"
	add_child(terrain)
	entities = Node2D.new()
	entities.name = "Entities"
	add_child(entities)
	fx_root = Node2D.new()
	fx_root.name = "FX"
	fx_root.z_index = 10

	var backdrop := data.get_str("backdrop", "")
	var backdrop_top := data.get_int("backdrop_top", 0)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(level_id)
	var secret_cells: Dictionary = {}
	# power blocks get their contents in left-to-right order
	var power_cells: Array = data.find_all("!")
	power_cells.sort_custom(func(a, b): return a.x < b.x or (a.x == b.x and a.y < b.y))
	for i in power_cells.size():
		block_contents[power_cells[i]] = "power:" + str(_power_queue[i] if i < _power_queue.size() else "mega")

	for y in data.height:
		for x in data.width:
			var ch := data.at(x, y)
			var c := Vector2i(x, y)
			match ch:
				"#":
					terrain.set_cell(c, 0, _ground_tile(x, y, rng))
				"=":
					terrain.set_cell(c, 0, Tiles.BRICK)
				"?":
					terrain.set_cell(c, 0, Tiles.EBLOCK)
					block_contents[c] = "token"
				"!":
					terrain.set_cell(c, 0, Tiles.EBLOCK)
				"B":
					terrain.set_cell(c, 0, Tiles.HARD)
				"X":
					terrain.set_cell(c, 0, Tiles.BARRIER)
				"^":
					terrain.set_cell(c, 0, Tiles.SPIKES)
					hazard_cells[c] = "spikes"
				"~":
					terrain.set_cell(c, 0, Tiles.GOO_TOP if data.at(x, y - 1) != "~" else Tiles.GOO_FILL)
					hazard_cells[c] = "goo"
				"_":
					var l := data.at(x - 1, y) == "_"
					var r := data.at(x + 1, y) == "_"
					terrain.set_cell(c, 0, Tiles.PLAT_M if (l and r) or (not l and not r) else (Tiles.PLAT_R if l else Tiles.PLAT_L))
				"c":
					terrain.set_cell(c, 0, Tiles.CLOUD)
				"I":
					terrain.set_cell(c, 0, Tiles.ICE)
				"<":
					terrain.set_cell(c, 0, Tiles.CONV_L)
				">":
					terrain.set_cell(c, 0, Tiles.CONV_R)
				"n":
					terrain.set_cell(c, 0, Tiles.SNOWCAP)
				"[":
					terrain.set_cell(c, 0, Tiles.PIPE_TL if data.at(x, y - 1) != "[" else Tiles.PIPE_L)
				"]":
					terrain.set_cell(c, 0, Tiles.PIPE_TR if data.at(x, y - 1) != "]" else Tiles.PIPE_R)
				"%":
					secret_cells[c] = true
				"b":
					back.set_cell(c, 0, Tiles.BG_WALL)
				"|":
					back.set_cell(c, 0, Tiles.CHAIN)
				"h":
					hidden_blocks[c] = "token"
				"H":
					hidden_blocks[c] = "life"
				"*":
					back.set_cell(c, 0, Tiles.BUSH)
				"f":
					back.set_cell(c, 0, Tiles.FLOWER)
				"F":
					back.set_cell(c, 0, Tiles.FENCE)
				"l":
					back.set_cell(c, 0, Tiles.LAMP)
				"a":
					back.set_cell(c, 0, Tiles.ARROW)
				"w":
					back.set_cell(c, 0, Tiles.WINDOW)
				"t":
					back.set_cell(c, 0, Tiles.TORCH)
				"s":
					back.set_cell(c, 0, Tiles.SIGN)
				"y":
					back.set_cell(c, 0, Tiles.CRYSTAL)
			if backdrop == "wall" and y >= backdrop_top and back.get_cell_source_id(c) == -1 \
					and terrain.get_cell_source_id(c) == -1 and not secret_cells.has(c):
				back.set_cell(c, 0, Tiles.BG_WALL if (x + y) % 7 != 0 else Tiles.BG_WALL2)
	_build_secret_layers(secret_cells, rng)
	# filler below the level (visible through pits and in portrait framing)
	var filler := ColorRect.new()
	filler.color = Color("0b0b12")
	filler.position = Vector2(-600, data.height * T)
	filler.size = Vector2(data.width * T + 1200, 900)
	filler.z_index = -20
	filler.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(filler)
	# invisible side walls
	for wx in [0.0, float(data.width * T)]:
		var wall := StaticBody2D.new()
		wall.collision_layer = 1
		var cs := CollisionShape2D.new()
		var seg := SegmentShape2D.new()
		seg.a = Vector2(wx, -T * 20.0)
		seg.b = Vector2(wx, data.height * T)
		cs.shape = seg
		wall.add_child(cs)
		add_child(wall)
	add_child(fx_root)


func _ground_tile(x: int, y: int, rng: RandomNumberGenerator) -> Vector2i:
	var top_open := not LevelData.is_ground_char(data.at(x, y - 1)) and y > 0
	var left_open := not LevelData.is_ground_char(data.at(x - 1, y)) and x > 0
	var right_open := not LevelData.is_ground_char(data.at(x + 1, y)) and x < data.width - 1
	if top_open:
		if left_open and not right_open:
			return Tiles.GROUND_TL
		if right_open and not left_open:
			return Tiles.GROUND_TR
		return Tiles.GROUND_T2 if rng.randf() < 0.15 else Tiles.GROUND_T
	if left_open and not right_open:
		return Tiles.WALL_L
	if right_open and not left_open:
		return Tiles.WALL_R
	return Tiles.FILL2 if rng.randf() < 0.18 else Tiles.FILL


func _build_secret_layers(cells: Dictionary, rng: RandomNumberGenerator) -> void:
	var seen: Dictionary = {}
	for start in cells.keys():
		if seen.has(start):
			continue
		var layer := TileMapLayer.new()
		layer.tile_set = terrain.tile_set
		layer.collision_enabled = false
		layer.z_index = 8
		add_child(layer)
		var stack: Array = [start]
		var rect := Rect2(Vector2(start) * T, Vector2(T, T))
		seen[start] = true
		while not stack.is_empty():
			var c: Vector2i = stack.pop_back()
			layer.set_cell(c, 0, _ground_tile(c.x, c.y, rng))
			rect = rect.merge(Rect2(Vector2(c) * T, Vector2(T, T)))
			for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				var n: Vector2i = c + d
				if cells.has(n) and not seen.has(n):
					seen[n] = true
					stack.append(n)
		secret_groups.append({"layer": layer, "rect": rect, "revealed": false})


func _spawn_entities() -> void:
	var shard_i := 0
	var core_i := 0
	var cp_i := 0
	var door_list: Array = []
	for y in data.height:
		for x in data.width:
			var ch := data.at(x, y)
			var c := Vector2i(x, y)
			var bottom := data.cell_bottom(c)
			var center := data.cell_center(c)
			match ch:
				"S":
					start_pos = bottom
				"G":
					goal = Goal.new()
					goal.position = bottom
					goal.enabled = data.get_str("boss", "") == ""
					goal.touched.connect(_on_goal_touched)
					entities.add_child(goal)
				"C":
					var cp := Checkpoint.new()
					cp.index = cp_i
					cp.position = bottom
					cp.active = GameState.checkpoint >= cp_i
					cp.reached.connect(_on_checkpoint)
					entities.add_child(cp)
					checkpoints.append(cp)
					cp_i += 1
				"o":
					_add_collectible("token", 0, center)
				"$":
					if not (shard_i in GameState.attempt_shards):
						_add_collectible("shard", shard_i, center)
					shard_i += 1
				"@":
					if not (core_i in GameState.attempt_cores):
						_add_collectible("core", core_i, center)
					core_i += 1
				"+":
					_add_collectible("life", 0, center)
				"p":
					var kind: String = _item_queue.pop_front() if not _item_queue.is_empty() else "shield"
					spawn_powerup(kind, bottom, false)
				"e", "u", "d", "k", "z":
					var en: Enemy = ENEMY_SCRIPTS[ch].new()
					en.level = self
					en.position = bottom if ch != "d" else center + Vector2(0, 6)
					entities.add_child(en)
				"K":
					var cr := Crusher.new()
					cr.level = self
					cr.position = Vector2(x * T, y * T)
					cr.offset = float(data.get_int("crusher_offset_%d" % x, 0)) / 10.0 + fmod(x * 0.37, 1.2)
					entities.add_child(cr)
				"m", "v":
					var mp := MovingPlatform.new()
					mp.theme = theme
					mp.position = Vector2(x * T, y * T)
					mp.travel = _platform_travel(x, y, ch)
					mp.speed = float(data.get_int("platform_speed", 40))
					entities.add_child(mp)
				"x":
					var fp := FallingPlatform.new()
					fp.level = self
					fp.position = Vector2(x * T, y * T)
					entities.add_child(fp)
				"j":
					var sp := Spring.new()
					sp.position = bottom
					entities.add_child(sp)
				"D":
					var dr := Door.new()
					dr.position = bottom
					entities.add_child(dr)
					door_list.append(dr)
				"Z":
					var zp := Zapper.new()
					zp.level = self
					zp.position = Vector2(x * T + 8, y * T)
					zp.offset = fmod(x * 0.53, 1.5)
					entities.add_child(zp)
				"i":
					var ic := Icicle.new()
					ic.level = self
					ic.position = Vector2(x * T + 8, y * T)
					entities.add_child(ic)
				"r":
					var bp := BoostPad.new()
					bp.position = Vector2(x * T, (y + 1) * T)
					entities.add_child(bp)
				"Y":
					arena_gate_x = x
				"Q":
					boss_spawn = bottom
	shards_total = shard_i
	cores_total = core_i
	for i in range(0, door_list.size() - 1, 2):
		door_list[i].partner = door_list[i + 1]
		door_list[i + 1].partner = door_list[i]
	doors = door_list


func _platform_travel(x: int, y: int, ch: String) -> Vector2:
	if ch == "m":
		var n := 0
		while data.at(x + 1 + n, y) == "-":
			n += 1
		if n == 0:
			while data.at(x - 1 - n, y) == "-":
				n += 1
			return Vector2(-n * T, 0)
		return Vector2(n * T, 0)
	var k := 0
	while data.at(x, y + 1 + k) == ":":
		k += 1
	if k == 0:
		while data.at(x, y - 1 - k) == ":":
			k += 1
		return Vector2(0, -k * T)
	return Vector2(0, k * T)


func _add_collectible(kind: String, index: int, pos: Vector2) -> void:
	var it := Collectible.new()
	it.kind = kind
	it.index = index
	it.level = self
	it.position = pos
	entities.add_child(it)


func spawn_powerup(kind: String, pos: Vector2, emerge: bool) -> void:
	var p := PowerupItem.new()
	p.kind = kind
	p.level = self
	p.emerge = emerge
	p.position = pos
	entities.add_child(p)


func _spawn_player() -> void:
	player = Player.new()
	player.level = self
	var pos := start_pos
	if GameState.checkpoint >= 0 and GameState.checkpoint < checkpoints.size():
		pos = checkpoints[GameState.checkpoint].position
	player.position = pos
	add_child(player)
	move_child(player, fx_root.get_index())
	player.died.connect(_on_player_died)


func _build_camera_and_bg() -> void:
	camera = GameCamera.new()
	camera.bounds = Rect2(0, 0, data.width * T, data.height * T)
	camera.target = player
	add_child(camera)
	camera.make_current()
	camera.snap_to_target()
	background = ParallaxBG.new()
	add_child(background)
	background.setup(data.get_str("bg", theme), camera)
	background.level_bottom = data.height * T


func _build_ui() -> void:
	hud = HudScript.new()
	hud.level = self
	add_child(hud)
	touch = TouchScript.new()
	add_child(touch)
	touch.pause_pressed.connect(toggle_pause)
	pause_menu = PauseScript.new()
	add_child(pause_menu)
	pause_menu.resume_requested.connect(func(): set_paused(false))
	var info := GameState.level_info(level_id)
	hud.show_banner("WORLD %s" % level_id, info.get("name", ""))


# =================================================================== loop
func _physics_process(delta: float) -> void:
	if player == null:
		return
	_door_cooldown = max(0.0, _door_cooldown - delta)
	if player.is_on_floor():
		combo = 0
	if not completed and player.state != Player.State.DEAD and player.state != Player.State.CUTSCENE:
		time_left -= delta
		if time_left <= 60.0 and not _hurry:
			_hurry = true
			AudioManager.play_sfx("hurry")
			AudioManager.set_music_pitch(1.12)
		if time_left <= 0.0:
			time_left = 0.0
			player.die("time")
	_update_doors()
	_update_arena()
	if player.state == Player.State.DEAD and player.death_finished() and not _death_started:
		_death_started = true
		_after_death()


func _update_doors() -> void:
	var near: Node = null
	if player.state == Player.State.NORMAL and player.is_on_floor() and _door_cooldown <= 0.0:
		for d in doors:
			if d.partner and d.player_inside(player):
				near = d
				break
	if touch:
		touch.set_context_visible(near != null)
	if near and (Input.is_action_just_pressed("interact") or (touch and touch.consume_context())):
		_use_door(near)


func _use_door(d: Node) -> void:
	_door_cooldown = 1.0
	player.enter_cutscene()
	d.open_anim()
	AudioManager.play_sfx("door")
	if hud:
		await hud.fade_out(0.25)
	player.global_position = d.partner.global_position
	player.velocity = Vector2.ZERO
	camera.snap_to_target()
	d.partner.open_anim()
	if hud:
		await hud.fade_in(0.25)
	player.leave_cutscene()


# =================================================================== queries
func cell_at(world: Vector2) -> Vector2i:
	return terrain.local_to_map(terrain.to_local(world))


func atlas_at(c: Vector2i) -> Vector2i:
	if terrain.get_cell_source_id(c) == -1:
		return Vector2i(-1, -1)
	return terrain.get_cell_atlas_coords(c)


func is_solid_at(world: Vector2) -> bool:
	var a := atlas_at(cell_at(world))
	return a in Tiles.SOLID or Tiles.ONE_WAY.has(a)


func floor_kind_at(world: Vector2) -> String:
	var a := atlas_at(cell_at(world))
	if a == Tiles.ICE:
		return "ice"
	if a == Tiles.CONV_L:
		return "conveyor_left"
	if a == Tiles.CONV_R:
		return "conveyor_right"
	return ""


func hazard_in_rect(r: Rect2) -> String:
	var c0 := cell_at(r.position)
	var c1 := cell_at(r.end)
	for y in range(c0.y, c1.y + 1):
		for x in range(c0.x, c1.x + 1):
			var c := Vector2i(x, y)
			if not hazard_cells.has(c):
				continue
			var kind: String = hazard_cells[c]
			# spikes/goo only hurt in their lower part (their art has empty space on top)
			var cell_rect := Rect2(x * T + 2, y * T + (6 if kind == "spikes" else 7), T - 4, T - 6)
			if atlas_at(c) == Tiles.GOO_FILL:
				cell_rect = Rect2(x * T, y * T, T, T)
			if cell_rect.intersects(r):
				return kind
	return ""


func kill_y() -> float:
	return data.height * T + 40.0


func is_near_view(pos: Vector2, margin: float) -> bool:
	if camera == null:
		return true
	return camera.visible_rect().grow(margin).has_point(pos)


func is_far_behind(pos: Vector2) -> bool:
	if camera == null:
		return false
	var r := camera.visible_rect()
	return pos.x < r.position.x - 480.0 or pos.x > r.end.x + 640.0


func camera_punch(amount: float) -> void:
	if camera:
		camera.punch(amount)


# =================================================================== blocks
func hit_block_at(world: Vector2, p: Player) -> bool:
	var c := cell_at(world)
	var a := atlas_at(c)
	if a == Vector2i(-1, -1) or not (a in Tiles.SOLID):
		return false
	if a == Tiles.EBLOCK:
		var content: String = block_contents.get(c, "token")
		block_contents.erase(c)
		_bump_tile(c, Tiles.USED)
		_release_content(c, content)
		_bump_enemies_above(c)
		Settings.haptic(15, 0.3)
		return true
	if Tiles.is_breakable(a):
		if p.is_mega() or p.has_power("overload"):
			break_tile(c)
		else:
			_bump_tile(c, a)
			AudioManager.play_sfx("bump")
		_bump_enemies_above(c)
		return true
	AudioManager.play_sfx("bump", 0.05, -6.0)
	return true


func _bump_tile(c: Vector2i, restore: Vector2i) -> void:
	var a := atlas_at(c)
	var tex: Texture2D = (terrain.tile_set.get_source(0) as TileSetAtlasSource).texture
	terrain.set_cell(c, 0, Tiles.INVISIBLE)
	var region := Rect2(Vector2(a) * T, Vector2(T, T))
	BlockEffects.bump(fx_root, tex, region, Vector2(c) * T + Vector2(8, 8), func():
		if atlas_at(c) == Tiles.INVISIBLE:
			terrain.set_cell(c, 0, restore))


func _release_content(c: Vector2i, content: String) -> void:
	var top := Vector2(c.x * T + 8, c.y * T)
	if content == "token":
		BlockEffects.token_pop(fx_root, top)
		AudioManager.play_sfx("token")
		on_collect("token", 0, top, true)
	elif content == "life":
		_add_collectible("life", 0, top + Vector2(0, -10))
		AudioManager.play_sfx("powerup_appear")
	elif content.begins_with("power:"):
		spawn_powerup(content.substr(6), Vector2(c.x * T + 8, (c.y + 1) * T), true)


func try_reveal_hidden(world: Vector2, head_now: float) -> void:
	var c := cell_at(world)
	if not hidden_blocks.has(c):
		return
	if head_now < (c.y + 1) * T - 1:
		return   # only when coming from below
	if terrain.get_cell_source_id(c) != -1:
		return
	block_contents[c] = hidden_blocks[c]
	hidden_blocks.erase(c)
	terrain.set_cell(c, 0, Tiles.EBLOCK)
	AudioManager.play_sfx("secret", 0.0, -4.0)


func break_tile(c: Vector2i) -> void:
	var a := atlas_at(c)
	terrain.erase_cell(c)
	var center := Vector2(c) * T + Vector2(8, 8)
	FX.debris(center, Color("ff8af0") if a == Tiles.BARRIER else Color.WHITE)
	FX.spawn("puff", center)
	AudioManager.play_sfx("break_barrier" if a == Tiles.BARRIER else "brick")
	Settings.haptic(20, 0.4)
	GameState.add_score(50)
	_bump_enemies_above(c)


func dash_break_at(world: Vector2) -> void:
	var c := cell_at(world)
	var a := atlas_at(c)
	if a == Tiles.BARRIER or Tiles.is_breakable(a):
		break_tile(c)
		FX.shake(1.5, 0.12)


func _bump_enemies_above(c: Vector2i) -> void:
	var r := Rect2(c.x * T - 2, c.y * T - 10, T + 4, 12)
	for e in get_tree().get_nodes_in_group("enemies"):
		if e is Enemy and not e.dead and r.has_point(e.global_position):
			e.defeat("knock")
	for it in entities.get_children():
		if it is CharacterBody2D and it.has_method("_on_body") and r.has_point(it.global_position):
			it.velocity.y = -200.0


func update_secret_walls(r: Rect2) -> void:
	for g in secret_groups:
		var inside: bool = (g.rect as Rect2).grow(-2).intersects(r)
		var layer: TileMapLayer = g.layer
		var want := 0.25 if inside else 1.0
		layer.modulate.a = move_toward(layer.modulate.a, want, 0.08)
		if inside and not g.revealed:
			g.revealed = true
			stats.secrets_revealed += 1
			AudioManager.play_sfx("secret")
			FX.popup(r.get_center() + Vector2(0, -20), "SECRET!", Color("7dff5a"))


# =================================================================== events
func on_collect(kind: String, index: int, pos: Vector2, from_block := false) -> void:
	match kind:
		"token":
			stats.tokens += 1
			GameState.add_score(10)
			GameState.add_tokens(1)
			if not from_block:
				AudioManager.play_sfx("token", 0.03)
		"shard":
			GameState.attempt_shards.append(index)
			GameState.add_score(1000)
			AudioManager.play_sfx("shard")
			FX.popup(pos, "1000", Color("8fe0ff"))
			Settings.haptic(40, 0.6)
			camera_punch(0.05)
		"core":
			GameState.attempt_cores.append(index)
			GameState.add_score(2000)
			AudioManager.play_sfx("secret")
			FX.popup(pos, "ENERGY CORE!", Color("7dff5a"))
			Settings.haptic(50, 0.7)
		"life":
			GameState.add_life()
			AudioManager.play_sfx("oneup")
			FX.popup(pos, "1UP", Color("7dff5a"))
	if hud:
		hud.refresh()


func on_powerup_collected(kind: String, pos: Vector2) -> void:
	GameState.add_score(1000)
	FX.popup(pos + Vector2(0, -8), kind.to_upper(), Player.POWER_COLOR.get(kind, Color.WHITE))


func on_enemy_defeated(e: Enemy, how: String) -> void:
	stats.enemies += 1
	var values := [100, 200, 400, 800, 1000]
	var pts: int = values[min(combo, values.size() - 1)] * (2 if e.score_value >= 200 else 1)
	if combo >= values.size():
		GameState.add_life()
		AudioManager.play_sfx("oneup")
		FX.popup(e.global_position + Vector2(0, -16), "1UP", Color("7dff5a"))
	else:
		FX.popup(e.global_position + Vector2(0, -16), str(pts))
	GameState.add_score(pts)
	if how == "squash" and not player.is_on_floor():
		combo += 1
	FX.shake(1.0, 0.08)


func _on_checkpoint(index: int) -> void:
	for cp in checkpoints:
		if cp.index < index:
			cp.set_active(true)
	GameState.set_checkpoint(index)
	player.heal_full()
	if hud:
		hud.flash_message("CHECKPOINT")


func _on_player_died() -> void:
	if touch:
		touch.set_enabled(false)


func _after_death() -> void:
	if testing:
		return
	if GameState.lose_life():
		GameState.respawn_after_death()
	else:
		AudioManager.play_music("game_over", 0.1)
		var go := GameOverScript.new()
		add_child(go)


# =================================================================== arena
func _update_arena() -> void:
	if arena_gate_x < 0 or arena_active or completed:
		return
	if player.global_position.x > arena_gate_x * T + 28 and player.state == Player.State.NORMAL:
		start_arena()


func start_arena() -> void:
	arena_active = true
	var gx := arena_gate_x
	camera.lock_rect = Rect2(gx * T, 0, (data.width - gx) * T, data.height * T)
	for y in data.height:
		var c := Vector2i(gx, y)
		if terrain.get_cell_source_id(c) == -1:
			terrain.set_cell(c, 0, Tiles.HARD)
	FX.shake(2.0, 0.3)
	AudioManager.play_sfx("slam")
	var boss_name := data.get_str("boss", "")
	if BOSS_SCRIPTS.has(boss_name):
		boss = load(BOSS_SCRIPTS[boss_name]).new()
		boss.level = self
		boss.arena = camera.lock_rect
		boss.position = boss_spawn
		entities.add_child(boss)
		boss.defeated.connect(_on_boss_defeated)
		if hud:
			hud.show_boss(boss)
	if not testing:
		AudioManager.play_music("final_boss" if boss_name == "overload_core" else "boss", 0.4)


func _on_boss_defeated() -> void:
	GameState.add_score(10000)
	FX.popup(boss.global_position + Vector2(0, -40), "10000", Color("ffd23f"))
	if hud:
		hud.hide_boss()
	if not testing:
		AudioManager.play_music("victory", 0.2)
	await get_tree().create_timer(2.0, false).timeout
	if goal:
		goal.set_enabled(true)
		FX.sparkle(goal.global_position + Vector2(0, -40), 10, 24)
		AudioManager.play_sfx("powerup_appear")
	if not testing:
		AudioManager.play_music(data.get_str("music", "overworld"), 1.0)


# =================================================================== completion
func _on_goal_touched(ratio: float) -> void:
	if completed or player.state == Player.State.DEAD:
		return
	completed = true
	var flag_bonus := 100
	for tier in [[0.9, 5000], [0.7, 2000], [0.5, 800], [0.3, 400]]:
		if ratio >= tier[0]:
			flag_bonus = tier[1]
			break
	GameState.add_score(flag_bonus)
	FX.popup(player.global_position + Vector2(0, -30), str(flag_bonus), Color("ffd23f"))
	player.enter_goal_state()
	player.clear_powers(false)
	if touch:
		touch.set_enabled(false)
	AudioManager.stop_music(0.2)
	AudioManager.play_sfx("powerup")
	Settings.haptic(80, 0.8)
	camera_punch(0.08)
	player.global_position.x = goal.global_position.x - 7
	var ground_y: float = goal.global_position.y
	var t := create_tween()
	t.tween_property(player, "global_position:y", ground_y, 0.7)
	goal.flag_drop(0.7)
	await t.finished
	player.global_position.x += 12
	player.cutscene_walk = 70.0
	await get_tree().create_timer(0.9, false).timeout
	player.cutscene_walk = 0.0
	player.play_victory()
	if not testing:
		AudioManager.play_music("victory", 0.1)
	FX.sparkle(player.global_position + Vector2(0, -20), 10, 26)
	await get_tree().create_timer(1.6, false).timeout
	var result := build_result(flag_bonus)
	level_completed.emit(result)
	if testing:
		return
	GameState.complete_level(result)
	var lc := CompleteScript.new()
	lc.result = result
	add_child(lc)


func build_result(flag_bonus := 0) -> Dictionary:
	var time_bonus := int(ceil(time_left)) * 10
	var shards: Array = GameState.attempt_shards.duplicate()
	var cores: Array = GameState.attempt_cores.duplicate()
	GameState.add_score(time_bonus)
	var level_score: int = GameState.score - GameState.level_start_score
	return {
		"level": level_id, "tokens": stats.tokens, "enemies": stats.enemies,
		"time_left": int(ceil(time_left)), "time_bonus": time_bonus, "flag_bonus": flag_bonus,
		"shards": shards, "shards_total": shards_total, "cores": cores, "cores_total": cores_total,
		"secrets_revealed": stats.secrets_revealed, "level_score": level_score,
	}


# =================================================================== pause
func toggle_pause() -> void:
	set_paused(not get_tree().paused)


func set_paused(on: bool) -> void:
	if completed or (player and player.state == Player.State.DEAD) or testing:
		return
	if pause_menu == null:
		return
	get_tree().paused = on
	if on:
		pause_menu.open()
		AudioManager.duck_music(0.35)
		AudioManager.play_sfx("pause")
		GameState.save_continue()
	else:
		pause_menu.close()
		AudioManager.duck_music(1.0)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		toggle_pause()
		get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_WM_WINDOW_FOCUS_OUT:
			if not get_tree().paused:
				set_paused(true)
			Settings.save()
		NOTIFICATION_WM_GO_BACK_REQUEST:
			if not get_tree().paused:
				set_paused(true)
			elif pause_menu and pause_menu.has_method("back"):
				pause_menu.back()
