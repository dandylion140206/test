class_name Ball
extends Hitbox

enum HitstopPhase {
	READY,
	STOPPED,
	RECOVERY,
}

@export_group("Ball")
@export_range(1.0, 100.0, 1.0, "or_greater") var radius: float = 24.0

@export_group("Movement")
@export_range(100.0, 10000.0, 100.0) var target_speed: float = 6000.0
@export_range(100.0, 20000.0, 100.0) var acceleration: float = 10000.0
@export_range(100.0, 20000.0, 100.0) var max_speed: float = 7000.0

@export_group("Hit")
@export_range(0.0, 1.0, 0.001, "or_greater") var damage_per_speed: float = 0.02
@export_range(0.0, 10.0, 0.05, "or_greater") var impulse_per_speed: float = 1.0

var velocity: Vector2 = Vector2.ZERO
var _shape := CircleShape2D.new()
var _contact_hurtboxes: Array[Hurtbox] = []
var _hitstop_phase := HitstopPhase.READY

@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var shape_cast: ShapeCast2D = $ShapeCast2D
@onready var visual: Visual = $Visual


func _ready() -> void:
	collision.shape = _shape
	shape_cast.shape = _shape
	shape_cast.add_exception(self)
	_shape.radius = radius
	visual.radius = radius
	global_position = get_global_mouse_position()


func _physics_process(delta: float) -> void:
	var can_start_hitstop := _hitstop_phase == HitstopPhase.READY
	if _hitstop_phase == HitstopPhase.STOPPED:
		_hitstop_phase = HitstopPhase.RECOVERY
		return
	if _hitstop_phase == HitstopPhase.RECOVERY:
		_hitstop_phase = HitstopPhase.READY

	var to_cursor := get_global_mouse_position() - global_position

	if to_cursor.is_zero_approx():
		velocity = velocity.move_toward(Vector2.ZERO, acceleration * delta)
	else:
		var target_velocity := to_cursor.normalized() * target_speed
		velocity = velocity.move_toward(target_velocity, acceleration * delta).limit_length(max_speed)

	var motion := velocity * delta
	var did_hit := _cast_hits(motion)
	global_position += motion
	if can_start_hitstop and did_hit:
		_hitstop_phase = HitstopPhase.STOPPED


func _calculate_damage(_hurtbox: Hurtbox) -> float:
	return damage + velocity.length() * damage_per_speed


func _calculate_impulse(_hurtbox: Hurtbox, impulse_direction: Vector2) -> Vector2:
	var speed := velocity.length()
	if is_zero_approx(speed):
		return Vector2.ZERO
	return impulse_direction * (impulse_strength + speed * impulse_per_speed)


func _cast_hits(motion: Vector2) -> bool:
	shape_cast.target_position = motion
	shape_cast.force_shapecast_update()

	var current_hurtboxes: Array[Hurtbox] = []
	var impact_fraction := shape_cast.get_closest_collision_unsafe_fraction()
	var impact_position := global_position + motion * impact_fraction
	var did_hit := false

	for collision_index in shape_cast.get_collision_count():
		var hurtbox := shape_cast.get_collider(collision_index) as Hurtbox
		if hurtbox == null or hurtbox in current_hurtboxes:
			continue
		current_hurtboxes.append(hurtbox)

		if hurtbox in _contact_hurtboxes:
			continue
		var impulse_direction := (hurtbox.global_position - impact_position).normalized()
		if impulse_direction.is_zero_approx():
			impulse_direction = -shape_cast.get_collision_normal(collision_index)
		_hit(hurtbox, impulse_direction)
		did_hit = true

	_contact_hurtboxes = current_hurtboxes
	return did_hit
