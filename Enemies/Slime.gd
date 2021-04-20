extends "res://Enemies/BasicEnemy.gd"

onready var deck = get_parent().get_parent().get_node("CanvasLayer/Deck")
var blind_card = preload("res://Cards/Blind.tres")

func attack():
	if player != null:
		if player.global_position.distance_to(global_position) < 30:
			player.be_attacked($Hitbox.damage)
			deck.add_card_to_deck(blind_card, true)
			deck.draw_x_cards(1)
