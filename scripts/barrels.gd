extends Node3D

@onready var interact_label = get_node("../UI/CanvasLayer/InteractLabel")

func interact():
	interact_label.text = "There is only sadness."
	interact_label.visible = true
