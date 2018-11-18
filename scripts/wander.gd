
extends "state.gd"

# member variables here, example:
# var a=2
# var b="textvar"
var target = null
var group

var chasePlayer = preload("chasePlayer.gd")
func execute(var delta):
	agent.timePassed += delta
	
	var targets = agent.get_tree().get_nodes_in_group(group)
	targets = util.get_objects_within_radius(agent.get_global_pos(), targets, agent.viewRadius)
	target = util.weakest_agent(targets)
	
	#TODO: add in behavior that if enemy sees other enemies attacking, join in attack even if player not in view
	#TODO; change player_in_view() so it rayTraces
	if target != null:
		agent.path = null
		agent.dest = null
		stateMachine.changeState(chasePlayer, [target, group])
	elif agent.timePassed > 0.3 and agent.path == null:
		#recalc wandering path if path completed/not possible/not set
		agent.change_dest(agent.dungeon.get_random_valid_map_pos())
		agent.navigate(delta, true)
		agent.timePassed = 0
	else:
		agent.navigate(delta)
	
func enter(var oldState):
	pass
	
func exit():
	pass
	
func parse_args(var args):
	if args.size() > 0:
		group = args[0]
	"""
	if args.size() > 1:
		target = args[1]
	"""

