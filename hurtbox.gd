class_name Hurtbox
extends Area2D

signal hit_taken(hit_data: HitData)


func take_hit(hit_data: HitData) -> void:
	hit_taken.emit(hit_data)
