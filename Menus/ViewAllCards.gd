extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	$VBoxContainer/DeckView.add_all_cards()
	$VBoxContainer/DeckView.hide_close()


func _on_ToMainMenuButton_pressed():
	get_tree().change_scene("res://Menus/MainMenu.tscn")
	self.queue_free()
