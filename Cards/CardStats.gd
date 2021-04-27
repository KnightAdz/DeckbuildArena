extends Resource
class_name CardStats

export(int) var focus_cost: = 1
export(int) var movement: = 0
export(int) var attack: = 0
export(int) var defence: = 0
export(int) var healing: = 0
export(int) var max_health_change: = 0

# Movement modifiers
export(bool) var stealth = false

# Attack modifiers
export(bool) var ranged_attack: = false
export(bool) var area_attack: = false
export(int) var knockback = 1
export(bool) var stun_enemy = false

# Card mechancis
export(int) var cards_to_draw: = 0
export(int) var cards_to_discard: = 0
export(bool) var destroy_after_use = false
export(bool) var one_use_per_wave = false
export(bool) var needs_target = false

# Buffs
export(int) var damage_multiplier = 1
export(int) var damage_multiplier_duration = 1 #num_of_attacks

# Debuffs
export(bool) var blind = false
export(bool) var slow = false

# Action order, only needed if multiple effects
export(Array, Resource) var actions = []

export(Texture) var image
export(String) var text
export(String) var name
export(String) var colour = "RED"
