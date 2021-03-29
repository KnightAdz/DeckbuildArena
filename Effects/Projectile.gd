extends KinematicBody2D

const EnemyDeathEffect = preload("res://Effects/EnemyDeathEffect.tscn")

export var MAX_SPEED = 20
var velocity = Vector2.RIGHT setget set_velocity
var destroy_self = false

func _ready():
	set_velocity(velocity)
	$Hitbox.activate()


func set_velocity(direction):
	velocity = direction.normalized()
	$Sprite.rotation = velocity.angle_to(Vector2.DOWN)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if destroy_self:
		queue_free()
	
	var collision = move_and_collide(velocity*MAX_SPEED)
	if collision != null:
		create_effect()
		self.visible = false
		destroy_self = true # wait until hitbox has activated


func create_effect():
	var effect = EnemyDeathEffect.instance()
	var main = get_tree().current_scene
	main.add_child(effect)
	effect.global_position = global_position


func set_stun(value):
	$Hitbox.stun = value
