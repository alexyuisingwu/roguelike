extends Node

const playerTeam = 0

const enemyBulletScene = preload("../enemyBullet.scn")

const companionBulletScene = preload("../companionBullet.scn")
const followPlayer = preload("followPlayer.gd")
const protectPlayer = preload("protectPlayer.gd")

const healScene = preload("../heal.scn")

var player
var ball
var nav
var dungeon

const inf = 3.402823e+38
const negativeInf = -2.802597e-45

const healTeamScene = preload("healTeam.gd")

# playerModel is vector of [Killer, Explorer, Achiever], each ranging from 1 to 3 (float)
const playerModel = [3, 3, 3]

const chasePlayer = preload("chasePlayer.gd")
const chaseEnemy = preload("chaseEnemy.gd")
const wander = preload("wander.gd")

const menu = preload("../menu.scn")
const gameOver = preload("../Game Over.scn")
const roomDungeon = preload("../attempting procedural.scn")
const caveDungeon = preload("../generator.xml")
const bricks = preload("bricks.gd")