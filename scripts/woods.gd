
extends "dungeon..gd"
var topLeftCorner
var topRightCorner
var bottomLeftCorner
var bottomRightCorner
var topWall1
var bottomWall
var leftWall1
var rightWall1
var ledgeTopRight
var ledgeBottomRight
var ledgeTopLeft
var ledgeBottomLeft

var flower1
var flower2
var grass
var grassland
#TODO: find way to make _ready() overriden (so parent's _ready() not called before _ready()
#TODO: if not possible, make abstract class that dungeon also inherits from
func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	

	tiles = preload("../tilesets/tinyWoods.res")
	set_tileset(tiles)
	_update_dirty_quadrants()
	wall = tiles.find_tile_by_name("Top Wall 1")
	topWall1 = tiles.find_tile_by_name("Top Wall 1")
	bg = tiles.find_tile_by_name("BG")
	stairs = tiles.find_tile_by_name("Stairs Down")
	visitedTile = tiles.find_tile_by_name("Visited Tile")
	topLeftCorner = tiles.find_tile_by_name("Top Left Corner")
	topRightCorner = tiles.find_tile_by_name("Top Right Corner")
	bottomLeftCorner = tiles.find_tile_by_name("Bottom Left Corner")
	bottomRightCorner = tiles.find_tile_by_name("Bottom Right Corner")
	bottomWall = tiles.find_tile_by_name("Bottom Wall")
	leftWall1 = tiles.find_tile_by_name("Left Wall 1")
	rightWall1 = tiles.find_tile_by_name("Right Wall 1")
	ledgeTopRight = tiles.find_tile_by_name("Ledge Top Right")
	ledgeBottomRight = tiles.find_tile_by_name("Ledge Bottom Right")
	ledgeTopLeft = tiles.find_tile_by_name("Ledge Top Left")
	ledgeBottomLeft = tiles.find_tile_by_name("Ledge Bottom Left")
	flower1 = tiles.find_tile_by_name("Flower 1")
	flower2 = tiles.find_tile_by_name("Flower 2")
	grass = tiles.find_tile_by_name("Grass")
	grassland = {
		flower1 : null,
		flower2 : null,
		grass : null
	}
	traversables = {
		bg : null,
		stairs : null,
		visitedTile : null
	}
	screenSize = get_viewport_rect().size
	screenSizeMultiplier = 1.0
	tileSize = Vector2(24, 24)
	itemScale = 0.1
	itemRate = 0.05
	enemyRate = 0.05
	roomWidthRange = [5, 6]
	roomHeightRange = [5, 6]
	
	reset_level()
	
	process_player_model(global.playerModel)
	
	make_random_floor()
	
	ball.init(get_valid_pos(), 300, 0.5)

	make_nav()
	populate_enemies()
	populate_items()
	set_fixed_process(true)
	
func make_random_floor():
	for i in range(50):
		#make_random_room(3, maxCells[0], 3, maxCells[1])
		make_random_room(roomWidthRange[0], roomWidthRange[1], roomHeightRange[0], roomHeightRange[1])
	make_halls()
	#fix any remaining errors in floorplan
	clean_up_floor()
	clean_up_floor()
	place_exit()
	
#makes rectangular room width (x,y) position and width and height specified by cell units
#NOTE: size is size of room INCLUDING wall tiles (actual traversable area smaller)
#WARNING: MINIMUM DIMENSION OF ROOM IS 4X4, LOWER DIMENSIONS CAN LEAD TO ERRORS
func make_room(var x, var y, var width, var height):
	for i in range(x + 1, x + width - 1):
		#top and bottom walls
		set_cell(i, y, topWall1)
		set_cell(i, y + height - 1, bottomWall)

	for j in range(y + 1, y + height - 1):
		#left and right walls
		set_cell(x, j, leftWall1)
		set_cell(x + width - 1, j, rightWall1)
		
	for i in range(x + 1, x + width - 1):
		#background tiles
		for j in range(y + 1, y + height - 1):
			set_cell(i, j, bg)

	set_cell(x, y, topLeftCorner)
	set_cell(x + width - 1, y, topRightCorner)
	set_cell(x, y + height - 1, bottomLeftCorner)
	set_cell(x + width - 1, y + height - 1, bottomRightCorner)
	var newRoom = roomScene.instance()
	newRoom.init(Rect2(x, y, width, height))
	rooms.append(newRoom)

