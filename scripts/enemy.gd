extends "shooter.gd"

# enemy variables


var max_hp_level_scale = 15

var attack_level_scale = 5

var defense_level_scale = 1	
var xp_on_death
var xp_level_scale = 10
var pos
var texture

var timePassed = 0

var recruitChance = 0.5


onready var ball = global.ball
const enemyBulletScene = preload("../enemyBullet.scn")
const enemyBulletTexture = preload("../images/enemy bullet.png")
const companionBulletTexture = preload("../images/bullet.png")
#onready var fieldOfView = get_node("Vision")
var visible = []
var sawPlayer = false

var stateMachine = preload("stateMachine.gd").new()
var wander = preload("wander.gd")

var healTimePassed = 0
var healRate = 1

# Enemy types = shooter, healer
var type = "shooter"

func init(pos, level):
	self.pos = pos
	set_global_pos(pos)
	
	
	randomize()
	var rand_scale = rand_range(0.5, level)
	
	max_hp = int(rand_scale * max_hp_level_scale)
	hp = max_hp
	attack = int(rand_scale * attack_level_scale)
	defense = int(rand_scale * defense_level_scale)
	xp_on_death = int(rand_scale * xp_level_scale)

func _ready():
	team = 1
	set_radius(ball.get_radius())
	speed = 100
	#dest = dungeon.get_random_valid_map_pos()
	dest = ball.get_global_pos()
	#fieldOfView.set_radius(100)
	viewRadius = get_radius()[0] * 50
	
	if type == "healer":
		var newHeal = global.healTeamScene.new()
		newHeal.init(self, stateMachine, ["enemies"])
		stateMachine.state = newHeal
	else:
		var newWander = wander.new()
		newWander.init(self, stateMachine, ["allies"])
		stateMachine.state = newWander
		
		bulletScene = enemyBulletScene
	nav = global.nav
	
	set_fixed_process(true)

# TODO: all the AI!
func _fixed_process(delta):
	
	if dead:
		set_fixed_process(false)
		return
	
	""" TESTING FINDING NEARBY ITEMS """
	#for item in get_tree().get_nodes_in_group("items"):
		#if object_in_view(item):
			#print(item.name)
	""" TESTING FINDING NEARBY ITEMS """
		
	timePassed += delta
	healTimePassed += delta
	
	stateMachine.update(delta)

func player_in_view():
	return object_in_view(ball)
	
func get_player():
	return ball
	
func shoot():
	var bullet =.shoot()
	if bullet != null and team == 1:
		bullet.add_to_group("enemyBullets")
		
func heal():
	if healTimePassed > healRate:
		var heal = global.healScene.instance()
		heal.set_pos(get_global_pos())
		heal.maxRadius = get_radius()[0] * 6
		heal.set_radius(0.01)
		heal.owner = self
		get_node("../").add_child(heal)
		healTimePassed = 0
		return heal
	return null

func die():
	dead = true
	if self in ball.protectors:
		ball.protectors.erase(self)
		ball.protect_player(ball.protectors)
	if team != ball.team:
		ball.increment_xp(xp_on_death)
		#groups return shallow copy, not deep copy
		dungeon.enemyArray.erase(self)
		remove_from_group("enemies")
		var rand = randf()
		if rand < recruitChance and ball.companions.size() < ball.maxCompanions:
			ball.recruit(self)
		else:
			queue_free()
	else:
		remove_from_group("allies")
		ball.companions.erase(self)
		queue_free()
	#return xp_on_death