extends TileMap


var tiles
var wall
var bg
var stairs
var visitedTile
var screenSize
var screenSizeMultiplier
var tileSize
var exit
#max number of (horizontal, vertical) cells
var maxCells

var rooms

const roomScene = preload("../room.scn")
const util = preload("util.gd")
const items = preload("../item.scn")
const enemies = preload("../enemy.scn")
var itemInstance = items.instance()
onready var ball = get_node("../ball")
onready var nav2D = get_node("../")

var level = 1

var enemyRate
var healerRate = 0.25

var itemScale
var itemRate
#TODO: consider just using 2-dimensional array to somewhat cut down on storage/indexing
# maps tile [x, y] to boolean: true if free, false otherwise
var freeSpaces

var roomWidthRange
var roomHeightRange

var itemLocations = {}
var enemyLocations = {}
var traversables = {}

# used to assist with stateMachine as get_nodes_in_group returns fresh array, so changes aren't reflected in later references
# groups provide shallow copies, not deep copies
var enemyArray = []

#NOTE: make sure screen size divisible by tile size (look into scaling)
#TODO: set display size in code, not just in settings
func _ready():
	global.dungeon = self
	global.player = ball
	global.ball = ball
	global.nav = get_node("Navigation2D")
	
	
	ball.add_to_group("allies")
	
	set_process_input(true)
	pass

func _fixed_process(delta):
	if not weakref(ball).get_ref():
		return
	
	var pos = world_to_map(ball.get_global_pos())
	
	if pos == exit:
		if Input.is_action_pressed("ui_accept"):
			next_level()
	if pos in itemLocations:
		if Input.is_action_pressed("ui_accept"):
			pickup_item(ball, map_to_world(pos))
				
	if Input.is_action_pressed("menu"):
		get_tree().change_scene_to(global.menu)

	debug_functions()
	
# playerModel is vector of [Killer, Explorer, Achiever], each ranging from 1 to 3 (float)
func process_player_model(var playerModel):
	enemyRate *= playerModel[0]
	roomWidthRange[0] /= (float(playerModel[1]) / 3)
	roomWidthRange[1] /= (float(playerModel[1]) / 3)
	roomHeightRange[0] /= (float(playerModel[1]) / 3)
	roomHeightRange[1] /= (float(playerModel[1]) / 3)
	itemRate *= playerModel[2] * 2
	return


func get_items():
	return get_tree().get_nodes_in_group("items")

func get_items_within_radius(var pos, var radius):
	return util.get_objects_within_radius(pos, get_items(), radius)

func get_closest_item_within_radius(var pos, var radius):
	return util.get_closest_object_within_radius(pos, get_tree().get_nodes_in_group("items"), radius)

# returns true if tile corresponding to map pos contains item
func has_item(var pos):
	return world_to_map(pos) in itemLocations

# target (which has add_item func) gets item if it exists in specified map position
func pickup_item(var target, var pos):
	pos = world_to_map(pos)
	var item = itemLocations[pos]
	var success = target.add_item(item)
	if success:
		remove_child(item)
		itemLocations.erase(pos)
		freeSpaces[pos] = null
		item.set_owner(target)
		item.remove_from_group("items")
#makes rectangular room width (x,y) position and width and height specified by cell units
#NOTE: size is size of room INCLUDING wall tiles (actual traversable area smaller)
#WARNING: MINIMUM DIMENSION OF ROOM IS 4X4, LOWER DIMENSIONS CAN LEAD TO ERRORS
func make_room(var x, var y, var width, var height):
	for i in range(x, x + width):
		#top and bottom walls
		set_cell(i, y, wall)
		set_cell(i, y + height - 1, wall)

	for j in range(y + 1, y + height - 1):
		#left and right walls
		set_cell(x, j, wall)
		set_cell(x + width - 1, j, wall)
		
	for i in range(x + 1, x + width - 1):
		#background tiles
		for j in range(y + 1, y + height - 1):
			set_cell(i, j, bg)

	var newRoom = roomScene.instance()
	newRoom.init(Rect2(x, y, width, height))
	rooms.append(newRoom)
	
#used to allow rooms to merge; set_cell calls should be replaced with merge_tile to use
func merge_tile(var x, var y, var type):
	if get_cell(x, y) != bg and get_cell(x, y) != stairs:
		set_cell(x, y, type)

