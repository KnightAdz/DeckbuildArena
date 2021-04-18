extends Control


onready var health_value_label = $VBoxContainer/HealthInfo/HealthValue
onready var max_health_value_label = $VBoxContainer/HealthInfo/MaxHealth
onready var wave_value_label = $VBoxContainer/WaveInfo/WaveValue
onready var enemy_value_label = $VBoxContainer/EnemyInfo/EnemyValue

var enemy_count = 0

var enemies_alive = 0
var cards_played = 0
var last_enemies_alive = 0
var last_cards_played = 0

signal toggle_music(value)

func _on_Player_health_changed(new_value):
	if health_value_label:
		health_value_label.text = str(new_value)
		if new_value <= 1:
			enemy_value_label.modulate = Color.red
		else:
			enemy_value_label.modulate = Color.white


func _on_Enemies_wave_changed(wave_number):
	if wave_value_label:
		wave_value_label.text = str(wave_number)


func _on_Enemies_number_enemies_changed(number):
	enemy_count = number
	if enemy_value_label:
		enemy_value_label.text = str(number)
		if number <= 0:
			enemy_value_label.modulate = Color.green
		else:
			enemy_value_label.modulate = Color.white


func _on_Player_max_health_changed(new_value):
	if max_health_value_label:
		max_health_value_label.text = str(new_value)


func _on_Deck_card_played(_card):
	# keep track of enemies as cards are played 
	# so that we can make the player feel good
	last_cards_played = cards_played
	cards_played += 1
	last_enemies_alive = enemies_alive


# Signal connected from player
func _on_Player_is_idle():
	enemies_alive = enemy_count
	# if we have killed something since last idle
	if enemies_alive < last_enemies_alive:
		action_message("Kill")


func action_message(text):
	$ActionMessage.text = text
	$ActionMessage.visible = true
	$Tween.interpolate_property($ActionMessage,
								"rect_position",
								$ActionMessage.rect_position,
								Vector2($ActionMessage.rect_position.x,
									$ActionMessage.rect_position.y - 30),
								0.3,
								Tween.TRANS_BACK,
								Tween.EASE_OUT)
	$Tween.start()


func reset_action_message():
	$ActionMessage.visible = false
	#$ActionMessage.position = Vector2(	$ActionMessage.rect_position.x,
	#									$ActionMessage.rect_position.y + 30)


func _on_Tween_tween_all_completed():
	reset_action_message()


func _on_MusicButton_toggled(button_pressed):
	emit_signal("toggle_music", button_pressed)


func turn_message_animation(text):
	$TurnMessage.text = text
	$TurnMessage.visible = true
	$Timer.start()


func _on_Timer_timeout():
	$TurnMessage.visible = false
