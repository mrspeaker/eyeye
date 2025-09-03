extends ColorRect

@export var player: CharacterBody3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player.connect("eyes_toggled", self.on_eyes_toggled, 0)

func on_eyes_toggled(open: bool) -> void:
	self.visible = not open
