class_name Shockwave
extends Hitbox

@export var max_radius: float = 200.0
@export var expand_time: float = 0.2
@export var transition_type := Tween.TRANS_QUAD
@export var ease_type := Tween.EASE_OUT

@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var visual: ShockwaveVisual = $ShockwaveVisual

var _shape := CircleShape2D.new()

var radius: float = 0.0:
	set(value):
		radius = maxf(value, 0.0)
		_shape.radius = maxf(radius, 0.01)

var visual_radius: float = 0.0:
	set(value):
		visual_radius = maxf(value, 0.0)
		visual.set_radius(visual_radius)


func _ready() -> void:
	super()
	collision.shape = _shape
	radius = 0.0
	visual_radius = 0.0

	var physics_tween := create_tween()
	physics_tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	physics_tween.tween_property(self, "radius", max_radius, expand_time) \
		.set_trans(transition_type).set_ease(ease_type)
	physics_tween.tween_callback(queue_free)

	var visual_tween := create_tween()
	visual_tween.tween_property(self, "visual_radius", max_radius, expand_time) \
		.set_trans(transition_type).set_ease(ease_type)
