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

signal card_played(card)
signal turn_taken()
signal card_is_hovered(bool_value)
signal button_pressed()
signal player_blinded()
signal player_unblinded()
signal player_slowed(value)

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
		
	# Keyboard input controls
	# If cards are eligible to be selected (assume if first hand card is, all are)
	if len(hand) > 0:
		if !hand[0].ignore_input:
			if Input.is_action_just_pressed("ui_left"):
				change_highlighted_card(-1)
				for b in $Buttons.get_children():
					b.release_focus()
			if Input.is_action_just_pressed("ui_right"):
				change_highlighted_card(1)
				for b in $Buttons.get_children():
					b.release_focus()
			if Input.is_action_just_released("ui_focus_next"):
				if highlighted_card:
					var discarding = (self.turn_state == TurnState.CHOOSE_DISCARD)
					highlighted_card.highlight_card(false, discarding)
					_on_card_unhovered(highlighted_card)
				self.highlighted_card = null
				$Buttons/EndTurnButton.grab_focus()
			if Input.is_action_just_released("ui_accept"):
				if self.highlighted_card:
					_on_card_selected(self.highlighted_card)


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
	self.turn_state = TurnState.SELECT_CARD


func set_state(new_state):
	# if coming out of discard, reset indicators 
	if turn_state == TurnState.CHOOSE_DISCARD:
		if new_state != turn_state:
			remove_all_discard_indicators()
	# Set new state
	turn_state = new_state
	for c in hand:
		c.modulate = Color.white
	match new_state:
		TurnState.SELECT_CARD:
			$Turnstate.text = "Select card"
			$Buttons/EndTurnButton.visible = true	
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
			# Can't play corruption cards
			if selected_card.card_stats.colour != "PURPLE":
				play_card()
		TurnState.FINISHED:
			$Turnstate.text = "Finished"
			$Buttons/EndTurnButton.visible = false
		TurnState.WAIT:
			$Turnstate.text = "Wait"
		TurnState.CHOOSE_DISCARD:
			$Turnstate.text = "Choose a card to discard"
			for c in hand:
				c.modulate = Color.red
			disable_buttons()


func end_turn():	
	emit_signal("player_unblinded")
	emit_signal("player_slowed", false)
	# Discard any cards in hand
	# and check for corruption cards
	var cards_in_hand = len(hand)
	var i = cards_in_hand-1
	while i >= 0:
		var c = hand[i]
		if c.card_stats.colour == "PURPLE":
			selected_card = c
			play_card(true)
			# need to wait for animation to play before continuing
			yield(c, "card_played")
		else:
			discard(c)
		i -= 1
	
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


func add_card_to_deck(card_resource, on_top=false):
	var card = CardScene.instance()
	self.add_child(card)
	card.set_stats(card_resource)
	card.global_position = $DrawPile.global_position
	card.is_face_up = true
	card.is_face_up = false
	card.connect("card_selected", self, "_on_card_selected")
	card.connect("card_highlighted", self, "_on_card_hovered")
	card.connect("card_unhighlighted", self, "_on_card_unhovered")
	card.connect("card_played", self, "_on_card_played")

	if !on_top:
		draw_pile.append(card)
	else:
		draw_pile.push_front(card)


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
	for _i in range(cards_to_draw):
		#_i += curr_hand_size
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
		hand[i].target_position = hand_positions[spacing] + self.position 
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


func play_card(play_anim=false):
	var stats = selected_card.card_stats
	
	last_card_highlighted = null
	hovered_cards = []
	cards_played_this_turn += 1
	emit_signal("card_played", selected_card)
	emit_signal("card_is_hovered", false)
	if play_anim:
		selected_card.play_card_animation($DiscardPile.global_position)
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
	
	if stats.max_health_change != 0:
		player.gain_max_health(stats.max_health_change)
	if stats.healing != 0:
		player.gain_health(stats.healing)
	
	# Debuffs and statuses
	if stats.blind:
		emit_signal("player_blinded")
	
	if stats.slow:
		emit_signal("player_slowed", true)
	
	if play_anim:
		# Wait for card played signal
		return
	else:
		_on_card_played(selected_card)


func _on_card_played(card):
	# Remove from hand and add to discard pile
	if card.card_stats.destroy_after_use:
		destroy_card(card)
	else:
		discard(card)
	reposition_hand_cards()


