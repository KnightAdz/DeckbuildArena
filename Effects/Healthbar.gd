extends Control


func _on_max_health_changed(value):
	$TextureProgress.max_value = value


func _on_health_changed(value):
	$TextureProgress.value = value
