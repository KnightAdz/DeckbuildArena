extends Control


var card = null setget set_card
var card_pos = Vector2.ZERO

signal add_card_to_discard(card)

# Called when the node enters the scene tree for the first time.
func _ready():
	var panel = $HBoxContainer/Panel
	card_pos = panel.rect_global_position
	card_pos.x += panel.rect_size.x*0.5
	card_pos.y += panel.rect_size.y*0.67 
	$HBoxContainer/VBoxContainer/Keep.grab_focus()


func set_card(c):
	card = c
	card.global_position = card_pos


func _on_Keep_pressed():
	remove_child(card)
	emit_signal("add_card_to_discard", card)
	self.queue_free()


func _on_Leave_pressed():
	card.queue_free()
	self.queue_free()
