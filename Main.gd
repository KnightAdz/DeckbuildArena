extends Node2D

var CardScene = preload("res://Cards/Card.tscn")
var GainCardDialog = preload("res://Dialogs/GainCard.tscn")

onready var turn_order = [$CanvasLayer/Deck, $Enemies]
var turn_idx = 0
var ready_for_next_turn = true


# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	take_turn(turn_idx)


func _process(_delta):
	if ready_for_next_turn:
		ready_for_next_turn = false
		take_next_turn()


func _input(event):
	if Input.is_action_pressed("ui_accept"):
		show_overview()
	else:
		show_player_camera()


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
	# Assumes null entries will always be last
	if turn_order[turn_idx] == null:
		turn_order.remove(turn_idx)
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
	card_gain_dialog.add_child(new_card)
	new_card.set_stats(load(card_stats))
	new_card.is_face_up = true
	
	card_gain_dialog.set_card(new_card)


func add_to_turn_order(node):
	turn_order.append(node)


func _on_Player_health_changed(new_value):
	if new_value <= 0:
		game_over()
		

func game_over():
	$CanvasLayer/GameOverScreen.visible = true
	var wave_num = $Enemies.get_wave()
	$CanvasLayer/GameOverScreen.text = "Game Over!\nYou made it to wave " + str(wave_num)


func show_overview():
	$Camera2D.current = false
	$OverviewCamera.current = true
	$CanvasLayer/Deck.lose_control()
	


func show_player_camera():
	$Camera2D.current = true
	$OverviewCamera.current = false
	$CanvasLayer/Deck.gain_control()
