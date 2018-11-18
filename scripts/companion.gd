
extends "shooter.gd"
var owner
var followTarget = preload("followPlayer.gd")
const companionBulletScene = preload("../companionBullet.scn")
var stateMachine = preload("stateMachine.gd").new()
var timePassed = 0
#TODO: possible states: focus fire (might not be state, just in companion)
#	   split targets (might not be state, just in companion)
#TODO: keypress in ball for changing companion behavior (z for focus fire on specified enemy)
#TODO: 
func init(var max_hp, var attack, var defense, var speed, var viewRadius, var owner):
	self.hp = max_hp
	self.max_hp = max_hp
	self.attack = attack
	self.defense = defense
	self.speed = speed
	self.viewRadius = viewRadius
	self.owner = owner
	
	
func _ready():

	#TODO: create followPlayer and chaseEnemy states (chaseEnemy might be able to use a modified chasePlayer, not sure yet)
	#TODO: modify followPlayer to reduce collisions/blocking player/companions
	#TODO: allow player to press key to switch all companion states (attackEnemy/follow) (make some boolean to ensure companion doesn't immediately switch back to chasing enemy because of state transition conditions if under command)
	var follow = followTarget.new()
	
	#TODO: change wander/chasePlayer to allow for multiple targets (based on target type, not specific target object)
	#TODO: make wander/chasePlayer target the first thing with type matching the target
	follow.init(self, stateMachine, [owner, dungeon.enemyArray])
	stateMachine.state = follow
	
	bulletScene = companionBulletScene
	nav = get_node("../TileMap/Navigation2D")
	
	set_fixed_process(true)

func _fixed_process(delta):
	if dead:
		#die()
		set_fixed_process(false)
		return
	"""
	var temp = stateMachine.state
	if temp extends followTarget:
		print("State is follow player")
	else:
		print("State is target enemy")
	"""
	
	
	timePassed += delta
	stateMachine.update(delta)
	
	

func die():
	dead = true
	owner.companions.erase(self)
	queue_free()

