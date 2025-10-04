extends CharacterBody3D

@export var gridmap: GridMap

const MOVE_TIME = 0.5

var move_time = 0.0
var dest_pos = null
var move_elapsed = 0.0
var active = false
var dir = Globals.Dir.W #NONE

var rng = RandomNumberGenerator.new()

func turn_start():
	active = true
	
func turn_end():
	active = false
	
func _physics_process(dt: float) -> void:
	if not active:
		return

	move_time -= dt;
	var can_move = move_time <= 0 and dest_pos == null
	
	if dir == Globals.Dir.NONE:
		dir = rng.randi_range(Globals.Dir.N, Globals.Dir.W) as Globals.Dir
	
	# movement check and logic
	if can_move:
		#var cur_cell = gridmap.pos_to_two_cell(position)
		var next_dest = get_next_cell_pos(dir)
		var next_cell = gridmap.pos_to_two_cell(next_dest)
		var edges = gridmap.get_cell_edge_items(next_cell)
		var edge = edges[Globals.dir_op(dir)]
		var ground_ok = gridmap.is_walkable(edges[4])
		#print(cur_cell, next_cell, position, next_dest, ground_ok, edges, gridmap.is_walkable(edge))
		# Check if free spot
		if  ground_ok && gridmap.is_walkable(edge):
			dest_pos = next_dest #gridmap.map_to_local(next_cell)
			dest_pos.y = position.y
			look_at(dest_pos, Vector3.UP, true)
			move_time = MOVE_TIME
		else:
			dir = Globals.Dir.NONE

	if dest_pos:
		move_elapsed += dt
		var t = move_elapsed / MOVE_TIME
		if t >= 1.0:
			position.x = dest_pos.x
			position.z = dest_pos.z
			dest_pos = null
			move_elapsed = 0
			turn_end()
		else:
			var d := transform.basis.z.normalized()
			var speed := 350.0 * dt
			velocity = d * speed
			move_and_slide()

func get_next_cell_pos(d: Globals.Dir) -> Vector3:
	var cell = get_next_cell(d)
	var pos_edge = gridmap.map_to_local(cell)
	return pos_edge + Vector3(1.5, 0, 0) # todo: why 0 for z?!

func get_next_cell(d: Globals.Dir) -> Vector3i:
	var x_dir = 0
	var z_dir = 0
	if d == Globals.Dir.N: z_dir = -1
	if d == Globals.Dir.S: z_dir = 1
	if d == Globals.Dir.E: x_dir = 1
	if d == Globals.Dir.W: x_dir = -1
	var cur_cell = gridmap.pos_to_two_cell(position)
	var one_cell = Vector3i(x_dir, 0, z_dir) * 2
	return cur_cell + one_cell
