extends Resource
class_name Wave

enum enemies { BAT, WALKY, MAGE }

export(Array, enemies) var enemy_scene_paths
export(int) var health_addition = 0
export(int) var damage_addition = 0
export(Resource) var next_wave
