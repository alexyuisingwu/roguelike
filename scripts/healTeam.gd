
extends "state.gd"

var group

func execute(var delta):
	#TODO: first priority is player (if group is allies), then allies if player is healthy
	var allies = agent.get_tree().get_nodes_in_group(group)
	var weakest = util.weakest_agent(allies)
	#print(weakest.hp / weakest.max_hp)
	#print(allies)
	
	if agent.timePassed > 0.3 and agent.path == null:
		agent.change_dest(weakest.get_global_pos())
		agent.navigate(delta, true)
		agent.timePassed = 0
	else:
		agent.navigate(delta)
	
	agent.heal()

func parse_args(var args):
	if args.size() > 0:
		group = args[0]