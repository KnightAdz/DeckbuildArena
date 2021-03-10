extends Area2D

var knockback_vector = Vector2.LEFT
export var damage = 1


func _ready():
	self.deactivate()


func activate():
	self.monitorable = true
	$Timer.start(0.1)


func deactivate():
	self.monitorable = false


func _on_Timer_timeout():
	self.deactivate()
