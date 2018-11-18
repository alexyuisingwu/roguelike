
extends "state.gd"

# member variables here, example:
# var a=2
# var b="textvar"

var player
var target
var enemies
const followPlayer = preload("followPlayer.gd")
const util = preload("util.gd")
#TODO: find out why agent replanning path doesn't occur right after state transition
func enter(var oldState):
	self.oldState = oldState
	agent.path = null
	agent.dest = null
	agent.timePassed = 0.4

func execute(var delta):
	if target in enemies and weakref(target).get_ref():
		if agent.timePassed > 0.3 and agent.path == null:
			agent.change_dest(target.get_global_pos())
			agent.navigate(delta, true)
			agent.timePassed = 0
		else:
			agent.navigate(delta)
		if agent.type == "shooter":
			agent.shoot_at_pos(target.get_global_pos())
		#var predict = util.predict_navigator_location(target, delta)
		#agent.shoot_at_pos(predict)
	else:
		#enemy is dead, return to following player
		stateMachine.changeState(followPlayer, [player, enemies])
	#TODO: switch to wander or something when target dies (only applicable for compaions)

func parse_args(var args):
	if args.size() > 0:
		target = args[0]
	if args.size() > 1:
		enemies = args[1]
	if args.size() > 2:
		player = args[2]