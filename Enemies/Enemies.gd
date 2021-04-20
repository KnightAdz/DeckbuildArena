extends Node2D

var BatScene = preload("res://Enemies/BasicEnemy.tscn")
var WalkyScene = preload("res://Enemies/Walky.tscn")
var MageScene = preload("res://Enemies/ProjectileEnemy.tscn")
var SlimeScene = preload("res://Enemies/Slime.tscn")

var LootScene = preload("res://Loot/Loot.tscn")
var OfferScene = preload("res://Dialogs/CardOffer.tscn")

onready var DeckNode = get_parent().get_node("CanvasLayer/Deck")

var turn_started = false
var enemy_health = 1
var enemy_damage = 1
var num_enemies = 3
var last_enemy_count = 0

var wave_count = 1 setget set_wave_count
var wave_started = true
var next_wave_file = preload("res://Enemies/WaveT1.tres")

var loot_options = Globals.available_cards

signal turn_taken()
signal wave_changed(wave_number)
signal number_enemies_changed(number)
signal wave_complete()
signal new_wave_loaded()
signal completed_tutorial()
signal advance_tutorial()
signal enemy_killed(position)
signal enemy_hurt(position)

func _ready():
	load_wave_from_resource(next_wave_file)


func take_turn():		
	turn_started = true
		
	for c in get_children():
		c.take_turn()

	var children = get_children()
	# If all enemies are killed, we've reached the end of the wave
	if len(children) == 0:
		wave_started = false
		emit_signal("wave_complete")
		offer_cards(3)


func spawn_random_enemies(): 
	var placed_pos = []
	var player = get_parent().get_node("Player")
	placed_pos.append(player.global_position)
	var enemies_to_spawn = min(num_enemies+wave_count,10)
	for _i in range(enemies_to_spawn):
		var safe_position = generate_position(placed_pos)
		if safe_position == null:
			break
		if wave_count <= 2:
			spawn_bat(enemy_health, enemy_damage, safe_position)
		elif wave_count == 3:
			spawn_walky(1,1, safe_position)
		else:
			var enemy_scenes = [BatScene, WalkyScene, MageScene]
			var rand = randi()%len(enemy_scenes)
			spawn_enemy(enemy_scenes[rand], 
						enemy_health, 
						enemy_damage, 
						safe_position)
		placed_pos.append(safe_position)


# Generate a random position that is far enough away from provided positions
func generate_position(placed_pos):
	var safe_dist = 60
	var tries = 1000
	for _i in range(tries):
		var new_pos = Vector2(randi()%800+100, randi()%450+100)
		var safe = true
		for p in placed_pos:
			if p.distance_to(new_pos) < safe_dist:
				safe = false
		if safe:
			return new_pos
	return null


func _process(_delta):
	count_enemies() #not needed every frame
	if !turn_started:
		return
	
	var all_enemies_done = true
	for e in self.get_children():
		if e.is_in_group("enemy"):
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


func spawn_enemy(scene, health=1, damage=1, pos=Vector2.ZERO):
	var new_enemy = scene.instance()
	self.add_child(new_enemy)
	if pos == Vector2.ZERO:
		new_enemy.global_position = Vector2(randi()%800+100, randi()%450+100)
	else:
		new_enemy.global_position = pos
	new_enemy.stats.max_health = health
	new_enemy.stats.health = health
	new_enemy.set_damage(damage)
	new_enemy.wanderController.reset_start_position()
	count_enemies()


func on_enemy_death(position):
	# spawn some loot with random chance
	var chance = 1
	var decider = randi()%10 
	emit_signal("enemy_killed", position)
	count_enemies()

	if (decider <= chance):# or num_alive_enemies<=1:
		spawn_loot(position)


func count_enemies():
	var num_alive_enemies = get_tree().get_nodes_in_group("enemy").size();
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
	Globals.wave_number = value
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


# Triggered by offer scene close signal
func start_next_wave():
	wave_started = true
	self.wave_count += 1
	load_wave_from_resource(next_wave_file)
	
	if wave_count > 2:
		if wave_count%2:
			enemy_health += 1
		else:
			enemy_damage += 1
	
	emit_signal("new_wave_loaded")


func load_wave_from_resource(info):
	if info == null:
		spawn_random_enemies()
		return
	var h = 1 + info.health_addition
	var d = 1 + info.damage_addition
	for e in info.enemies:
		match e:
			info.EnemyTypes.BAT:
				spawn_enemy(BatScene,h,d)
			info.EnemyTypes.WALKY:
				spawn_enemy(WalkyScene,h,d)
			info.EnemyTypes.MAGE:
				spawn_enemy(MageScene,h,d)
			info.EnemyTypes.SLIME:
				spawn_enemy(SlimeScene,h,d)
	next_wave_file = info.next_wave
	self.wave_count = info.wave_number
	if wave_count == 0:
		emit_signal("advance_tutorial")
	if wave_count == 1:
		Globals.completed_tutorial = true
		emit_signal("completed_tutorial")


func despawn_enemies():
	for c in get_children():
		if c.is_in_group("enemy"):
			c.queue_free()


func save_state():
	var n_enemies = count_enemies()
	var wave_file = ""
	if next_wave_file:
		wave_file = next_wave_file.get_path()
	
	var save_dict = {
		"node" : "enemies",
		"wave_number" : wave_count,
		"next_wave_file" : wave_file,
		"num_enemies" : n_enemies,
		"enemy_data" : save_enemies()
	}
	return save_dict


func save_enemies():
	var idx = 0
	var save_dict = { }
	for c in get_children():
		if c.is_in_group("enemy"):
			save_dict["enemy"+str(idx)] = c.get_save_info()
			idx+=1
	return save_dict


func load_state(data):
	despawn_enemies()
	var enemy_data = data["enemy_data"]
	var n_enemies = data["num_enemies"]
	for i in range(0,n_enemies):
		var this_enemy = enemy_data["enemy"+str(i)] 
		spawn_enemy(load(this_enemy["filename"]),
					this_enemy["health"],
					this_enemy["damage"],
					Vector2(this_enemy["global_position.x"],
							this_enemy["global_position.y"]))
	self.wave_count = data["wave_number"]
	if data["next_wave_file"] != "":
		self.next_wave_file = load(data["next_wave_file"])
	else:
		self.next_wave_file = null

func on_enemy_hurt(position):
	emit_signal("enemy_hurt",position)


func _on_player_blinded():
	for e in self.get_children():
		if e.is_in_group("enemy"):
			e.visible = false
