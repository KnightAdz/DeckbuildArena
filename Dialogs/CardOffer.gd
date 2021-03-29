extends Control

const CardScene = preload("res://Cards/Card.tscn")

signal add_card_to_discard(card)
signal turn_taken()

var loot_options = Globals.available_cards


func _ready():
	for c in $Cards.get_children():
		c.is_face_up = true
		c.ignore_input = false
	
	var to_offer = []
	for _i in range(3):
		var rand_select = randi()%len(loot_options)
		while loot_options[rand_select] in to_offer:
			rand_select = randi()%len(loot_options)
		to_offer.append(loot_options[rand_select])
	set_cards(to_offer)


func take_turn():
	pass


func set_cards(cardstats):
	$Cards/Card.set_stats(load(cardstats[0]))
	$Cards/Card2.set_stats(load(cardstats[1]))
	$Cards/Card3.set_stats(load(cardstats[2]))


func _on_Leave_pressed():
	emit_signal("turn_taken")
	queue_free()


func _on_card_selected(card):
	$Cards.remove_child(card)
	emit_signal("turn_taken")
	emit_signal("add_card_to_discard", card)
	queue_free()
