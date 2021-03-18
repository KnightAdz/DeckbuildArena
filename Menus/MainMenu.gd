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
	var main_game = preload("res://Main.tscn").instance()
	get_tree().add_child(main_game)
	self.queue_free()


func _on_HowToPlay_pressed():
	pass # Replace with function body.


func _on_Credits_pressed():
	var credits = preload("res://Menus/Credits.tscn").instance()
	get_tree().add_child(credits)
	self.queue_free()
