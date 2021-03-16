extends Node2D

var BatScene = preload("res://Enemies/Bat.tscn")
var LootScene = preload("res://Loot/Loot.tscn")

onready var DeckNode = get_parent().get_node("CanvasLayer/Deck")

var turn_started = false
var enemy_health = 1
var enemy_damage = 1
var num_enemies = 3

var wave_count = 1 setget set_wave_count


var loot_options = ["res://Cards/Attack&draw1.tres",
					"res://Cards/Attack&move.tres",
					"res://Cards/Attack4.tres",
					"res://Cards/RangedAttack.tres",
					"res://Cards/StrongDefend.tres",
					"res://Cards/AreaAttack.tres"]

signal turn_taken()
signal wave_changed(wave_number)


func _ready():
	for i in range(4):
		spawn_bat()


func take_turn():
	turn_started = true
	var children = get_children()
	if len(children) == 0:
		self.wave_count += 1
		for i in range(num_enemies+wave_count):
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
	# last enemy always spawns loot
	var chance = 1
	var decider = randi()%10 
	var num_alive_enemies = 0
	for c in self.get_children():
		if c.is_in_group("enemy"):
			num_alive_enemies += 1

	if (decider <= chance) or num_alive_enemies<=1:
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
