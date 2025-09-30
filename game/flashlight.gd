extends SpotLight3D

@onready var camera: Camera3D = get_node("%Controller/CameraController/Camera3D")
@onready var spotlight: SpotLight3D = $"."

var spotlight_target := Vector3.ZERO 
#var flashlight_on = false

func _ready() -> void:
	visible = Globals.flashlight_on

func _input(event):
	if event.is_action_pressed("flashlight"):
		Globals.flashlight_on = !Globals.flashlight_on
		visible = Globals.flashlight_on
		SignalBus.flashlight_toggled.emit()

func _process(delta):
	if camera == null:
		return

	var mouse_pos = get_viewport().get_mouse_position()
	var screen_size = get_viewport().get_visible_rect().size
	var screen_center = screen_size / 2

	# Normalize cursor position
	var normalized = Vector2(mouse_pos.x / screen_size.x, mouse_pos.y / screen_size.y)

	# Mirror both axes: top-left → bottom-right
	var mirrored_x = (1.0 - normalized.x - 0.5) * 2.0  # range [-1, 1]
	var mirrored_y = (1.0 - normalized.y - 0.5) * -2.0

	# Apply mirrored offset in camera space
	#var offset_x = mirrored_x * 0.2  # horizontal sway
	var offset_x = 0.0  # horizontal sway
	var offset_y = mirrored_y * 0.1  # vertical sway

	var offset = (
		camera.transform.basis.x * offset_x +
		camera.transform.basis.y * offset_y
	)

	var from = camera.project_ray_origin(screen_center) + offset
	spotlight.global_transform.origin = from


	# Ray direction still based on actual mouse position
	var to = from + camera.project_ray_normal(mouse_pos) * 1000
	
	#spotlight.global_transform.origin = from

	var ray_params := PhysicsRayQueryParameters3D.new()
	ray_params.from = from
	ray_params.to = to

	var smoothed_target_pos = spotlight.global_transform.origin.lerp(to + Vector3.UP * 0.1, 0.5)
	spotlight.look_at(smoothed_target_pos, Vector3.UP)
#	
	#_draw_ray(from, to)
	## Normalize mouse position to range [0, 1]
	#var normalized = Vector2(mouse_pos.x / screen_size.x, mouse_pos.y / screen_size.y)
#
	## Mirror it: top-left → bottom-right, bottom → top, etc.
	#var mirrored = Vector2(1.0 - normalized.x, normalized.y)
#
	## Define max offset in camera space (tweak these values)
	#var max_offset_x = 0.2  # side sway
	#var max_offset_y = 0.1  # vertical sway
#
	## Convert to camera-space offset
	#var offset = (
		#camera.transform.basis.x * (mirrored.x - 0.5) * 2.0 * max_offset_x +
		#camera.transform.basis.y * (mirrored.y - 0.5) * 2.0 * max_offset_y
	#)
#
	## Final ray origin
	#var screen_center = screen_size / 2
	#var from = camera.project_ray_origin(screen_center) + offset
#
	#
	##var from: Vector3 = camera.project_ray_origin(mouse_pos)
	#spotlight.global_transform.origin = from 
#
	##spotlight.global_transform.origin = from + forward_offset
	#var to: Vector3 = from + camera.project_ray_normal(mouse_pos) * 1000
#
	##var space_state = get_world_3d().direct_space_state
	#var ray_params := PhysicsRayQueryParameters3D.new()
	#ray_params.from = from
	#ray_params.to = to
	#
	##var max_distance = 2.5
	##
	##var result = space_state.intersect_ray(ray_params)
	#var target_pos = to 
	##if result and from.distance_to(result.position) <= max_distance and Globals.flashlight_on:
		##print('close')
		##target_pos = result.position
	##elif result and Globals.flashlight_on:
		##print('far')
###
	## Store this as a member variable in your script
	#var smoothed_target_pos: Vector3 = target_pos + Vector3.UP * 0.1
#
	##_draw_ray(from, smoothed_target_pos)
	## Inside _process or _physics_process
	#smoothed_target_pos = smoothed_target_pos.lerp(target_pos, 0.5)
	#spotlight.look_at(smoothed_target_pos, Vector3.UP)

	#spotlight.look_at(target_pos, Vector3.UP)
	
	

func _draw_ray(from: Vector3, to: Vector3):
	var mesh := ImmediateMesh.new()
	var material := StandardMaterial3D.new()
	material.albedo_color = Color.RED
	mesh.surface_begin(Mesh.PRIMITIVE_LINES, material)
	mesh.surface_add_vertex(from)
	mesh.surface_add_vertex(to)
	mesh.surface_end()

	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = mesh
	mesh_instance.global_transform.origin = Vector3.ZERO  # World space
	get_tree().current_scene.add_child(mesh_instance)  # Add to root scene

	await get_tree().create_timer(0.2).timeout
	mesh_instance.queue_free()
