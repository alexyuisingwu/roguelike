extends Node2D
const enemies = preload("../enemy.scn")
const SIZE = Vector2( 45, 32)
#const SIZE = Vector2( 45, 35)
var tileSize
var map = []
var tiles
var enemyArray
var tilemap
var traversables = {}
var ball
var free
var freeSpaces
var enemyRate
const items = preload("../item.scn")
var itemRate
var itemInstance = items.instance()
var itemLocations = {}
var itemScale
func _ready():
	# get TileMap node
	global.dungeon = self
	tilemap = get_node("TileMap")
	var nav2D = tilemap.get_node("Navigation2D")
	print(nav2D)
	global.nav = nav2D
	print(global.nav)
	print("no1")
	ball = get_node("ball")
	print("no2")
	ball.init(Vector2(-10,-10), 150, 1)
	ball.set_scale(Vector2(.75,.75))
	ball.add_to_group("allies")
	global.ball=ball
	tiles = preload("../tilesets/tileset.res")
	_on_Random_pressed()
	set_fixed_process(true)
func _fixed_process(delta):
	
	debug_functions()
	
	var pos = tilemap.world_to_map(ball.get_global_pos())
	
	if pos in itemLocations:
		if Input.is_action_pressed("ui_accept"):
			pickup_item(ball, tilemap.map_to_world(pos))
			
	if Input.is_action_pressed("menu"):
		get_tree().change_scene_to(global.menu)
# Random button pressed
func _on_Random_pressed():
	print("no2.5")
	map.resize(SIZE.x * SIZE.y)
	print("no2.5")

	for y in range(SIZE.y):
		for x in range(SIZE.x):
			var i = y * SIZE.x + x # index of current tile
			#print(fill_percent)
			# fill map with random tiles
			var fill_percent = 50#get_node("Buttons/Panel/Fill").get_val() # how much walls we want
			if randi() % 101 < fill_percent or x == 0 or x == SIZE.x-1 or y == 0 or y == SIZE.y-1:
				map[i] = 1 # wall
			else:
				map[i] = 0 # empty
	# draw the map
	#var num = largestIsland()
	_on_Smooth_pressed()
	_on_Smooth_pressed()
	update_map()
	#get_node("Buttons/Smooth").set_disabled(false) # when we have a map user can smooth it
	
	#print(largestIsland()[0].size())
#Check if a tile is safe
func isSafe(map, r, c, visited):
	return (r >= 0) and (r < SIZE.x) and (c >= 0) and (c < SIZE.y) and (map[c * SIZE.x + r] == 0 and !visited[c * SIZE.x + r])
func DFS(map, r, c, visited,l):
	var rowNbr = []
	var colNbr = []
	rowNbr.resize(4)
	colNbr.resize(4)
	rowNbr = [-1,0,0,1]
	colNbr = [0,-1,1,0]
	visited[c * SIZE.x + r] = true 
	var holder = c * SIZE.x + r
	l.append([r,c])
	for k in range(4):
		if(isSafe(map, r + rowNbr[k], c + colNbr[k],visited)):
			l = DFS(map, r + rowNbr[k], c + colNbr[k],visited,l)
	return l
func largestIsland():
	var visited = []
	var l = []
	visited.resize(SIZE.x * SIZE.y)
	var count = 0
	var idxs = []
	var idx = []
	for i in range(SIZE.x * SIZE.y):
		visited[i] = false
	for y in range(SIZE.y):
		for x in range(SIZE.x):
			if(map[y * SIZE.x + x]==0 and !visited[y * SIZE.x + x]):
				idxs.append( DFS(map, x, y, visited,l))
				l = []
				count = count + 1
	var maximum = 0
	var candidate = 0
	for j in range(idxs.size()):
		candidate = idxs[j].size()
		if candidate > maximum:
			 maximum = candidate
	for k in range(idxs.size()):
		if maximum == idxs[k].size():
			idx.append(idxs[k])		
	return idx
