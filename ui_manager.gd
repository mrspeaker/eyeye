extends Control
@onready var cursor = $Cursor
@onready var fade_timer = Timer.new()
@onready var tween = Tween.new()

var cursor_texture_size = 0
var suppress_next_motion = false

func _ready():
	# Starting with this centres the mouse before swapping
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	Input.mouse_mode = Input.MOUSE_MODE_CONFINED_HIDDEN
	add_child(fade_timer)
	
	cursor_texture_size = cursor.texture.get_size()

	fade_timer.wait_time = 2.5
	fade_timer.one_shot = true
	fade_timer.connect("timeout", Callable(self, "_on_fade_timer_timeout"))
	cursor.modulate.a = 0.1  # Start at 10% opacity

func _input(event):
	if event is InputEventMouseMotion:
		# so the mouse doesn't become visible again when recentred programmatically
		if suppress_next_motion:
			suppress_next_motion = false
			return
		fade_timer.start()
		cursor.modulate.a = 0.8  # Make cursor mostly visible

func _on_fade_timer_timeout():
	var tween := create_tween()
	tween.tween_property(cursor, "modulate:a", 0.00, 0.8)  # Fade to nothing over 0.8 seconds
	tween.connect("finished", Callable(self, "_on_fade_complete"))

func _on_fade_complete():
	suppress_next_motion = true
	get_viewport().warp_mouse(get_viewport().size / 2)


func _process(delta):
	cursor.position = get_viewport().get_mouse_position() - (cursor_texture_size / 2)
