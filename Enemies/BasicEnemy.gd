extends KinematicBody2D

const EnemyDeathEffect = preload("res://Effects/EnemyDeathEffect.tscn")
const ExclamationEffect = preload("res://Effects/ExclaimationEffect.tscn")

export var ACCELERATION = 300
export var MAX_SPEED = 5
export var FRICTION = 200
export var WANDER_TARGET_RANGE = 4

enum {
	IDLE,
	WANDER,
	CHASE,
	ATTACKING
}

var velocity = Vector2.ZERO
var knockback_vector = Vector2.ZERO

var state = IDLE

var player = null

onready var stats = $Stats
onready var hurtbox = $Hurtbox
#onready var softCollision = $SoftOverlap
onready var wanderController = $WanderController
onready var sprite = $Sprite

signal turn_taken()
signal no_health(position)

func _ready():
	state = WANDER
	$AnimationPlayer.play("fly")
	$Hitbox.deactivate()
	self.connect("no_health", self.get_parent(), "on_enemy_death")
	$HealthRemaining.text = str(stats.health)


func take_turn():
	if player != null:
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
			
		WANDER:
			$Label.text = "WANDER"
			accelerate_towards_point(wanderController.target_position, delta)
			if global_position.distance_to(wanderController.target_position) <= WANDER_TARGET_RANGE:
				state = pick_random_state([IDLE,WANDER])
			
		CHASE:
			$Label.text = "CHASE"
			if player != null:
				accelerate_towards_point(player.global_position, delta)
			else:
				state = IDLE
		ATTACKING:
			attack()
			state = IDLE
	
#	if softCollision.is_colliding():
#		velocity += softCollision.get_push_vector() * delta * 400
	
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
	$HealthRemaining.text = str(stats.health)
	#knockback_vector = area.knockback_vector*100*area.knockback_strength
	knockback_vector = area.damage_source.direction_to(self.global_position)
	knockback_vector = knockback_vector.normalized()
	knockback_vector *= 100*area.knockback_strength
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
		var effect = ExclamationEffect.instance()
		self.add_child(effect)
		effect.position = Vector2(0,-30)


func _on_PlayerDetectionZone_body_exited(body):
	if body.is_in_group("player"):
		player = null
		state = IDLE


func attack():
	if player != null:
		player.be_attacked(1)
		#$Hitbox.activate()


func set_damage(value):
	$Hitbox.damage = value
