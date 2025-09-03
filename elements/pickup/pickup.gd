extends Node3D

@export var item:Item

func _ready() -> void:
	var instance = item.scene.instantiate()
	add_child(instance)
	
func click_pickup(body: Node3D):
	if body.has_method("on_item_picked_up"):
		body.on_item_picked_up(item)
		queue_free()

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.has_method("on_item_picked_up"):
		print("hit a pickup", item.name)
