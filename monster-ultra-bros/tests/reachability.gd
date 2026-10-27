class_name Reachability
extends RefCounted
## Conservative reachability analysis on a LevelData grid.
##
## The can is modelled as a 1x2-cell body. From every standable cell it may
## walk, fall, jump (<= JUMP_UP cells up, limited horizontal reach that
## shrinks with height, with a clear arc), use springs and warp doors.
## Moving platforms count as support along their whole track, falling
## platforms as support where they hang. Breakable blocks/barriers count as
## solid unless `can_break` is set (Energy Surge available). The model is
## stricter than the real physics (see test_physics.gd), so "reachable"
## here implies reachable in-game.

const JUMP_UP := 3
const SPRING_UP := 8
const SOLID := "#=?!BXI<>[]n"
const ONE_WAY := "_c"
const HAZARD := "^~"

var data: LevelData
var can_break := false
var jump_up := JUMP_UP           # 3 for the required route, 4 for optional collectibles
var reach: Dictionary = {}       # Vector2i -> true (standable + reachable)
var _support: Dictionary = {}    # extra support cells from platforms
var _track_h: Dictionary = {}    # cells occupied by horizontal/falling platforms (no standing inside)
var _doors: Dictionary = {}      # Vector2i -> partner Vector2i


func _init(d: LevelData, breaker := false, up := JUMP_UP) -> void:
	data = d
	can_break = breaker
	jump_up = up
	_index_platforms()


func _index_platforms() -> void:
	var doors: Array = []
	for y in data.height:
		for x in data.width:
			var ch := data.at(x, y)
			if ch == "m":
				var n := 0
				while data.at(x + 1 + n, y) == "-":
					n += 1
				for i in range(0, 3 + n):
					_support[Vector2i(x + i, y)] = true
					_track_h[Vector2i(x + i, y)] = true
			elif ch == "v":
				var k := 0
				while data.at(x, y + 1 + k) == ":":
					k += 1
				for j in range(0, k + 1):
					for i in 3:
						_support[Vector2i(x + i, y + j)] = true
			elif ch == "x":
				for i in 2:
					_support[Vector2i(x + i, y)] = true
					_track_h[Vector2i(x + i, y)] = true
			elif ch == "D":
				doors.append(Vector2i(x, y))
	for i in range(0, doors.size() - 1, 2):
		_doors[doors[i]] = doors[i + 1]
		_doors[doors[i + 1]] = doors[i]


func solid(x: int, y: int) -> bool:
	if x < 0 or x >= data.width:
		return true
	if y < 0 or y >= data.height:
		return false
	var ch := data.at(x, y)
	if can_break and (ch == "X" or ch == "="):
		return false
	return SOLID.contains(ch)


func passable(x: int, y: int) -> bool:
	return not solid(x, y)


func supports(x: int, y: int) -> bool:
	## Can the can stand on cell (x, y)?
	if y >= data.height:
		return false
	if solid(x, y):
		return true
	var ch := data.at(x, y)
	return ONE_WAY.contains(ch) or _support.has(Vector2i(x, y))


func standable(x: int, y: int) -> bool:
	if y < 1 or y >= data.height:
		return false
	if not (passable(x, y) and passable(x, y - 1)):
		return false
	if HAZARD.contains(data.at(x, y)):
		return false
	if _track_h.has(Vector2i(x, y)):
		return false   # inside a horizontal track; the can stands on top of it
	return supports(x, y + 1)


func body_clear(x: int, y: int) -> bool:
	return passable(x, y) and passable(x, y - 1) and not HAZARD.contains(data.at(x, y))


func max_dx(dy: int) -> int:
	## Horizontal reach in cells for a jump that ends `dy` cells higher.
	## Measured physics (test_physics): 4.4 cells high, 5.8 cells far when
	## walking; these limits keep a safety margin of at least one cell.
	if dy < 0:
		return mini(6, 4 + (-dy) / 2)
	if dy <= 2:
		return 4
	if dy == 3:
		return 3
	return 2


func run(from: Vector2i) -> Dictionary:
	reach.clear()
	var start := from
	# the start marker sits on the floor already
	var queue: Array = [start]
	reach[start] = true
	while not queue.is_empty():
		var c: Vector2i = queue.pop_front()
		for n in _neighbours(c):
			if not reach.has(n):
				reach[n] = true
				queue.append(n)
	return reach


func _neighbours(c: Vector2i) -> Array:
	var out: Array = []
	var x := c.x
	var y := c.y
	# walking / falling off ledges
	for dx in [-1, 1]:
		var nx: int = x + dx
		if standable(nx, y):
			out.append(Vector2i(nx, y))
		elif body_clear(nx, y):
			var land := _fall(nx, y)
			if land != Vector2i(-1, -1):
				out.append(land)
	# warp doors
	if _doors.has(c):
		out.append(_doors[c])
	# jumps
	var up := SPRING_UP if data.at(x, y) == "j" else jump_up
	for ty in range(y - up, y + 8):
		var dy := y - ty
		var lim := max_dx(dy) if up == jump_up else 3
		for tx in range(x - lim, x + lim + 1):
			if tx == x and ty == y:
				continue
			if not standable(tx, ty):
				continue
			if _arc_clear(x, y, tx, ty, up):
				out.append(Vector2i(tx, ty))
	return out


func _fall(x: int, y: int) -> Vector2i:
	var yy := y
	while yy < data.height + 1:
		if not body_clear(x, yy):
			return Vector2i(-1, -1)
		if standable(x, yy):
			return Vector2i(x, yy)
		yy += 1
	return Vector2i(-1, -1)


func _arc_clear(x: int, y: int, tx: int, ty: int, up: int) -> bool:
	# Try apex rows from just above the higher end up to the jump limit.
	var top := mini(y, ty)
	for apex in range(top, y - up - 1, -1):
		if apex < y - up:
			break
		if _path_ok(x, y, tx, ty, apex):
			return true
	return false


func _path_ok(x: int, y: int, tx: int, ty: int, apex: int) -> bool:
	for yy in range(apex, y + 1):
		if not body_clear(x, yy) and not (yy == y):
			return false
	var step := 1 if tx > x else -1
	if tx != x:
		var xx := x
		while xx != tx:
			xx += step
			if not body_clear(xx, apex):
				return false
	for yy in range(apex, ty + 1):
		if not body_clear(tx, yy):
			return false
	return true


## Can an item at `cell` be touched from any reachable position?
func item_reachable(cell: Vector2i) -> bool:
	for c in reach.keys():
		var dx: int = abs(c.x - cell.x)
		var dy: int = c.y - cell.y
		if dx <= 1 and dy >= 0 and dy <= jump_up + 1:
			var ok := true
			for yy in range(cell.y, c.y + 1):
				if solid(c.x, yy):
					ok = false
					break
			if ok:
				return true
		if dx <= 3 and data.at(c.x, c.y) == "j" and dy >= 0 and dy <= SPRING_UP + 1:
			return true
	return false


func any_reached(pred: Callable) -> bool:
	for c in reach.keys():
		if pred.call(c):
			return true
	return false
