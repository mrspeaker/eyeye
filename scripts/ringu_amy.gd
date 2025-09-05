extends Node3D

@export var player: Node3D
@export var speed: float = 1.0

var start_pos: Vector3
var moving = true
var move_time = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	start_pos = position
	SignalBus.connect("player_eyes_toggled", on_player_eyes)
	SignalBus.connect("player_moved", on_player_moved)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if not moving or move_time <= 0 or player == null:
		return
		
	move_time -= delta;
	var offset = player.position - position

	if offset.length() < 1.5:
		position = start_pos
		return
	
	var dir = offset.normalized()
	var vel = dir * speed * delta
	position.x += vel.x
	position.z += vel.z

func on_player_moved(player: CharacterBody3D):
	move_time = 5.0

func on_player_eyes(open: bool):
	moving = open
