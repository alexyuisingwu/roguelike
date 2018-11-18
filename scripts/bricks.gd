
extends "dungeon..gd"

# member variables here, example:
# var a=2
# var b="textvar"

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	tiles = preload("../tilesets/mytiles.res")
	set_tileset(tiles)
	_update_dirty_quadrants()
	wall = tiles.find_tile_by_name("Wall")
	bg = tiles.find_tile_by_name("BG")
	stairs = tiles.find_tile_by_name("Stairs Down")
	visitedTile = tiles.find_tile_by_name("Visited Tile")
	screenSize = get_viewport_rect().size * 2
	screenSizeMultiplier = 1.0
	tileSize = (tiles.tile_get_region(wall).size)
	itemScale = 0.1
	itemRate = 0.25
	enemyRate = 0.05
	roomWidthRange = [5, 6]
	roomHeightRange = [5, 6]
	traversables = {
		bg : null,
		stairs : null,
		visitedTile : null
	}
	reset_level()
	process_player_model(global.playerModel)	
	make_random_floor()
	ball.init(get_valid_pos(), 500, 1)
	make_nav()
	populate_enemies()
	
	populate_items()
	set_fixed_process(true)


