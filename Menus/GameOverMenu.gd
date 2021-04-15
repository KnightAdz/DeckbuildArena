extends Control

var main_scene = null

# Called when the node enters the scene tree for the first time.
func _ready():
	$VBoxContainer/RestartWave.grab_focus()
	$VBoxContainer/Stats.bbcode_text = "[center]"
	$VBoxContainer/Stats.bbcode_text += "You reached Wave number " + str(Globals.wave_number) + "!"
	$VBoxContainer/Stats.bbcode_text += "\nCan you beat that next time?"
	$VBoxContainer/Stats.bbcode_text += "[/center]"


func _on_MainMenuButton_pressed():
	get_tree().change_scene("res://Menus/MainMenu.tscn")
	self.queue_free()


func _on_RestartGame_pressed():
	get_tree().change_scene("res://Main.tscn")
	self.queue_free()


func _on_RestartWave_pressed():
	#get_tree().get_root().add_child(main_scene)
	#main_scene.load_state(Globals.wave_checkpoint_save)
	#get_tree().get_root().add_child(main_scene)
	#self.queue_free()
	#get_tree().change_scene_to(main_scene)
	Globals.load_wave = true
	get_tree().change_scene("res://Main.tscn")
	self.queue_free()
