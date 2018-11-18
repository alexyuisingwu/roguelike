
extends "ability.gd"

onready var player = get_node("../../")

func push():
	.push()
	player.normal_attack()

func _init():
	.set_cost(0)
	.set_label("Attack (Cost: " + str(.get_cost()) + ")")
	
func use():
	print("attack needs to be implemented")
	return 1