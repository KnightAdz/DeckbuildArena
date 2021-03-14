extends Node2D

var BatScene = preload("res://Enemies/Bat.tscn")
var LootScene = preload("res://Loot/Loot.tscn")

onready var DeckNode = get_parent().get_node("CanvasLayer/Deck")

var turn_started = false
var enemy_health = 1

var loot_options = ["res://Cards/Attack&draw1.tres",
					"res://Cards/Attack&move.tres",
					"res://Cards/Attack4.tres",
					"res://Cards/RangedAttack.tres",
					"res://Cards/StrongDefend.tres"]

signal turn_taken()


func take_turn():
	turn_started = true
	var children = get_children()
	if len(children) < 3:
		spawn_bat()
		
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


func spawn_bat():
	var new_bat = BatScene.instance()
	self.add_child(new_bat)
	new_bat.global_position = Vector2(randi()%500, randi()%500)
	new_bat.stats.max_health = enemy_health
	new_bat.stats.health = enemy_health
	enemy_health += 1
	new_bat.wanderController.reset_start_position()


func on_enemy_death(position):
	# spawn some loot
	var new_loot = LootScene.instance()
	get_parent().call_deferred("add_child", new_loot)
	new_loot.global_position = position
	var rand_select = randi()%len(loot_options)
	new_loot.card_stats_file = loot_options[rand_select]
	new_loot.connect("gained_card", get_parent(), "on_card_collected")
