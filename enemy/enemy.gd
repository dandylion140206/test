class_name Enemy
extends Node2D

@export var stats: EnemyStats

@onready var hurtbox: Hurtbox = $Hurtbox
@onready var movement: Movement = $Movement
@onready var impulse: Impulse = $Impulse

var territory: Territory = null


func _ready() -> void:
	hurtbox.hit_taken.connect(_on_hit_taken)
	movement.territory = territory


func _physics_process(delta: float) -> void:
	movement.update(delta, global_position)
	position += (movement.velocity + impulse.velocity) * delta
	impulse.update(delta)


func set_target(value: Node2D) -> void:
	movement.target = value


func _on_hit_taken(hit_data: HitData) -> void:
	impulse.add_impulse(hit_data.impulse * stats.inverse_mass)
