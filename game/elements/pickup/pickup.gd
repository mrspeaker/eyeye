extends Node3D

@export var item:Item
#@onready var tween = create_tween()

var hover_offset := Vector3(0, 0.05, 0)  # Amount to raise
var original_position := Vector3.ZERO

func _ready() -> void:
	var instance = item.scene.instantiate()
	add_child(instance)
	original_position = position
	SignalBus.connect("hovered_object_changed", _on_hovered_object_changed)

	
func click_pickup(body: Node3D):
	if body.has_method("on_item_picked_up"):
		body.on_item_picked_up(item)
	queue_free()

func _on_hovered_object_changed(new_object):
	if new_object == self:
		raise_on_hover()
	else:
		reset_hover()

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.has_method("on_item_picked_up"):
		print("hit a pickup", item.name)


func raise_on_hover():
	var tween = create_tween()
	tween.tween_property(self, "position", original_position + hover_offset, 0.2)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)

func reset_hover():
	var tween = create_tween()
	tween.tween_property(self, "position", original_position, 0.2)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN)
