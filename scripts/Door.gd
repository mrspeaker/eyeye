extends StaticBody3D

var toggle = false
var interactable = true
@export var anim_player: AnimationPlayer

func interact():
	if not interactable:
		pass
	interactable = false
	toggle = !toggle
	anim_player.play("door_open" if toggle else "door_close")
	await get_tree().create_timer(1.0, false).timeout
	interactable = true