#TODO: constrain rooms to within 1 tile of edge, to try to prevent rare hallway to the end of the screen
#WARNING: WILL INFINITELY LOOP IF CONSTRAINTS DO NOT ALLOW FOR VALID ROOM
#creates and draws random room; returns true if successful, false otherwise
func make_random_room(var minWidth, var maxWidth, var minHeight, var maxHeight):
	#if width > maxCells[0] - 1 or y + height > maxCells[1] - 1 or x < 1 or y < 1:
	
	randomize()
	var x = randi() % int(maxCells[0])
	var y = randi() % int(maxCells[1])
	var width =randi() % int(maxWidth - minWidth) + minWidth
	var height = randi() % int(maxHeight - minHeight) + minHeight
	while x + width > maxCells[0] - 1 or y + height > maxCells[1] - 1 or x < 1 or y < 1:
		#ensures most rooms within display bounds (walls may be generated whiel halls formed)
		x = randi() % int(maxCells[0])
		y = randi() % int(maxCells[1])

	for room in rooms:
		if room.get_rect().intersects(\
			Rect2(x, y, width, height)):
				return false
				
	make_room(x, y, width, height)

	return true
	
#WARNING: MINIMUM DIMENSION OF ROOM IS 4X4, LOWER DIMENSIONS CAN LEAD TO ERRORS
func make_random_floor():
	for i in range(50):
		#make_random_room(3, maxCells[0], 3, maxCells[1])
		make_random_room(roomWidthRange[0], roomWidthRange[1], roomHeightRange[0], roomHeightRange[1])
	make_halls()
	#fix any remaining errors in floorplan
	clean_up_floor()
	place_exit()

#creates MST for floor; each room is assigned its neighbors (does not return anything)
func min_span_tree():
	var edges = []
	var roomToTree = {}
	for i in range(rooms.size()):
		var r1 = rooms[i]
		#each room node belongs to a different tree
		roomToTree[r1] = i
		for j in range(i + 1, rooms.size()):
			var r2 = rooms[j]
			edges.append([r1, r2])
	edges.sort_custom(rooms[0], "sort_by_dist")
	
	var ind = 0
	var edgesAdded = 0

	#MST has |V| - 1 edges
	while ind < edges.size() and edgesAdded != rooms.size() - 1:
		var edge = edges[ind]
		if roomToTree[edge[0]] != roomToTree[edge[1]]:
			#add edge to mst and merge trees if 2 nodes belong to different trees
			var tree0 = roomToTree[edge[0]]
			for room in roomToTree:
				if roomToTree[room] == tree0:
					#merge trees
					roomToTree[room] = roomToTree[edge[1]]
				var a = 1
			roomToTree[edge[0]] = roomToTree[edge[1]]
			edge[0].add_adj(edge[1])
			edge[1].add_adj(edge[0])
			edgesAdded += 1
		ind += 1

func make_halls():
	min_span_tree()
	for r1 in rooms:
		for r2 in r1.adj:
			var mid = util.midpoint(r1.centroid, r2.centroid)
			var bounds1 = r1.get_traversable_bounds()
			var bounds2 = r2.get_traversable_bounds()
			# midpoint's x or y position must be within traversable region of both rooms
			# for vertical/horizontal hallway to be drawn
			
			var order = [r1, r2]
			if util.within(mid[0], bounds1[0]) and util.within(mid[0], bounds2[0]):
				#vertical hallway can be drawn
				r1.low_to_high(order)

				#p1 = top of lower room (larger y), p2 = bottom of upper room (smaller y)
				var p1 = [floor(mid[0]), order[0].rect.pos[1]]
				var p2 = [floor(mid[0]), order[1].rect.pos[1] + order[1].rect.size[1] - 1]
				draw_v_hall(p1, p2)
				
			elif util.within(mid[1], bounds1[1]) and util.within(mid[1], bounds2[1]):
				#horizontal hallway can be drawn
				r1.left_to_right(order)
				
				#p1 = right side of left room, p2 = left side of right room
				var p1 = [order[0].rect.pos[0] + order[0].rect.size[0] - 1, floor(mid[1])]
				var p2 = [order[1].rect.pos[0], floor(mid[1])]
				draw_h_hall(p1, p2)
			else:
				#L-shape pathway needed
				r1.left_to_right(order)
				
				# p1 = right side of left room, p2 = L intersection
				# p3 = top/bottom of right room
				var p1 = ([order[0].rect.pos[0] + order[0].rect.size[0] - 1,\
							round(order[0].centroid[1])])
				var p2 = [round(order[1].centroid[0]), round(order[0].centroid[1])]
				var p3 = [round(order[1].centroid[0]),\
							order[1].rect.pos[1]]
				draw_l_hall(p1, p2, p3, order)

