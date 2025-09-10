extends ColorRect

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SignalBus.connect("player_eyes_toggled", on_eyes_toggled)

func on_eyes_toggled(open: bool) -> void:
	self.visible = not open