#adds in missing walls (draw_v/h_hall only draws passage, not enclosing walls)
func clean_up_floor():
	for i in range(0, maxCells[0]):
		for j in range(0, maxCells[1]):
			
			if (get_cell(i, j - 1) == bg and get_cell(i, j + 1) == bg)\
					or (get_cell(i - 1, j) == bg and get_cell(i + 1, j) == bg):
					set_cell(i, j, bg)
					freeSpaces[Vector2(i, j)] = null
			var tile = get_cell(i, j)
			if tile == bg:
				if get_cell(i, j - 1) == -1 or get_cell(i, j - 1) in grassland:
					set_cell(i, j, topWall1)
				else:
					freeSpaces[Vector2(i, j)] = null
			elif tile == -1:
				if not get_cell(i, j - 1) in grassland and get_cell(i, j - 1) != -1\
					and not get_cell(i + 1, j) in grassland and get_cell(i + 1, j) != -1:
						set_cell(i, j, bottomLeftCorner)
						freeSpaces.erase(Vector2(i, j))
				add_grassland(i, j)
			else:
				clean_up_tile(i, j)
	for i in range(0, maxCells[0]):
		for j in range(0, maxCells[1]):
			
			if (get_cell(i, j - 1) == bg and get_cell(i, j + 1) == bg)\
					or (get_cell(i - 1, j) == bg and get_cell(i + 1, j) == bg):
					set_cell(i, j, bg)
					freeSpaces[Vector2(i, j)] = null
			var tile = get_cell(i, j)
			if tile == bg:
				if get_cell(i, j - 1) == -1 or get_cell(i, j - 1) in grassland:
					set_cell(i, j, topWall1)
				else:
					freeSpaces[Vector2(i, j)] = null
			elif tile == -1:
				if not get_cell(i, j - 1) in grassland and get_cell(i, j - 1) != -1\
					and not get_cell(i + 1, j) in grassland and get_cell(i + 1, j) != -1:
						set_cell(i, j, bottomLeftCorner)
						freeSpaces.erase(Vector2(i, j))
				add_grassland(i, j)
			else:
				clean_up_tile(i, j)
				
