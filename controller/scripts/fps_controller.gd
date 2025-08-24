extends CharacterBody3D

#@onready var gridmap: GridMap = $"../GridMap"
@onready var gridmap: GridMap = get_node("../GridMap") as GridMap
@onready var interact_label = get_node("../UI/CanvasLayer/InteractLabel")

const SPEED = 4;
const MOVE_TIME = 0.2
const TURN_TIME = 0.3

var move_time = 0.0
var turning = false
var dest_pos = null
var start_pos = null
var can_move = true
var move_elapsed = 0.0

var cell_size_x = 0

var sensitivity = 0.2
var _mouse_input = false
var _mouse_rot: Vector3
var _rot_input: float
var _tilt_input: float
var TILT_LOWER := deg_to_rad(-30)
var TILT_UPPER := deg_to_rad(30.0)
@export var CAM_CONTROLLER : Camera3D

func _ready() -> void:
	print(get_tree().get_nodes_in_group("NPC"))
	if gridmap == null:
		print("GridMap node not found!")
		pass
	else:
		print("GridMap cell size:", gridmap.cell_size)
		cell_size_x = gridmap.cell_size.x

	var new_mat = $PlaceholderMesh.get_active_material(0).duplicate()
	new_mat.albedo_color = Color(0,0.4,0.8) # Change color to for p2
	$PlaceholderMesh.set_surface_override_material(0, new_mat)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event):
	_mouse_input = event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
	if _mouse_input:
		_rot_input = -event.relative.x
		_tilt_input = -event.relative.y
		
func clear_destination():
	dest_pos = null

func update_camera(dt):
	_tilt_input *= sensitivity
	_rot_input *= sensitivity
	
	_mouse_rot.x += _tilt_input * dt
	_mouse_rot.x = clamp(_mouse_rot.x, TILT_LOWER, TILT_UPPER)
	_tilt_input = 0.0

	_mouse_rot.y += _rot_input * dt
	_mouse_rot.y = clamp(_mouse_rot.y, TILT_LOWER, TILT_UPPER)
	_rot_input = 0.0
	
	CAM_CONTROLLER.transform.basis = Basis.from_euler(_mouse_rot)
	CAM_CONTROLLER.rotation.z = 0

func _physics_process(dt: float) -> void:
	move_time -= dt;
	update_camera(dt)
	
	if not is_on_floor():
		velocity += get_gravity() * dt

	can_move = move_time <= 0 and not turning and dest_pos == null 
	
	var fwd = Input.is_action_pressed("move_forward")
	var bak = Input.is_action_pressed("move_backward")	
	var dir = -1 if fwd else 1 if bak else 0 
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
			print("Wall detected ahead!")
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

func turn_end():
	# world acts here
	turn_start()
	
# player turn begins after commital action+
func turn_start():
	scan_ahead()

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
		print("world_pos:", world_pos, " con_pos:", node.global_position)
		# compare positions approximately (floating point tolerance)
		if node.global_position.distance_to(world_pos) < cell_size_x / 2:
			return node
	return null

func handle_scanned(scanned):
	if scanned != null and scanned.is_in_group("NPC"):
		interact_label.text = "[E] Interact"
		interact_label.visible = true
	elif scanned != null and scanned.is_in_group("Container"):
		interact_label.text = "[E] Loot"
		interact_label.visible = true
	else:
		interact_label.visible = false

var current_rot = Vector3.ZERO
var target_rot = Vector3.ZERO
var elapsed_time = 0.0

func _process(delta):
	can_move = move_time <= 0 and not turning and dest_pos == null
	if turning:
		elapsed_time += delta
		var t = elapsed_time / TURN_TIME
		if t >= 1.0:
			t = 1.0
			turning = false
			var scanned = scan_ahead()
			#print(scanned)
			handle_scanned(scanned)
	
		# Ease out cubic (fast start, slow end)
		var eased_t = 1 - pow(1 - t, 3)
		rotation_degrees = current_rot.lerp(target_rot, eased_t)
		_mouse_rot.y *= 0.85 # move view back towards middle
	
	# Start turning left
	if Input.is_action_just_pressed("move_left") and can_move:
		current_rot = rotation_degrees
		target_rot = rotation_degrees + Vector3(0, 90, 0)
		elapsed_time = 0.0
		turning = true
	
	# Start turning right
	if Input.is_action_just_pressed("move_right") and can_move:
		current_rot = rotation_degrees
		target_rot = rotation_degrees + Vector3(0, -90, 0)
		elapsed_time = 0.0
		turning = true
	
	# Interact with object ahead
	if Input.is_action_pressed("interact"):  
		var scanned = scan_ahead()
		if scanned != null and scanned.is_in_group("NPC"):
			scanned.interact()  # run NPC specific interaction
		elif scanned != null and scanned.is_in_group("Container"):
			scanned.interact() # run Container specific interaction
