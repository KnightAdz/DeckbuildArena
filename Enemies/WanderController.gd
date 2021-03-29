extends Node2D

export(int) var wander_range = 100

onready var start_position = global_position
onready var target_position = global_position


func _ready():
	update_target_position()


func update_target_position():
	var target_vector = Vector2(rand_range(-wander_range, wander_range), rand_range(-wander_range, wander_range))
	target_position = start_position + target_vector


func reset_start_position():
	start_position = global_position
