class_name Hitbox
extends Area2D

@export_range(0.0, 1000.0, 0.1) var damage: float = 0.0
@export_range(-5000.0, 5000.0, 10.0) var impulse_strength: float = 0.0


func _ready() -> void:
	area_entered.connect(_on_area_entered)


func _on_area_entered(area: Area2D) -> void:
	var hurtbox := area as Hurtbox
	if hurtbox == null:
		return

	_hit(hurtbox, _impulse_direction(hurtbox))


func _hit(hurtbox: Hurtbox, impulse_direction: Vector2) -> void:
	hurtbox.take_hit(
		_calculate_damage(hurtbox),
		_calculate_impulse(hurtbox, impulse_direction)
	)


func _calculate_damage(_hurtbox: Hurtbox) -> float:
	return damage


func _calculate_impulse(_hurtbox: Hurtbox, impulse_direction: Vector2) -> Vector2:
	if is_zero_approx(impulse_strength):
		return Vector2.ZERO
	return impulse_direction * impulse_strength


func _impulse_direction(hurtbox: Hurtbox) -> Vector2:
	return (hurtbox.global_position - global_position).normalized()