#draws vertical hall from p1 to p2, excluding walls
func draw_v_hall(var p1, var p2):
	if p2[1] > p1[1]:
		var temp = p1
		p1 = p2
		p2 = temp
	for i in range(p2[1], p1[1] + 1):
		set_cell(p1[0], i, bg)
#draws horizontal hall from p1 to p2, excluding walls
func draw_h_hall(var p1, var p2):
	if p1[0] > p2[0]:
		var temp = p1
		p1 = p2
		p2 = temp
	for i in range(p1[0], p2[0] + 1):
		set_cell(i, p1[1], bg)
		
# order is left-to-right order of room1 and room2
# p1 = right side of left room, p2 = L intersection
# p3 = top/bottom of right room
func draw_l_hall(var p1, var p2, var p3, var order):
	if order[1].rect.pos[1] < order[0].rect.pos[1]:
		# if right room above left room, p3 is on bottom of room L = _|
		p3[1] += order[1].rect.size[1] - 1	
		draw_h_hall(p1, [p2[0] - 1, p2[1]])
		draw_v_hall([p2[0], p2[1] - 1], p3)
		set_cell(p2[0], p2[1], bg)
	else:
		# right room below left room L = -|
		draw_h_hall(p1, [p2[0] - 1, p2[1]])
		draw_v_hall([p2[0], p2[1] + 1], p3)
		set_cell(p2[0], p2[1], bg)
#adds in missing walls (draw_v/h_hall only draws passage, not enclosing walls)
func clean_up_floor():
	for i in range(0, maxCells[0]):
		for j in range(0, maxCells[1]):
			var tile = get_cell(i, j)
			if tile == bg:
				clean_up_tile(i , j)
				freeSpaces[Vector2(i, j)] = null

#adds in missing walls in 3x3 square centered on specified bg tile position
func clean_up_tile(var x, var y):
	for i in range(max(x - 1, 0), min(x + 2, maxCells[0])):
		for j in range(max(y - 1, 0), min(y + 2, maxCells[1])):
			var tile = get_cell(i, j)
			if tile == -1:
				set_cell(i, j, wall)
				freeSpaces.erase(Vector2(i, j))

# returns dictionary mapping tile type to number of occurences
# in a 3 block square centered on (x, y) (including the center block)
func adj_composition(var x, var y):
	var dict = {}
	for tileID in tiles.get_tiles_ids():
		dict[tileID] = 0
	
	#-1 returned for cells with no tiles
	dict[-1] = 0
	for i in range(max(x - 1, 0), min(x + 2, maxCells[0])):
		for j in range(max(y - 1, 0), min(y + 2, maxCells[1])):
			var tile = get_cell(i, j)
			dict[tile] += 1
	return dict

#returns first traversable tile position
func get_valid_tile_pos():
	for space in freeSpaces:
		if space != get_player_tile():
			return space
	return null
	
#returns first traversable world position
func get_valid_pos():
	var pos = get_valid_tile_pos()
	if pos == null:
		return null
	pos = map_to_world(pos)
	return Vector2(pos[0] + float(tileSize[0]) / 2, pos[1] + float(tileSize[1]) / 2)
	
# adds item i
func add_item(var name, var pos):
	var temp = add_item_without_erasing_from_free(name, pos)
	if temp == true:
		freeSpaces.erase(world_to_map(pos))
		return true
	return false

func add_item_without_erasing_from_free(var name, var pos):
	var item = items.instance()
	if pos != null:
		add_child(item)
		item.init(name, pos, itemScale)
		#TODO: see if updating navigation polygon after placing bg tiles will update already-placed tiles
		#var bgNav = tiles.tile_get_navigation_polygon(bg)
		#TODO: how to address problem (all tiles affected by poly update, not just tiels with items)
		#TODO: idea: make navigation polygon a child of tilemap instead, and add to it for every tile added
		"""
		for tileID in tiles.get_tiles_ids():
			var nav = tiles.tile_get_navigation_polygon(tileID)
			if nav != null:
				#nav.add_outline(item.get_collision_points())
				nav.make_polygons_from_outlines()
		"""
		itemLocations[world_to_map(pos)] = item
		item.add_to_group("items")
		return true
	return false

