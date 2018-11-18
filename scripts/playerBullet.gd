
extends "bullet.gd"

# member variables here, example:
# var a=2
# var b="textvar"

#TODO: see if want to change behavior (currently identical to player bullet)
func handle_collisions(var collisions):
	for collision in collisions:
		if collision extends enemyClass:
			collision.increment_hp(-damage)
			queue_free()
		elif collision extends TileMap:
			queue_free()



