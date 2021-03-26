extends Node


func _ready():
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), -10)


var available_cards =  ["res://Cards/Attack&draw1.tres",
					"res://Cards/Attack&move.tres",
					"res://Cards/Attack4.tres",
					"res://Cards/RangedAttack.tres",
					"res://Cards/StrongDefend.tres",
					"res://Cards/AreaAttack.tres",
					"res://Cards/Draw3.tres",
					"res://Cards/Knockback.tres",
					"res://Cards/HealthPotion.tres",
					"res://Cards/DefencePotion.tres",
					"res://Cards/StunAttack.tres",
					"res://Cards/Sprint.tres",
					"res://Cards/StunDart.tres"]

var completed_tutorial = false

# Endgame stats
var wave_number = 0

var save_locaton = "user://savegame.save"
