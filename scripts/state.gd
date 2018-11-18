extends Object
# member variables here, example:
# var a=2
# var b="textvar"
var agent
var stateMachine
var oldState

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	pass
	
func init(var agent, var stateMachine, var args=[]):
	self.agent = agent
	self.stateMachine = stateMachine
	parse_args(args)
	
func execute(var delta):
	pass
	
func enter(var oldState):
	self.oldState = oldState
	pass
	
func exit():
	pass
	
func parse_args(var args):
	pass

