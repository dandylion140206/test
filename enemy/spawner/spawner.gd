class_name Spawner
extends Node2D

@export var enemy_scene: PackedScene
@export var area_size: Vector2 = Vector2(1920, 1080)
@export_range(0, 100, 1) var count: int = 5

@export var spawn_parent: Node
@export var target_path: NodePath

var _target: Node2D = null


func _ready() -> void:
	_target = get_node_or_null(target_path) as Node2D
	for i in count:
		spawn()


func spawn() -> Enemy:
	if enemy_scene == null:
		return null

	var enemy: Enemy = enemy_scene.instantiate()
	enemy.spawn_area = get_area()

	var parent: Node = spawn_parent if spawn_parent != null else get_parent()
	parent.add_child(enemy)

	enemy.global_position = _random_point()
	if _target != null:
		enemy.set_target(_target)
	return enemy


func get_area() -> Rect2:
	return Rect2(global_position - area_size * 0.5, area_size)


func _random_point() -> Vector2:
	var area := get_area()
	return Vector2(
		randf_range(area.position.x, area.end.x),
		randf_range(area.position.y, area.end.y)
	)
