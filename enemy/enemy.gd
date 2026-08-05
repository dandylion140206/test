extends Node2D

@onready var hurtbox: Hurtbox = $Hurtbox
@onready var impulse: ImpulseComponent = $ImpulseComponent

var move_velocity: Vector2 = Vector2.ZERO


func _ready() -> void:
	hurtbox.hit_taken.connect(_on_hit_taken)


func _physics_process(delta: float) -> void:


	position += (impulse.get_velocity()) * delta
	impulse.update(delta)

func _on_hit_taken(hit_data: HitData) -> void:
	impulse.add_impulse(hit_data.impulse)
