extends SubViewportContainer

@export var p1: Node3D
@export var p2: Node3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("jump"):
		visible = !visible
		if visible:
			p1.position = p2.position + p2.basis.z
			p1.rotation = p2.rotation
