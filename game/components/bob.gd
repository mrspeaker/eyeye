extends Node3D

@export var bobobj: Node3D

var tim = 0.0
var init_y = 0.0

func _ready() -> void:
	init_y = bobobj.position.y

func _process(dt: float) -> void:
	tim += dt
	bobobj.position.y = init_y + sin(tim * 8) * 0.03
