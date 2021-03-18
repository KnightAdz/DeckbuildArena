extends "res://Enemies/BasicEnemy.gd"


func _ready():
	# Walkies always chase the player
	player = get_parent().get_parent().get_node("Player")
	MOVE_LIMIT = 100


func _on_PlayerDetectionZone_body_exited(body):
	# override parent function so that we don't forget player
	pass
