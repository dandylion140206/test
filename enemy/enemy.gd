class_name Enemy
extends Node2D

signal died

@export var stats: EnemyStats

@onready var hurtbox: Hurtbox = $Hurtbox
@onready var health: Health = $Health
@onready var movement: Movement = $Movement
@onready var impulse: Impulse = $Impulse

var territory: Territory = null


func _ready() -> void:

	health.max_health = stats.max_health
	movement.territory = territory

	hurtbox.hit_taken.connect(_on_hit_taken)
	health.died.connect(_on_died)


func _physics_process(delta: float) -> void:
	movement.update(delta, global_position)
	position += (movement.velocity + impulse.velocity) * delta
	impulse.update(delta)


func set_target(value: Node2D) -> void:
	movement.target = value


func _on_hit_taken(damage: float, impulse_value: Vector2) -> void:
	health.take_damage(damage)
	impulse.add_impulse(impulse_value * stats.inverse_mass)


func _on_died() -> void:
	died.emit(self)
	queue_free()
