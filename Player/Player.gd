extends KinematicBody2D


enum STATES {IDLE, AIMING, ATTACKING, MOVING}
var state = STATES.IDLE

onready var attackIndicator = $AttackIndicator
onready var stats = $Stats
onready var hurtbox = $Hurtbox

export var ACCELERATION = 300
export var MAX_SPEED = 5 #50
export var FRICTION = 200

var velocity = Vector2.ZERO
var target_position = null
var TARGET_RANGE = 5

var move_radius = 0 setget set_move_radius
var radius_size = 50

var hit_direction = Vector2.RIGHT
var hit_range = 30

var defence = 0 setget set_defence

signal health_changed(new_value)

# Called when the node enters the scene tree for the first time.
func _ready():
	radius_size = $MoveRadius/CollisionShape2D.shape.radius
	update_attack_indicator()


func start_turn():
	state = STATES.IDLE
	move_radius = 0
	self.defence = 0


func _process(delta):
	update() # Needed for drawing circles
	$Label.text = STATES.keys()[state]
	match state:
		STATES.IDLE:
			#$AttackIndicator/Hitbox.deactivate()
			velocity = velocity.move_toward(Vector2.ZERO, FRICTION*delta)
		STATES.MOVING:
			if target_position != null:
				accelerate_towards_point(target_position, delta)
				if global_position.distance_to(target_position) <= TARGET_RANGE:
					target_position = null
					state = STATES.IDLE
		STATES.AIMING:
			update_attack_indicator()
		STATES.ATTACKING:
			$AttackIndicator/Hitbox.activate()
			state = STATES.IDLE

	#velocity = move_and_slide(velocity)
	var collision = move_and_collide(velocity)
	if state == STATES.MOVING and collision != null:
		state = STATES.IDLE
		velocity = Vector2.ZERO


func _unhandled_input(event):
	match state:
		STATES.AIMING:
			hit_direction = (self.get_local_mouse_position()).normalized()
			if Input.is_action_just_released("click"):
				state = STATES.ATTACKING


func move():
	position.x += 100


func attack(damage=1, ranged=false):
	$AttackIndicator/Hitbox.damage = damage
	if ranged:
		hit_range = 100
	else:
		hit_range = 30
	state = STATES.AIMING
	


func defend(defence=1):
	self.defence += defence
	#$Tween.interpolate_property(self, "scale", Vector2(1.1,1.1), Vector2.ONE, 0.2, Tween.TRANS_BACK, Tween.EASE_OUT_IN)
	#$Tween.start()


func set_defence(value):
	defence = value
	$ShieldIcon.update_value(defence)


func gain_movement(radius):
	self.move_radius += radius


func set_move_radius(value):
	move_radius = value
	if move_radius > 0:
		$MoveRadius/CollisionShape2D.shape.radius = move_radius*radius_size


func _draw():
	if move_radius > 0:
		draw_circle($MoveRadius.position, 
					$MoveRadius/CollisionShape2D.shape.radius, 
					Color(0,0.9,0.5,0.25))


func _on_MoveRadius_input_event(viewport, event, shape_idx):
	if move_radius > 0 and state == STATES.IDLE:
		if Input.is_action_just_released("click"):
			# get coords
			target_position = self.position + self.get_local_mouse_position()
			#target_position = event.global_position
			move_radius = 0
			state = STATES.MOVING


func accelerate_towards_point(point, delta):
	var direction = global_position.direction_to(point).normalized()
	velocity = velocity.move_toward(direction*MAX_SPEED, ACCELERATION*delta)


func update_attack_indicator():
	attackIndicator.position = hit_direction*hit_range


func be_attacked(damage):
	if defence > 0:
		self.defence -= damage
		if defence < 0:
			stats.health += defence
	else:
		stats.health -= damage
	hurtbox.create_effect()


func _on_Stats_health_changed(value):
	emit_signal("health_changed", value)


func _on_Hurtbox_area_entered(area):
	stats.health -= area.damage
	#knockback_vector = area.knockback_vector*100
	hurtbox.start_invincibility(0.4)
	hurtbox.create_effect()
