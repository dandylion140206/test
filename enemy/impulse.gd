class_name ImpulseComponent
extends Node

@export_range(0.0, 10000.0, 10.0) var max_speed: float = 5000.0
@export_range(0.0, 50.0, 1.0) var damping: float = 20.0
@export_range(0.0, 100.0, 1.0) var stop_threshold: float = 10.0

var _velocity: Vector2 = Vector2.ZERO

func add_impulse(impulse: Vector2) -> void:
	_velocity += impulse

func get_velocity() -> Vector2:
	return _velocity.limit_length(max_speed)

func update(delta: float) -> void:
	_velocity *= exp(-damping * delta)
	if _velocity.length_squared() < stop_threshold * stop_threshold:
		_velocity = Vector2.ZERO

func clear() -> void:
	_velocity = Vector2.ZERO
