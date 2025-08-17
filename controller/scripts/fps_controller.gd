extends CharacterBody3D

@onready var gridmap: GridMap = $"../GridMap"

@export var player_view:= 0

const SPEED = 3;
const MOVE_TIME = 0.2
const TURN_TIME = 0.3

var move_time = 0.0
var turning = false
var dest_pos = null

var sensitivity = 0.2
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
		new_mat.albedo_color = Color(0,0.4,0.8) # Change color to for p2
		$PlaceholderMesh.set_surface_override_material(0, new_mat)
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event):
	if player_view == 0:
		pass
	_mouse_input = event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
	if _mouse_input:
		_rot_input = -event.relative.x
		_tilt_input = -event.relative.y

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

	var p1 = player_view == 0
	var can_move = move_time <= 0 and not turning
	
	var fwd = Input.is_action_pressed("move_forward") if p1 else false
	var bak = Input.is_action_pressed("move_backward") if p1 else false	
	var dir = -1 if fwd else 1 if bak else 0 
	if dir != 0 and can_move:
		var grid_pos = gridmap.local_to_map(position)
		var one_cell = Vector3i(dir * basis.z.round())   
		var next_cell = grid_pos + one_cell
		dest_pos = gridmap.map_to_local(next_cell)
		#print(grid_pos, one_cell, dest_pos, next_cell)
		move_time = MOVE_TIME

	if dest_pos:
		position = position.move_toward(dest_pos, SPEED * dt)
		if position.distance_to(dest_pos) < 0.01:
			position = dest_pos
			dest_pos = null

	# Reset if fall off map
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
		_mouse_rot.y *= 0.85 # move view back towards middle
	
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
