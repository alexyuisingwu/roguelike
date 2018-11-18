
# member variables here, example:
# var a=2
# var b="textvar"
var speed = 50
var direction = Vector2(1, 0)
const enemyClass = preload("enemy.gd")
#onready var ball = get_node("../ball")
var damage = 5
var owner
var team

var initialRadius
func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	initialRadius = get_node("CollisionShape2D").get_shape().radius
	set_fixed_process(true)
	
func _fixed_process(delta):	
	var radius = get_node("CollisionShape2D").get_shape().radius
	var pos = get_pos()
	var increment = direction * speed * delta
	pos = Vector2(pos[0] + increment[0], pos[1] + increment[1])
	set_pos(pos)
	var collisions = get_overlapping_bodies()
	if collisions.size() > 0:
		handle_collisions(collisions)

func init(var pos, var direction, var speed, var owner):
	set_global_pos(pos)
	self.direction = direction
	self.speed = speed
	self.owner = owner
	team = owner.team
	
func handle_collisions(var collisions):
	pass
	
func get_radius():
	return get_node("CollisionShape2D").get_shape().radius * get_scale()
	
func set_radius(var radius):
	var scale = radius / get_node("CollisionShape2D").get_shape().radius
	set_scale(Vector2(scale, scale))


