class_name SpawnArea
extends Area2D

## 敵の出現位置と行動範囲を表すエリア。
## 子に CollisionPolygon2D か CollisionShape2D を 1 つ置いて形を編集する。
## 当たり判定には使わないため monitoring / monitorable は無効化する。

const MAX_SAMPLING_ATTEMPTS := 32
const CIRCLE_SEGMENTS := 24

var _global_polygon := PackedVector2Array()
var _bounds := Rect2()
var _cached := false


func _ready() -> void:
	monitoring = false
	monitorable = false
	refresh()


## 実行中に頂点や Transform を変えた場合に呼ぶ
func refresh() -> void:
	_global_polygon = _collect_polygon()
	_bounds = _calculate_bounds()
	_cached = true


## 点が範囲内にあるか
func contains(point: Vector2) -> bool:
	_ensure_cache()
	if _global_polygon.size() < 3:
		return false
	return Geometry2D.is_point_in_polygon(point, _global_polygon)


## 範囲内のランダムな点。棄却法で求め、失敗したら外接矩形の中心を返す
func random_point() -> Vector2:
	_ensure_cache()
	if _global_polygon.size() < 3:
		return global_position

	for i in MAX_SAMPLING_ATTEMPTS:
		var point := Vector2(
			randf_range(_bounds.position.x, _bounds.end.x),
			randf_range(_bounds.position.y, _bounds.end.y)
		)
		if Geometry2D.is_point_in_polygon(point, _global_polygon):
			return point
	return _bounds.get_center()


## 境界から margin 以内なら内向きのベクトルを返す。長さは 0.0〜1.0 の強さ
func inward_vector(point: Vector2, margin: float) -> Vector2:
	_ensure_cache()
	if _global_polygon.size() < 3 or margin <= 0.0:
		return Vector2.ZERO

	var to_boundary := _closest_boundary_point(point) - point
	var distance := to_boundary.length()
	if is_zero_approx(distance):
		return Vector2.ZERO

	if not Geometry2D.is_point_in_polygon(point, _global_polygon):
		return to_boundary / distance
	if distance >= margin:
		return Vector2.ZERO
	return -to_boundary / distance * (1.0 - distance / margin)


# --- 内部処理 ---

func _ensure_cache() -> void:
	if not _cached:
		refresh()


func _collect_polygon() -> PackedVector2Array:
	for child in get_children():
		var polygon_node := child as CollisionPolygon2D
		if polygon_node != null:
			return _to_global_points(polygon_node, polygon_node.polygon)

		var shape_node := child as CollisionShape2D
		if shape_node != null and shape_node.shape != null:
			return _to_global_points(shape_node, _shape_to_points(shape_node.shape))

	push_warning("SpawnArea: CollisionPolygon2D か CollisionShape2D の子が必要です")
	return PackedVector2Array()


static func _to_global_points(node: Node2D, points: PackedVector2Array) -> PackedVector2Array:
	var result := PackedVector2Array()
	for point in points:
		result.append(node.to_global(point))
	return result


static func _shape_to_points(shape: Shape2D) -> PackedVector2Array:
	var rectangle := shape as RectangleShape2D
	if rectangle != null:
		var half := rectangle.size * 0.5
		return PackedVector2Array([
			-half,
			Vector2(half.x, -half.y),
			half,
			Vector2(-half.x, half.y)
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


func _closest_boundary_point(point: Vector2) -> Vector2:
	var count := _global_polygon.size()
	var closest := _global_polygon[0]
	var closest_distance_squared := INF

	for i in count:
		var candidate := Geometry2D.get_closest_point_to_segment(
			point, _global_polygon[i], _global_polygon[(i + 1) % count]
		)
		var distance_squared := point.distance_squared_to(candidate)
		if distance_squared < closest_distance_squared:
			closest_distance_squared = distance_squared
			closest = candidate

	return closest


func _calculate_bounds() -> Rect2:
	if _global_polygon.is_empty():
		return Rect2()

	var bounds := Rect2(_global_polygon[0], Vector2.ZERO)
	for point in _global_polygon:
		bounds = bounds.expand(point)
	return bounds
