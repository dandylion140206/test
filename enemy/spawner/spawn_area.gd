class_name SpawnArea
extends Area2D

## 多角形の行動範囲。子の CollisionPolygon2D を多角形編集ツールで編集する。
## 検出には使わないため monitoring / monitorable は無効化する。

const MAX_SAMPLING_ATTEMPTS := 32

@onready var _shape: CollisionPolygon2D = $CollisionPolygon2D

var _global_polygon := PackedVector2Array()
var _bounds := Rect2()


func _ready() -> void:
	monitoring = false
	monitorable = false
	refresh()


## 実行中に頂点や Transform を変えた場合に呼ぶ
func refresh() -> void:
	_global_polygon = PackedVector2Array()
	if _shape == null:
		return
	for point in _shape.polygon:
		_global_polygon.append(_shape.to_global(point))
	_bounds = _calculate_bounds()
