extends Node2D

var card_stats : CardStats setget set_stats

export(Resource) var card_type = preload("res://Cards/BasicAttack.tres")

var target_position = Vector2.ZERO setget set_target_position
var is_face_up = false setget set_face_up
var is_selected = false
var ignore_input = true

signal card_selected(card)


func _ready():
	self.card_stats = card_type
	$Icon.visible = false
	$Label.visible = false
	$Label2.visible = false
	$CostLabel.visible = false
	$Focus2.visible = false


func set_face_up(value):
	var old_value = is_face_up
	is_face_up = value
	if is_face_up != old_value:
		if value:
			$Background.frame -= 1
			$Icon.visible = true
			$Label.visible = true
			$Label2.visible = true
			$CostLabel.visible = true
			$Focus2.visible = true
			self.scale = Vector2(1,1)
		else:
			$Background.frame += 1
			$Icon.visible = false
			$Label.visible = false
			$Label2.visible = false
			$CostLabel.visible = false
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
		if self.is_face_up:
			$Background.frame -= 1
		
		if card_stats.image is Texture:
			$Icon.texture = card_stats.image


func set_target_position(pos):
	target_position = pos
	$Tween.interpolate_property(self, "global_position", global_position, target_position, 0.5, Tween.TRANS_LINEAR, Tween.EASE_IN)
	$Tween.start()


func _on_Area2D_mouse_entered():
	if is_face_up and !ignore_input:
		$Highlight.visible = true
		self.z_index = 1


func _on_Area2D_mouse_exited():
	if is_face_up and !ignore_input:
		$Highlight.visible = false
		self.z_index = 0


func select_card():
	if is_face_up and !ignore_input and !is_selected:
		# play discard animation
		#self.is_face_up = false
		self.target_position = self.global_position + Vector2(0,-20)
		self.scale = Vector2(1.1,1.1)
		$Highlight.visible = false
		is_selected = true
		emit_signal("card_selected", self)


func _on_Area2D_input_event(_viewport, event, _shape_idx):
	if ignore_input == false:
		if event.is_action_released("click"):
			select_card()


func deselect_card():
	self.target_position = self.global_position + Vector2(0,+20)
	self.scale = Vector2(1,1)
	is_selected = false
