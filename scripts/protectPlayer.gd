
extends "state.gd"

# member variables here, example:
# var a=2
# var b="textvar"
const util = preload("util.gd")
var target
var offset = Vector2(0, 0)
var squad = []
var prevSize

func enter(var oldState):
	self.oldState = oldState
	agent.path = null
	agent.dest = null
	agent.timePassed = 0.4
func execute(var delta):
	"""
	if agent.timePassed > 0.3 and agent.path == null:
		var bullets = agent.get_tree().get_nodes_in_group("enemyBullets")
		var closest = util.get_closest_object(target.get_global_pos(), bullets)
		if closest != null:
			var predictedPos = util.predict_bullet_location(closest, delta)
			#agent.set_global_pos(predictedPos)
			agent.change_dest(predictedPos)
			agent.navigate(delta, true)
	else:
		agent.navigate(delta)
	"""
	"""
	var size = squad.size()
	if size != prevSize:
		target.protect_player(squad)
		return
	"""
	offset = offset.rotated(PI/200)
	if agent.timePassed > 0.3 and agent.path == null:
		agent.change_dest(target.get_global_pos() + offset)
		agent.navigate(delta, true)
		agent.timePassed = 0
	else:
		agent.navigate(delta)
	
	if agent.type == "shooter":
		var enemies = agent.get_tree().get_nodes_in_group("enemies")
		var visible = util.get_objects_within_radius(agent.get_global_pos(), enemies, agent.viewRadius)
		var weakest = util.weakest_agent(visible)
		if weakest != null:
			agent.shoot_at_pos(weakest.get_global_pos())
	elif agent.type == "healer":
		agent.heal()
	

func parse_args(var args):
	if args.size() > 0:
		target = args[0]
	if args.size() > 1:
		offset = args[1]
	if args.size() > 2:
		squad = args[2]
		prevSize = squad.size()
	