func discard(card):
	if hand.find(card) >= 0:
		hand.remove(hand.find(card))
	if draw_pile.find(card) >= 0:
		draw_pile.remove(draw_pile.find(card))
	last_card_highlighted = null
	hovered_cards = []
	discard_pile.append(card)
	card.show_discard_indicator(false)
	card.target_position = $DiscardPile.global_position
	card.non_highlighted_position = null
	card.is_face_up = false
	card.is_selected = false
	card.modulate = Color.white
	card.z_index = 0
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


func _on_MovementButton_pressed():
	emit_signal("button_pressed")
	var cards_in_hand = count_discardable_cards()
	discard_discardable_cards()
	player.reset_preview()
	player.gain_movement(cards_in_hand)


func _on_AttackButton_pressed():
	emit_signal("button_pressed")
	var cards_in_hand = count_discardable_cards()
	discard_discardable_cards()
	player.reset_preview()
	player.attack(cards_in_hand)


func _on_DefenceButton_pressed():
	emit_signal("button_pressed")
	var cards_in_hand = count_discardable_cards()
	discard_discardable_cards()
	player.reset_preview()
	player.defend(cards_in_hand)


func count_discardable_cards():
	var count = 0
	for c in hand:
		if c.card_stats.colour != 'PURPLE':
			count += 1
	return count


func discard_discardable_cards():
	var discards = count_discardable_cards()
	var idx = len(hand)
	while idx > 0:
		# Need to not discard purples
		if hand[idx-1].card_stats.colour != 'PURPLE':
			discard(hand[idx-1])
			discards -= 1
		idx -= 1


func indicate_discardable_cards():
	for c in hand:
		if c.card_stats.colour != 'PURPLE':
			c.show_discard_indicator(true)


func add_card_to_discard(card):
	self.add_child(card)
	card.connect("card_selected", self, "_on_card_selected")
	card.connect("card_highlighted", self, "_on_card_hovered")
	card.connect("card_unhighlighted", self, "_on_card_unhovered")
	card.connect("card_played", self, "_on_card_played")
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
		var discarding = (self.turn_state == TurnState.CHOOSE_DISCARD)
		if highlighted_card:
			highlighted_card.highlight_card(false, discarding)
		highlighted_card = c
		last_card_highlighted = highlighted_card
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
	#emit_signal("card_is_hovered", false)


func gain_control():
	# rest opacity of cards, don't ignore input
	for c in hand:
		c.modulate = Color(1,1,1,1)
		c.ignore_input = false
	enable_buttons()


func disable_buttons():
	for b in $Buttons.get_children():
		b.disabled = true


func enable_buttons():
	for b in $Buttons.get_children():
		b.disabled = false


func update_button_labels():
	var num_cards = count_discardable_cards()
	$Buttons/MovementButton.text = str(num_cards) + " Movement"
	$Buttons/DefenceButton.text = str(num_cards) + " Defence"
	$Buttons/AttackButton.text = str(num_cards) + " Damage"


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
	
	for c in draw_pile:
		discard(c)

	for d in hand_cardstats:
		add_card_to_deck(load(d))
	draw_hand(len(hand_cardstats))
	
	for e in draw_cardstats:
		add_card_to_deck(load(e))
	

func _on_MovementButton_mouse_entered():
	# Also focus entered
	var movement = count_discardable_cards()
	player.move_preview += movement
	indicate_discardable_cards()


func _on_AttackButton_mouse_entered():
	# Also focus entered
	var damage = count_discardable_cards()
	player.set_attack_attribs(damage)
	indicate_discardable_cards()


func _on_DefenceButton_mouse_entered():
	# Also focus entered
	var defence = count_discardable_cards()
	player.defence_preview += defence
	indicate_discardable_cards()


func _on_MovementButton_mouse_exited():
	player.reset_preview()
	remove_all_discard_indicators()


func _on_DefenceButton_mouse_exited():
	player.reset_preview()
	remove_all_discard_indicators()


func _on_AttackButton_mouse_exited():
	# Also focus entered
	player.reset_preview()
	remove_all_discard_indicators()


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
	

func change_highlighted_card(idx_change):
	if highlighted_card == null:
		if len(hand) > 0:
			self.highlighted_card = hand[0]
			return
	else:
		_on_card_unhovered(highlighted_card)
		var current_idx = hand.find(highlighted_card)
		var new_idx = current_idx+idx_change
		new_idx = clamp(new_idx, 0, len(hand)-1)
		var card = hand[new_idx]
		self.highlighted_card = card


func remove_all_discard_indicators():
	for c in draw_pile:
		c.show_discard_indicator(false)
	for c in hand:
		c.show_discard_indicator(false)
	for c in discard_pile:
		c.show_discard_indicator(false)
