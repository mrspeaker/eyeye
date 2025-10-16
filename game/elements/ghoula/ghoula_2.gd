extends Node3D

@export var target: Node3D

var t:= 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$AnimationPlayer.play("Idle")

func _process(dt: float) -> void:
	if target:
		look_at(target.position, Vector3.UP, true)

	t+=dt
	if t > 8:
		$AnimationPlayer.play("IdleTest" if Globals.rng.randf() < 0.5 else "GlitchLeft")
		t -= 8

func _on_anim_done(_name):
	$AnimationPlayer.play("Idle")
