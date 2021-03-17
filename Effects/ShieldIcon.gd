extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	self.visible = false
	

func update_value(new_value):
	if new_value <= 0:
		if self.visible == true:
			pop_out()
	else:
		if self.visible == false:
			self.visible = true
			pop_in()
		else:
			bounce()
	$Label.text = str(new_value)


func pop_in():
	$Tween.interpolate_property(self, "scale", Vector2.ZERO, Vector2(1,1), 0.5, Tween.TRANS_BOUNCE, Tween.EASE_IN)
	$Tween.start()


func pop_out():
	$Tween.interpolate_property(self, "scale", Vector2(1,1), Vector2.ZERO, 0.5, Tween.TRANS_BOUNCE, Tween.EASE_IN)
	$Tween.start()


func bounce():
	$Tween.interpolate_property(self, "scale", Vector2(1.1,1.1), Vector2(1,1), 0.5, Tween.TRANS_BOUNCE, Tween.EASE_IN)
	$Tween.start()


func _on_Tween_tween_completed(_object, _key):
	if self.scale == Vector2.ZERO:
		self.visible = false