# set tiles in Tilemap to match map array
func update_map():
	for poly in get_tree().get_nodes_in_group("navPolys"):
		poly.queue_free()
	free = largestIsland()[0]
	randomize()
	enemyArray = []
	#print(num)
	var index = randi()%free.size()
	#print(Vector2(num[index][0],num[index][1]))
	ball.set_global_pos(tilemap.map_to_world(Vector2(free[index][0],free[index][1])))
	global.ball=ball
	#tilemap = get_node("TileMap")
	#print("no1")
	#ball = get_node("ball")
	#var num = largestIsland()[0]
	#print(num)
	#set_tileset(tiles)
	freeSpaces = {}
	for i in range(free.size()):
		freeSpaces[Vector2(free[i][0],free[i][1])] = null
	var empty = tiles.find_tile_by_name("empty")
	traversables = {empty: null}
	var screenSize = get_viewport_rect().size * 2
	var screenSizeMultiplier = 1.0
	tileSize = (tiles.tile_get_region(empty).size)
	itemScale = 0.1
	itemRate = 0.25
	enemyRate = 0.05
	print("made it")
	print("yup")
	for y in range(SIZE.y):
		for x in range(SIZE.x):
			var i = y * SIZE.x + x
			tilemap.set_cell(x, y, map[i])
	make_nav()
	
	populate_enemies()
	populate_items()
	
func _on_Smooth_pressed():
	# new map to apply changes
	var new_map = []
	new_map.resize(SIZE.x * SIZE.y)
	
	for e in range(map.size()): # copy old array
		new_map[e] = map[e]
	
	# we need to skip borders of screen
	for y in range(1,SIZE.y -1):
		for x in range(1,SIZE.x - 1):
			var i = y * SIZE.x + x
			if map[i] == 1: # if it was a wall
				if touching_walls(Vector2(x,y)) >= 4: # and 4 or more of its eight neighbors were walls
					new_map[i] = 1 # it becomes a wall
				else:
					new_map[i] = 0
			elif map[i] == 0: # if it was empty
				if touching_walls(Vector2(x,y)) >= 5: # we need 5 or neighbors
					new_map[i] = 1
				else:
					new_map[i] = 0
	map = new_map # apply new array
	#update_map()
	
# return count of touching walls 
func touching_walls(point):
	var result = 0
	for y in [-1,0,1]:
		for x in [-1,0,1]:
			if x == 0 and y == 0: # we don't want to count tested point
				continue
			var i = (y + point.y) * SIZE.x + (x + point.x)
			if map[i] == 1:
				result += 1
	return result

func make_nav():
	#TODO: could probably save time by using freeSpaces (though does not include item locations)
	#TODO: move everything under if tile in traversables if statement
	#TODO: fix navigation (probably problem due to overlapping polys?) try using Rect2 to find intersections
	for i in range(1, SIZE.x-1):
		for j in range(1, SIZE.y-1):
			var pos = tilemap.map_to_world(Vector2(i, j))
			#var adj = adj_composition(i, j)
			
			var rad = ball.get_radius()
			var tile = tilemap.get_cell(i, j)
			var left = tilemap.get_cell(i - 1, j)
			var right = tilemap.get_cell(i + 1, j)
			var up = tilemap.get_cell(i, j - 1)
			var down = tilemap.get_cell(i, j + 1)
			var topLeft = tilemap.get_cell(i - 1, j - 1)
			var topRight = tilemap.get_cell(i + 1, j - 1)
			var bottomLeft = tilemap.get_cell(i - 1, j + 1)
			var bottomRight = tilemap.get_cell(i + 1, j + 1)
				
			if tile in traversables:
				var outline
				var output
				output = make_outline(pos, rad, tileSize[0] - rad, rad, tileSize[1] - rad)
				if up in traversables:
					#top rectangle
					outline = make_outline(pos, rad, tileSize[0] - rad, 0, rad)
					output = util.merge(output, outline)
					
					if topLeft in traversables and left in traversables:
						outline = make_outline(pos, 0, rad, 0, rad)
						output = util.merge(output, outline)
						
					if topRight in traversables and right in traversables:
						outline = make_outline(pos, tileSize[0] - rad, tileSize[0], 0, rad)
						output = util.merge(output, outline)

				if down in traversables:
					outline = make_outline(pos, rad, tileSize[0] - rad, tileSize[1] - rad, tileSize[1])
					output = util.merge(output, outline)
					
					if bottomLeft in traversables and left in traversables:
						outline = make_outline(pos, 0, rad, tileSize[1] - rad, tileSize[1])
						output = util.merge(output, outline)
					if bottomRight in traversables and right in traversables:
						outline = make_outline(pos, tileSize[0] - rad, tileSize[0], tileSize[1] - rad, tileSize[1])
						output = util.merge(output, outline)
						
				if left in traversables:
					outline = make_outline(pos, 0, rad, rad, tileSize[1] - rad)
					add_nav(outline)
					
				if right in traversables:
					outline = make_outline(pos, tileSize[0] - rad, tileSize[0], rad, tileSize[1] - rad)
					add_nav(outline)
				
				
					
				add_nav(output)
				var a = 1
