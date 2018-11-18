
extends "bullet.gd"

# member variables here, example:
# var a=2
# var b="textvar"

#TODO: add owner to bullet class
var enemy = preload("enemy.gd")
var player
func init(var pos, var direction, var speed, var owner):
	.init(pos, direction, speed, owner)
	player = owner.owner
	
func handle_collisions(var collisions):
	
	for collision in collisions:
		if collision extends enemy:
			collision.increment_hp(-damage)
			queue_free()
		elif collision extends TileMap:
			queue_free()