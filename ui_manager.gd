extends Control

@onready var interact_label: Label = $CanvasLayer/InteractLabel
@onready var cursor = $Cursor
@onready var fade_timer := Timer.new()

var fade_tween: Tween
var cursor_texture_size := Vector2.ZERO
var suppress_next_motion := false

func _ready():
	SignalBus.interactable_scanned.connect(on_scanned)
		
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
		# Cancel fade tween if it's running
		if fade_tween and fade_tween.is_running():
			fade_tween.kill()
			fade_tween = null
		fade_timer.start()
		cursor.modulate.a = 0.8  # Make cursor mostly visible

func _on_fade_timer_timeout():
	fade_tween = create_tween()
	fade_tween.tween_property(cursor, "modulate:a", 0.00, 0.8)
	fade_tween.connect("finished", Callable(self, "_on_fade_complete"))

func _on_fade_complete():
	fade_tween = null
	suppress_next_motion = true
	get_viewport().warp_mouse(get_viewport().size / 2)

func _process(_delta):
	cursor.position = get_viewport().get_mouse_position() - (cursor_texture_size / 2)

func on_scanned(scanned):
	if scanned != null and scanned.is_in_group("NPC"):
		interact_label.text = "[E] Interact"
		interact_label.visible = true
	elif scanned != null and scanned.is_in_group("Container"):
		interact_label.text = "[E] Loot"
		interact_label.visible = true
	else:
		interact_label.visible = false
