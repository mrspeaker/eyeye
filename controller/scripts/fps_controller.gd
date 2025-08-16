extends CharacterBody3D

@export var player_view:= 0

const SPEED = 1.0
const JUMP_VELOCITY = 4.5
const MOVE_TIME = 0.3

var move_time = 0.0
var dest = null

func _ready() -> void:
	if player_view == 1:
		var new_mat = $PlaceholderMesh.get_active_material(0).duplicate()
		new_mat.albedo_color = Color(0,0.4,0.8) # Change color to red
		$PlaceholderMesh.set_surface_override_material(0, new_mat)

func _physics_process(dt: float) -> void:
	move_time -= dt;
	if not is_on_floor():
		velocity += get_gravity() * dt

	var p1 = player_view == 0
	var jump = Input.is_action_just_pressed("jump") if p1 else false
	if jump and is_on_floor():
		#velocity.y = JUMP_VELOCITY
		pass
		
	var fwd = Input.is_action_pressed("move_forward") if p1 else false
	if fwd and move_time <= 0:
		dest = position - basis.z # Vector3.FORWARD
		move_time = MOVE_TIME
	
	var bak = Input.is_action_pressed("move_backward") if p1 else false
	if bak and move_time <= 0:
		dest = position + basis.z #Vector3.FORWARD
		move_time = MOVE_TIME
		
	if p1 and Input.is_action_pressed("move_left") and move_time <= 0:
		rotation_degrees += Vector3(0, 90.0, 0)
		move_time = MOVE_TIME

	if p1 and Input.is_action_pressed("move_right") and move_time <= 0:
		rotation_degrees += Vector3(0, -90.0, 0)
		move_time = MOVE_TIME
			
	if dest:
	#	velocity = velocity.move_toward(dest, SPEED * dt)
		position = dest
		dest = null
		
	# Get the input direction and handle the movement/deceleration.
	#var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	#var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	#if direction:
#		velocity.x = direction.x * SPEED
	#	velocity.z = direction.z * SPEED
	#else:
#		velocity.x = move_toward(velocity.x, 0, SPEED)
	#	velocity.z = move_toward(velocity.z, 0, SPEED)
	
	if position.y < -2.0:
		get_tree().reload_current_scene()

	move_and_slide()
