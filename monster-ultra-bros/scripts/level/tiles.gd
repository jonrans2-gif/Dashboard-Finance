class_name Tiles
## Atlas coordinates (identical for every theme) and the TileSet factory.

const SIZE := 16
const SOURCE := 0

const GROUND_TL := Vector2i(0, 0)
const GROUND_T := Vector2i(1, 0)
const GROUND_TR := Vector2i(2, 0)
const FILL := Vector2i(3, 0)
const BRICK := Vector2i(4, 0)
const EBLOCK := Vector2i(5, 0)       # animated, 3 frames
const USED := Vector2i(0, 1)
const HARD := Vector2i(1, 1)
const PLAT_L := Vector2i(2, 1)
const PLAT_M := Vector2i(3, 1)
const PLAT_R := Vector2i(4, 1)
const BARRIER := Vector2i(5, 1)
const SPIKES := Vector2i(6, 1)
const ICE := Vector2i(7, 1)
const PIPE_TL := Vector2i(0, 2)
const PIPE_TR := Vector2i(1, 2)
const PIPE_L := Vector2i(2, 2)
const PIPE_R := Vector2i(3, 2)
const CONV_L := Vector2i(4, 2)       # animated, 2 frames
const CONV_R := Vector2i(6, 2)       # animated, 2 frames
const WALL_L := Vector2i(0, 3)
const WALL_R := Vector2i(1, 3)
const INVISIBLE := Vector2i(2, 3)    # solid, transparent (used while a block bumps)
const BUSH := Vector2i(3, 3)
const FLOWER := Vector2i(4, 3)
const FENCE := Vector2i(5, 3)
const LAMP := Vector2i(6, 3)
const ARROW := Vector2i(7, 3)
const BG_WALL := Vector2i(0, 4)
const BG_WALL2 := Vector2i(1, 4)
const CHAIN := Vector2i(2, 4)
const GOO_TOP := Vector2i(3, 4)      # animated, 2 frames
const GOO_FILL := Vector2i(5, 4)
const CLOUD := Vector2i(6, 4)
const SNOWCAP := Vector2i(7, 4)
const FILL2 := Vector2i(0, 5)
const GROUND_T2 := Vector2i(1, 5)
const BRICK_CRACKED := Vector2i(2, 5)
const WINDOW := Vector2i(3, 5)
const TORCH := Vector2i(4, 5)        # animated, 2 frames
const SIGN := Vector2i(6, 5)
const CRYSTAL := Vector2i(7, 5)

const SOLID := [GROUND_TL, GROUND_T, GROUND_TR, FILL, BRICK, EBLOCK, USED, HARD, BARRIER, ICE,
	PIPE_TL, PIPE_TR, PIPE_L, PIPE_R, CONV_L, CONV_R, WALL_L, WALL_R, INVISIBLE, SNOWCAP,
	FILL2, GROUND_T2, BRICK_CRACKED]
const ONE_WAY := {PLAT_L: 6, PLAT_M: 6, PLAT_R: 6, CLOUD: 9}
const DECOR := [BUSH, FLOWER, FENCE, LAMP, ARROW, BG_WALL, BG_WALL2, CHAIN, GOO_FILL,
	SIGN, CRYSTAL, WINDOW]
const ANIMATED := {EBLOCK: [3, 0.18], CONV_L: [2, 0.12], CONV_R: [2, 0.12],
	GOO_TOP: [2, 0.4], TORCH: [2, 0.15]}

static var _cache: Dictionary = {}


static func tileset(theme: String) -> TileSet:
	if _cache.has(theme):
		return _cache[theme]
	var ts := TileSet.new()
	ts.tile_size = Vector2i(SIZE, SIZE)
	ts.add_physics_layer()
	ts.set_physics_layer_collision_layer(0, 1)
	ts.set_physics_layer_collision_mask(0, 0)
	var src := TileSetAtlasSource.new()
	src.texture = load("res://assets/tiles/%s.png" % theme)
	src.texture_region_size = Vector2i(SIZE, SIZE)
	ts.add_source(src, SOURCE)
	var all: Array = SOLID + ONE_WAY.keys() + DECOR + [SPIKES, GOO_TOP, TORCH]
	for coords in all:
		if src.has_tile(coords):
			continue
		src.create_tile(coords)
		if ANIMATED.has(coords):
			src.set_tile_animation_columns(coords, 0)
			src.set_tile_animation_frames_count(coords, ANIMATED[coords][0])
			for f in ANIMATED[coords][0]:
				src.set_tile_animation_frame_duration(coords, f, ANIMATED[coords][1])
		var td := src.get_tile_data(coords, 0)
		var h := SIZE / 2.0
		if coords in SOLID:
			td.add_collision_polygon(0)
			td.set_collision_polygon_points(0, 0, PackedVector2Array([
				Vector2(-h, -h), Vector2(h, -h), Vector2(h, h), Vector2(-h, h)]))
		elif ONE_WAY.has(coords):
			var thick: float = ONE_WAY[coords]
			td.add_collision_polygon(0)
			td.set_collision_polygon_points(0, 0, PackedVector2Array([
				Vector2(-h, -h), Vector2(h, -h), Vector2(h, -h + thick), Vector2(-h, -h + thick)]))
			td.set_collision_polygon_one_way(0, 0, true)
			td.set_collision_polygon_one_way_margin(0, 0, 3.0)
	_cache[theme] = ts
	return ts


static func is_breakable(coords: Vector2i) -> bool:
	return coords == BRICK or coords == BRICK_CRACKED


static func is_ground_like(coords: Vector2i) -> bool:
	return coords in [GROUND_TL, GROUND_T, GROUND_TR, FILL, FILL2, GROUND_T2, WALL_L, WALL_R, SNOWCAP]
