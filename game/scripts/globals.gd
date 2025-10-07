extends Node

const MAX_STRESS_DISTANCE := 150

var flashlight_on := false
#
enum Dir {
	NONE = -1,
	N = 0,
	S,
	E,
	W,
	DOWN
}

func dir_op (d: Dir):
	if d == Dir.N: return Dir.S
	if d == Dir.S: return Dir.N
	if d == Dir.E: return Dir.W
	if d == Dir.W: return Dir.E
	return Dir.NONE

func dir_left (d: Dir):
	if d == Dir.N: return Dir.W
	if d == Dir.S: return Dir.E
	if d == Dir.E: return Dir.N
	if d == Dir.W: return Dir.S
	return Dir.NONE

func dir_right (d: Dir):
	if d == Dir.N: return Dir.E
	if d == Dir.S: return Dir.W
	if d == Dir.E: return Dir.S
	if d == Dir.W: return Dir.N
	return Dir.NONE

func dir_to_vec (d:Dir):
	if d == Dir.N: return Vector3(0, 0, -1)
	if d == Dir.S: return Vector3(0, 0, 1)
	if d == Dir.E: return Vector3(1, 0, 0)
	if d == Dir.W: return Vector3(-1, 0,0)
	return Vector3.ZERO

func ease_cubic (t: float): return 1 - pow(1 - t, 3)
