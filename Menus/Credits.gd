extends Control

const MainMenuScreen = preload("res://Menus/MainMenu.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_ToMainMenuButton_pressed():
	var newscreen = MainMenuScreen.instance()
	get_tree().add_child(newscreen)
	self.queue_free
