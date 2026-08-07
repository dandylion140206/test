class_name Movement
extends Node

@export_group("Wander")
@export_range(0.0, 1000.0, 10.0) var wander_speed: float = 100.0
@export_range(0.0, 5000.0, 10.0) var wander_acceleration: float = 100.0
@export_range(0.0, 16.0, 0.1) var max_turn_rate: float = 5.0
@export_range(0.0, 16.0, 0.1) var wander_noise_frequency: float = 1.0

@export_group("Chase")
@export_range(0.0, 1000.0, 10.0) var chase_speed: float = 180.0
@export_range(0.0, 5000.0, 10.0) var chase_acceleration: float = 200.0
@export_range(0.0, 1.0, 0.01) var chase_jitter: float = 0.5
@export_range(0.0, 16.0, 0.1) var chase_noise_frequency: float = 3.0

@export_group("Bounds")
@export_range(0.0, 500.0, 10.0) var boundary_margin: float = 60.0

var wander_area: SpawnArea = null
var target: Node2D = null

var velocity: Vector2:
	get: return _velocity

var _velocity: Vector2 = Vector2.ZERO
var _heading: float = 0.0
var _elapsed_time: float = 0.0
var _wander_noise := FastNoiseLite.new()
var _chase_noise := FastNoiseLite.new()


func _ready() -> void:
	var noise_seed := randi()
	_setup_noise(_wander_noise, noise_seed, wander_noise_frequency)
	_setup_noise(_chase_noise, noise_seed + 1, chase_noise_frequency)
	_heading = randf_range(0.0, TAU)


func _setup_noise(noise: FastNoiseLite, noise_seed: int, frequency: float) -> void:
	noise.seed = noise_seed
	noise.frequency = frequency
	noise.fractal_octaves = 3


func update(delta: float, global_position: Vector2) -> void:
	_elapsed_time += delta

	var desired_velocity: Vector2
	var acceleration: float

	if is_instance_valid(target):
		desired_velocity = _chase_direction(global_position) * chase_speed
		acceleration = chase_acceleration
	else:
		desired_velocity = _wander_direction(delta, global_position) * wander_speed
		acceleration = wander_acceleration

	if not desired_velocity.is_zero_approx():
		_heading = desired_velocity.angle()

	_velocity = _velocity.move_toward(desired_velocity, acceleration * delta)


func clear() -> void:
	_velocity = Vector2.ZERO


# --- 方向の決定 ---

func _wander_direction(delta: float, global_position: Vector2) -> Vector2:
	var turn := _wander_noise.get_noise_1d(_elapsed_time) * max_turn_rate * delta
	var direction := Vector2.from_angle(_heading + turn)
	return _steer_inward(direction, global_position)


func _chase_direction(global_position: Vector2) -> Vector2:
	var to_target := target.global_position - global_position
	if to_target.is_zero_approx():
		return Vector2.ZERO
	var jitter := _chase_noise.get_noise_1d(_elapsed_time) * chase_jitter
	return Vector2.from_angle(to_target.angle() + jitter)


# --- 境界処理 ---

func _steer_inward(direction: Vector2, global_position: Vector2) -> Vector2:
	if wander_area == null:
		return direction

	var inward := wander_area.inward_vector(global_position, boundary_margin)
	if inward.is_zero_approx():
		return direction

	return direction.slerp(inward.normalized(), minf(inward.length(), 1.0))
