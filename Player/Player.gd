extends KinematicBody2D


const ProjectileScene = preload("res://Effects/Projectile.tscn")
const PlayerCopyScene = preload("res://Player/PlayerCopy.tscn")

enum STATES {IDLE, AIMING, ATTACKING, AREA_ATTACK, MOVING, DEATH}
var state = STATES.IDLE setget set_state

onready var attackIndicator = $AttackIndicator
onready var stats = $Stats
onready var hurtbox = $Hurtbox

export var ACCELERATION = 300
export var MAX_SPEED = 5 #50
export var FRICTION = 200

var velocity = Vector2.ZERO
var target_position = null
var TARGET_RANGE = 5
var prev_mouse_position = Vector2.ZERO

# Movement
var move_radius = 0 setget set_move_radius
var move_preview = 0 setget set_move_preview
var radius_size = 1 # This gets set in the ready function
var accept_movement = true
var last_known_position = Vector2.ZERO
var in_stealth = false setget set_stealth

# Attack
var attack_preview_visible = false
var hit_direction = Vector2.RIGHT
var MELEE_RANGE = 30
var RANGED_RANGE = 500
var AREA_RANGE = 5
var hit_range = 30
var knockback_strength = 1

# Defence
var defence = 0 setget set_defence
var defence_preview = 0 setget set_defence_preview
var defence_at_turn_start = 0

# Buffs
var damage_multipliers = []
var damage_multiplier_durations = [] #in num of attacks

var action_queue = []


signal max_health_changed(new_value)
signal health_changed(new_value)
signal player_died()
signal player_controls_mouse()
signal player_releases_mouse()
signal is_idle()
signal health_reduced()

# Called when the node enters the scene tree for the first time.
func _ready():
	radius_size = $MoveRadius/CollisionShape2D.shape.radius
	self.defence = 2
	update_attack_indicator()
	last_known_position = global_position


func start_turn():
	if state == STATES.DEATH:
		return
	self.state = STATES.IDLE
	self.defence = 0
	move_radius = 0
	defence_at_turn_start = self.defence


func set_state(new_state):
	state = new_state
	match state:
		STATES.IDLE:
			emit_signal("is_idle")


func _process(delta):
	update() # Needed for drawing circles
	#$Label.text = STATES.keys()[state]
	match state:
		STATES.IDLE:
			$AnimationPlayer.play("Idle")
			$AttackIndicator.visible = false
			velocity = velocity.move_toward(Vector2.ZERO, FRICTION*delta)
			if action_queue != []:
				do_next_action_from_queue()
			if !in_stealth:
				last_known_position = global_position
			
		STATES.MOVING:
			if target_position != null:
				$AnimationPlayer.play("Walk")
				accelerate_towards_point(target_position, delta)
				if global_position.distance_to(target_position) <= TARGET_RANGE:
					target_position = null
					self.state = STATES.IDLE
					
		STATES.AIMING:
			emit_signal("player_controls_mouse")
			$AttackIndicator.visible = true
			attack_preview_visible = true
			update_attack_indicator()
			
		STATES.ATTACKING:
			emit_signal("player_releases_mouse")
			$AttackIndicator/Hitbox.set_knockback(self.global_position, knockback_strength)
			self.in_stealth = false
			if hit_range != RANGED_RANGE:
				$AttackIndicator/Hitbox.activate()
			else:
				var proj = ProjectileScene.instance()
				self.get_parent().add_child(proj)
				proj.set_stun($AttackIndicator/Hitbox.stun)
				proj.set_damage($AttackIndicator/Hitbox.damage)
				proj.global_position = self.global_position
				proj.velocity = hit_direction
			attack_preview_visible = false
			self.state = STATES.IDLE
			
		STATES.DEATH:
			pass
	
	#velocity = move_and_slide(velocity)
	var collision = move_and_collide(velocity)
	# If we are moving and crash into something
	if state == STATES.MOVING and collision != null:
		# Stop moving
		self.state = STATES.IDLE
		velocity = Vector2.ZERO


func _unhandled_input(_event):
	match state:
		STATES.AIMING:
			var mouse_pos = self.get_local_mouse_position()
			if mouse_pos != prev_mouse_position:
				hit_direction = mouse_pos.normalized()
				prev_mouse_position = mouse_pos
			else:
				var rotate_speed = 0.5
				if Input.is_action_pressed("ui_right"):
					hit_direction = hit_direction.rotated(rotate_speed)
				elif Input.is_action_pressed("ui_left"):
					hit_direction = hit_direction.rotated(-rotate_speed)
			
			if Input.is_action_just_released("click"):
				self.state = STATES.ATTACKING
			if Input.is_action_just_pressed("ui_accept"):
				self.state = STATES.ATTACKING


