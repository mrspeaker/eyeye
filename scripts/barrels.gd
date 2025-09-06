extends Node3D

@onready var interact_label: Label = %InteractLabel
@onready var item:Item = load("res://data/items/wine.tres")

@export var num_drinks: int = 2

func interact(entity:Node3D):
	if num_drinks > 0:
		interact_label.text = "You got some cheap plonk."
		num_drinks -= 1
		entity.inventory.add_item(item)
		
	else :
		interact_label.text = "There is only sadness."
	interact_label.visible = true
