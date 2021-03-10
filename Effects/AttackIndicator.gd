extends Node2D


func point_from_to(point_from, point_to):
	self.global_position = point_from
	var x_length = abs(point_from.x) - abs(point_to.x)
	var scale_x = x_length/$IndicatorArrow.texture.get_width()
	self.scale = Vector2(scale_x, 1)
	var angle = point_from.angle_to_point(point_to)
	self.rotation = angle
	$RichTextLabel.set_rotation(0)
	
func set_value(value):
	$RichTextLabel.text = str(value)
