extends "res://Enemies/BasicEnemy.gd"

onready var deck = get_parent().get_parent().get_node("CanvasLayer/Deck")
var status_card = preload("res://Cards/Slow.tres")


func _ready():
	MOVE_LIMIT = 200

func attack():
	if player != null:
		if player.global_position.distance_to(global_position) < 30:
			player.be_attacked($Hitbox.damage)
			deck.add_card_to_deck(status_card, true)
			deck.draw_x_cards(1)
