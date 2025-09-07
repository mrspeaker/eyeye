extends Node

@onready var controller: PlayerController = %Controller
@onready var cam: Camera3D = %AltCamera

func _ready() -> void:
	controller.rotate(Vector3.FORWARD, PI/2.0)
	cam.current = false

func _process(_delta: float) -> void:
	pass

func _on_health_component_died() -> void:
	print("yo ded")
