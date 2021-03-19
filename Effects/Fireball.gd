extends KinematicBody2D

const EnemyDeathEffect = preload("res://Effects/EnemyDeathEffect.tscn")

export var MAX_SPEED = 20
var velocity = Vector2.ZERO setget set_velocity
var destroy_self = false

func _ready():
	set_velocity(velocity)
	$AnimationPlayer.play("Idle")


func set_velocity(direction):
	velocity = direction.normalized()
	if velocity != Vector2.ZERO:
		$Hitbox.activate()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if destroy_self:
		queue_free()
	
	var collision = move_and_collide(velocity*MAX_SPEED)
	if collision != null:
		create_effect()
		self.queue_free()


func create_effect():
	var effect = EnemyDeathEffect.instance()
	var main = get_tree().current_scene
	main.add_child(effect)
	effect.global_position = global_position
