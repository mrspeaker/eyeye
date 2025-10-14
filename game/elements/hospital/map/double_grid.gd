extends GridMap

const CELL_SIZE := 3.0
const CELLS_X := 41
const CELLS_Z := 22
var _astar := AStar2D.new()

enum Tiles {
	TestCube,
	Floor,
	Wall,
	WallHalf,
	Doorway,
	Floor2,
	WallWood,
	DoorFlip,
	FloorDark,
	FloorLino,
	ShopCube,
	WallBlue,
	HandRail,
	Grass
}

func _ready() -> void:
	_init_astar()

func find_path(from: Vector3, to: Vector3) -> Array[Vector2]:
	var p1 = _astar.get_closest_point(Vector2(from.x, from.z))
	var p2 = _astar.get_closest_point(Vector2(to.x, to.z))
	var out: Array[Vector2] = []
	var packed = _astar.get_point_path(p1, p2)
	for i in packed: out.append(i)
	return out

func get_rnd_tile_pos_by_type(type: Tiles):
	var all = get_used_cells_by_item(type)
	var tile = all.pick_random()
	return map_to_local(tile)

func _init_astar():

	# Add all walkable ground positions
	for j in range(0, CELLS_X): # _astar.region.end.y):
		for i in range(0, CELLS_Z): #_astar.region.end.x):
			var pos = Vector3(i * CELL_SIZE, 0, -j * CELL_SIZE - 1)
			var cell = pos_to_two_cell(pos)
			var edges = get_cell_edge_items(cell)
			var ground = edges[Globals.Dir.DOWN]
			if !is_walkable(ground):
				continue
			var id = _astar.get_available_point_id()
			_astar.add_point(id, Vector2(pos.x, pos.z))

	# Take two: connect all walkable points
	for j in range(0, CELLS_X): # _astar.region.end.y):
		for i in range(0, CELLS_Z): #_astar.region.end.x):
			var pos = Vector3(i * CELL_SIZE, 0, -j * CELL_SIZE - 1)
			var cell = pos_to_two_cell(pos)
			var edges = get_cell_edge_items(cell)
			var ground = edges[Globals.Dir.DOWN]
			if !is_walkable(ground):
				continue
			var id = _astar.get_closest_point(Vector2(pos.x, pos.z))
			_connect_cardinal(id, pos, Globals.Dir.N)
			_connect_cardinal(id, pos, Globals.Dir.S)
			_connect_cardinal(id, pos, Globals.Dir.E)
			_connect_cardinal(id, pos, Globals.Dir.W)

'''
	Helper method to connect a point to the N,S,E,W cells
	if they are "walkable"
'''
func _connect_cardinal(id: int, pos: Vector3, dir: Globals.Dir):
	var pos2 = get_pos_in_direction(pos, dir)
	if pos2 == null: return
	var nid = _astar.get_closest_point(Vector2(pos2.x, pos2.z))
	if nid != id:
		_astar.connect_points(id, nid)

func pos_to_two_cell(pos: Vector3) -> Vector3i:
	# 0,0,0 is in positive z direction - so 0,0,-1 is first cell in our world
	var neg_offset = Vector3i(
		-1 if pos.x < 0 else 0,
		0,
		-1 if pos.z < 0 else 0)
	var grid_pos = local_to_map(pos) + neg_offset
	var grid_pos_mod_two = Vector3i(floor(grid_pos / 2) * 2)
	return grid_pos_mod_two - neg_offset

'''
THe way the grid works is you give position in the bottom left
of a 2x2 cell.

note in the editor (0,0,0) is +z (opposite side of z line).
So theThe first floor cell in the game world is (1,0,-1)
'''
func get_cell_edge_items(cell: Vector3i):
	# TODO: assert cell is mod 2?
	var ground = get_cell_item(cell + Vector3i(1, 0, 0)) # floor is br
	if ground == -1:
		#print("no ground!")
		ground = -2

	var north = get_cell_item(cell + Vector3i(1, 0, -1)) # tr is a wall N
	# NOTHING in tl... var trl= get_cell_item(cell + Vector3i(0, 0, -1))
	var west = get_cell_item(cell + Vector3i(0, 0, 0)) # bl is a wall W
	var south = get_cell_item(cell + Vector3i(1, 0, 1)) # tr in closer z cell
	var east = get_cell_item(cell + Vector3i(2, 0, 0)) # bl in futher x cell
	return [north, south, east, west, ground]

func get_cell_edges(cell: Vector3i):
	return get_cell_edge_items(cell).map(is_walkable)

const walkables = [
	false, true, false, false, true,
	true, false, true, true, true,
	false, false, false, true
]

func is_walkable(idx: int):
	if idx == -1:
		return true
	if idx == -2:
		return false
	return walkables[idx]

