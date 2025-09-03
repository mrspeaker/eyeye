extends CharacterBody3D

@onready var gridmap: GridMap = get_node("../../GridMap") as GridMap
@onready var interact_label = get_node("../../UI/CanvasLayer/InteractLabel")

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

var rng = RandomNumberGenerator.new()

func _ready() -> void:
	rng.set_seed(Time.get_unix_time_from_system()) 
	print(get_tree().get_nodes_in_group("NPC"))
	if gridmap == null:
		print("GridMap node not found!")
		pass
	else:
		print("GridMap cell size:", gridmap.cell_size)
		cell_size_x = gridmap.cell_size.x

func turn_start():
	active = true
	
func _physics_process(dt: float) -> void:
	if active:
		move_time -= dt;
		
		if not is_on_floor():
			velocity += get_gravity() * dt

		can_move = move_time <= 0 and not turning and dest_pos == null 
		
		#var fwd = Input.is_action_pressed("move_forward")
		#var bak = Input.is_action_pressed("move_backward")	
		
		var dir = rng.randi_range(-1, 1) 
		#var dir = -1 if fwd else 1 if bak else 0 
		var dir_norm = transform.basis.z.normalized() * dir
		
		var ray = PhysicsRayQueryParameters3D.new()
		ray.from = global_position
		ray.to = global_position + dir_norm * (cell_size_x / 1.5) + Vector3(0, 1, 0) # distance forward and up
		ray.exclude = [self]
		var space_state = get_world_3d().direct_space_state
		var wall_ahead = space_state.intersect_ray(ray)

		# movement check and logic
		if dir != 0 and can_move and (scan_ahead() == null or dir == 1):
			
			var next_cell = get_next_cell(dir)
			start_pos = position
			
			# Step 1: check if wall ahead
			if wall_ahead:
				if wall_ahead.collider.has_method("interact"):
					wall_ahead.collider.interact()
			# Step 2: check same height floor
			elif gridmap.get_cell_item(next_cell) != -1:
				dest_pos = gridmap.map_to_local(next_cell)
			else:
				# Step 3: Check one cell above (slope up / stairs)
				var up_cell = next_cell + Vector3i(0, 1, 0)
				if gridmap.get_cell_item(up_cell) != -1:
					next_cell = up_cell
					dest_pos = gridmap.map_to_local(next_cell)
				else:
					# Step 3: Check one cell below (slope down)
					var down_cell = next_cell + Vector3i(0, -1, 0)
					if gridmap.get_cell_item(down_cell) != -1:
						next_cell = down_cell
						dest_pos = gridmap.map_to_local(next_cell)
					else:
						dest_pos = null
			move_time = MOVE_TIME
			

		var move_duration = 0.5        # seconds to reach the target
		
		if dest_pos:
			move_elapsed += dt
			var t = move_elapsed / move_duration
			if t >= 1.0:
				position.x = dest_pos.x
				position.z = dest_pos.z
				#position = dest_pos
				#position.y = start_pos.y 
				dest_pos = null
				move_elapsed = 0
				turn_end()
				var scanned = scan_ahead()
				#print(scanned)
				handle_scanned(scanned)
			else:
				 # Lerp only X and Z
				var new_x = lerp(start_pos.x, dest_pos.x, t)
				var new_z = lerp(start_pos.z, dest_pos.z, t)
				position.x = new_x
				position.z = new_z
				# Y stays as is
				#position = start_pos.lerp(dest_pos, t)
				#position.y = start_pos.y 

		# Reset if fall off map
		if position.y < -2.0:
			get_tree().reload_current_scene()

		move_and_slide()

func get_next_cell(dir):
	var grid_pos = gridmap.local_to_map(position)
	var one_cell = Vector3i(dir * basis.z.round())   
	var next_cell = grid_pos + one_cell
	return next_cell

# checks ahead to see if there is something interactable
func scan_ahead():
	var next_cell = get_next_cell(-1)
	#func get_interactable_at(cell: Vector3i) -> Interactable:
	var world_pos = gridmap.map_to_local(next_cell)
	for node in get_tree().get_nodes_in_group("NPC"):
		#print("world_pos:", world_pos, " npc_pos:", node.global_position)
		# compare positions approximately (floating point tolerance)
		if node.global_position.distance_to(world_pos) < cell_size_x / 2:
			return node
	for node in get_tree().get_nodes_in_group("Container"):
		#print("world_pos:", world_pos, " con_pos:", node.global_position)
		# compare positions approximately (floating point tolerance)
		if node.global_position.distance_to(world_pos) < cell_size_x / 2:
			return node
	return null

func handle_scanned(scanned):
	if scanned != null and scanned.is_in_group("NPC"):
		pass
	elif scanned != null and scanned.is_in_group("Container"):
		pass
	else:
		pass
		#interact_label.visible = false
		
func turn_end():
	active = false
	return
