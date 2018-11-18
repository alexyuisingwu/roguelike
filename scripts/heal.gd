
extends Area2D

var maxRadius = 24
var player = preload("ball.gd")
var navigatorAgent = preload("navigatorAgent.gd")
var strength = 0.2
var owner
func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	set_fixed_process(true)
	
func _fixed_process(delta):
	
	var scale = get_scale()
	scale = Vector2(scale[0] + 0.008, scale[1] + 0.008)
	set_scale(scale)
	
	if get_radius() > maxRadius:
		var collisions = get_overlapping_bodies()
		for collision in collisions:
			if weakref(collision).get_ref() and weakref(owner).get_ref() and\
			(collision extends navigatorAgent or collision extends player)\
			 and collision.team == owner.team:
				collision.increment_hp(int(strength * collision.max_hp))
		queue_free()
		
	
	
func get_radius():
	return get_node("CollisionShape2D").get_shape().radius * get_scale()[0]

func set_radius(var radius):
	var scale = radius / get_node("CollisionShape2D").get_shape().radius
	set_scale(Vector2(scale, scale))



