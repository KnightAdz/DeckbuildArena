extends KinematicBody2D

const EnemyDeathEffect = preload("res://Effects/EnemyDeathEffect.tscn")
const ExclamationEffect = preload("res://Effects/ExclaimationEffect.tscn")

export var ACCELERATION = 300
export var MAX_SPEED = 5
export var FRICTION = 200
export var WANDER_TARGET_RANGE = 4
export var MOVE_LIMIT = 1000

enum {
	IDLE,
	WANDER,
	CHASE,
	ATTACKING,
	STUNNED,
	WAITING
}

var velocity = Vector2.ZERO
var knockback_vector = Vector2.ZERO
var pos_at_start_of_turn = Vector2.ZERO

var state = IDLE

var player = null
var perceived_player_position = null

onready var stats = $Stats
onready var hurtbox = $Hurtbox
onready var softCollision = $SoftOverlap
onready var wanderController = $WanderController
onready var sprite = $Sprite

signal turn_taken()
signal no_health(position)
signal took_damage(position)

func _ready():
	state = IDLE
	$AnimationPlayer.play("fly")
	$Hitbox.deactivate()
	self.connect("no_health", self.get_parent(), "on_enemy_death")
	self.connect("took_damage", self.get_parent(), "on_enemy_hurt")
	$HealthRemaining.text = str(stats.health)
	$HealthIndicator.health = stats.health


func take_turn():
	pos_at_start_of_turn = global_position
	if state == STUNNED:
		state = IDLE
	else:
		# Take turn
		if player != null:
			if !player.in_stealth:
				perceived_player_position = player.global_position
			else:
				perceived_player_position = player.last_known_position
			state = CHASE
		else:
			state = WANDER
			#state = pick_random_state([IDLE,WANDER])
		update_wander()
	emit_signal("turn_taken")


func _physics_process(delta):
	knockback_vector = knockback_vector.move_toward(Vector2.ZERO, 200*delta)
	knockback_vector = move_and_slide(knockback_vector)

	match state:
		IDLE:
			$Label.text = "IDLE"
			velocity = velocity.move_toward(Vector2.ZERO, FRICTION*delta)
			$AnimationPlayer.play("fly")
			
		WANDER:
			$Label.text = "WANDER"
			accelerate_towards_point(wanderController.target_position, delta)
			if global_position.distance_to(wanderController.target_position) <= WANDER_TARGET_RANGE:
				state = pick_random_state([IDLE,WANDER])
			
		CHASE:
			$Label.text = "CHASE"
			var dist_moved = global_position.distance_to(pos_at_start_of_turn)
			if perceived_player_position != null and dist_moved < MOVE_LIMIT:
				accelerate_towards_point(perceived_player_position, delta)
				if global_position.distance_to(perceived_player_position) < 10:
					state = IDLE
			else:
				state = IDLE
		
		ATTACKING:
			attack()
			state = IDLE
		
		STUNNED:
			$AnimationPlayer.stop()

	if softCollision.is_colliding():
		velocity += softCollision.get_push_vector() * delta * 400
	
	#velocity = move_and_slide(velocity)
	var collision = move_and_collide(velocity)
	if state != IDLE and collision != null:
		if collision != null:
			state = ATTACKING
			velocity = Vector2.ZERO


func update_wander():
	wanderController.update_target_position()


func accelerate_towards_point(point, delta):
	var direction = global_position.direction_to(point).normalized()
	velocity = velocity.move_toward(direction*MAX_SPEED, ACCELERATION*delta)
	sprite.flip_h = velocity.x < 0


func pick_random_state(state_list):
	state_list.shuffle()
	return state_list.pop_front()


func _on_Hurtbox_area_entered(area):
	stats.health -= area.damage
	if area.damage > 0:
		emit_signal("took_damage", self.global_position)
	$HealthRemaining.text = str(stats.health)
	#knockback_vector = area.knockback_vector*100*area.knockback_strength
	knockback_vector = area.damage_source.direction_to(self.global_position)
	knockback_vector = knockback_vector.normalized()
	knockback_vector *= 100*area.knockback_strength
	if area.stun:
		state = STUNNED
	hurtbox.start_invincibility(0.4)
	hurtbox.create_effect()


func _on_Stats_no_health():
	queue_free()
	var enemyDeathEffect = EnemyDeathEffect.instance()
	get_parent().add_child(enemyDeathEffect)
	enemyDeathEffect.global_position = global_position
	emit_signal("no_health", self.global_position)


func _on_Hurtbox_invincibility_started():
	$AnimationPlayer.play("Start")


func _on_Hurtbox_invincibility_ended():
	$AnimationPlayer.play("Stop")


func _on_PlayerDetectionZone_body_entered(body):
	if body.is_in_group("player"):
		player = body
		if !player.in_stealth:
			perceived_player_position = player.global_position
			var effect = ExclamationEffect.instance()
			self.add_child(effect)
			effect.position = Vector2(0,-30)
		else:
			player = null
			#perceived_player_position = player.last_known_position
			perceived_player_position = null


func _on_PlayerDetectionZone_body_exited(body):
	if body.is_in_group("player"):
		lose_player()


func lose_player():
	player = null
	perceived_player_position = null
	state = IDLE


func check_for_player():
	var bodies = $PlayerDetectionZone.get_overlapping_bodies()
	var found_player = false
	for b in bodies:
		if b.is_in_group("player"):
			_on_PlayerDetectionZone_body_entered(b)
			found_player = true
	if found_player == false:
		lose_player()


func attack():
	if player != null:
		if player.global_position.distance_to(global_position) < 30:
			player.be_attacked($Hitbox.damage)
		#$Hitbox.activate()


func set_damage(value):
	$Hitbox.damage = value


func get_save_info():
	var save_dict = {
		"filename" : filename,
		"global_position.x" : global_position.x,
		"global_position.y" : global_position.y,
		"damage" : $Hitbox.damage,
		"health" : stats.health
	}
	return save_dict
