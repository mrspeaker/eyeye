extends Node3D

@onready var interact_label = get_node("../UI/CanvasLayer/InteractLabel")

func interact():
	interact_label.text = "You'd be so scared if you were a crow."
	interact_label.visible = true
