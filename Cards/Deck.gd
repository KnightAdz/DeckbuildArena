extends Node2D
class_name Deck

onready var player = self.get_parent().get_parent().get_node("Player")

var DeckviewScene = preload("res://Menus/DeckView.tscn")
var CardScene = preload("res://Cards/Card.tscn")

enum TurnState {SELECT_CARD, SELECT_TARGET, PLAY_CARD, FINISHED, WAIT, CHOOSE_DISCARD}
var turn_state = TurnState.SELECT_CARD setget set_state

var cards_in_deck = [	preload("res://Cards/BasicAttack.tres"),
						preload("res://Cards/BasicDefend.tres"),
						preload("res://Cards/BasicMovement.tres")
						]
var card_counts = [2,2,2,2,2] #2,2,2

var draw_pile = []
var hand = []
var discard_pile = []

var hand_positions = null
# Mouse clicks can select more then 1 card at once
var clicked_cards = []
var selected_card = null setget set_selected_card
var last_card_played = null
var cards_played_this_turn = 0

var hovered_cards = []
var highlighted_card = null setget set_highlighted_card
var last_card_highlighted = null

var focus_level = 3 setget set_focus_level
var focus = 3 setget set_focus

signal card_played()
signal turn_taken()
signal card_is_hovered(bool_value)
signal button_pressed()

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
	if Input.is_action_just_pressed("viewdeck"):
		#show_whole_deck()	
		pass

func _process(_delta):
	# Clear out clicked cards
	for c in clicked_cards:
		if c:
			c.is_selected = false
			unpreview_card_effects()
	clicked_cards = []
	
	match self.turn_state:
		TurnState.FINISHED:
			# Wait for characters to finish acting
			var all_finished = true
			if all_finished:
				emit_signal("turn_taken")
				self.turn_state = TurnState.WAIT


func take_turn():
	cards_played_this_turn = 0
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
			enable_buttons()
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
			disable_buttons()


func end_turn():	
	# Discard any cards in hand?
	# yes for now as easier to manage card positions
	for c in hand:
		discard(c)
	
	last_card_highlighted = null
	hovered_cards = []
	
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
	card.connect("card_highlighted", self, "_on_card_hovered")
	card.connect("card_unhighlighted", self, "_on_card_unhovered")

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


func reposition_hand_card(card):
	var num_cards_in_hand = len(hand)
	if num_cards_in_hand == 0:
		return
	var hand_spacing = floor(len(hand_positions)*0.5)
	if num_cards_in_hand > 1:
		hand_spacing = len(hand_positions)/(num_cards_in_hand-1)
	
	var idx = hand.find(card)
	if idx >= 0:
		var spacing = idx*hand_spacing
		if spacing >= len(hand_positions)-1:
			spacing = len(hand_positions)-2 # minus 2 to allow rotation calcs later
		# Set position
		hand[idx].target_position = self.position + hand_positions[spacing]
		# Set rotation
		var angle = hand_positions[spacing+1].angle_to_point(hand_positions[spacing])
		hand[idx].rotation = angle


func shuffle_discard_into_draw():
	for d in discard_pile:
		d.target_position = $DrawPile.global_position
		d.rotation = 0
		draw_pile.append(d)
	draw_pile.shuffle()
	discard_pile = []
	last_card_played = null
	last_card_highlighted = null
	$Label.text = str(len(discard_pile))


func send_card_data_to_player(card, undo=false):
	var modifier = 1
	if undo:
		modifier = -1
	


func preview_card_effects(card):
	var stats = card.card_stats
	if stats.defence > 0:
		player.defence_preview += stats.defence
	if stats.movement > 0:
		player.move_preview += stats.movement
	if stats.attack > 0:
		player.set_attack_attribs(stats.attack, 
								stats.ranged_attack, 
								stats.area_attack, 
								stats.knockback,
								stats.stun_enemy)


func unpreview_card_effects():
	player.reset_preview()


