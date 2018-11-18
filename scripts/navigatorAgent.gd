
extends Object


var path = null
var dest = null
var pathIndex = 1
var velocity = Vector2(0, 0)
var speed = 0
var facingDir = Vector2(1, 0)
var nav
var viewRadius
var team

var dead = false
var hp
var max_hp
var attack
var defense

# stop navigation when true
var locked = false
#onready var dungeon = get_node("../")
#onready var dungeon = get_tree().get_root().get_node("Node2D/TileMap")
var dungeon = global.dungeon



#TODO: see why bullets tend to miss when enemies too close to ball (maybe because of sliding?)
func face_pos(var position):
	facingDir = (position - get_pos()).normalized()

func navigate(var delta, var recalcPath=false):
	if locked:
		return
	
	if dest != null:

		if path != null and pathIndex > path.size() - 1:
			dest = null
			path = null
			pathIndex = 1
		else:
			#turn optimize (3rd parameter) to true to get wall-hugging behavior
			if recalcPath:
				recalc_path()
			
			#prevents oscillating movement around destination
			var dist = get_global_pos() - dest
			dist = abs(dist[0]) + abs(dist[1])
			if dist < delta * speed:
				move_to(dest)
				dest = null
				path = null
				velocity.x = 0
				velocity.y = 0
				return
				
			if path != null and path.size() > 1:
				var dir = (path[pathIndex] - get_global_pos()).normalized()
				velocity = dir * speed
				
				#advances in path once close enough to path node
				var dist = get_global_pos() - path[pathIndex]
				dist = abs(dist[0]) + abs(dist[1])
				if dist < speed * delta:
					pathIndex += 1
			
	if velocity[0] + velocity[1] != 0:
		var motion = move(velocity * delta)
	
		# allows for sliding motion on walls instead of stopping
		if is_colliding():
	        var n = get_collision_normal()
	        motion = n.slide(motion)
	        velocity = n.slide(velocity)
	        move(motion)
	
		if velocity[0] + velocity[1] != 0:
			facingDir = velocity.normalized()
			
func change_dest(var newDest):
	dest = newDest

func recalc_path():
	path = nav.get_simple_path(get_global_pos(), dest, true)
	pathIndex = 1
	
func get_radius():
	return get_node("CollisionShape2D").get_shape().radius * get_scale()
	
func set_radius(var radius):
	var scale = radius / get_node("CollisionShape2D").get_shape().radius
	set_scale(Vector2(scale, scale))
	
func object_in_view(var object):
	if weakref(self).get_ref() and weakref(object).get_ref():
		return get_global_pos().distance_to(object.get_global_pos()) < viewRadius
	else:
		return false

func die():
	dead = true

func get_hp():
	return hp

func get_max_hp():
	return max_hp

func increment_hp(h):
	# enemy dies if it has 0 or less health
	# enemy also cannot have more than its current max health
	if hp + h <= 0:
		#return die()
		die()
	elif hp + h > max_hp:
		hp = max_hp
	else:
		hp += h
	return 0

func get_attack():
	return attack

func increment_attack(a):
	attack += a

func get_defense():
	return defense

func increment_defense(d):
	defense += d
	



