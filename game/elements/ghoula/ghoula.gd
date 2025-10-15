extends Node3D

@export var target: Node3D

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if target:
		look_at(target.position, Vector3.UP, true)
