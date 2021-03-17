extends Node2D
class_name Deck

onready var player = self.get_parent().get_parent().get_node("Player")

var CardScene = preload("res://Cards/Card.tscn")

enum TurnState {SELECT_CARD, SELECT_TARGET, PLAY_CARD, FINISHED, WAIT, CHOOSE_DISCARD}
var turn_state = TurnState.SELECT_CARD setget set_state

var cards_in_deck = [	preload("res://Cards/BasicAttack.tres"),
						preload("res://Cards/BasicDefend.tres"),
						preload("res://Cards/BasicMovement.tres"),
						preload("res://Cards/RangedAttack.tres"),
						preload("res://Cards/Knockback.tres")]
var card_counts = [2,2,2,2,2] #2,2,2

var draw_pile = []
var hand = []
var discard_pile = []

var hand_positions = null
var selected_card = null setget set_selected_card

var focus_level = 3 setget set_focus_level
var focus = 3 setget set_focus

signal card_played()
signal turn_taken()


func _ready():
	#set_process(true)
	hand_positions = $Path2D.curve.get_baked_points()
#	randomize()
	create_draw_pile()
	draw_hand()


func _input(_event):
	if Input.is_action_just_released("rclick"):	
		for c in hand:
			c.scale = Vector2(1,1)
		reposition_hand_cards()
		selected_card = null
		self.turn_state = TurnState.SELECT_CARD


func _process(_delta):
	match self.turn_state:
		TurnState.FINISHED:
			# Wait for characters to finish acting
			var all_finished = true
			if all_finished:
				emit_signal("turn_taken")
				self.turn_state = TurnState.WAIT


func take_turn():
	player.start_turn()
	gain_control()
	self.focus = self.focus_level
	self.turn_state = TurnState.SELECT_CARD


func set_state(new_state):
	turn_state = new_state
	match new_state:
		TurnState.SELECT_CARD:
			$Turnstate.text = "Select card"
			$Button.visible = true	
			# Set cards in hand to accept input if we have enough focus to spend them
			for c in hand:
				if c.card_stats.focus_cost <= focus:
					c.ignore_input = false
			# Update button labels
			update_button_labels()
		TurnState.SELECT_TARGET:
			$Turnstate.text = "Select target"
			# Set cards in hand to ignore input
			for c in hand:
				c.ignore_input = true
		TurnState.PLAY_CARD:
			$Turnstate.text = "Play card"
			play_card()
		TurnState.FINISHED:
			$Turnstate.text = "Finished"
			$Button.visible = false
		TurnState.WAIT:
			$Turnstate.text = "Wait"
		TurnState.CHOOSE_DISCARD:
			$Turnstate.text = "Choose a card to discard"


func end_turn():	
	# Discard any cards in hand?
	# yes for now as easier to manage card positions
	for c in hand:
		discard(c)
	
	# draw new hand
	draw_hand()	
	
	# Set all cards to ignore input
	for c in hand:
		c.ignore_input = true
	for c in draw_pile:
		c.ignore_input = true
	for c in discard_pile:
		c.ignore_input = true

	lose_control()	
	self.turn_state = TurnState.FINISHED


func add_card_to_deck(card_resource):
	var card = CardScene.instance()
	self.add_child(card)
	card.set_stats(card_resource)
	card.global_position = $DrawPile.global_position
	card.is_face_up = true
	card.is_face_up = false
	card.connect("card_selected", self, "_on_card_selected")
#	for a in card.card_stats.actions:
#		a.connect("draw_x_cards", self, "draw_x_cards")
 
	draw_pile.append(card)


func create_draw_pile(shuffle=true):
	# For each card
	for i in range(len(cards_in_deck)):
		# For the number of copies of that card
		for _j in range(card_counts[i]):
			# Add a card
			add_card_to_deck(cards_in_deck[i])

	if shuffle:
		draw_pile.shuffle()


func draw_hand(new_hand_size=5):
	var curr_hand_size = len(hand)
	var cards_to_draw = new_hand_size - curr_hand_size
	if cards_to_draw == 0:
		return
	for i in range(cards_to_draw):
		i += curr_hand_size
		# If no cards to draw from, shuffle the discard pile in
		if len(draw_pile) == 0:
			shuffle_discard_into_draw()
		
		if len(draw_pile) > 0:
			hand.append(draw_pile.pop_front())
			hand.back().is_face_up = true
			hand.back().ignore_input = false # Only when during a turn
			reposition_hand_cards()
		else:
			# If still no cards to draw from, we have the whole deck in hand!
			# Achievement
			pass


func draw_x_cards(x):
	if x > 0:
		var curr_hand_size = len(hand)
		draw_hand(curr_hand_size+x)


