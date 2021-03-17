extends KinematicBody2D


var ACCELERATION = 300
var MAX_SPEED = 50
var card_stats_file = "res://Cards/Attack4.tres"
var protected_time = 1
var picked_up = false
var player = null
var velocity = Vector2.ZERO

signal gained_card(card_stats)

# Called when the node enters the scene tree for the first time.
func _ready():
	$AnimationPlayer.play("Idle")
	$Timer.start(protected_time)


func _process(delta):
	if player == null:
		return
		
	var direction = global_position.direction_to(player.global_position).normalized()
	velocity = velocity.move_toward(direction*MAX_SPEED, ACCELERATION*delta)
	var _collision = move_and_collide(velocity)


func get_card_stats():
	return card_stats_file


func _on_Area2D_body_entered(body):
	player = body
	picked_up = true
	if $Timer.time_left <= 0:
		be_picked_up()


func _on_Timer_timeout():
	if picked_up:
		be_picked_up()


func be_picked_up():
	emit_signal("gained_card", card_stats_file)
	queue_free()
