extends Node3D

var tim = 0.0
var init_y = 0.0
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	init_y = position.y

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	tim += delta
	position.y = init_y + sin(tim * 0.5) * 0.15
	
