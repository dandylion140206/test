class_name Hitbox
extends Area2D

@export_range(0.0, 1000.0, 0.1) var damage: float = 0.0
@export_range(-10000.0, 10000.0, 10.0) var impulse_strength: float = 0.0

var _hit_hurtboxes: Array[Hurtbox] = []


func _ready() -> void:
	area_entered.connect(_on_area_entered)


func _on_area_entered(area: Area2D) -> void:
	var hurtbox := area as Hurtbox
	if hurtbox == null:
		return
	if hurtbox in _hit_hurtboxes:
		return
	_hit_hurtboxes.append(hurtbox)

	hurtbox.take_hit(_build_hit_data(hurtbox))


func _build_hit_data(hurtbox: Hurtbox) -> HitData:
	var hit_data := HitData.new()
	hit_data.damage = damage
	if not is_zero_approx(impulse_strength):
		hit_data.impulse = _impulse_direction(hurtbox) * impulse_strength
	return hit_data


func _impulse_direction(hurtbox: Hurtbox) -> Vector2:
	return (hurtbox.global_position - global_position).normalized()