func make_outline(var pos, var x0, var x1, var y0, var y1):
	return Vector2Array([
		pos + Vector2(x0, y1), pos + Vector2(x1, y1),
		pos + Vector2(x1, y0), pos + Vector2(x0, y0)
		])
func add_nav(var outline):
	add_multi_nav([outline])
func add_multi_nav(var outlines):
	var navInst = NavigationPolygonInstance.new()
	var navPoly = NavigationPolygon.new()
	for outline in outlines:
		navPoly.add_outline(outline)
	navPoly.make_polygons_from_outlines()
	
	navInst.set_navigation_polygon(navPoly)
	
	get_node("TileMap/Navigation2D").add_child(navInst)
	#TODO: clean up polys at level reset
	navInst.add_to_group("navPolys")
func add_enemy(var pos):
	var enemy = enemies.instance()
	var rand = randf()
	if rand < .25:
		enemy.type = "healer"
	

	if pos != null:
		add_child(enemy)
		enemy.init(pos, 1)
		enemy.set_radius(3)
		#enemyLocations[world_to_map(pos)] = enemy
		enemy.add_to_group("enemies")
		enemyArray.append(enemy)
		freeSpaces.erase(tilemap.world_to_map(pos))
func populate_enemies():
	for i in range(freeSpaces.size() * enemyRate):
		add_enemy(get_random_valid_map_pos())
func get_random_valid_map_pos():
	var pos = get_random_valid_pos()
	if pos != null:
		pos = tilemap.map_to_world(pos)
		return Vector2(pos[0] + float(tileSize[0]) / 2, pos[1] + float(tileSize[1]) / 2)
	else:
		return null
func get_random_valid_pos():
	if freeSpaces.size() > 0:
		var posIndex = randi() % freeSpaces.size()
		return freeSpaces.keys()[posIndex]
	else:
		return null

#NOTE: guarantees number of items = itemRate * number of free spaces
func populate_items():
	for i in range(freeSpaces.size() * itemRate):
		add_random_item()
		
func add_random_item():
	add_item(itemInstance.get_random_item_string(), get_random_valid_map_pos())
	return false

func add_item(var name, var pos):
	var temp = add_item_without_erasing_from_free(name, pos)
	if temp == true:
		freeSpaces.erase(tilemap.world_to_map(pos))
		return true
	return false
	
func add_item_without_erasing_from_free(var name, var pos):
	var item = items.instance()
	if pos != null:
		add_child(item)
		item.init(name, pos, itemScale)
		itemLocations[tilemap.world_to_map(pos)] = item
		item.add_to_group("items")
		return true
	return false

# target (which has add_item func) gets item if it exists in specified map position
func pickup_item(var target, var pos):
	pos = tilemap.world_to_map(pos)
	var item = itemLocations[pos]
	var success = target.add_item(item)
	if success:
		remove_child(item)
		itemLocations.erase(pos)
		freeSpaces[pos] = null
		item.set_owner(target)
		item.remove_from_group("items")
		
func debug_functions():
	#FOR TESTING ONLY: CAMERA ZOOM SHOULD PROBABLY BE DISABLED IN GAME
	if Input.is_action_pressed("zoom_in"):
		var camera = ball.get_node("Camera2D")
		var zoom = camera.get_zoom()
		zoom = Vector2(max(zoom[0] - 0.1, 0.1), max(zoom[1] - 0.1, 0.1))
		camera.set_zoom(zoom)
	if Input.is_action_pressed("zoom_out"):
		var camera = ball.get_node("Camera2D")
		var zoom = camera.get_zoom()
		zoom = Vector2(zoom[0] + 0.1, zoom[1] + 0.1)
		camera.set_zoom(zoom)
	if Input.is_action_pressed("reset_position"):
		ball.set_global_pos(get_random_valid_map_pos())