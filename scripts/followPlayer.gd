
extends "state.gd"

#TODO: follow at certain distance/positions to avoid colliding with player

var player

# which agents, if in range, cause transition to chasePlayer
var enemies

const chase = preload("chaseEnemy.gd")
func enter(var oldState):
	#self.oldState = oldState
	agent.path = null
	agent.dest = null
	agent.timePassed = 0.4

func execute(var delta):
	if agent.type == "shooter":
		for enemy in enemies:
			if agent.object_in_view(enemy):
				stateMachine.changeState(chase, [enemy, enemies, player])
				return
	#print(agent.dungeon.get_items_within_radius(agent.get_global_pos(), agent.viewRadius))
	
	"""
	if !player.is_inventory_full():
		var closestItem = agent.dungeon.get_closest_item_within_radius(agent.get_global_pos(), agent.viewRadius)
		print(agent.viewRadius)
		if closestItem == null:
			print("no items in view")
		else:
			print(closestItem.name)
	"""
	
	if agent.timePassed > 0.3 and agent.path == null:
		agent.change_dest(player.get_global_pos())
		agent.navigate(delta, true)
		agent.timePassed = 0
	else:
		agent.navigate(delta)
		
	#TODO: switch to wander or something when target dies (only applicable for companion use, assuming game ends when player dies)

func parse_args(var args):
	if args.size() > 0:
		player = args[0]
	if args.size() > 1:
		enemies = args[1]

