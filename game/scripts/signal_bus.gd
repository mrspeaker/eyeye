extends Node

@warning_ignore("unused_signal")
signal player_turned(player:CharacterBody3D)
@warning_ignore("unused_signal")
signal player_moved(player:CharacterBody3D)
@warning_ignore("unused_signal")
signal player_eyes_toggled(open: bool)

@warning_ignore("unused_signal")
signal interactable_scanned(interactable: Node3D)

@warning_ignore("unused_signal")
signal hovered_object_changed(hovered_object: Node3D)