func reposition_hand_cards():
	var num_cards_in_hand = len(hand)
	if num_cards_in_hand == 0:
		return
	var hand_spacing = floor(len(hand_positions)*0.5)
	if num_cards_in_hand > 1:
		hand_spacing = len(hand_positions)/(num_cards_in_hand-1)
	for i in range(num_cards_in_hand):
		var spacing = i*hand_spacing
		if spacing >= len(hand_positions)-1:
			spacing = len(hand_positions)-2 # minus 2 to allow rotation calcs later
		# Set position
		hand[i].target_position = self.position + hand_positions[spacing]
		# Set rotation
		var angle = hand_positions[spacing+1].angle_to_point(hand_positions[spacing])
		hand[i].rotation = angle


func shuffle_discard_into_draw():
	for d in discard_pile:
		d.target_position = $DrawPile.global_position
		d.rotation = 0
		draw_pile.append(d)
	draw_pile.shuffle()
	discard_pile = []
	$Label.text = str(len(discard_pile))


func _on_card_selected(card):
	self.selected_card = card # Invokes the setter function


func play_card():
	emit_signal("card_played")
	var stats = selected_card.card_stats
	self.focus -= stats.focus_cost
	
	# Default next state will be select card but some cards may change this
	self.turn_state = TurnState.SELECT_CARD

	if stats.attack > 0:
		player.attack(	stats.attack, 
						stats.ranged_attack, 
						stats.area_attack, 
						stats.knockback)
	if stats.defence > 0:
		player.defend(stats.defence)
	if stats.movement > 0:
		player.gain_movement(stats.movement)
	if stats.cards_to_draw > 0:
		draw_x_cards(stats.cards_to_draw)
	if stats.cards_to_discard > 0:
		if len(hand) > 1:
			self.turn_state = TurnState.CHOOSE_DISCARD

	# Remove from hand and add to discard pile
	discard(selected_card)
	
	# If no cards in hand, draw a new hand
	#if len(hand) == 0:
	#	end_turn()
	#else:
	reposition_hand_cards()


func discard(card):
	discard_pile.append(card)
	if hand.find(card) >= 0:
		hand.remove(hand.find(card))
	card.target_position = $DiscardPile.global_position
	card.is_face_up = false
	card.is_selected = false
	$Label.text = str(len(discard_pile))
	update_button_labels()


func get_name():
	return "Player"


func _on_Button_pressed():
	if self.turn_state == TurnState.FINISHED:
		return
	if self.turn_state == TurnState.WAIT:
		return
	end_turn()


func set_focus_level(value):
	focus_level = value
	$FocusLevel.region_rect = Rect2(0, 0, focus_level*64, 64) 


func set_focus(value):
	focus = clamp(value, 0, focus_level)
	$Focus.region_rect = Rect2(0, 0, focus*64, 64) 


func _on_MovementButton_pressed():
	var cards_in_hand = len(hand)
	while len(hand):
		discard(hand.back())
	player.gain_movement(cards_in_hand)


func _on_AttackButton_pressed():
	var cards_in_hand = len(hand)
	while len(hand):
		discard(hand.back())
	player.attack(cards_in_hand)


func _on_DefenceButton_pressed():
	while len(hand):
		discard(hand.back())
		player.defend()


func add_card_to_discard(card):
	self.add_child(card)
	card.connect("card_selected", self, "_on_card_selected")
	discard(card)


func set_selected_card(c):
	selected_card = c
	if selected_card:
		match self.turn_state:
			TurnState.SELECT_CARD:
				if selected_card.card_stats.needs_target:
					self.turn_state = TurnState.SELECT_TARGET #needs target
				else:
					turn_state = TurnState.PLAY_CARD
					play_card()

			TurnState.CHOOSE_DISCARD:
				discard(selected_card)
				selected_card = null
				self.turn_state = TurnState.SELECT_CARD


func lose_control():
	# lower opacity of cards, ignore input
	for c in hand:
		c.modulate = Color(1,1,1,0.2)
		c.ignore_input = true
		c.z_index = 0
	$MovementButton.disabled = true
	$AttackButton.disabled = true
	$DefenceButton.disabled = true


func gain_control():
	# rest opacity of cards, don't ignore input
	for c in hand:
		c.modulate = Color(1,1,1,1)
		c.ignore_input = false
	$MovementButton.disabled = false
	$AttackButton.disabled = false
	$DefenceButton.disabled = false


func update_button_labels():
	var num_cards = len(hand)
	$MovementButton.text = str(num_cards) + " Movement"
	$DefenceButton.text = str(num_cards) + " Defence"
	$AttackButton.text = "1 Attack for " + str(num_cards) + " damage"
