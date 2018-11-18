
extends "state.gd"

# member variables here, example:
# var a=2
# var b="textvar"

var target
var group

#TODO: find out why agent replanning path doesn't occur right after state transition
func enter(var oldState):
	self.oldState = oldState
	agent.path = null
	agent.dest = null
	agent.timePassed = 0.4

func execute(var delta):
	if weakref(agent).get_ref():
		if weakref(target).get_ref():
			if agent.timePassed > 0.3 and agent.path == null:
				agent.change_dest(target.get_global_pos())
				agent.navigate(delta, true)
				agent.timePassed = 0
			else:
				agent.navigate(delta)
			
			agent.shoot_at_pos(target.get_global_pos())
			
		if !weakref(target).get_ref() or not target in agent.get_tree().get_nodes_in_group(group):
			agent.stateMachine.changeState(global.wander, [group])
		
	#TODO: switch to wander or something when target dies (only applicable for compaions)

func parse_args(var args):
	if args.size() > 0:
		target = args[0]
	if args.size() > 1:
		group = args[1]