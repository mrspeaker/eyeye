extends CharacterBody3D

@onready var gridmap: GridMap = $"../GridMap"

@export var player_view:= 0

const SPEED = 3.0
const JUMP_VELOCITY = 4.5
const MOVE_TIME = 0.2
const TURN_TIME = 0.3

var move_time = 0.0
var dest = null
var turning = false

var _mouse_input = false
var _mouse_rot: Vector3
var _rot_input: float
var _tilt_input: float
var TILT_LOWER := deg_to_rad(-30)
var TILT_UPPER := deg_to_rad(30.0)
@export var CAM_CONTROLLER : Camera3D

func _ready() -> void:
	if player_view == 1:
		var new_mat = $PlaceholderMesh.get_active_material(0).duplicate()
		new_mat.albedo_color = Color(0,0.4,0.8) # Change color to red
		$PlaceholderMesh.set_surface_override_material(0, new_mat)
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		
func _input(event):
	if event.is_action_pressed("exit"):
		get_tree().quit()
		
func _unhandled_input(event):
	if player_view == 0:
		pass
	_mouse_input = event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
	if _mouse_input:
		_rot_input = -event.relative.x
		_tilt_input = -event.relative.y

func update_camera(dt):
	_tilt_input *= 0.1
	_rot_input *= 0.1
	_mouse_rot.x += _tilt_input * dt
	_mouse_rot.x = clamp(_mouse_rot.x, TILT_LOWER, TILT_UPPER)
	_mouse_rot.y += _rot_input * dt
	_mouse_rot.y = clamp(_mouse_rot.y, TILT_LOWER, TILT_UPPER)
	CAM_CONTROLLER.transform.basis = Basis.from_euler(_mouse_rot)
	CAM_CONTROLLER.rotation.z = 0
	_rot_input = 0.0
	_tilt_input = 0.0

func _physics_process(dt: float) -> void:
	move_time -= dt;
	update_camera(dt)
	
	if not is_on_floor():
		velocity += get_gravity() * dt

	var p1 = player_view == 0
	var jump = Input.is_action_just_pressed("jump") if p1 else false
	if jump and is_on_floor():
		#velocity.y = JUMP_VELOCITY
		pass
		
	#var fwd = Input.is_action_pressed("move_forward") if p1 else false
	#if fwd and move_time <= 0:
		#dest = position - basis.z # Vector3.FORWARD
		#move_time = MOVE_TIME
	#
	#var bak = Input.is_action_pressed("move_backward") if p1 else false
	#if bak and move_time <= 0:
		#dest = position + basis.z #Vector3.FORWARD
		#move_time = MOVE_TIME
		
	var fwd = Input.is_action_pressed("move_forward") if p1 else false
	if fwd and move_time <= 0 and !turning:
		# this converts the player position to a grid cell coordinate
		var grid_pos = gridmap.local_to_map(position)
		# forward direction as grid step, round gives us a clean integer z
		var forward = -basis.z.round()   
		# position plus one grid cell coordinate (Vector3i) forwards
		var next_cell = grid_pos + Vector3i(forward)
		dest = gridmap.map_to_local(next_cell)
		move_time = MOVE_TIME
		
	var bak = Input.is_action_pressed("move_backward") if p1 else false
	if bak and move_time <= 0 and !turning:
		# this converts the player position to a grid cell coordinate
		var grid_pos = gridmap.local_to_map(position)
		# backwards direction as grid step, round gives us a clean integer z
		var backward = basis.z.round()
		# position plus one grid cell coordinate (Vector3i) backwards
		var next_cell = grid_pos + Vector3i(backward)
		dest = gridmap.map_to_local(next_cell)
		move_time = MOVE_TIME
			
	if dest:
		position = position.move_toward(dest, SPEED * dt)
		if position.distance_to(dest) < 0.01:
			position = dest
			dest = null
			
	if position.y < -2.0:
		get_tree().reload_current_scene()

	move_and_slide()


var current_rot = Vector3.ZERO
var target_rot = Vector3.ZERO
var elapsed_time = 0.0

func _process(delta):
	var p1 = player_view == 0
		
	if turning:
		elapsed_time += delta
		var t = elapsed_time / TURN_TIME
		if t >= 1.0:
			t = 1.0
			turning = false
		# Ease out cubic (fast start, slow end)
		var eased_t = 1 - pow(1 - t, 3)
		rotation_degrees = current_rot.lerp(target_rot, eased_t)
	
	# Start turning left
	if p1 and Input.is_action_just_pressed("move_left") and not turning:
		current_rot = rotation_degrees
		target_rot = rotation_degrees + Vector3(0, 90, 0)
		elapsed_time = 0.0
		turning = true
	
	# Start turning right
	if p1 and Input.is_action_just_pressed("move_right") and not turning:
		current_rot = rotation_degrees
		target_rot = rotation_degrees + Vector3(0, -90, 0)
		elapsed_time = 0.0
		turning = true
