class_name VelocityComposer
extends RefCounted

const SUSTAINED_GRACE_FRAMES: int = 1

var intent_velocity: Vector2 = Vector2.ZERO
var default_duration: float = 0.2
var default_transition_type: Tween.TransitionType = Tween.TRANS_QUAD
var default_ease_type: Tween.EaseType = Tween.EASE_OUT

var _impulses: Array[Impulse] = []
var _sustained_velocity: Vector2 = Vector2.ZERO
var _sustained_frame: int = -1


func add_impulse(velocity: Vector2, duration: float = -1.0) -> void:
	_impulses.append(Impulse.new(
		velocity,
		duration if duration > 0.0 else default_duration,
		default_transition_type,
		default_ease_type
	))


func add_sustained(velocity: Vector2) -> void:
	var frame := Engine.get_physics_frames()
	if frame != _sustained_frame:
		_sustained_velocity = Vector2.ZERO
		_sustained_frame = frame

	_sustained_velocity += velocity


func step(delta: float) -> Vector2:
	var result := intent_velocity + _consume_sustained()

	for i in range(_impulses.size() - 1, -1, -1):
		var impulse := _impulses[i]
		impulse.advance(delta)
		if impulse.is_finished():
			_impulses.remove_at(i)
		else:
			result += impulse.current_velocity()

	return result


func _consume_sustained() -> Vector2:
	var age := Engine.get_physics_frames() - _sustained_frame
	return _sustained_velocity if age <= SUSTAINED_GRACE_FRAMES else Vector2.ZERO


class Impulse extends RefCounted:
	var initial_velocity: Vector2
	var duration: float
	var transition_type: Tween.TransitionType
	var ease_type: Tween.EaseType
	var elapsed: float = 0.0

	func _init(
		p_velocity: Vector2,
		p_duration: float,
		p_transition_type: Tween.TransitionType,
		p_ease_type: Tween.EaseType
	) -> void:
		assert(p_duration > 0.0, "duration must be positive.")
		initial_velocity = p_velocity
		duration = p_duration
		transition_type = p_transition_type
		ease_type = p_ease_type

	func advance(delta: float) -> void:
		elapsed = minf(elapsed + delta, duration)

	func current_velocity() -> Vector2:
		return initial_velocity * _remaining_ratio()

	func is_finished() -> bool:
		return elapsed >= duration

	# 開始時 1.0、終了時 0.0 になる減衰係数
	func _remaining_ratio() -> float:
		var elapsed_ratio: float = Tween.interpolate_value(
			0.0, 1.0, elapsed, duration, transition_type, ease_type
		)
		return 1.0 - elapsed_ratio
