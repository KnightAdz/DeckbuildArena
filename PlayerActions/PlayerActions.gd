extends Resource
class_name PlayerAction

enum ActionType { MOVE, DEFEND, SHORT_ATTACK, RANGED_ATTACK, AREA_ATTACK }

export(ActionType) var type = ActionType.MOVE

export(int) var movement: = 0
export(int) var attack: = 0
export(int) var defence: = 0
export(int) var healing: = 0
export(int) var max_health_change: = 0

# Attack modifiers
export(int) var knockback = 1
export(bool) var stun_enemy = false
