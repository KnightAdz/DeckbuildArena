extends Area2D

var knockback_vector = Vector2.LEFT
var knockback_strength = 1
export var damage = 1
export var stun = false
var damage_source = Vector2.ZERO
export var active_time = 0.1

func _ready():
	self.deactivate()


func activate(timer_override=null):
	self.monitorable = true
	if timer_override:
		$Timer.start(timer_override)
	else:
		$Timer.start(active_time)


func deactivate():
	self.monitorable = false


func _on_Timer_timeout():
	self.deactivate()


func set_knockback(source=self.global_position, strength=1):
	damage_source = source
	knockback_strength = strength
