# player variables
var hp = 50
var max_hp = 50
var attack = 5
var defense = 0
var xp = 0
var xp_to_next_level = 100
var companion_xp_decrease = 3

# points in the path
var points = []
var velocity = Vector2()
var speed
var scale
var inventory = []
var facingDir = Vector2(1, 0)

#TODO: consider increasing maxCompanions to 10 to allow for multiple protected units
var maxCompanions = 10
var protectorLimit = 5

var companions = []


var dest = null
onready var nav = global.nav
onready var dungeon = get_node("../TileMap")
onready var actionBar = get_node("../hud/action bar")
const util = preload("util.gd")
const companionScene = preload("../companion.scn")

const chaseEnemy = preload("chaseEnemy.gd")
const protectPlayer = preload("protectPlayer.gd")
var team = global.playerTeam

var protectors = []
func _ready():
	set_fixed_process(true)
	set_process_input(true)

func init(var pos, var speed, var scale):
	self.scale = scale
	set_global_pos(pos)
	self.speed = speed
	set_scale(Vector2(scale, scale))	

# action bar inputs
func _input(event):
	if (event.is_action_pressed("action_bar_press") and !event.is_echo()):
		var num = OS.get_scancode_string(event.scancode)
		num = int(num)
		
		if num == 1:
			normal_attack()
		else:
			actionBar.use_slot(num)
	elif event.is_action_pressed("ui_cancel") and !event.is_echo():
		var bulletScene = preload("../bullet.scn")
		var bullet = bulletScene.instance()
		
		var bulletDir = (get_global_mouse_pos() - get_global_pos()).normalized()
		#TODO: make position dependent on radii of player and bullet
		bullet.init(get_global_pos() + get_radius() * 2 * bulletDir, bulletDir, speed * 2, self)
		bullet.damage = attack
		get_node("../").add_child(bullet)
		bullet.add_to_group("bullets")
		
	#press z to have companions pursue/attack enemy closest to mouse
	elif event.is_action_pressed("attack_enemy") and !event.is_echo():
		var mousePos = get_global_mouse_pos()
		var closestEnemy = util.get_closest_object(mousePos, dungeon.enemyArray)
		for companion in companions:
			if companion.type == "shooter":
				companion.stateMachine.changeState(chaseEnemy, [closestEnemy, dungeon.enemyArray, self])
	elif event.is_action_pressed("protect") and !event.is_echo():
		protect_player(companions)
		"""
		var bullets = get_tree().get_nodes_in_group("enemyBullets")
		var closest = util.get_closest_object(get_global_pos(), bullets)
		if closest != null:
			print(closest)
			var predictedPos = util.predict_bullet_location(closest, 0.16)
			for companion in companions:
				companion.set_global_pos(predictedPos)
		"""
		#for companion in companions:
		#	companion.stateMachine.changeState(protectPlayer, [self])
		
		"""
		if companions.size() > 0:
			var angle = 2 * PI / companions.size()
			var offset = (companions[0].get_radius()[0] + get_radius()) * 2
			offset = Vector2(0, offset)
			for i in range(companions.size()):
				var companion = companions[i]
				var tempOffset = util.rotate(offset, angle * i)
				companion.stateMachine.changeState(protectPlayer, [self, tempOffset])
				"""
				
				#companion.stateMachine.changeState(protectPlayer, [self])
				#companion.locked = true
				#companion.set_global_pos(util.rotate_around_point(get_global_pos() + offset, angle * i, get_global_pos()))
		#TODO: implement protect player
# TODO implement player death

func reset_protector_positions():
	protect_player(protectors)
	
func protect_player(var defenders):
	protectors = defenders
	
	if defenders.size() == 0:
		return
	
	var angle = 2 * PI / defenders.size()
	var offset = (get_radius()) * 4
	offset = Vector2(0, offset)
	for i in range(defenders.size()):
		var defender = defenders[i]
		#if defender has not been freed
		if weakref(defender).get_ref():
			var state = defender.stateMachine.state
			#if not (state extends protectPlayer and state.target == self):
			var tempOffset = util.rotate(offset, angle * i)
			defender.stateMachine.changeState(protectPlayer, [self, tempOffset, protectors])

func add_protector(var protector):
	if protector != null and not protector in protectors and protectors.size() < protectorLimit:
		protectors.append(protector)
		protect_player(protectors)
		return true
	return false

func reset_companion(var companion):
	if !weakref(companion).get_ref():
		return
	
	var success = add_protector(companion)
	
	if !success and not protectors in protectors:
		#if adding protector failed because of being over protector limit, use default behaviors
		if companion.type == "healer":
				var newHeal = global.healTeamScene.new()
				newHeal.init(companion, companion.stateMachine, ["allies"])
				companion.stateMachine.state = newHeal
		else:
			"""
			var follow = global.followPlayer.new()
			follow.init(companion, companion.stateMachine, [self, dungeon.enemyArray])
			companion.stateMachine.state = follow
			companion.bulletScene = global.companionBulletScene
			"""
			var newWander = global.wander.new()
			newWander.init(companion, companion.stateMachine, ["enemies"])
			companion.stateMachine.state = newWander


#TODO: remove protector if protector limit changes
func remove_protector():
	var removed = protectors[protectors.size() - 1]
	
	reset_companion(removed)
			
	protectors.pop_back()
	
	reset_protector_positions()

func die():
	get_tree().change_scene_to(global.menu)
	queue_free()