#TODO: clean up function logic (if statements can be simplified)
func clean_up_tile(var i, var j):
	
			var tile = get_cell(i, j)
			
			if get_cell(i, j - 1) == -1 and get_cell(i, j + 1) == bg:
				set_cell(i, j, topWall1)
				freeSpaces.erase(Vector2(i, j))
			elif get_cell(i, j - 1) == topRightCorner and get_cell(i + 1, j) == topRightCorner:
				set_cell(i, j, bottomLeftCorner) 
				freeSpaces.erase(Vector2(i, j))
			elif get_cell(i, j - 1) == ledgeTopRight and get_cell(i, j + 1) == bg:
				set_cell(i, j, ledgeBottomRight)
				freeSpaces.erase(Vector2(i, j))
			elif get_cell(i, j - 1) == ledgeTopLeft and get_cell(i, j + 1) == bg:
				set_cell(i, j, ledgeBottomLeft)
				freeSpaces.erase(Vector2(i, j))
			elif get_cell(i, j - 1) == topRightCorner and get_cell(i + 1, j) == topWall1:
				set_cell(i, j, ledgeBottomLeft)
				freeSpaces.erase(Vector2(i, j))
			elif get_cell(i, j + 1) == bottomRightCorner and get_cell(i, j - 1) == bottomWall:
				set_cell(i, j, ledgeTopLeft)
				freeSpaces.erase(Vector2(i, j))
			elif get_cell(i, j - 1) == rightWall1 and get_cell(i + 1, j) == topWall1:
				set_cell(i, j, ledgeBottomLeft)
				freeSpaces.erase(Vector2(i, j))
			elif get_cell(i - 1, j) == ledgeBottomLeft and get_cell(i, j - 1) == leftWall1:
				set_cell(i, j, ledgeBottomRight)
				freeSpaces.erase(Vector2(i, j))
			elif get_cell(i, j - 1) == rightWall1 and get_cell(i + 1, j) == topRightCorner:
				set_cell(i, j, ledgeBottomLeft)
				freeSpaces.erase(Vector2(i, j))
			elif get_cell(i, j + 1) == bottomRightCorner and get_cell(i + 1, j) == bottomWall:
				set_cell(i, j, ledgeTopLeft)
				freeSpaces.erase(Vector2(i, j))
			elif get_cell(i, j - 1) == topRightCorner and get_cell(i + 1, j) == topRightCorner:
				set_cell(i, j, ledgeBottomLeft)
				freeSpaces.erase(Vector2(i, j))
			elif get_cell(i, j + 1) == rightWall1 and get_cell(i + 1, j) == bottomWall:
				set_cell(i, j, ledgeTopLeft)
				freeSpaces.erase(Vector2(i, j))
			elif get_cell(i - 1, j) == topWall1 and get_cell(i + 1, j) == ledgeBottomRight:
				set_cell(i, j, topWall1)
				freeSpaces.erase(Vector2(i, j))
			elif get_cell(i - 1, j) == topWall1 and get_cell(i, j - 1) == leftWall1:
				set_cell(i, j, ledgeBottomRight)
				freeSpaces.erase(Vector2(i, j))
			elif get_cell(i - 1, j) == bottomWall and get_cell(i, j + 1) == bottomLeftCorner:
				set_cell(i, j, ledgeTopRight)
				freeSpaces.erase(Vector2(i, j))
			elif get_cell(i - 1, j) == bottomWall and get_cell(i, j + 1) == ledgeBottomRight:
				set_cell(i, j, ledgeTopRight)
				freeSpaces.erase(Vector2(i, j))
			elif get_cell(i - 1, j) == bottomWall and get_cell(i, j + 1) == leftWall1:
				set_cell(i, j, ledgeTopRight)
				freeSpaces.erase(Vector2(i, j))
			elif get_cell(i + 1, j) == bottomWall and get_cell(i, j + 1) == bottomLeftCorner:
				set_cell(i, j, ledgeTopLeft)
				freeSpaces.erase(Vector2(i, j))
			elif get_cell(i + 1, j) == ledgeTopRight and get_cell(i, j + 1) == rightWall1:
				set_cell(i, j, ledgeTopLeft)
				freeSpaces.erase(Vector2(i, j))
			elif get_cell(i - 1, j) == ledgeTopLeft and get_cell(i, j + 1) == leftWall1:
				set_cell(i, j, ledgeTopRight)
				freeSpaces.erase(Vector2(i, j))
			elif get_cell(i - 1, j) == topWall1 and get_cell(i, j - 1) == topLeftCorner:
				set_cell(i, j, ledgeBottomRight)
				freeSpaces.erase(Vector2(i, j))
			elif get_cell(i - 1, j) == topLeftCorner and get_cell(i, j - 1) == leftWall1:
				set_cell(i, j, ledgeBottomRight)
				freeSpaces.erase(Vector2(i, j))
			elif get_cell(i + 1, j) == topRightCorner:
				set_cell(i, j, topWall1)
				freeSpaces.erase(Vector2(i, j))
			elif get_cell(i - 1, j) == topWall1 and get_cell(i, j - 1) == ledgeTopRight:
				set_cell(i, j, ledgeBottomRight)
				freeSpaces.erase(Vector2(i, j))
			elif get_cell(i + 1, j) == bottomRightCorner and get_cell(i, j + 1) == rightWall1:
				set_cell(i, j, ledgeTopLeft)
				freeSpaces.erase(Vector2(i, j))
			elif get_cell(i - 1, j) == topWall1 and get_cell(i + 1, j) == topWall1:
				set_cell(i, j, topWall1)
				freeSpaces.erase(Vector2(i, j))
			elif get_cell(i, j - 1) == rightWall1 and get_cell(i, j + 1) == rightWall1:
				set_cell(i, j, rightWall1)
				freeSpaces.erase(Vector2(i, j))
			elif get_cell(i + 1, j) == ledgeBottomLeft and (get_cell(i, j + 1) == -1 or get_cell(i, j + 1) in grassland):
				set_cell(i, j, ledgeTopRight)
			elif get_cell(i, j - 1) == ledgeBottomLeft and (get_cell(i - 1, j) == -1 or get_cell(i - 1, j) in grassland):
				set_cell(i, j, ledgeTopRight)
			elif get_cell(i, j + 1) == ledgeBottomLeft and get_cell(i + 1, j) == ledgeTopRight:
				set_cell(i, j, ledgeTopLeft)
			elif get_cell(i - 1, j) == ledgeBottomLeft and get_cell(i, j - 1) == ledgeTopRight:
				set_cell(i, j, ledgeBottomRight)
			elif get_cell(i, j - 1) == ledgeTopLeft and get_cell(i, j + 1) == rightWall1:
				set_cell(i, j, rightWall1)
			elif get_cell(i, j - 1) == rightWall1 and get_cell(i , j + 1) == ledgeBottomLeft:
				set_cell(i, j, rightWall1)
			elif get_cell(i - 1, j) == bottomWall and get_cell(i + 1, j) == ledgeTopRight:
				set_cell(i, j, bottomWall)
			elif get_cell(i, j - 1) == rightWall1 and get_cell(i + 1, j) == ledgeBottomRight:
				set_cell(i, j ,ledgeBottomLeft)
			elif get_cell(i, j - 1) == topRightCorner and get_cell(i + 1, j) == topRightCorner:
				set_cell(i, j, ledgeBottomLeft)
			elif get_cell(i, j + 1) == bottomRightCorner and get_cell(i + 1, j) == bottomRightCorner:
				set_cell(i, j, ledgeTopLeft)
			elif get_cell(i - 1, j) == bottomWall and get_cell(i + 1, j) == bottomWall:
				set_cell(i, j, bottomWall)

