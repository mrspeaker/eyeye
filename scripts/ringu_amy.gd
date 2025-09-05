extends Node3D

@export var player: Node3D
@export var speed: float = 1.0

var start_pos: Vector3
var moving = true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	start_pos = position
	SignalBus.connect("player_eyes_toggled", on_player_eyes)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if not moving or player == null:
		return
	var offset = player.position - position

	if offset.length() < 1.5:
		position = start_pos
		return
	
	var dir = offset.normalized()
	var vel = dir * speed * delta
	position.x += vel.x
	position.z += vel.z


func on_player_eyes(open: bool):
	moving = open
