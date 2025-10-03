extends CharacterBody3D

@export var gridmap: GridMap

const MOVE_TIME = 0.2
const TURN_TIME = 0.3

var move_time = 0.0
var turning = false
var dest_pos = null
var start_pos = null
var can_move = true
var move_elapsed = 0.0

var cell_size_x = 0
var active = false

var dir = Globals.Dir.NONE

var rng = RandomNumberGenerator.new()

func _ready() -> void:
	#rng.set_seed(Time.get_unix_time_from_system() as int) 
	print("GridMap cell size:", gridmap.cell_size)
	cell_size_x = gridmap.cell_size.x

func turn_start():
	active = true
	
func turn_end():
	active = false
	
func _physics_process(dt: float) -> void:
	if not active:
		return

	move_time -= dt;
	can_move = move_time <= 0 and not turning and dest_pos == null
	#var dir = -1 if rng.randi_range(0, 1) == 0 else 1
	if dir == Globals.Dir.NONE:
		dir = rng.randi_range(Globals.Dir.N, Globals.Dir.W) as Globals.Dir

	# movement check and logic
	if can_move:
		print(dir)
		var cur_cell = gridmap.pos_to_two_cell(position)
		var next_cell = get_next_cell(dir)
		print(cur_cell, next_cell)	
		# Check if free spot

		if 1 != -1: #and edges[Globals.dir_op(dir)]:
			# grr, why is  x+1.5 but z +0?
			dest_pos = gridmap.map_to_local(next_cell) + Vector3(1.5, 0, 0)
			dest_pos.y = position.y
			look_at(dest_pos, Vector3.UP, true)
			start_pos = position
			move_time = MOVE_TIME
		else:
			dir = Globals.Dir.NONE

		
	var move_duration = 0.5        # seconds to reach the target
	
	if dest_pos:
		move_elapsed += dt
		var t = move_elapsed / move_duration
		if t >= 1.0:
			position.x = dest_pos.x
			position.z = dest_pos.z
			dest_pos = null
			move_elapsed = 0
			turn_end()
			
		else:
			#var new_x = lerp(start_pos.x, dest_pos.x, t)
			#var new_z = lerp(start_pos.z, dest_pos.z, t)
			#position.x = new_x
			#position.z = new_z
			#var direct := position.direction_to(dest_pos)
			var d := transform.basis.z.normalized()  #position.distance_to(dest_pos)
			var speed := 350.0 * dt
			velocity = d * speed
			move_and_slide()

func get_next_cell(d: Globals.Dir):
	var x_dir = 0
	var z_dir = 0
	if d == Globals.Dir.N: z_dir = -1
	if d == Globals.Dir.S: z_dir = 1
	if d == Globals.Dir.E: x_dir = -1
	if d == Globals.Dir.W: x_dir = 1
	var cur_cell = gridmap.pos_to_two_cell(position) # gridmap.local_to_map(position)
	# var grid_pos_mod_two = Vector3i(floor(grid_pos / 2) * 2)# + Vector3i(1, 0, -1)
	var one_cell = Vector3i(x_dir * basis.z.round() + z_dir * basis.x.round()) * 2
	return cur_cell + one_cell
	#var next_cell = grid_pos_mod_two + one_cell
	#var next_cell = gridmap.get_cell_edge_items(grid_pos + one_cell)
	#return next_cell