func set_attack_attribs(damage=1, ranged=false, area=false, knockback=1, stun=false, attack_duration=0.1):
	$AttackIndicator/Hitbox.active_time = attack_duration
	$AttackIndicator/Hitbox.damage = damage
	$AttackIndicator/Hitbox.stun = stun
	$AttackIndicator/Hitbox/CollisionShape2D.shape.radius = 25
	if ranged:
		hit_range = RANGED_RANGE
	else:
		hit_range = MELEE_RANGE
	
	if area:
		hit_range = AREA_RANGE
		# make radius larger
		$AttackIndicator/Hitbox/CollisionShape2D.shape.radius = 60

	self.knockback_strength = knockback
	$AttackIndicator/Hitbox.set_knockback(self.global_position, knockback_strength)
	update_attack_indicator()
	attack_preview_visible = true


func attack(damage=1, ranged=false, area=false, knockback=1, stun=false, attack_duration=0.1):
	#Apply damage multipliers
	var total_damage = damage
	for m in damage_multipliers:
		if total_damage < 99999:
			total_damage*=m
	set_attack_attribs(total_damage, ranged, area, knockback, stun, attack_duration)
	decrement_damage_multipliers()
	# Move into a state to perform the attack
	if !area:
		self.state = STATES.AIMING
	else:
		self.state = STATES.ATTACKING


func defend(defence_new=1):
	self.defence += defence_new
	#$Tween.interpolate_property(self, "scale", Vector2(1.1,1.1), Vector2.ONE, 0.2, Tween.TRANS_BACK, Tween.EASE_OUT_IN)
	#$Tween.start()


func set_defence(value):
	defence = value
	$ShieldIcon.update_value(defence)
	if defence < 0:
		defence = 0


func gain_movement(radius, stealth=false):
	self.move_radius += radius
	self.in_stealth = stealth
	

func gain_health(value):
	self.stats.health += value


func set_move_radius(value):
	move_radius = value
	if move_radius > 0:
		$MoveRadius/CollisionShape2D.shape.radius = move_radius*radius_size
	else:
		move_radius = 0

#func toggle_movement(value):
#	$MoveRadius.pickable = value


func _draw():
	# draw the move radius
	if move_radius > 0:
		draw_circle($MoveRadius.position, 
					$MoveRadius/CollisionShape2D.shape.radius, 
					Color(0,0.9,0.5,0.25))
	
	# draw the attack range
	if attack_preview_visible:
		if hit_range != RANGED_RANGE:
			draw_circle($AttackIndicator.position, 
						$AttackIndicator/Hitbox/CollisionShape2D.shape.radius, 
						Color(0.9,0.0,0.0,0.25))
		else:
			draw_line(Vector2(0,0), 
						$AttackIndicator.position,
						Color(0.9,0.0,0.0,0.25),
						10,
						false)


func _on_MoveRadius_input_event(viewport, event, shape_idx):
	if accept_movement:
		if move_radius > 0 and state == STATES.IDLE:
			if Input.is_action_just_released("click"):
				# get coords
				target_position = self.position + self.get_local_mouse_position()
				#target_position = event.global_position
				move_radius = 0
				self.state = STATES.MOVING


func accelerate_towards_point(point, delta):
	var direction = global_position.direction_to(point).normalized()
	velocity = velocity.move_toward(direction*MAX_SPEED, ACCELERATION*delta)


func update_attack_indicator():
	attackIndicator.position = hit_direction*hit_range


func be_attacked(damage):
	if defence > 0:
		if damage > defence:
			stats.health -= damage - defence
		self.defence -= damage
	else:
		stats.health -= damage
	hurtbox.create_effect()


func _on_Stats_health_changed(value):
	emit_signal("health_changed", value)
	if value <= 0:
		self.state = STATES.DEATH
		$AnimationPlayer.play("Die")
		# Will emit player died signal at end of animation


func _on_Hurtbox_area_entered(area):
	stats.health -= area.damage
	#knockback_vector = area.knockback_vector*100
	hurtbox.start_invincibility(0.4)
	hurtbox.create_effect()


