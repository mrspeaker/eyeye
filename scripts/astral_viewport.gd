extends SubViewportContainer

@export var astral_view: Node3D
@export var entity: Node3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = false
	astral_view.visible = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("jump"):
		visible = !visible
		astral_view.visible = visible
		if !visible:
			entity.position = astral_view.position - astral_view.basis.z
			entity.rotation = astral_view.rotation
			entity.clear_destination()
		else:
			astral_view.position = entity.position + entity.basis.z
			astral_view.rotation = entity.rotation
