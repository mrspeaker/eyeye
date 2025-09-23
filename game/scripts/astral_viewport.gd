extends SubViewportContainer

@export var astral_view: Node3D
@export var entity: Node3D

var t: Transform3D

func _ready() -> void:
	visible = false
	astral_view.visible = false

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("jump"):
		# Set the astral-projection view
		visible = !visible
		astral_view.visible = visible
		var cam = entity.find_child("CameraController")
		if !visible:
			# Reset view to original position
			#entity.position = astral_view.position #- Vector3.UP * 0.75 # - astral_view.basis.z
			#entity.rotation = astral_view.rotation
			entity.transform = t
			entity.clear_destination()
		else:
			# Start the spooky view - set astral pos+rot to player
			t = entity.transform
			astral_view.position = cam.global_position + Vector3.RIGHT * 0.05 #entity.position# + Vector3.UP * 1.75 # + entity.basis.z
			astral_view.rotation = cam.global_rotation #entity.rotation
