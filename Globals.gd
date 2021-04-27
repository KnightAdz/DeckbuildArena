extends Node


func _ready():
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), -10)

# cards to earn
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
					"res://Cards/StunDart.tres",
					"res://Cards/Sneak.tres",
					"res://Cards/DoubleDamage2.tres",
					"res://Cards/AbsorbHealth.tres",
					"res://Cards/Evade.tres",
					"res://Cards/Frenzy.tres",
					"res://Cards/MaxHealthUp.tres"]

var completed_tutorial = false

# Endgame stats
var wave_number = 0

var save_location = "user://savegame.save"
var wave_checkpoint_save = "user://wavecheckpoint.save"

# all possible cards
var all_cards =  [	"res://Cards/BasicAttack.tres",
					"res://Cards/BasicDefend.tres",
					"res://Cards/BasicMovement.tres",
					# Reward cards
					"res://Cards/Attack&draw1.tres",
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
					"res://Cards/StunDart.tres",
					"res://Cards/Sneak.tres",
					"res://Cards/DoubleDamage2.tres",
					"res://Cards/AbsorbHealth.tres",
					"res://Cards/Evade.tres",
					"res://Cards/Frenzy.tres",
					"res://Cards/MaxHealthUp.tres",
					# Corruption cards last
					"res://Cards/Blind.tres",
					"res://Cards/Slow.tres"]

var load_wave = false
