extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	$VBoxContainer/HBoxContainer/StartGame.grab_focus()


func _on_StartGame_pressed():
	get_tree().change_scene("res://Main.tscn")
	self.queue_free()


func _on_HowToPlay_pressed():
	get_tree().change_scene("res://Menus/HowToPlay.tscn")
	self.queue_free()


func _on_Credits_pressed():
	get_tree().change_scene("res://Menus/Credits.tscn")
	self.queue_free()


func _on_StartTutorial_pressed():
	var main_scene = load("res://Main.tscn").instance()
	main_scene.load_tutorial()
	get_tree().change_scene_to(main_scene)
	self.queue_free()


func _on_ViewAll_pressed():
	get_tree().change_scene("res://Menus/ViewAllCards.tscn")
	self.queue_free()
