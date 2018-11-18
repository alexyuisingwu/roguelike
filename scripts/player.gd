
extends Node

# preload
# TODO: add a real player texture
var texture = preload("../images/bowling_ball.png")

# member variables here
var player_sprite
var pos
var health
var companions = []

func _init():
	health = 100
	

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	pos = get_node("player").get_pos()
	get_node("player").set_texture(texture)
	
	# for the bowling ball image specifically, scale it down (75%) 
	# so that it can fit in paths
	var scale = Vector2(0.75, 0.75)
	get_node("player").set_scale(scale)
	
	set_process(true)
	

func _process(delta):
	# player movement
	pos = get_node("player").get_pos()
	#if 


