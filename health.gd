class_name Health
extends Node

signal health_changed(current_health: float, max_health: float)
signal died

var max_health: float = 0.0:
	set(value):
		max_health = maxf(value, 1.0)
		current_health = max_health
var current_health: float = 0.0


func take_damage(amount: float) -> void:
	if amount <= 0.0 or current_health <= 0.0:
		return

	current_health = maxf(current_health - amount, 0.0)
	health_changed.emit(current_health, max_health)
	
	if is_zero_approx(current_health):
		died.emit()
