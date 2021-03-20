extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	$VBoxContainer/Stats.bbcode_text = "[center]"
	$VBoxContainer/Stats.bbcode_text += "You reached Wave number " + str(Globals.wave_number) + "!"
	$VBoxContainer/Stats.bbcode_text += "\nCan you beat that next time?"
	$VBoxContainer/Stats.bbcode_text += "[/center]"


func _on_TryAgainButton_pressed():
	get_tree().change_scene("res://Main.tscn")
	self.queue_free()


func _on_MainMenuButton_pressed():
	get_tree().change_scene("res://Menus/MainMenu.tscn")
	self.queue_free()
