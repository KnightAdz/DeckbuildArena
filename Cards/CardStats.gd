extends Resource
class_name CardStats

export(int) var focus_cost: = 1
export(int) var movement: = 0
export(int) var attack: = 0
export(int) var defence: = 0
export(bool) var ranged_attack: = false
export(bool) var area_attack: = false
export(int) var cards_to_draw: = 0
export(int) var cards_to_discard: = 0
export(bool) var needs_target = false
export(Texture) var image
export(String) var text
export(String) var name
export(String) var colour = "RED"
