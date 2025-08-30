extends CharacterBody3D

@export var gridmap: GridMap;
@export var camera : Camera3D
@export var health_component: HealthComponent

@onready var interact_label = get_node("../../UI/CanvasLayer/InteractLabel")
@onready var world = get_node("../../")

const MOVE_TIME = 0.2
const TURN_TIME = 0.3

var moving = false
var move_elapsed_time = 0.0
var move_dest_pos = null
var move_start_pos = null

var turning = false
var turn_current_rot = Vector3.ZERO
var turn_target_rot = Vector3.ZERO
var turn_elapsed_time = 0.0

const MOUSE_ROT_MAX := deg_to_rad(30)
var mouse_sensitivity = 0.2
var mouse_rot: Vector3
var mouse_yaw: float
var mouse_pitch: float

var scanned_thing = null

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

#func _unhandled_input(event):
func _input(event):
	var is_mouse_event = event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
	if is_mouse_event:
		mouse_yaw = -event.relative.x
		mouse_pitch = -event.relative.y

func update_camera(dt):
	mouse_pitch *= mouse_sensitivity
	mouse_yaw *= mouse_sensitivity
	
	mouse_rot.x += mouse_pitch * dt
	mouse_rot.x = clamp(mouse_rot.x, -MOUSE_ROT_MAX, MOUSE_ROT_MAX)
	mouse_pitch = 0.0

	mouse_rot.y += mouse_yaw * dt
	mouse_rot.y = clamp(mouse_rot.y, -MOUSE_ROT_MAX, MOUSE_ROT_MAX)
	mouse_yaw = 0.0
	
	camera.transform.basis = Basis.from_euler(mouse_rot)
	camera.rotation.z = 0

func _physics_process(dt: float) -> void:
	update_camera(dt)

	# gravity	
	if not is_on_floor():
		velocity += get_gravity() * dt
	# Reset if fall off map
	if position.y < -2.0:
		get_tree().reload_current_scene()

	var fwd = Input.is_action_pressed("move_forward")
	var bak = Input.is_action_pressed("move_backward")	
	var dir = -1 if fwd else 1 if bak else 0 
	
	var wall_ahead = raycast_ahead(dir)
	scanned_thing = scan_ahead()
	var blocked = fwd and scanned_thing != null
	
	var can_move = not moving and not turning and not blocked
	if dir != 0 and can_move:
		var next_cell = get_next_cell(dir)
		move_start_pos = position
		
		# Step 1: check if wall ahead
		if wall_ahead:
			print("Wall detected ahead")
			if wall_ahead.collider.has_method("interact"):
				wall_ahead.collider.interact()
		# Step 2: check same height floor
		elif gridmap.get_cell_item(next_cell) != -1:
			move_dest_pos = gridmap.map_to_local(next_cell)
		else:
			# Step 3: Check one cell above (slope up / stairs)
			var up_cell = next_cell + Vector3i(0, 1, 0)
			if gridmap.get_cell_item(up_cell) != -1:
				next_cell = up_cell
				move_dest_pos = gridmap.map_to_local(next_cell)
			else:
				# Step 4: Check one cell below (slope down)
				var down_cell = next_cell + Vector3i(0, -1, 0)
				if gridmap.get_cell_item(down_cell) != -1:
					next_cell = down_cell
					move_dest_pos = gridmap.map_to_local(next_cell)
				else:
					move_dest_pos = null

	if move_dest_pos:
		move_elapsed_time += dt
		const move_duration = 0.5        # seconds to reach the target
		var t = move_elapsed_time / move_duration
		if t >= 1.0:
			# Turn ended.
			position.x = move_dest_pos.x
			position.z = move_dest_pos.z
			move_dest_pos = null
			move_elapsed_time = 0
			
			# world acts here
			world.world_turn()
			handle_scanned(scanned_thing)
			
		else:
			 # Lerp only X and Z
			var new_x = lerp(move_start_pos.x, move_dest_pos.x, t)
			var new_z = lerp(move_start_pos.z, move_dest_pos.z, t)
			position.x = new_x
			position.z = new_z
			
	moving = move_dest_pos != null
	move_and_slide()
	
func _process(delta):
	if turning:
		turn_elapsed_time += delta
		var t = turn_elapsed_time / TURN_TIME
		if t >= 1.0:
			# turn done (TODO: signal)
			t = 1.0
			turning = false
			# TODO: handle this in signal somewhere else
			handle_scanned(scanned_thing)
	
		# Ease out cubic (fast start, slow end)
		var eased_t = 1 - pow(1 - t, 3)
		rotation_degrees = turn_current_rot.lerp(turn_target_rot, eased_t)
		mouse_rot.y *= 0.85 # move view back towards middle
	
	var can_turn = not moving and not turning
	
	var left = Input.is_action_pressed("move_left")
	var right = Input.is_action_pressed("move_right")
	var dir = 1 if left else -1 if right else 0 
	
	# Start turning
	if dir != 0 and can_turn:
		turn_current_rot = rotation_degrees
		turn_target_rot = rotation_degrees + Vector3(0, 90 * dir, 0)
		turn_elapsed_time = 0.0
		turning = true

	# Interact with object ahead
	if Input.is_action_pressed("interact"):  
		var scanned = scan_ahead()
		if scanned != null and scanned.is_in_group("NPC"):
			scanned.interact()  # run NPC specific interaction
		elif scanned != null and scanned.is_in_group("Container"):
			scanned.interact() # run Container specific interaction

func raycast_ahead(dir):
	var dir_norm = transform.basis.z.normalized() * dir
	var ray = PhysicsRayQueryParameters3D.new()
	ray.from = global_position
	ray.to = global_position + dir_norm * (gridmap.cell_size.x / 1.5) + Vector3(0, 1, 0) # distance forward and up
	ray.exclude = [self]
	var space_state = get_world_3d().direct_space_state
	return space_state.intersect_ray(ray)

# checks ahead to see if there is something interactable
func scan_ahead():
	var next_cell = get_next_cell(-1)
	var world_pos = gridmap.map_to_local(next_cell)
	for node in get_tree().get_nodes_in_group("NPC"):
		if node.global_position.distance_to(world_pos) < gridmap.cell_size.x / 2:
			return node
	for node in get_tree().get_nodes_in_group("Container"):
		if node.global_position.distance_to(world_pos) < gridmap.cell_size.x / 2:
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

func get_next_cell(dir):
	var grid_pos = gridmap.local_to_map(position)
	var one_cell = Vector3i(dir * basis.z.round())   
	var next_cell = grid_pos + one_cell
	return next_cell
	
func clear_destination():
	move_dest_pos = null
	
func _on_health_component_died() -> void:
	health_component.reset()
	print("health reset to ", health_component.health)
