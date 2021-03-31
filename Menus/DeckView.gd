extends Control

# Scene that is a card in a control
const CardControlScene = preload("res://Cards/CardControl.tscn")

onready var GridNode = $ScrollContainer/GridContainer

signal card_clicked(card_stats)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass


func add_all_cards():
	for c in Globals.all_cards:
		add_card(c)


func add_card(cardstats_file):
	var new_card = CardControlScene.instance()
	GridNode.add_child(new_card)
	if cardstats_file is CardStats:
		new_card.get_node("Card").set_stats(cardstats_file)
	else:
		new_card.get_node("Card").set_stats(load(cardstats_file))
	new_card.get_node("Card").is_face_up = true
	new_card.hint_tooltip = new_card.get_node("Card").get_name()
	new_card.connect("gui_input", self, "on_card_clicked", [new_card])


func add_list_of_cards(cardstats_filelist):
	for c in cardstats_filelist:
		add_card(c)


func on_card_clicked(event, card):
	if Input.is_action_just_released("click"):
		emit_signal("card_clicked", card.get_node("Card").card_stats)
