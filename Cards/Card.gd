extends Node2D

var card_stats : CardStats setget set_stats

export(Resource) var card_type = preload("res://Cards/BasicAttack.tres")

var target_position = Vector2.ZERO setget set_target_position
var is_face_up = false setget set_face_up
var is_selected = false
var ignore_input = true
var non_highlighted_position = Vector2.ZERO
var play_pos = Vector2(0.5*ProjectSettings.get_setting("display/window/size/width"),
		0.70*ProjectSettings.get_setting("display/window/size/height"))

signal card_selected(card)
signal card_highlighted(card)
signal card_unhighlighted(card)
signal card_played(card)

func _ready():
	self.card_stats = card_type
	$Icon.visible = false
	$Label.visible = false
	$Label2.visible = false
	$CostLabel.visible = false
	$Focus2.visible = false
	non_highlighted_position = global_position


func set_face_up(value):
	var old_value = is_face_up
	is_face_up = value
	if is_face_up != old_value:
		if value:
			$Background.frame -= 1
			$Icon.visible = true
			$Label.visible = true
			$Label2.visible = true
			#$CostLabel.visible = true
			$Focus2.visible = true
			self.scale = Vector2(1,1)
		else:
			$Background.frame += 1
			$Icon.visible = false
			$Label.visible = false
			$Label2.visible = false
			#$CostLabel.visible = false
			$Focus2.visible = false
			self.scale = Vector2(0.5,0.5)


func set_stats(stats):
	if stats is CardStats:
		card_stats = stats
		$Label.text = str(card_stats.name)
		$Label2.text = str(card_stats.text)
		$CostLabel.text = str(card_stats.focus_cost)
		match card_stats.colour:
			'BLUE':
				$Background.frame = 1
			'GREEN':
				$Background.frame = 3
			'RED':
				$Background.frame = 5
			'PURPLE':
				$Background.frame = 7
		if self.is_face_up:
			$Background.frame -= 1
		
		if card_stats.image is Texture:
			$Icon.texture = card_stats.image


func set_target_position(pos):
	target_position = pos
	$Tween.interpolate_property(self, "global_position", global_position, target_position, 0.4, Tween.TRANS_LINEAR, Tween.EASE_IN)
	$Tween.start()


func _on_Area2D_mouse_entered():
	if is_face_up and !ignore_input:
		emit_signal("card_highlighted", self)		
		# Will signal to deck and deck will confirm if highlighted


func _on_Area2D_mouse_exited():
	if is_face_up and !ignore_input:
		emit_signal("card_unhighlighted", self)
		highlight_card(false)


func highlight_card(bool_value, discard=false):
	if bool_value:
		#if global_position == target_position:
		#	self.non_highlighted_position = global_position
		#self.target_position.y -= 40
		$Highlight.visible = true
		self.z_index = 1
		toggle_tool_tips(true)
		animate_sheen()
		show_discard_indicator(discard)
	else:
		#if self.non_highlighted_position:
		#	self.target_position = self.non_highlighted_position
		$Highlight.visible = false
		self.z_index = 0
		toggle_tool_tips(false)
		show_discard_indicator(discard)


func select_card():
	if is_face_up and !ignore_input and !is_selected:
		self.scale = Vector2(1.1,1.1)
		$Highlight.visible = false
		is_selected = true
		emit_signal("card_selected", self)


func _on_Area2D_input_event(_viewport, event, _shape_idx):
	if ignore_input == false:
		if event.is_action_released("click"):
			select_card()
		if event.is_action_pressed("rclick"):
			focus_on_card()


func deselect_card():
#	self.target_position = self.global_position + Vector2(0,+20)
	self.scale = Vector2(1,1)
	is_selected = false
	

func toggle_tool_tips(value):
	if value:
		pass
	else:
		pass


func focus_on_card():
	self.global_position.y = ProjectSettings.get_setting("display/window/size/height") - 90


func get_name():
	return card_stats.name


func animate_sheen():
	$SheenAnimation.visible = true
	$SheenAnimation.frame = 0
	$SheenAnimation.play("default")


func _on_SheenAnimation_animation_finished():
	$SheenAnimation.visible = false
	if global_position == play_pos:
		emit_signal("card_played", self)



func show_discard_indicator(value):
	$DiscardIndicator.visible = value


func play_card_animation(final_pos):
	self.ignore_input = true
	self.z_index = 2
#	$Tween.interpolate_property(self, 
#								"global_position", 
#								global_position, 
#								centre_pos,
#								0.2,
#								Tween.TRANS_BACK,
#								Tween.EASE_IN)
#	$Tween.start()
	self.target_position = play_pos
	$Tween.interpolate_property(self, 
								"rotation_degrees",
								rotation_degrees,
								0,
								0.15,
								Tween.TRANS_BACK,
								Tween.EASE_IN
								)
#	$AnimationPlayer.play("playcard")


func _on_Tween_tween_completed(object, key):
	if global_position == play_pos:
		animate_sheen()
