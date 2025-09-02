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

var mouse_free = true
var start_rotation = Vector3.ZERO

func _ready() -> void:
	# Starting with this centres the mouse before swapping
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	Input.mouse_mode = Input.MOUSE_MODE_CONFINED
	
	#rotation_degrees.y = fposmod(rotation_degrees.y, 90)
	# set faced direction to start_rotation to prevent spin on spawn
	start_rotation = rotation_degrees
	var crosshair_tex = preload("res://textures/UI/white circle small.png")
	var size = crosshair_tex.get_size()
	var img_centre = size / 2   # centre of whatever custom cursor
	Input.set_custom_mouse_cursor(crosshair_tex, Input.CURSOR_ARROW, img_centre)

#func _unhandled_input(event):
func _input(event):
	var is_fps_event = event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
	var is_free_event = event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE

	if event.is_action_pressed("test_input"):
		mouse_free = !mouse_free
		if mouse_free:
			#Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE) # Free movement
			Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)
			start_rotation = rotation_degrees
		else:
			rotation_degrees = start_rotation
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED) # FPS mode
	if is_fps_event:
		mouse_yaw = -event.relative.x
		mouse_pitch = -event.relative.y

func shortest_angle_diff(current, target):
	# Shift into [0, 360), then offset to (–180, +180]
	var raw = fposmod((target - current) + 180.0, 360.0) - 180.0
	return raw


func update_camera(dt):
	var max_angle = 10.0 # degrees of max camera tilt
	
	if mouse_free: # fixed edge looking
		var viewport_size = get_viewport().get_visible_rect().size
		var center = viewport_size / 2
		var mouse_pos = get_viewport().get_mouse_position()
		
		# offset from center (-1.0 to 1.0 range)
		var offset = (mouse_pos - center) / center  
		#print(offset)
	
		# Clamp in case of screen weirdness I don't know
		offset = offset.clamp(Vector2(-1, -1), Vector2(1, 1))
		
		# Dead zone threshold
		var threshold = 0.8  # 0.0 = instant, 1.0 = only edges
		if abs(offset.x) < threshold: offset.x = 0
		else: offset.x = (abs(offset.x) - threshold) / (1.0 - threshold) * sign(offset.x)

		if abs(offset.y) < threshold: offset.y = 0
		else: offset.y = (abs(offset.y) - threshold) / (1.0 - threshold) * sign(offset.y)


		# Compute offset rotation
		var yaw_offset   = -offset.x * max_angle * 0.5
		var pitch_offset = -offset.y * max_angle * 0.5
		
		# Target rotation = starting rotation + offset
		var target_yaw   = start_rotation.y + yaw_offset
		var target_pitch = start_rotation.x + pitch_offset
		
		# Apply smoothing (lerp so movement slows at edges)
		var t = 1.0 - exp(-5.0 * dt)
		
		# Yaw step toward target:
		var yaw_delta = shortest_angle_diff(rotation_degrees.y, target_yaw)
		rotation_degrees.y += yaw_delta * t

		# Pitch 
		var pitch_delta = shortest_angle_diff(rotation_degrees.x, target_pitch)
		rotation_degrees.x = rotation_degrees.x + pitch_delta * t
		
	else: # regular FPS controls 
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
			print(start_rotation, ' ', rotation_degrees)
			# realign just in case
			rotation_degrees.x = round(rotation_degrees.x / 90.0) * 90.0
			rotation_degrees.y = round(rotation_degrees.y / 90.0) * 90.0
			# set current faced direction default for edge looking system
			start_rotation = rotation_degrees
			print(start_rotation, ' ', rotation_degrees)
			# reset cursor to confined to allow movement again
			Input.mouse_mode = Input.MOUSE_MODE_CONFINED
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
		# capture mouse until turn is finished to prevent offsetting alignment
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		turn_current_rot = rotation_degrees
		
		# keep from drifting when turning while edge looking by rounding
		rotation_degrees.x = round(rotation_degrees.x / 90.0) * 90.0
		rotation_degrees.y = round(rotation_degrees.y / 90.0) * 90.0
		turn_target_rot = rotation_degrees + Vector3(0, 90 * dir, 0)
		#turn_target_rot.y = round(turn_target_rot.y)
		print('targ ', turn_target_rot)
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
