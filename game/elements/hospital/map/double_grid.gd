extends GridMap

func pos_to_two_cell(pos: Vector3) -> Vector3i:
	# 0,0,0 is in positive z direction - so 0,0,-1 is first cell in our world
	var neg_offset = Vector3i(0, 0, -1 if pos.z < 0 else 0)
	var grid_pos = local_to_map(pos) + neg_offset
	var grid_pos_mod_two = Vector3i(floor(grid_pos / 2) * 2)
	return grid_pos_mod_two - neg_offset
	
func _ready() -> void:
	_test_two_grid()
	pass
	
'''
THe way the grid works is you give position in the bottom left
of a 2x2 cell.

note in the editor (0,0,0) is +z (opposite side of z line).
So theThe first floor cell in the game world is (1,0,-1)
'''
func get_cell_edge_items(cell: Vector3i):
	# TODO: assert cell is mod 2?
	var ground = get_cell_item(cell + Vector3i(0, 0, 0)) # floor is br
	var north = get_cell_item(cell + Vector3i(0, 0, -1)) # tr is a wall N
	# NOTHING in tl... var trl= get_cell_item(cell + Vector3i(0, 0, -1))
	var west = get_cell_item(cell + Vector3i(1, 0, 0)) # bl is a wall W
	var south = get_cell_item(cell + Vector3i(0, 0, 1)) # tr in closer z cell
	var east = get_cell_item(cell + Vector3i(-1, 0, 0)) # bl in futher x cell
	return [north, south, east, west, ground]
	
func get_cell_edges(cell: Vector3i):
	return get_cell_edge_items(cell).map(is_walkable)

const walkables = [
	false, true, false, false, true, 
	true, false, true, true, true, 
	false
]

func is_walkable(idx: int):
	if idx == -1:
		return true
	return walkables[idx]
	

'''
Some "unit test" stuff
'''

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
	
	# Position + direction to cell
	ut_eq("items 2", get_cell_edge_items(Vector3i(1, 0, -1)), [2, 2, 2, 2, 1])
