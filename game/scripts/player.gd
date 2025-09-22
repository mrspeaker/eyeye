extends Node

@onready var controller: PlayerController = %Controller

func _ready() -> void:
	#controller.rotate(Vector3.FORWARD, PI/2.0)
	pass
	
func _process(_delta: float) -> void:
	pass

func _on_health_component_died() -> void:
	print("yo ded")
