
extends "navigatorAgent.gd"

# member variables here, example:
# var a=2
# var b="textvar"

var shootTimePassed = 0
var shootRate = 1
var bulletScene


func _fixed_process(delta):
	shootTimePassed += delta

func set_bullet_type(var bulletScene):
	self.bulletScene = bulletScene

func shoot():
	if shootTimePassed > shootRate:
		var bullet = bulletScene.instance()
		bullet.init(get_global_pos() + get_radius() * 2 * facingDir, facingDir, speed, self)
		bullet.set_radius(get_radius()[0] * 0.6)
		bullet.add_to_group("bullets")
		get_node("../").add_child(bullet)
		bullet.team = team
		shootTimePassed = 0
		return bullet
	return null

func shoot_at_pos(var pos):
	face_pos(pos)
	shoot()