func draw_v_hall(var p1, var p2):
	if p1 == p2:
		return
	
	#p2 must be above (lower in y value) than p1
	if p2[1] > p1[1]:
		var temp = p1
		p1 = p2
		p2 = temp
	
	#if 
	for i in range(p2[1], p1[1] + 1):
		set_cell(p1[0], i, bg)
		
	for i in range(p2[1] + 1, p1[1]):
		if get_cell(p1[0] - 1, i) == topWall1:
			merge_tile(p1[0] - 1, i, bottomRightCorner)
		else:
			merge_tile(p1[0] - 1, i, leftWall1)
		merge_tile(p1[0] + 1, i, rightWall1)
	
	if get_cell(p2[0] - 1, p2[1] - 1) == leftWall1:
		merge_tile(p2[0] - 1, p2[1], leftWall1)
	else:
		merge_tile(p2[0] - 1, p2[1], ledgeTopRight)	
	if get_cell(p2[0] + 1, p2[1] - 1) == rightWall1:
		merge_tile(p2[0] + 1, p2[1], rightWall1)
	else:
		merge_tile(p2[0] + 1, p2[1], ledgeTopLeft)
	if get_cell(p1[0], p1[1]) == topWall1:
		merge_tile(p1[0] - 1, p1[1], topWall1)
	elif get_cell(p1[0] - 1, p1[1] + 1) == leftWall1:
		merge_tile(p1[0] - 1, p1[1], leftWall1)
	else:
		merge_tile(p1[0] - 1, p1[1], ledgeBottomRight)
	if get_cell(p1[0] + 1, p1[1] + 1) == rightWall1:
		merge_tile(p1[0] + 1, p1[1], rightWall1)
	else:
		merge_tile(p1[0] + 1, p1[1], ledgeBottomLeft)