func add_enemy(var pos):
	var enemy = enemies.instance()
	var rand = randf()
	if rand < healerRate:
		enemy.type = "healer"
	
	print("enemy location is ", world_to_map(pos))
	print("max cells are ", maxCells)
	if pos != null:
		add_child(enemy)
		enemy.init(pos, self.level)
		#enemyLocations[world_to_map(pos)] = enemy
		enemy.add_to_group("enemies")
		enemyArray.append(enemy)
		freeSpaces.erase(world_to_map(pos))
		
func place_companions():
	for companion in ball.companions:
		if weakref(companion).get_ref():
			place_companion(companion)


func place_companion(var companion):
	var pos = get_valid_pos()
	companion.set_global_pos(pos)

	ball.reset_companion(companion)
		
	freeSpaces.erase(world_to_map(pos))

#returns valid map location Vector2(x, y)
func get_random_valid_pos():
	if freeSpaces.size() > 0:
		var posIndex = randi() % freeSpaces.size()
		return freeSpaces.keys()[posIndex]
	else:
		return null
	
#returns valid world location (at center of tile)
func get_random_valid_map_pos():
	var pos = get_random_valid_pos()
	if pos != null:
		pos = map_to_world(pos)
		return Vector2(pos[0] + float(tileSize[0]) / 2, pos[1] + float(tileSize[1]) / 2)
	else:
		return null

#TODO: make random item go in random free space
func add_random_item():
	
	add_item(itemInstance.get_random_item_string(), get_random_valid_map_pos())
	return false
#TODO: change to player (currently is referencing ball)
func get_player_tile():
	return world_to_map(ball.get_pos())
	
func is_pos_free(var world_pos):
	var map_pos = world_to_map(map_pos)
	return map_pos in freeSpaces and map_pos != get_player_tile()
	
func place_exit():
	if exit == null:
		exit = get_random_valid_pos()
		freeSpaces.erase(exit)
		set_cellv(exit, stairs)

#NOTE: DOES NOT RESET SCREEN-SIZE MULTIPLIER
#resets all level variables, clears screen
func reset_level():
	if itemLocations != null and not itemLocations.empty():
		for pos in itemLocations:
			remove_child(itemLocations[pos])
			itemLocations[pos].queue_free()
	if level > 1:
		get_tree().call_group(0, "enemies", "queue_free")
	enemyArray = []
	itemLocations = {}
	freeSpaces = {}
	clear()
	exit = null
	rooms = Array([])
	maxCells = (screenSize / tileSize).floor()
	set_cell_size(Vector2(tileSize[0], tileSize[1]))
	for poly in get_tree().get_nodes_in_group("navPolys"):
		poly.queue_free()
	
	
	
	
#NOTE: guarantees number of items = itemRate * number of free spaces
func populate_items():
	for i in range(freeSpaces.size() * itemRate):
		add_random_item()

func populate_enemies():
	for i in range(freeSpaces.size() * enemyRate):
		add_enemy(get_random_valid_map_pos())

func next_level():
	level += 1
	reset_level()
	screenSizeMultiplier += 0.1
	screenSize *= screenSizeMultiplier
	make_random_floor()
	var ballPos = get_valid_pos()
	ball.set_pos(ballPos)
	freeSpaces.erase(map_to_world(ballPos))
	place_companions()
	populate_enemies()
	populate_items()

	make_nav()

func make_nav():
	#TODO: could probably save time by using freeSpaces (though does not include item locations)
	#TODO: move everything under if tile in traversables if statement
	#TODO: fix navigation (probably problem due to overlapping polys?) try using Rect2 to find intersections
	for i in range(0, maxCells[0]):
		for j in range(0, maxCells[1]):
			var pos = map_to_world(Vector2(i, j))
			var adj = adj_composition(i, j)
			
			var rad = ball.get_radius()
			var tile = get_cell(i, j)
			var left = get_cell(i - 1, j)
			var right = get_cell(i + 1, j)
			var up = get_cell(i, j - 1)
			var down = get_cell(i, j + 1)
			var topLeft = get_cell(i - 1, j - 1)
			var topRight = get_cell(i + 1, j - 1)
			var bottomLeft = get_cell(i - 1, j + 1)
			var bottomRight = get_cell(i + 1, j + 1)
				
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
	
	get_node("Navigation2D").add_child(navInst)
	#TODO: clean up polys at level reset
	navInst.add_to_group("navPolys")
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
	#print ball's tile location
	if Input.is_action_pressed("ui_accept"):
		print(world_to_map(ball.get_pos()))