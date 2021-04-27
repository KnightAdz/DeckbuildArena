extends Resource
class_name Wave

enum EnemyTypes { BAT, WALKY, MAGE, SLIME, ROCKY }

export(Array, EnemyTypes) var enemies
export(int) var health_addition = 0
export(int) var damage_addition = 0
export(Resource) var next_wave
export(int) var wave_number = 0
