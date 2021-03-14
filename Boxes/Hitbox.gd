extends Area2D

var knockback_vector = Vector2.LEFT
export var damage = 1
export var active_time = 0.1

func _ready():
	self.deactivate()


func activate():
	self.monitorable = true
	$Timer.start(active_time)


func deactivate():
	self.monitorable = false


func _on_Timer_timeout():
	self.deactivate()
