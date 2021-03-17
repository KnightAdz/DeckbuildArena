extends Node2D

var BatScene = preload("res://Enemies/BasicEnemy.tscn")
var LootScene = preload("res://Loot/Loot.tscn")
var OfferScene = preload("res://Dialogs/CardOffer.tscn")

onready var DeckNode = get_parent().get_node("CanvasLayer/Deck")

var turn_started = false
var enemy_health = 1
var enemy_damage = 1
var num_enemies = 3

var wave_count = 1 setget set_wave_count

var loot_options = Globals.available_cards

signal turn_taken()
signal wave_changed(wave_number)


func _ready():
	for _i in range(1):
		spawn_bat(2)


func take_turn():
	turn_started = true
	var children = get_children()
	if len(children) == 0:
		offer_cards(3)
		self.wave_count += 1
		for _i in range(num_enemies+wave_count):
			spawn_bat(enemy_health, enemy_damage)
		
		enemy_health += 1
		enemy_damage += 1

	for c in get_children():
		c.take_turn()


func _process(delta):
	if !turn_started:
		return
	
	var all_enemies_done = true
	for e in self.get_children():
		if e.state != 0:
			all_enemies_done = false
	
	if all_enemies_done:
		turn_started = false
		emit_signal("turn_taken")


func spawn_bat(health=1, damage=1):
	var new_bat = BatScene.instance()
	self.add_child(new_bat)
	new_bat.global_position = Vector2(randi()%800+100, randi()%450+100)
	new_bat.stats.max_health = health
	new_bat.stats.health = health
	new_bat.set_damage(damage)
	new_bat.wanderController.reset_start_position()


func on_enemy_death(position):
	# spawn some loot with random chance
	var chance = 1
	var decider = randi()%10 
	#var num_alive_enemies = 0
	#for c in self.get_children():
	#	if c.is_in_group("enemy"):
	#		num_alive_enemies += 1

	if (decider <= chance):# or num_alive_enemies<=1:
		spawn_loot(position)


func spawn_loot(position):
	var new_loot = LootScene.instance()
	get_parent().call_deferred("add_child", new_loot)
	new_loot.global_position = position
	var rand_select = randi()%len(loot_options)
	new_loot.card_stats_file = loot_options[rand_select]
	new_loot.connect("gained_card", get_parent(), "on_card_collected")


func set_wave_count(value):
	wave_count = value
	emit_signal("wave_changed", wave_count)


func offer_cards(num_cards):
	# select 3 random cards
	var to_offer = []
	for _i in range(num_cards):
		var rand_select = randi()%len(loot_options)
		to_offer.append(loot_options[rand_select])
	
	var offer_scene = OfferScene.instance()
	get_parent().get_node("CanvasLayer").call_deferred("add_child", offer_scene)
	offer_scene.connect("add_card_to_discard", get_parent().get_node("CanvasLayer/Deck"), "add_card_to_discard")
	offer_scene.connect("turn_taken", get_parent(), "take_next_turn")
	get_parent().add_to_turn_order(offer_scene)


func get_wave():
	return wave_count
