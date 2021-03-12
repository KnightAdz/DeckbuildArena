extends Node2D

var CardScene = preload("res://Cards/Card.tscn")
var GainCardDialog = preload("res://Dialogs/GainCard.tscn")

onready var turn_order = [$CanvasLayer/Deck, $World, $Enemies]
var turn_idx = 0
var ready_for_next_turn = true


# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	take_turn(turn_idx)


func _process(delta):
	if ready_for_next_turn:
		ready_for_next_turn = false
		take_next_turn()


func take_turn(idx):
	turn_order[idx].take_turn()


func get_targets():
	var targets = []
	for c in get_children():
		if c.is_in_group("target"):
			targets.append(c)
	targets.shuffle()
	return targets


func _on_turn_taken():
#	take_next_turn()
	ready_for_next_turn = true


func take_next_turn():
	turn_idx += 1
	if turn_idx >= len(turn_order):
		turn_idx = 0
	take_turn(turn_idx)


func _on_Deck_card_played():
	pass


func on_card_collected(card_stats):
	# Create the card, show it to the player
	var card_gain_dialog = GainCardDialog.instance()
	$CanvasLayer.add_child(card_gain_dialog)
	card_gain_dialog.connect("add_card_to_discard", $CanvasLayer/Deck, "add_card_to_discard")
	
	var new_card = CardScene.instance()
	var centre_position = Vector2(300,300)
	new_card.global_position = centre_position
	$CanvasLayer.add_child(new_card)
	new_card.set_stats(load(card_stats))
	new_card.is_face_up = true
	
	card_gain_dialog.set_card(new_card)
	
