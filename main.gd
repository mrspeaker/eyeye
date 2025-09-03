extends Node3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _input(event):
	if event.is_action_pressed("exit"):
		get_tree().quit()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
		 
func world_turn():
	enemies_act()

# loop through all enemies turns
func enemies_act():
	for enemy in get_tree().get_nodes_in_group("Enemy"):
		if enemy.has_method("turn_start"):
			enemy.turn_start()
