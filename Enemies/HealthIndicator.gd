extends Node2D


var health = 1
var max_health = 1
var size = 7
var gap = 1

# Called when the node enters the scene tree for the first time.
#func _ready():
#	health = get_parent().stats.health
#	max_health = get_parent().stats.max_health

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	update()


func _draw():
	for i in range(health):
		var r = Rect2(	position.x + i*(size+gap), 
						position.y, 
						size, 
						size)
		draw_rect(r,Color.green)


func _on_Stats_health_changed(value):
	health = value
