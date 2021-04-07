extends Node2D

var MessageScene = preload("res://Effects/TextMessage.tscn")

var events_this_card = []
var events_this_turn = []

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func _on_Deck_card_played():
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
	var enemies_killed = count_events(events_this_card, GameEvent.EventType.KILL)
	if enemies_killed[0] > 1:
		create_message(str(enemies_killed[0]) + " in 1", enemies_killed[1])


func create_message(text, position):
	var new_msg = MessageScene.instance()
	self.add_child(new_msg)
	new_msg.set_text(text)
	new_msg.global_position = position
