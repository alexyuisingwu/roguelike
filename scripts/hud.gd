
extends CanvasLayer

# preload
#const action_bar = preload("action_bar.gd")

# member variables here
var screen_size = OS.get_window_size()

func _init():
	# Called every time the node is added to the scene.
	# Initialization here
	set_layer(1)
	#screen_size = OS.get_window_size()

func get_offset(percent):
	return screen_size * percent