func _fixed_process(delta):
	#print(xp)
	#handle_actions()
	if float(hp) / max_hp < 0.3:
		protectorLimit = 5
		for companion in companions:
			add_protector(companion)
	else:
		protectorLimit = 3
		
	while protectors.size() > protectorLimit:
		remove_protector()

	handle_movement(delta)
	
	""" TESTING FEATURES """
	#pressing p makes player teleport to place of closest bullet
	"""
	if Input.is_action_pressed("protect"):
		var bullets = get_tree().get_nodes_in_group("enemyBullets")
		var closest = util.get_closest_object(get_global_pos(), bullets)
		if closest != null:
			print(closest)
			var predictedPos = util.predict_bullet_location(closest, delta)
			set_global_pos(predictedPos)
		#var pos = util.
	"""
	""" TESTING FEATURES """
	
	#TODO: consider removing navigation tile from bg if item placed there to get around collisions not working?

func handle_movement(delta):
	if dest == null:
		velocity.x = 0
		velocity.y = 0
	if Input.is_action_pressed("move_up"):
		velocity.y = -speed
		dest = null
	elif Input.is_action_pressed("move_down"):
		velocity.y = speed
		dest = null
	if Input.is_action_pressed("move_left"):
		velocity.x = -speed
		dest = null
	elif Input.is_action_pressed("move_right"):
		velocity.x = speed
		dest = null
	
	if Input.is_action_pressed("left_click"):
		var mousePos = get_global_mouse_pos()
		nav = global.nav
		dest = nav.get_closest_point(mousePos)
		
	if dest != null:
		#prevents vibrating behavior when close to destination
		var dist = get_global_pos() - dest
		dist = abs(dist[0]) + abs(dist[1])
		if dist < 0.01 * speed:
			move_to(dest)
			dest = null
		else:
			#turn optimize (3rd parameter) to true to get wall-hugging behavior
			var path = nav.get_simple_path(get_global_pos(), dest, true)
			if path != null and path.size() > 1:
				var dir = (path[1] - get_global_pos()).normalized()
				velocity = dir * speed
	
	var motion = move(velocity * delta)
	
	# allows for sliding motion on walls instead of stopping
	if is_colliding():
        var n = get_collision_normal()
        motion = n.slide(motion)
        velocity = n.slide(velocity)
        move(motion)

	if velocity[0] + velocity[1] != 0:
		facingDir = velocity.normalized()

#TODO: fix/remove so in line with current recruitment (handled in die)
func normal_attack():
	# TODO: get list of enemies
	"""
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if util.distance(enemy.get_global_pos(), self.get_global_pos()) < 10 * get_radius():
			enemy.increment_hp(-attack)
	"""
	var areaScene = preload("../areaAttack.scn")
	var areaAttack = areaScene.instance()
	areaAttack.set_pos(get_global_pos())
	areaAttack.damage = attack
	areaAttack.maxRadius = get_radius() * 6
	get_node("../").add_child(areaAttack)

# TODO: finish random chance, add companion to map/list
func recruit_companion():
	randomize()
	

# TODO: remove 1 companion from the map
func release_companion():
	if companions.size() > 0:
		companions.pop_front()

func get_hp():
	return hp

func get_max_hp():
	return max_hp

func increment_hp(h):
	# player dies if they have 0 or less health
	# player also cannot have more than their current max health
	if hp + h <= 0:
		die()
	elif hp + h > max_hp:
		hp = max_hp
	else:
		hp += h

func increment_max_hp(h):
	# cannot decrease max health past what they started with
	# increase current hp to max health if possible
	if max_hp + h < 50:
		max_hp = 50
	else:
		max_hp += h
		if hp < max_hp:
			hp = max_hp

func get_attack():
	return attack

func increment_attack(a):
	# do not decrease player attack past what they started with
	if attack + a < 5:
		attack = 5
	else:
		attack += a

func get_defense():
	return defense

func increment_defense(d):
	# do not decrease player defense past what they started with
	if defense + d < 0:
		defense = 0
	else:
		defense += d

func get_xp():
	return xp

func get_xp_to_next_level():
	return xp_to_next_level

func get_xp_ratio():
	return float(xp) / float(xp_to_next_level)

func get_max_xp():
	return xp_to_next_level

func increment_xp(x):
	# modify the incoming xp by the number of companions
	x -= companions.size() * companion_xp_decrease
	if x < 0:
		return
	# if player levels down, decrease attack, defense
	# remove any excess xp from previous level
	if xp + x < 0:
		# don't decrease level past the original level
		if xp_to_next_level <= 100:
			return
		else:
			increment_max_hp(-10)
			increment_attack(-3)
			increment_defense(-2)
			var extra_xp = xp + x
			xp_to_next_level = int(xp_to_next_level * 0.6)
			xp = xp_to_next_level - extra_xp
			
	# if there are no level changes, just add xp
	elif xp + x < xp_to_next_level:
		xp += x
		
	# if player levels up, increase max health, attack, defense
	# add any excess xp to the next level
	else: 
		increment_max_hp(10)
		increment_attack(3)
		increment_defense(2)
		var extra_xp = x - (xp_to_next_level - xp)
		xp = extra_xp
		xp_to_next_level = int(xp_to_next_level * 1.4)
		
func get_radius():
	return get_node("collision").get_shape().radius * scale
	
func add_item(var item):
	if item.name == "xp":
		item.use_on(self)
		return true
	else:
		var success = actionBar.add_item(item)
		if success:
			inventory.append(item)
			return true
		return false
		
func teleport_randomly():
	dungeon = global.dungeon
	set_global_pos(dungeon.get_random_valid_map_pos())
	
func recruit(var enemy):
	
	var companionTexture = preload("../images/companion.png")
	enemy.team = team
	enemy.get_node("Sprite").set_texture(companionTexture)
	companions.append(enemy)
	enemy.set_radius(get_radius())
	enemy.dead = false
	enemy.hp = enemy.max_hp
	reset_companion(enemy)
	enemy.remove_from_group("enemies")
	enemy.add_to_group("allies")
	
func is_inventory_full():
	return actionBar.is_full()