func play_card():
	last_card_highlighted = null
	hovered_cards = []
	cards_played_this_turn += 1
	emit_signal("card_played")
	emit_signal("card_is_hovered", false)
	var stats = selected_card.card_stats
	self.focus -= stats.focus_cost
	
	# Default next state will be select card but some cards may change this
	self.turn_state = TurnState.SELECT_CARD


	# if the card has a player actions list
	if stats.actions != []:
		player.queue_actions(stats.actions)
	else:
		if stats.attack > 0:
			player.attack(	stats.attack, 
							stats.ranged_attack, 
							stats.area_attack, 
							stats.knockback,
							stats.stun_enemy)
		if stats.defence > 0:
			player.defend(stats.defence)
		if stats.movement > 0:
			player.gain_movement(stats.movement, stats.stealth)
		if stats.damage_multiplier > 1:
			player.add_damage_multiplier(stats.damage_multiplier, 
										stats.damage_multiplier_duration)
	
	# Activate deck actions
	if stats.cards_to_draw > 0:
		draw_x_cards(stats.cards_to_draw)
	if stats.cards_to_discard > 0:
		if len(hand) > 1:
			self.turn_state = TurnState.CHOOSE_DISCARD
	if stats.healing > 0:
		player.gain_health(stats.healing)
	
	# Remove from hand and add to discard pile
	if stats.destroy_after_use:
		destroy_card(selected_card)
	else:
		discard(selected_card)
	
	# If no cards in hand, draw a new hand
	#if len(hand) == 0:
	#	end_turn()
	#else:
	reposition_hand_cards()


func discard(card):
	if hand.find(card) >= 0:
		hand.remove(hand.find(card))
	last_card_highlighted = null
	hovered_cards = []
	discard_pile.append(card)
	card.show_discard_indicator(false)
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
	emit_signal("button_pressed")
	var cards_in_hand = len(hand)
	while len(hand):
		discard(hand.back())
	player.reset_preview()
	player.gain_movement(cards_in_hand)


func _on_AttackButton_pressed():
	emit_signal("button_pressed")
	var cards_in_hand = len(hand)
	while len(hand):
		discard(hand.back())
	player.reset_preview()
	player.attack(cards_in_hand)


func _on_DefenceButton_pressed():
	emit_signal("button_pressed")
	var cards_in_hand = len(hand)
	while len(hand):
		discard(hand.back())
	player.reset_preview()
	player.defend(cards_in_hand)
	

func add_card_to_discard(card):
	self.add_child(card)
	card.connect("card_selected", self, "_on_card_selected")
	card.connect("card_highlighted", self, "_on_card_hovered")
	card.connect("card_unhighlighted", self, "_on_card_unhovered")
	discard(card)


func _on_card_selected(card):
	self.clicked_cards.append(card)
	if card != clicked_cards[0]:
		card.deselect_card()
	else:
		self.selected_card = clicked_cards[0] # Invokes the setter function


func set_selected_card(c):
	# Prevent double playing when 2 cards are clicked at same time
	if c == last_card_played:
		TurnState.SELECT_CARD
		selected_card = null
		clicked_cards = []
		#last_card_played = null
		return 
	
	#if different to previous
	selected_card = c
	last_card_played = selected_card
	if selected_card:
		match self.turn_state:
			TurnState.SELECT_CARD:
				if selected_card.card_stats.needs_target:
					self.turn_state = TurnState.SELECT_TARGET #needs target
				else:
					self.turn_state = TurnState.PLAY_CARD
					#play_card()

			TurnState.CHOOSE_DISCARD:
				discard(selected_card)
				selected_card = null
				self.turn_state = TurnState.SELECT_CARD


func set_highlighted_card(c):
	# Prevent double highlighting when 2 cards are hovered at same time
	if c == last_card_highlighted:
		highlighted_card = null
		clicked_cards = []
		return 
	#if different to previous and not null
	if c != null:
		highlighted_card = c
		last_card_highlighted = highlighted_card
		var discarding = self.turn_state == TurnState.CHOOSE_DISCARD
		last_card_highlighted.highlight_card(true, discarding)
		preview_card_effects(highlighted_card)
	else:
		unpreview_card_effects()


