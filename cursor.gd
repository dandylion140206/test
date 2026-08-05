extends Node2D

@export var shockwave_secne: PackedScene
@export var cooldown: float = 0.1

var _can_fire: bool = true


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		if _can_fire:
			_fire_shockwave(get_global_mouse_position())


func _fire_shockwave(spawn_position: Vector2) -> void:
	_can_fire = false

	var shockwave: Shockwave = shockwave_secne.instantiate()
	add_child(shockwave)
	shockwave.global_position = spawn_position

	await get_tree().create_timer(cooldown).timeout
	_can_fire = true
