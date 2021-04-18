extends Control

var idx = 0
onready var order = [$EnemyTip1, $EnemyTip2, $EnemyTip3]
onready var basic = [$BasicTip1, $BasicTip2, $BasicTip3]
var is_shown = [false,false,false]


func _on_Enemies_advance_tutorial():
	order[idx].visible = true
	if idx == 1:
		show_spacebar_tip()
	if idx == 2:
		show_rclick_tip()
	idx += 1


func show_spacebar_tip():
	$ControlTip1.visible = true


func show_rclick_tip():
	$ControlTip2.visible = true


func _on_Player_health_reduced():
	if !is_shown[0]:
		basic[0].visible = true
		is_shown[0] = true


func _on_Deck_card_played(card):
	if !is_shown[1]:
		if card.card_stats.colour == "RED":
			basic[1].visible = true
			is_shown[1] = true


func _on_Enemies_enemy_killed(_position):
	if !is_shown[2]:
		basic[2].visible = true
		is_shown[2] = true
