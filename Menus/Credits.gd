extends Control


func _on_ToMainMenuButton_pressed():
	get_tree().change_scene("res://Menus/MainMenu.tscn")
	self.queue_free()
