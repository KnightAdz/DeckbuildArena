extends Control


onready var health_value_label = $HBoxContainer/HealthValue
onready var wave_value_label = $HBoxContainer/WaveValue


func _on_Player_health_changed(new_value):
	if health_value_label:
		health_value_label.text = str(new_value)


func _on_Enemies_wave_changed(wave_number):
	if wave_value_label:
		wave_value_label.text = str(wave_number)
