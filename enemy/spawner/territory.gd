class_name Territory
extends Area2D

## 敵が出現し、徘徊する矩形領域。子の CollisionShape2D で大きさを編集する。
## 検出には使わないため monitoring / monitorable は無効化する。

var bounds: Rect2:
	get:
		var size := _rectangle.size
		return Rect2(_shape.global_position - size * 0.5, size)

@onready var _shape: CollisionShape2D = $CollisionShape2D
@onready var _rectangle: RectangleShape2D = _shape.shape as RectangleShape2D


func _ready() -> void:
	assert(_rectangle != null, "Territory: CollisionShape2D には RectangleShape2D が必要")


func random_point() -> Vector2:
	var area := bounds
	return Vector2(
		randf_range(area.position.x, area.end.x),
		randf_range(area.position.y, area.end.y)
	)
