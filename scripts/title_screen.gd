class_name TitleScreen
extends Node3D

var time: float

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	time = 0.0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	time += delta;
	if time > 30.0:
		_start_game()


func _on_button_pressed() -> void:
	_start_game()

func _start_game():
	get_tree().change_scene_to_file("res://main.tscn")
