extends Control

const CardScene = preload("res://Cards/Card.tscn")

signal add_card_to_discard(card)
signal turn_taken()

var loot_options = Globals.available_cards
onready var selected_card_idx = 0


func _ready():
	for c in $Cards.get_children():
		c.is_face_up = true
		c.ignore_input = false
	
	var to_offer = []
	loot_options.shuffle()
	for i in range(3):
	#	var rand_select = randi()%len(loot_options)
	#	while loot_options[rand_select] in to_offer:
	#		rand_select = randi()%len(loot_options)
		to_offer.append(loot_options[i])
	set_cards(to_offer)


func take_turn():
	pass


func _input(event):
	var cards = $Cards.get_children()
	
	if Input.is_action_just_released("ui_accept"):
		if selected_card_idx >= len(cards):
			_on_Leave_pressed()
		else:
			_on_card_selected(cards[selected_card_idx])
	
	if Input.is_action_just_pressed("ui_right"):
		selected_card_idx += 1
		$Leave.release_focus()
		if selected_card_idx == len(cards):
			$Leave.grab_focus()
		elif selected_card_idx > len(cards):
			selected_card_idx = 0
		if selected_card_idx < len(cards):
			_on_card_highlighted(cards[selected_card_idx])
	
	if Input.is_action_just_pressed("ui_left"):
		selected_card_idx -= 1
		$Leave.release_focus()
		if selected_card_idx == -1:
			$Leave.grab_focus()
		elif selected_card_idx <= -2:
			selected_card_idx = len(cards)-1
		if selected_card_idx >= 0:
			_on_card_highlighted(cards[selected_card_idx])


func set_cards(cardstats):
	$Cards/Card.set_stats(load(cardstats[0]))
	$Cards/Card2.set_stats(load(cardstats[1]))
	$Cards/Card3.set_stats(load(cardstats[2]))


func _on_Leave_pressed():
	emit_signal("turn_taken")
	queue_free()


func _on_card_selected(card):
	$Cards.remove_child(card)
	emit_signal("add_card_to_discard", card)
	emit_signal("turn_taken")
	queue_free()


func _on_card_highlighted(card):
	card.animate_sheen()
