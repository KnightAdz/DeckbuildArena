extends "res://Enemies/BasicEnemy.gd"


var ProjectileScene = preload("res://Effects/Fireball.tscn")
var created_projectile = false
var projectile = null

func _ready():
	MOVE_LIMIT = 100


func take_turn():
	pos_at_start_of_turn = global_position
	if state == STUNNED:
		state = IDLE
	else:
		# Take turn
		if player != null:
			# Don't chase, just fire projectiles until killed
			if projectile:
				launch_projectile()
				state = ATTACKING
			else:
				create_projectile()
		else:
			state = WANDER
			#state = pick_random_state([IDLE,WANDER])
		update_wander()
	
	if projectile:
		if projectile.velocity != Vector2.ZERO:
			# Wait for projectile to finish
			return
	
	emit_signal("turn_taken")


func launch_projectile():
	projectile.velocity = global_position.direction_to(player.global_position)
	projectile.velocity = projectile.velocity.normalized()


func create_projectile():
	var new_projectile = ProjectileScene.instance()
	self.add_child(new_projectile)
	var dist = 40
	var pos = global_position.direction_to(player.global_position)
	pos = pos.normalized()*dist
	new_projectile.global_position = global_position + pos
	new_projectile.velocity = Vector2.ZERO
	self.projectile = new_projectile


func on_fireball_destroyed():
	state = IDLE
	emit_signal("turn_taken")
