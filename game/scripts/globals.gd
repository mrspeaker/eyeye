extends Node

var flashlight_on := false
#
#func toggle_flashlight():
	#flashlight_on = !flashlight_on
	
enum Dir {
	NONE = -1,
	N = 0,
	S,
	E,
	W
}

func dir_op (d: Dir):
	if d == Dir.N: return Dir.S
	if d == Dir.S: return Dir.N
	if d == Dir.E: return Dir.W
	if d == Dir.W: return Dir.E
	return Dir.NONE
