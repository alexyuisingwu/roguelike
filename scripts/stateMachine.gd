
extends Object

# member variables here, example:
# var a=2
# var b="textvar"

var state = null
var old = null
var new = null
func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	pass

		
func update(delta):
	if state != null:
		state.execute(delta)
	

func changeState(newstateclass, args=[]):
	#TODO: dictionary (states) mapping newstatelass to preloaded state script

	old = state
	if old != null:
		old.exit()
	if newstateclass != null:
		new = newstateclass.new()
		new.init(old.agent, self, args)
		new.enter(old)
		state = new
	else:
		state = null
			
	#TODO: queue_free stuff
func getState():
	if state == null:
		return null
	else:
		return state



