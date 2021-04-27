extends Node2D

var CardScene = preload("res://Cards/Card.tscn")
var GainCardDialog = preload("res://Dialogs/GainCard.tscn")

onready var turn_order = [$CanvasLayer/Deck, $Enemies]
var turn_idx = 0
var turns_this_wave = 0
var ready_for_next_turn = true

var tutorial_hidden = false

# Start with the 1st wave as default
var starting_wave = preload("res://Enemies/Wave1.tres")
var tutorial_wave = preload("res://Enemies/WaveT1.tres")
var wave_saved = false

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	if Globals.completed_tutorial:
		$Enemies.despawn_enemies()
		$Enemies.load_wave_from_resource(starting_wave)
	
	if Globals.load_wave:
		Globals.load_wave = false
		load_state(Globals.wave_checkpoint_save)
		turn_idx = 0
	
	take_turn(turn_idx)


func _process(_delta):
	if ready_for_next_turn:
		ready_for_next_turn = false
		take_next_turn()


func _input(_event):
	if Input.is_action_just_pressed("ui_select"):
		if $Camera2D.current:
			show_overview()
		else:
			show_player_camera()
	
	if Input.is_action_just_pressed("load"):
		load_state(Globals.save_location)


func take_turn(idx):
	save_state(Globals.save_location)
	var turn_text = null	
	match idx:
		0: turn_text = "Player turn" 
		1: turn_text = "Enemy turn"
		2: turn_text = "??? turn"
	$CanvasLayer/HUD.turn_message_animation(turn_text)
	
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


func game_over():
	var game_over_screen = preload("res://Menus/GameOverMenu.tscn").instance()
	get_tree().get_root().add_child(game_over_screen)
	#game_over_screen.main_scene = self
	#get_tree().get_root().remove_child(self)
	
	self.queue_free()


func show_overview():
	if $OverviewCamera.current:
		return
	$Camera2D.current = false
	$OverviewCamera.current = true
	$CanvasLayer/Deck.lose_control()


func show_player_camera():
	if $Camera2D.current:
		return
	$Camera2D.current = true
	$OverviewCamera.current = false
	$CanvasLayer/Deck.gain_control()


func start_next_wave():
	turn_idx = 0
	turns_this_wave = 0
	wave_saved = false
	take_turn(turn_idx)


func _on_SkipTutorialButton_pressed():
	$Enemies.despawn_enemies()
	$Enemies.load_wave_from_resource(starting_wave)
	self.save_state(Globals.wave_checkpoint_save)
#	hide_tutorial()


func _on_Enemies_completed_tutorial():
	hide_tutorial()


func hide_tutorial():
	if tutorial_hidden:
		return
	$CanvasLayer/SkipTutorialButton.queue_free()
	$CanvasLayer/Tip.queue_free()


func save_state(file_location):
	var save_game = File.new()
	save_game.open(file_location, File.WRITE)

	var save_nodes = get_tree().get_nodes_in_group("persist")
	for node in save_nodes:
		# Check the node has a save function.
		if !node.has_method("save_state"):
			print("persistent node '%s' is missing a save() function, skipped" % node.name)
			continue

		# Call the node's save function.
		var node_data = node.call("save_state")

		# Store the save dictionary as a new line in the save file.
		save_game.store_line(to_json(node_data))
	save_game.close()


# Note: This can be called from anywhere inside the tree. This function
# is path independent.
func load_state(file_location):
	var save_game = File.new()
	if not save_game.file_exists(file_location):
		return # Error! We don't have a save to load.
	
	# Load the file line by line and process that dictionary to restore
	# the object it represents.
	save_game.open(file_location, File.READ)
	while save_game.get_position() < save_game.get_len():
		# Get the saved dictionary from the next line in the save file
		var node_data = parse_json(save_game.get_line())
		if node_data:
			match node_data["node"]:
				"deck" : $CanvasLayer/Deck.load_state(node_data)
				"player" : $Player.load_state(node_data)
				"enemies" : $Enemies.load_state(node_data)
	turns_this_wave = 0
	ready_for_next_turn = false
	save_game.close()


func kill_player_copy():
	for c in get_children():
		if c.is_in_group("player_copy"):
			c.queue_free()
	for e in $Enemies.get_children():
		if e.is_in_group("enemy"):
			e.perceived_player_position = null
			e.check_for_player()


func _on_MusicButton_toggled(button_pressed):
	if button_pressed:
		$AudioStreamPlayer.stop()
	else:
		$AudioStreamPlayer.play()


func _on_Enemies_new_wave_loaded():
	#if !wave_saved and $Enemies.count_enemies() > 0:
	#Save a checkpoint
	save_state(Globals.wave_checkpoint_save)
	#	wave_saved = true


func _on_player_blinded():
	$Blindness.visible = true

func _on_player_unblinded():
	$Blindness.visible = false
