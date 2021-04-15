extends Node2D


func _ready():
	$AnimationPlayer.play("Animate")
	$AnimationPlayer.connect("animation_finished", self, "_on_animation_finished")


func _on_animation_finished(_anim):
	queue_free()


func set_text(text):
	$Node2D/Label.text = text
