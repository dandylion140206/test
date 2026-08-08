class_name EnemyStats
extends Resource

@export_range(1.0, 1000.0, 1.0, "or_greater") var max_health: float = 100.0
@export_range(0.01, 100.0, 0.01, "or_greater") var mass: float = 1.0

@export_group("Crowd")
@export_range(0.0, 500.0, 1.0, "or_greater") var body_radius: float = 10.0
@export_range(0.0, 500.0, 1.0, "or_greater") var avoidance_radius: float = 20.0

var inverse_mass: float:
	get: return 1.0 / mass
