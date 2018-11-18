
extends "bullet.gd"

# member variables here, example:
# var a=2
# var b="textvar"
var player = preload("ball.gd")
#var companion = preload("companion.gd")

var navigatorAgent = preload("navigatorAgent.gd")
func handle_collisions(var collisions):
	
	for collision in collisions:
		if (collision extends navigatorAgent or collision extends player)\
		 and collision.team != team:
			collision.increment_hp(-damage)
			queue_free()

		elif collision extends TileMap:
			queue_free()

	

