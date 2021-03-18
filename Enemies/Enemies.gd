extends Node2D

var BatScene = preload("res://Enemies/BasicEnemy.tscn")
var WalkyScene = preload("res://Enemies/Walky.tscn")
var LootScene = preload("res://Loot/Loot.tscn")
var OfferScene = preload("res://Dialogs/CardOffer.tscn")

onready var DeckNode = get_parent().get_node("CanvasLayer/Deck")
onready var player = get_parent().get_node("Player")

var turn_started = false
var enemy_health = 1
var enemy_damage = 1
var num_enemies = 3

var wave_count = 1 setget set_wave_count
var wave_started = true

var loot_options = Globals.available_cards

signal turn_taken()
signal wave_changed(wave_number)
signal number_enemies_changed(number)


func _ready():
	pass


func take_turn():
	if wave_started == false:
		emit_signal("turn_taken")
		return
		
	turn_started = true
		
	for c in get_children():
		c.take_turn()

	var children = get_children()
	# If all enemies are killed, we've reached the end of the wave
	if len(children) == 0:
		wave_started = false
		offer_cards(3)
		

func spawn_enemies(): 
	var placed_pos = []
	placed_pos.append(player.global_position)
	for _i in range(num_enemies+wave_count):
		var safe_position = generate_position(placed_pos)
		if safe_position == null:
			break
		if wave_count <= 2:
			spawn_bat(enemy_health, enemy_damage, safe_position)
		elif wave_count == 3:
			spawn_walky(1,1, safe_position)
		else:
			var rand = randi()%2
			if rand:
				spawn_bat(enemy_health, enemy_damage, safe_position)
			else:
				spawn_walky(enemy_health, enemy_damage, safe_position)
		placed_pos.append(safe_position)


# Generate a random position that is far enough away from provided positions
func generate_position(placed_pos):
	var safe_dist = 60
	var tries = 1000
	for i in range(tries):
		var new_pos = Vector2(randi()%800+100, randi()%450+100)
		var safe = true
		for p in placed_pos:
			if p.distance_to(new_pos) < safe_dist:
				safe = false
		if safe:
			return new_pos
	return null


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


func spawn_bat(health=1, damage=1, pos=Vector2.ZERO):
	var new_bat = BatScene.instance()
	self.add_child(new_bat)
	if pos == Vector2.ZERO:
		new_bat.global_position = Vector2(randi()%800+100, randi()%450+100)
	else:
		new_bat.global_position = pos
	new_bat.stats.max_health = health
	new_bat.stats.health = health
	new_bat.set_damage(damage)
	new_bat.wanderController.reset_start_position()
	count_enemies()


func spawn_walky(health=1, damage=1, pos=Vector2.ZERO):
	var new_walky = WalkyScene.instance()
	self.add_child(new_walky)
	if pos == Vector2.ZERO:
		new_walky.global_position = Vector2(randi()%800+100, randi()%450+100)
	else:
		new_walky.global_position = pos
	new_walky.stats.max_health = health
	new_walky.stats.health = health
	new_walky.set_damage(damage)
	new_walky.wanderController.reset_start_position()
	count_enemies()


func on_enemy_death(position):
	# spawn some loot with random chance
	var chance = 1
	var decider = randi()%10 
	
	count_enemies()

	if (decider <= chance):# or num_alive_enemies<=1:
		spawn_loot(position)


func count_enemies():
	var num_alive_enemies = 0
	var children = self.get_children()
	for c in children:
		if c.is_in_group("enemy"):
			num_alive_enemies += 1
	num_alive_enemies -= 1
	emit_signal("number_enemies_changed", num_alive_enemies)
	return num_alive_enemies


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
	offer_scene.connect("turn_taken", get_parent(), "start_next_wave")
	offer_scene.connect("turn_taken", self, "start_next_wave")
	get_parent().add_to_turn_order(offer_scene)


func get_wave():
	return wave_count


func start_next_wave():
	wave_started = true
	self.wave_count += 1
	spawn_enemies()
	
	if wave_count > 2:
		enemy_health += 1
		enemy_damage += 1