func _on_card_hovered(card):
	unpreview_card_effects()
	self.hovered_cards.append(card)
	if card == hovered_cards[0]:
		self.highlighted_card = hovered_cards[0] # Invokes the setter function
		emit_signal("card_is_hovered", true)


func _on_card_unhovered(card):
	if highlighted_card == card:
		unpreview_card_effects()
		if hovered_cards.find(card) >= 0:
			hovered_cards.remove(hovered_cards.find(card))
		if len(hovered_cards) > 0:
			self.highlighted_card = self.hovered_cards[0]
			self.hovered_cards = []
		else:
			self.last_card_highlighted = null
			emit_signal("card_is_hovered", false)

		


func lose_control():
	# lower opacity of cards, ignore input
	for c in hand:
		c.modulate = Color(1,1,1,0.2)
		c.ignore_input = true
		c.z_index = 0
	disable_buttons()


func gain_control():
	# rest opacity of cards, don't ignore input
	for c in hand:
		c.modulate = Color(1,1,1,1)
		c.ignore_input = false
	enable_buttons()


func disable_buttons():
	$MovementButton.disabled = true
	$AttackButton.disabled = true
	$DefenceButton.disabled = true
	$Button.disabled = true


func enable_buttons():
	$MovementButton.disabled = false
	$AttackButton.disabled = false
	$DefenceButton.disabled = false
	$Button.disabled = false


func update_button_labels():
	var num_cards = len(hand)
	$MovementButton.text = str(num_cards) + " Movement"
	$DefenceButton.text = str(num_cards) + " Defence"
	$AttackButton.text = "1 Attack for " + str(num_cards) + " damage"


func destroy_card(card):
	if clicked_cards.find(card) >= 0:
		clicked_cards.remove(clicked_cards.find(card))
	hand.remove(hand.find(card))
	card.queue_free()


func _on_Enemies_wave_complete():
	lose_control()


func save_state():
	var save_dict = {
		"node" : "deck",
		"hand_cards" : list_cardstats_in_array(hand),
		"draw_pile_cards" : list_cardstats_in_array(draw_pile),
		"discard_pile_cards" : list_cardstats_in_array(discard_pile)
	}
	return save_dict
	

func load_state(save_dict):
	var hand_cardstats = save_dict["hand_cards"]
	var discard_cardstats = save_dict["discard_pile_cards"]
	var draw_cardstats = save_dict["draw_pile_cards"]
	
	# Clear existing arrays
	for c in hand:
		c.queue_free()
	hand = []
	for c in draw_pile:
		c.queue_free()
	draw_pile = []
	for c in discard_pile:
		c.queue_free()
	discard_pile = []
	
	# Recreate
	for c in discard_cardstats:
		add_card_to_deck(load(c))
		discard(draw_pile.back())

	for c in hand_cardstats:
		add_card_to_deck(load(c))
		draw_hand(len(hand_cardstats))
	
	for c in draw_cardstats:
		add_card_to_deck(load(c))
	

func _on_MovementButton_mouse_entered():
	var movement = len(hand)
	player.move_preview += movement
	

func _on_MovementButton_mouse_exited():
	player.reset_preview()


func _on_AttackButton_mouse_entered():
	var damage = len(hand)
	player.set_attack_attribs(damage)


func _on_DefenceButton_mouse_entered():
	var defence = len(hand)
	player.defence_preview += defence
	

func _on_DefenceButton_mouse_exited():
	player.reset_preview()


func _on_AttackButton_mouse_exited():
	player.reset_preview()


func list_cardstats_in_deck():
	var cardstats = []
	for c in self.get_children():
		if c.is_in_group("card"):
			cardstats.append(c.card_stats)
	return cardstats


func list_cardstats_in_array(array_name):
	var cardstats = []
	for c in array_name:
		if c.is_in_group("card"):
			cardstats.append(c.card_stats.resource_path)
	return cardstats


func show_whole_deck():
	var deckview = DeckviewScene.instance()
	self.get_parent().add_child(deckview)
	deckview.add_list_of_cards(list_cardstats_in_deck())
	
