extends Node3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SignalBus.player_moved.connect(world_turn)

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
