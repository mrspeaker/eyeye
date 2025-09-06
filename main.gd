extends Node3D

@onready var grid:GridMap = %GridMap

var _cell_timer:Timer = Timer.new()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SignalBus.player_moved.connect(world_turn)
	
	_cell_timer.wait_time = 1.0
	_cell_timer.connect("timeout", self._on_timeout)
	_cell_timer.autostart = true
	add_child(_cell_timer)

func _on_timeout():
	grid.set_cell_item(Vector3i.ZERO, randi_range(0, 8))

func _input(event):
	if event.is_action_pressed("exit"):
		get_tree().quit()

func world_turn(_player):
	enemies_act()

# loop through all enemies turns
func enemies_act():
	for enemy in get_tree().get_nodes_in_group("Enemy"):
		if enemy.has_method("turn_start"):
			enemy.turn_start()
