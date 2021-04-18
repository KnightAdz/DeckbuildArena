extends Node2D

var MessageScene = preload("res://Effects/TextMessage.tscn")

var total_cards_played = 0

var events_this_card = []
var events_this_turn = []


func _on_Deck_card_played(_card):
	events_this_card = []
	total_cards_played += 1


func _on_Deck_button_pressed():
	events_this_card = []


func on_enemy_hurt(position):
	var event = GameEvent.new()
	event.type = event.EventType.HURT
	event.position = position
	events_this_card.append(event)
	events_this_turn.append(event)
	$Timer.start()


func on_enemy_killed(position):
	var event = GameEvent.new()
	event.type = event.EventType.KILL
	event.position = position
	events_this_card.append(event)
	events_this_turn.append(event)
	$Timer.start()


# Count number of events of a particular type 
# and return the position of the last one
func count_events(array, type):
	var count = 0
	var position = null
	for e in array:
		if e.type == type:
			count += 1
			position = e.position
	return [count, position]


func _on_Timer_timeout():
	var kill_data = count_events(events_this_card, GameEvent.EventType.KILL)
	var enemies_killed = kill_data[0]
	var pos = kill_data[1]
	if enemies_killed > 1:
		create_message(str(enemies_killed) + " KILL!", pos)
	else:
		var hurt_data = count_events(events_this_card, GameEvent.EventType.HURT)
		var enemies_hurt = hurt_data[0]
		pos = hurt_data[1]
		if enemies_hurt > 1:
			create_message(str(enemies_hurt) + " in 1", pos)


func create_message(text, position):
	var new_msg = MessageScene.instance()
	self.add_child(new_msg)
	new_msg.set_text(text)
	new_msg.global_position = position


func _on_Enemies_enemy_hurt(position):
	on_enemy_hurt(position)


func on_turn_ended():
	if 1 == 2:
		var pos = Vector2(ProjectSettings.get_setting("display/window/size/width")*0.8,
							ProjectSettings.get_setting("display/window/size/height")*0.5)
		var kill_data = count_events(events_this_turn, GameEvent.EventType.KILL)
		var enemies_killed = kill_data[0]
		
		if enemies_killed > 1:
			create_message(str(enemies_killed) + " killed in 1 turn", pos)
		else:
			var hurt_data = count_events(events_this_turn, GameEvent.EventType.HURT)
			var enemies_hurt = hurt_data[0]
			if enemies_hurt > 1:
				create_message(str(enemies_hurt) + " in 1 turn", pos)
	events_this_turn = []


func _on_Deck_turn_taken():
	on_turn_ended()
