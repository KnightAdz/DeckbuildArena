extends Control

var idx = 0
onready var order = [$AcceptDialog, $AcceptDialog2, $AcceptDialog3]

func _on_Enemies_advance_tutorial():
	order[idx].visible = true
	if idx == 1:
		show_spacebar_tip()
	idx += 1


func show_spacebar_tip():
	$AcceptDialog4.visible = true
