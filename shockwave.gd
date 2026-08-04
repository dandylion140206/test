class_name Shockwave
extends Area2D

@export var max_radius: float = 200.0
@export var expand_time: float = 0.2
@export var transition_type := Tween.TRANS_QUAD
@export var ease_type := Tween.EASE_OUT

@export var damage: float = 10.0
@export var knockback_strength: float = 10.0

@onready var _collision: CollisionShape2D = $CollisionShape2D
@onready var _visual: ShockwaveVisual = $ShockwaveVisual

var _shape := CircleShape2D.new()
var _hit_hurtboxes: Array[Hurtbox] = []

var radius: float = 0.0:
	set(value):
		radius = maxf(value, 0.0)
		_shape.radius = maxf(radius, 0.01)

var visual_radius: float = 0.0:
	set(value):
		visual_radius = maxf(value, 0.0)
		_visual.set_radius(visual_radius)


func _ready() -> void:
	_collision.shape = _shape
	radius = 0.0
	visual_radius = 0.0
	area_entered.connect(_on_area_entered)

	var physics_tween := create_tween()
	physics_tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	physics_tween.tween_property(self, "radius", max_radius, expand_time) \
		.set_trans(transition_type).set_ease(ease_type)
	physics_tween.tween_callback(queue_free)

	var visual_tween := create_tween()
	visual_tween.tween_property(self, "visual_radius", max_radius, expand_time) \
		.set_trans(transition_type).set_ease(ease_type)


func _on_area_entered(area: Area2D) -> void:
	if not area is Hurtbox:
		return

	var hurtbox := area as Hurtbox

	if hurtbox in _hit_hurtboxes:
		return

	_hit_hurtboxes.append(hurtbox)

	var direction := (hurtbox.global_position - global_position).normalized()
	var hit_data := HitData.new(damage, direction * knockback_strength)
	hurtbox.receive_hit(hit_data)
