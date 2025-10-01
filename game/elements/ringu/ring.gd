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

var dir = -1

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
	if dir == -1:
		dir = rng.randi_range(0, 3)
		
	# movement check and logic
	if can_move:
		print(dir)
		#if gridmap.get_cell_item(next_cell)
		var next_cell = get_next_cell(dir)
		
		# Check if free spot
		print(next_cell, gridmap.get_cell_item(next_cell))
		# TODO: ah, get_cell_item is meaningless in double-grid
		# Make a func in double_grid.gd to see if this is really
		# a valid path
		if gridmap.get_cell_item(next_cell) != -1:
			dest_pos = gridmap.map_to_local(next_cell)
			look_at(dest_pos, Vector3.UP, true)
			start_pos = position
			move_time = MOVE_TIME
		else:
			dir = -1

		
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
			var speed := 400.0 * dt
			velocity = d * speed
			move_and_slide()

func get_next_cell(dir):
	var x_dir = 0
	var z_dir = 0
	if dir == 0: z_dir = -1
	if dir == 1: z_dir = 1
	if dir == 2: x_dir = -1
	if dir == 3: x_dir = 1
	var grid_pos = gridmap.local_to_map(position)
	var grid_pos_mod_two = Vector3i(floor(grid_pos / 2) * 2) + Vector3i(1, 0, -1)
	var one_cell = Vector3i(x_dir * basis.z.round() * 2.0 + z_dir * basis.x.round() * 2.0)   
	var next_cell = grid_pos_mod_two + one_cell
	return next_cell
