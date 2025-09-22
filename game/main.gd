class_name Game
extends Node3D

@onready var grid:GridMap = %GridMap
@onready var cinema_camera:Camera3D = %CinemaCamera
@onready var player:PlayerController = %Controller

var _cell_timer:Timer = Timer.new()

enum GameState {
	INIT,
	CUTSCENE,
	PLAY,
}

var _state: GameState = GameState.INIT
var _state_time: float = 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SignalBus.player_moved.connect(world_turn)
	
	_cell_timer.wait_time = 1.0
	_cell_timer.connect("timeout", self._on_timeout)
	_cell_timer.autostart = true
	add_child(_cell_timer)
	
	_state = GameState.CUTSCENE
	_state_time = 0.0
	player.enabled = false


func _on_timeout():
	grid.set_cell_item(Vector3i.ZERO, randi_range(0, 8))

func _input(event):
	if event.is_action_pressed("exit"):
		get_tree().quit()

func _process(delta: float):
	if _state == GameState.CUTSCENE:
		if _state_time == 0:
			player.camera.current = true
	
		if _state_time >= 2.0:
			_state = GameState.PLAY
			_state_time = 0
			player.enabled = true
			return
	_state_time += delta

func world_turn(_player):
	enemies_act()

# loop through all enemies turns
func enemies_act():
	for enemy in get_tree().get_nodes_in_group("Enemy"):
		if enemy.has_method("turn_start"):
			enemy.turn_start()
