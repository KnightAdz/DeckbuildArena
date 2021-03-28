extends Control


onready var health_value_label = $VBoxContainer/HealthInfo/HealthValue
onready var max_health_value_label = $VBoxContainer/HealthInfo/MaxHealth
onready var wave_value_label = $VBoxContainer/WaveInfo/WaveValue
onready var enemy_value_label = $VBoxContainer/EnemyInfo/EnemyValue


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
	if enemy_value_label:
		enemy_value_label.text = str(number)
		if number <= 0:
			enemy_value_label.modulate = Color.green
		else:
			enemy_value_label.modulate = Color.white


func _on_Player_max_health_changed(new_value):
	if max_health_value_label:
		max_health_value_label.text = str(new_value)
