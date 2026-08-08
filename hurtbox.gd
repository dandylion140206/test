class_name Hurtbox
extends Area2D

signal hit_taken(damage: float, impulse: Vector2)


func take_hit(damage: float, impulse: Vector2) -> void:
	hit_taken.emit(damage, impulse)
