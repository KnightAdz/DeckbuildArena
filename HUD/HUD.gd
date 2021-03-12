extends Control


onready var health_value_label = $HBoxContainer/HealthValue


func _on_Player_health_changed(new_value):
	if health_value_label:
		health_value_label.text = str(new_value)
