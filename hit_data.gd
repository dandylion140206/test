class_name HitData
extends RefCounted

var damage: float
var knockback: Vector2


func _init(
	p_damage: float = 0.0,
	p_knockback: Vector2 = Vector2.ZERO
) -> void:
	damage = p_damage
	knockback = p_knockback
