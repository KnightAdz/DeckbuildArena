extends Node2D

export(int) var max_health = 1 setget set_max_health
var health = max_health setget set_health

signal no_health
signal health_changed(value)
signal max_health_changed(value)
signal health_reduced()

func set_health(value):
	if value < health:
		emit_signal("health_reduced")
	health = value
	if health > max_health:
		health = max_health
	emit_signal("health_changed", health)
	if health <= 0:
		emit_signal("no_health")


func set_max_health(value):
	max_health = value
	self.health = min(health, max_health)
	emit_signal("max_health_changed", max_health)


func _ready():
	self.health = max_health


func save_state():
    var save_dict = {
        "node" : "stats",
        "parent" : get_parent().get_path(),
        "health" : health,
        "max_health" : max_health
    }
    return save_dict