#draws horizontal hall from p1 to p2, excluding walls
func draw_h_hall(var p1, var p2):
	if p1[0] > p2[0]:
		var temp = p1
		p1 = p2
		p2 = temp
	for i in range(p1[0], p2[0] + 1):
		set_cell(i, p1[1], bg)
		
	for i in range(p1[0] + 1, p2[0]):
		merge_tile(i, p1[1] - 1, topWall1)
		var cellBelow = get_cell(i, p1[1] + 1)
		if cellBelow == leftWall1 or cellBelow == rightWall1:
			merge_tile(i, p1[1] + 1, ledgeTopRight)
		else:
			merge_tile(i, p1[1] + 1, bottomWall)
	if get_cell(p1[0] - 1, p1[1] - 1) == topWall1:
		merge_tile(p1[0], p1[1] - 1, topWall1)
	elif get_cell(p1[0] - 1, p1[1] - 1) == ledgeBottomLeft and (get_cell(p1[0] + 1, p1[1] - 1) == ledgeBottomRight or get_cell(p1[0] + 1, p1[1] - 1) == topWall1):
		merge_tile(p1[0], p1[1] - 1, topWall1)
	else:
		merge_tile(p1[0], p1[1] - 1, ledgeBottomLeft)
	if get_cell(p2[0] + 1, p2[1] - 1) == topWall1:
		merge_tile(p2[0], p2[1] - 1, topWall1)
	else:
		merge_tile(p2[0], p2[1] - 1, ledgeBottomRight)
	if get_cell(p1[0], p1[1] + 1) == -1 or get_cell(p1[0] - 1, p1[1] + 1) == bottomWall:
		merge_tile(p1[0], p1[1] + 1, bottomWall)
	else:
		merge_tile(p1[0], p1[1] + 1, ledgeTopLeft)
	if get_cell(p2[0] + 1, p2[1] + 1) == bottomWall:
		merge_tile(p2[0], p2[1] + 1, bottomWall)
	else: 
		merge_tile(p2[0], p2[1] + 1, ledgeTopRight)

# order is left-to-right order of room1 and room2
# p1 = right side of left room, p2 = L intersection
# p3 = top/bottom of right room
func draw_l_hall(var p1, var p2, var p3, var order):
	if order[1].rect.pos[1] < order[0].rect.pos[1]:
		# if right room above left room, p3 is on bottom of room L = _|
		p3[1] += order[1].rect.size[1] - 1	
		draw_h_hall(p1, [p2[0] - 1, p2[1]])
		merge_tile(p2[0] - 1, p2[1] + 1, bottomWall)
		merge_tile(p2[0], p2[1] + 1, bottomWall)
		merge_tile(p2[0] + 1, p2[1] + 1, bottomRightCorner)
		draw_v_hall([p2[0], p2[1] - 1], p3)
		merge_tile(p2[0] + 1, p2[1] - 1, rightWall1)
		merge_tile(p2[0] + 1, p2[1], rightWall1)
		set_cell(p2[0], p2[1], bg)
	else:
		# right room below left room L = -|
		draw_h_hall(p1, [p2[0] - 1, p2[1]])
		draw_v_hall([p2[0], p2[1] + 1], p3)
		merge_tile(p2[0] - 1, p2[1] - 1, topWall1)
		merge_tile(p2[0], p2[1] - 1, topWall1)
		merge_tile(p2[0] + 1, p2[1] - 1, topRightCorner)
		merge_tile(p2[0] + 1, p2[1], rightWall1)
		merge_tile(p2[0] + 1, p2[1] + 1, rightWall1)
		set_cell(p2[0], p2[1], bg)
		
func add_grassland(var x, var y):
	var rand = randf()
	if rand < 0.02:
		set_cell(x, y, tiles.find_tile_by_name("Flower 1"))
	elif rand < 0.98:
		set_cell(x, y, tiles.find_tile_by_name("Grass"))
	elif rand <= 1:
		set_cell(x, y, tiles.find_tile_by_name("Flower 2"))