func _on_Deck_playing_first_card():
	pass
	
	
func set_defence_preview(value):
	defence_preview = value
	self.defence += defence_preview
	

func set_move_preview(value):
	move_preview = value
	self.move_radius += move_preview


func reset_preview():
	self.move_radius -= move_preview
	self.defence -= defence_preview
	self.move_preview = 0
	self.defence_preview = 0
	self.attack_preview_visible = false


func queue_actions(actions):
	for a in actions:
		action_queue.append(a)
	do_next_action_from_queue()


func do_next_action_from_queue():
	if action_queue == []:
		return
	var a = action_queue[0]
	action_queue.remove(0)
	match a.type:
		a.ActionType.SHORT_ATTACK:
			attack(	a.attack, 
					false,#ranged
					false,#area
					a.knockback,
					a.stun_enemy,
					a.attack_duration)
					
		a.ActionType.DEFEND:
			defend(a.defence)
			
		a.ActionType.MOVE:
			gain_movement(a.movement)
		
		a.ActionType.RANGED_ATTACK:
			attack(	a.attack, 
					true,#ranged
					false,#area
					a.knockback,
					a.stun_enemy,
					a.attack_duration)
		
		a.ActionType.AREA_ATTACK:
			attack(	a.attack, 
					false,#ranged
					true,#area
					a.knockback,
					a.stun_enemy,
					a.attack_duration)


func save_state():
	var save_dict = {
		"node" : "player",
		"global_position.x" : global_position.x,
		"global_position.y" : global_position.y,
		"defence" : defence,
		"health" : stats.health,
		"max_health" : stats.max_health,
		"in_stealth" : in_stealth,
		"last_known_position.x" : last_known_position.x,
		"last_known_position.y" : last_known_position.y,
		"damage_multipliers" : save_damage_multipliers(),
		"damage_multiplier_durations" : save_damage_durations()
	}
	return save_dict


func save_damage_multipliers():
	# Assume they are all single digits
	var multipliers = ""
	for m in damage_multipliers:
		multipliers += str(m)
	return multipliers


func save_damage_durations():
	# Assume they are all single digits
	var multipliers = ""
	for m in damage_multiplier_durations:
		multipliers += str(m)
	return multipliers


func load_state(data):
	$AnimationPlayer.play("Idle")
	self.global_position.x = data["global_position.x"]
	self.global_position.y = data["global_position.y"]
	self.defence = data["defence"]
	stats.health = data["health"]
	stats.max_health = data["max_health"]
	in_stealth = data["in_stealth"]
	last_known_position.x = data["last_known_position.x"]
	last_known_position.y = data["last_known_position.y"]
	
	# Set stealth properly
	get_parent().kill_player_copy()
	if in_stealth:
		create_player_copy()
	
	# Set damage multipliers
	self.damage_multipliers = []
	self.damage_multiplier_durations = []
	for m in data["damage_multipliers"]:
		self.damage_multipliers.append(int(m))
	for d in data["damage_multiplier_durations"]:
		self.damage_multiplier_durations.append(int(d))


func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "Die":
		emit_signal("player_died")


func _on_Deck_card_is_hovered(bool_value):
	self.accept_movement = !bool_value
	$Label.text = str(bool_value)


func _on_Stats_max_health_changed(value):
	emit_signal("max_health_changed", value)


func set_stealth(value):
	if in_stealth == false and value == true:
		last_known_position = self.global_position
		create_player_copy()
		in_stealth = value
	elif in_stealth == true and value == false:
		#set_collision_mask_bit(2,true)
		in_stealth = value
		get_parent().kill_player_copy()


func create_player_copy():
	var copy = PlayerCopyScene.instance()
	get_parent().add_child(copy)
	copy.global_position = last_known_position


func on_new_wave(_wave_num):
	self.in_stealth = false


func add_damage_multiplier(multiplier, duration):
	self.damage_multipliers.append(multiplier)
	self.damage_multiplier_durations.append(duration)


func decrement_damage_multipliers():
	var idx = 0
	while idx < len(damage_multipliers):
		damage_multiplier_durations[idx] -= 1
		if damage_multiplier_durations[idx] <= 0:
			damage_multiplier_durations.remove(idx)
			damage_multipliers.remove(idx)
		else:
			idx += 1


func _on_Stats_health_reduced():
	emit_signal("health_reduced")
