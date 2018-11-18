
extends Area2D

# member variables here, example:
# var a=2
# var b="textvar"

onready var collisionShape = get_node("CollisionShape2D")
func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	pass
	
func set_radius(var radius):
	radius = radius/collisionShape.get_shape().radius
	collisionShape.set_scale(Vector2(radius, radius))
	
func get_visible():
	return get_overlapping_bodies()

func get_radius():
	return collisionShape.get_shape().radius * collisionShape.get_scale()
