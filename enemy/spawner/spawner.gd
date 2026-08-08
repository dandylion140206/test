class_name Spawner
extends Node2D

@export var enemy_scene: PackedScene
@export var territory: Territory
@export var crowd_manager: EnemyCrowdManager
@export_range(0, 500, 1) var count: int = 30

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
	enemy.territory = territory

	var parent: Node = spawn_parent if spawn_parent != null else get_parent()
	parent.add_child(enemy)

	enemy.global_position = territory.random_point() if territory != null else global_position
	if _target != null:
		enemy.set_target(_target)
	crowd_manager.register_enemy(enemy)
	enemy.died.connect(despawn)
	return enemy


func despawn(enemy: Enemy) -> void:
	crowd_manager.unregister_enemy(enemy)
	enemy.queue_free()
