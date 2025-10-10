extends Node3D

var target: Vector3 = Vector3.INF
var speed: float = 2.0
var wait_time: float = 5.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(dt: float) -> void:
	if target == Vector3.INF:
		target = position + Vector3(
			Globals.rng.randf_range(-0.6, 0.6),
			0,
			Globals.rng.randf_range(-0.6, 0.6))
		speed = Globals.rng.randf_range(0.3, 0.8)
		wait_time = Globals.rng.randf_range(0.0, 1.5)

	wait_time -= dt
	if wait_time <= 0:
		var dir = position.direction_to(target).normalized()
		look_at(Vector3(target.x, position.y, target.z))
		position = position + (dir * dt * speed)
		if position.distance_to(target) < 0.03:
			target = Vector3.INF
