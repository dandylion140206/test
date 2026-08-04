extends Node2D

const SHOCKWAVE_SCENE: PackedScene = preload("res://shockwave.tscn")

@export var cooldown: float = 0.1

var _can_fire: bool = true


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		if _can_fire:
			_fire_shockwave(get_global_mouse_position())


func _fire_shockwave(pos: Vector2) -> void:
	print("fire")
	_can_fire = false

	var shockwave := SHOCKWAVE_SCENE.instantiate() as Shockwave
	get_tree().current_scene.add_child(shockwave)
	shockwave.global_position = pos

	await get_tree().create_timer(cooldown).timeout
	_can_fire = true
