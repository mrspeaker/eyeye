class_name InventoryDialog
extends PanelContainer

@export var slot_scene:PackedScene
@onready var grid_container:GridContainer = %GridContainer

func open(inventory:Inventory):
	for child in grid_container.get_children():
		child.queue_free()

	for item in inventory.get_items():
		var slot = slot_scene.instantiate()
		grid_container.add_child(slot)
	show()

func toggle(inventory:Inventory):
	if visible:
		hide()
	else:
		open(inventory)

func _on_close_button_pressed() -> void:
	hide()