func get_pos_in_direction(pos: Vector3, dir: Globals.Dir):
	var dest = get_next_cell_pos(pos, dir)
	var cell = pos_to_two_cell(dest)
	var edges = get_cell_edge_items(cell)
	# Can we pass?
	if not is_walkable(edges[Globals.Dir.DOWN]): return null # ground
	if not is_walkable(edges[Globals.dir_op(dir)]): return null # opposite edge
	return dest

func get_next_cell_pos(pos: Vector3, d: Globals.Dir) -> Vector3:
	var cell = get_next_cell(pos, d)
	var pos_edge = map_to_local(cell)
	return pos_edge + Vector3(1.5, 0, 0) # todo: why the offset on x (or why ONLY x?!)

func get_next_cell(pos: Vector3, d: Globals.Dir) -> Vector3i:
	var x_dir = 0
	var z_dir = 0
	if d == Globals.Dir.N: z_dir = -1
	if d == Globals.Dir.S: z_dir = 1
	if d == Globals.Dir.E: x_dir = 1
	if d == Globals.Dir.W: x_dir = -1
	var cur_cell = pos_to_two_cell(pos)
	var one_cell = Vector3i(x_dir, 0, z_dir) * 2
	return cur_cell + one_cell


'''
Some "unit test" stuff
'''

func dumpit():
	for y in range(0, -82, -1):
		var row := ""
		for x in range(0, 43):
			var item = get_cell_item(Vector3(x, 0, y))
			row += (str(item) if item >=0 else ".") + " "
		print(row)


func arr_eq(a: Array, b: Array) -> bool:
	return a.hash() == b.hash()

func ut_eq(nom, a, b):
	var is_equal = false
	var typ = typeof(a)
	if typ == 28: #array
		is_equal = arr_eq(a, b)
	else:
		#print("tupe:", typeof(a))
		is_equal = a == b
	print("PASS" if is_equal else "FAIL", " - ", nom, " expects ", b, " is ", a)

func _test_two_grid():
	# local to map
	ut_eq("loc-map1", local_to_map(Vector3(0,0,1.6)), Vector3i(0, 0, 1))
	ut_eq("loc-map2", local_to_map(Vector3(0,0,0.1)), Vector3i(0, 0, 0))
	ut_eq("loc-map3", local_to_map(Vector3(0,0,-0.1)), Vector3i(0, 0, -1))
	ut_eq("loc-map4", local_to_map(Vector3(0,0,-1.6)), Vector3i(0, 0, -2))
	ut_eq("loc-map5", local_to_map(Vector3(0,0,-3.1)), Vector3i(0, 0, -3))

	ut_eq("loc-map6", local_to_map(Vector3(0.1,0,-0.1)), Vector3i(0, 0, -1))
	ut_eq("loc-map7", local_to_map(Vector3(1.6,0,-1.6)), Vector3i(1, 0, -2))
	ut_eq("loc-map8", local_to_map(Vector3(3.1,0,-3.1)), Vector3i(2, 0, -3))

	# Test get cell item
	ut_eq("cell item", get_cell_item(Vector3i(1,0,-1)), 1)

	# Test position to cell
	print("Pos to two cell")
	ut_eq("pos two-cell1", pos_to_two_cell(Vector3(0, 0, 0)), Vector3i(0, 0, 0))
	ut_eq("pos two_cell2", pos_to_two_cell(Vector3(2.9, 0, 0)), Vector3i(0, 0, 0))
	ut_eq("pos two-cell3", pos_to_two_cell(Vector3(0, 0, 2.9)), Vector3i(0, 0, 0))
	ut_eq("pos two_cell4", pos_to_two_cell(Vector3(2.9, 0, 2.9)), Vector3i(0, 0, 0))

	ut_eq("pos two-cell5", pos_to_two_cell(Vector3(0.1, 0, -0.1)), Vector3i(0, 0, -1))
	ut_eq("pos two-cell6", pos_to_two_cell(Vector3(0.1, 0, -1.6)), Vector3i(0, 0, -1))
	ut_eq("pos two-cell7", pos_to_two_cell(Vector3(0.1, 0, -3.1)), Vector3i(0, 0, -3))

	ut_eq("pos two-cell8", pos_to_two_cell(Vector3(-0.1, 0, -0.1)), Vector3i(-1, 0, -1))


	# Position + direction to cell
	ut_eq("items 1", get_cell_edge_items(Vector3i(0, 0, -1)), [2, 2, 2, 2, 1])
	ut_eq("items 2", get_cell_edge_items(Vector3i(8, 0, -25)), [-1, -1, 4, -1, 1])
	ut_eq("items 3", get_cell_edge_items(Vector3i(10, 0, -25)), [-1, 2, -1, 4, 5])

	#ut_eq("path 1", _astar.get_point_path(3, 7), [Vector3(18.0, 0, -1.0), Vector3(18.0, 0, -4.0), Vector3(18.0, 0, -7.0)])
