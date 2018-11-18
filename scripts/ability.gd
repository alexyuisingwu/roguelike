
extends "slot.gd"

# member variables here
var cost

func _init():
	pass

func set_cost(c):
	cost = c

func get_cost():
	return cost

func push():
	print("TODO: decrement player's resource by ability cost")

func set_label(text):
	.set_label(text)
