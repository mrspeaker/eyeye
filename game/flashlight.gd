extends SpotLight3D

@onready var camera: Camera3D = get_node("%Controller/CameraController/Camera3D")
@onready var spotlight: SpotLight3D = $"."

func _process(delta):
	if camera == null:
		return

	var mouse_pos = get_viewport().get_mouse_position()
	var from: Vector3 = camera.project_ray_origin(mouse_pos)
	var to: Vector3 = from + camera.project_ray_normal(mouse_pos) * 1000

	var space_state = get_world_3d().direct_space_state
	var ray_params := PhysicsRayQueryParameters3D.new()
	ray_params.from = from
	ray_params.to = to

	var result = space_state.intersect_ray(ray_params)
	var target_pos = result.position if result else to

	spotlight.look_at(target_pos, Vector3.UP)
