extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_StartGame_pressed():
	get_tree().change_scene("res://Main.tscn")
	self.queue_free()


func _on_HowToPlay_pressed():
	get_tree().change_scene("res://Menus/HowToPlay.tscn")
	self.queue_free()


func _on_Credits_pressed():
	get_tree().change_scene("res://Menus/Credits.tscn")
	self.queue_free()
