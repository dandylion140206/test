class_name SpawnArea
extends Area2D

## 敵の出現位置と行動範囲を表す領域。
## 子の CollisionPolygon2D か CollisionShape2D で形を編集する。当たり判定には使わない。

const CIRCLE_SEGMENTS := 24
const MAX_SAMPLING_ATTEMPTS := 32

var _polygon := PackedVector2Array()


func _ready() -> void:
	monitoring = false
	monitorable = false
	refresh()


## 実行中に形や Transform を変えた場合に呼ぶ
func refresh() -> void:
	_polygon = _build_polygon()
	assert(_polygon.size() >= 3, "SpawnArea: 3頂点以上の形状を持つ子ノードが必要")


func has_point(point: Vector2) -> bool:
	return Geometry2D.is_point_in_polygon(point, _polygon)


## 範囲内のランダムな点。棄却法で求め、失敗した場合は外接矩形の中心を返す
func random_point() -> Vector2:
	var bounds := _bounds()
	for i in MAX_SAMPLING_ATTEMPTS:
		var point := Vector2(
			randf_range(bounds.position.x, bounds.end.x),
			randf_range(bounds.position.y, bounds.end.y)
		)
		if has_point(point):
			return point
	return bounds.get_center()


## 各辺のうち point に最も近い点
func closest_boundary_point(point: Vector2) -> Vector2:
	var count := _polygon.size()
	var closest := _polygon[0]
	var closest_distance_squared := INF

	for i in count:
		var candidate := Geometry2D.get_closest_point_to_segment(
			point, _polygon[i], _polygon[(i + 1) % count]
		)
		var distance_squared := point.distance_squared_to(candidate)
		if distance_squared < closest_distance_squared:
			closest_distance_squared = distance_squared
			closest = candidate

	return closest


func _build_polygon() -> PackedVector2Array:
	for child in get_children():
		var polygon_node := child as CollisionPolygon2D
		if polygon_node != null:
			return _to_global(polygon_node, polygon_node.polygon)

		var shape_node := child as CollisionShape2D
		if shape_node != null and shape_node.shape != null:
			return _to_global(shape_node, _shape_points(shape_node.shape))

	return PackedVector2Array()


func _bounds() -> Rect2:
	var bounds := Rect2(_polygon[0], Vector2.ZERO)
	for point in _polygon:
		bounds = bounds.expand(point)
	return bounds


static func _to_global(node: Node2D, points: PackedVector2Array) -> PackedVector2Array:
	var node_transform := node.global_transform
	var result := PackedVector2Array()
	for point in points:
		result.append(node_transform * point)
	return result


## NOTE: 円は多角形で近似する。境界の押し戻し方向が段階的になるが実用上は問題ない
static func _shape_points(shape: Shape2D) -> PackedVector2Array:
	var rectangle := shape as RectangleShape2D
	if rectangle != null:
		var half := rectangle.size * 0.5
		return PackedVector2Array([
			-half, Vector2(half.x, -half.y), half, Vector2(-half.x, half.y)
		])

	var circle := shape as CircleShape2D
	if circle != null:
		var points := PackedVector2Array()
		for i in CIRCLE_SEGMENTS:
			points.append(Vector2.from_angle(TAU * i / CIRCLE_SEGMENTS) * circle.radius)
		return points

	var convex := shape as ConvexPolygonShape2D
	if convex != null:
		return convex.points

	push_warning("SpawnArea: 未対応の形状 " + shape.get_class())
	return PackedVector2Array()
