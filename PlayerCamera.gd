extends Camera2D


# Called when the node enters the scene tree for the first time.
func _ready():
	limit_left = $TopLeftLimit.global_position.x
	limit_top = $TopLeftLimit.global_position.y
	limit_right = $BottomRightLimit.global_position.x
	limit_bottom = $BottomRightLimit.global_position.y

