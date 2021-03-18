extends Control


onready var health_value_label = $HBoxContainer/HealthValue
onready var wave_value_label = $HBoxContainer/WaveValue
onready var enemy_value_label = $HBoxContainer/EnemyValue


func _on_Player_health_changed(new_value):
	if health_value_label:
		health_value_label.text = str(new_value)


func _on_Enemies_wave_changed(wave_number):
	if wave_value_label:
		wave_value_label.text = str(wave_number)


func _on_Enemies_number_enemies_changed(number):
	if enemy_value_label:
		enemy_value_label.text = str(number)
