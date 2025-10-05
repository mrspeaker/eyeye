extends CharacterBody3D

@export var gridmap: GridMap

const MOVE_TIME := 0.5
const SPEED := 166.67 * 2 #(MOVE_TIME * 1000) / 3.0 # 1 sec / 3 units (1 cell)

var target_pos = null
var move_timer := 0.0
var active := false
var dir := Globals.Dir.NONE
var num_gone_straights := 0 # just testing not allowing more than X straight moves

var rng = RandomNumberGenerator.new()

# Called externally to start a move
func turn_start():
	active = true
	
func turn_end():
	active = false
	
func _physics_process(dt: float) -> void:
	if not active:	return

	# Pick a random direction
	if dir == Globals.Dir.NONE:
		dir = rng.randi_range(Globals.Dir.N, Globals.Dir.W) as Globals.Dir
	
	if target_pos == null:
		_look_for_a_direction()
	else:
		_do_move(dt)
	
func _do_move(dt: float):
	move_timer += dt
	if move_timer / MOVE_TIME < 1.0:
		var direction := transform.basis.z.normalized()
		velocity = direction * SPEED * dt
		move_and_slide()
	else:
		position.x = target_pos.x
		position.z = target_pos.z
		target_pos = null
		num_gone_straights += 1
		turn_end()

func _look_for_a_direction():
	target_pos = gridmap.get_pos_in_direction(position, dir)
	# Silly thing to just not go straight all the time
	if num_gone_straights > 4:
		target_pos = null
		
	if target_pos != null:
		_start_move()
	else:
		# couldn't go that way... reset and try again
		dir = Globals.Dir.NONE
		num_gone_straights = 0

func _start_move():
	target_pos.y = position.y # set target Y to whatever is already set to keep Y position
	look_at(target_pos, Vector3.UP, true)
	move_timer = 0
