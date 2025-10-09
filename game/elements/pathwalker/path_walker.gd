extends Node3D

@onready var grid:GridMap = %GridMap

enum PathStates {
	IDLE,
	LOOKING,
	PATHING,
	DONE_PATH
}
var homing := false
var home:Vector3

const SPEED := 2.0

var state: PathStates = PathStates.IDLE
var path: Array[Vector2] = []
var target: Vector3 = Vector3.INF

func _ready() -> void:
	home = position

func _process(dt: float) -> void:
	if state == PathStates.IDLE:
		state = PathStates.LOOKING
		return

	if state == PathStates.LOOKING:
		path = grid.find_path(position, grid.get_rnd_tile_pos_by_type(grid.Tiles.Floor2) if not homing else home)
		if path.size() > 0:
			#print("found path ", path.size())
			state = PathStates.PATHING
		return

	if state == PathStates.PATHING:
		if target == Vector3.INF:
			if path.size() == 0:
				state = PathStates.DONE_PATH
				return
			var t = path.pop_front()
			target = Vector3(t.x + 1.5, position.y, t.y - 0.5)
		else:
			var dir = global_transform.origin.direction_to(target).normalized()
			position = position + (dir * dt * SPEED)
			# Are we at target cell?
			if global_transform.origin.distance_to(target) < 0.15:
				target = Vector3.INF
				homing = not homing
		return

	if state == PathStates.DONE_PATH:
		#print("path over...")
		state = PathStates.IDLE
		return
