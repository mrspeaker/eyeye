extends Node3D

@onready var interact_label: Label = %InteractLabel

@export var num_drinks: int = 2

func interact():
	if num_drinks > 0:
		interact_label.text = "You got some cheap plonk."
		num_drinks -= 1
	else :
		interact_label.text = "There is only sadness."
	interact_label.visible = true
