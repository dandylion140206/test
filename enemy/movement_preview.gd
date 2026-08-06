@tool
extends Node2D

# FastNoiseLite の挙動を確認するための独立プレビュー。
# 専用シーンに Node2D を1つ置いてこのスクリプトを付けるだけで動作する。
#
# frequency はリソース側のインスペクタだと 1.0 が上限になるため、
# スクリプトの @export から毎回リソースへ書き込んでいる。

const IMAGE_PANEL := Vector2(160, 160)
const WAVE_PANEL := Vector2(360, 160)
const PATH_PANEL := Vector2(540, 260)
const GAP := 28.0
const TEXTURE_SIZE := 128

const COLOR_BG := Color(0.09, 0.09, 0.11, 0.9)
const COLOR_FRAME := Color(1, 1, 1, 0.25)
const COLOR_GUIDE := Color(1, 1, 1, 0.15)
const COLOR_WANDER := Color(0.45, 0.9, 0.6)
const COLOR_CHASE := Color(1.0, 0.65, 0.3)
const COLOR_TEXT := Color(1, 1, 1, 0.7)

@export var wander_noise: FastNoiseLite
@export var chase_noise: FastNoiseLite

@export_group("Preview")
@export_range(1.0, 120.0, 0.5) var duration: float = 60.0
@export_range(10, 240, 10) var samples_per_second: int = 60
@export_range(0.0, 360.0, 1.0) var start_angle_degrees: float = 0.0

@export_group("Wander")
## リソース側の上限 1.0 を無視して設定できる
@export_range(0.0, 20.0, 0.1) var wander_noise_frequency: float = 1.0
@export_range(0.0, 1000.0, 10.0) var wander_speed: float = 100.0
@export_range(0.0, 5000.0, 10.0) var wander_acceleration: float = 200.0
@export_range(0.0, 16.0, 0.1) var max_turn_rate: float = 5.0
@export var bounds_size: Vector2 = Vector2(1920, 1080)
@export_range(0.0, 500.0, 10.0) var boundary_margin: float = 60.0

@export_group("Chase")
## リソース側の上限 1.0 を無視して設定できる
@export_range(0.0, 20.0, 0.1) var chase_noise_frequency: float = 4.0
@export_range(0.0, 1000.0, 10.0) var chase_speed: float = 180.0
@export_range(0.0, 5000.0, 10.0) var chase_acceleration: float = 600.0
@export_range(0.0, 1.0, 0.01) var chase_jitter: float = 0.5
@export_range(100.0, 3000.0, 50.0) var chase_distance: float = 800.0

var _texture: ImageTexture = null
var _wander_path := PackedVector2Array()
var _chase_path := PackedVector2Array()
var _chase_arrival_time: float = -1.0
var _snapshot: Array = []


# --- 初期化 ---

func _ready() -> void:
	if wander_noise == null:
		wander_noise = _create_noise()
	if chase_noise == null:
		chase_noise = _create_noise()
	_rebuild()


func _create_noise() -> FastNoiseLite:
	var noise := FastNoiseLite.new()
	noise.fractal_octaves = 1
	return noise


# --- 更新 ---

func _process(_delta: float) -> void:
	var snapshot := _make_snapshot()
	if snapshot != _snapshot:
		_snapshot = snapshot
		_rebuild()


func _make_snapshot() -> Array:
	return [
		_noise_snapshot(wander_noise),
		_noise_snapshot(chase_noise),
		duration, samples_per_second, start_angle_degrees,
		wander_noise_frequency, wander_speed, wander_acceleration, max_turn_rate,
		bounds_size, boundary_margin,
		chase_noise_frequency, chase_speed, chase_acceleration, chase_jitter, chase_distance,
	]


func _noise_snapshot(noise: FastNoiseLite) -> Array:
	if noise == null:
		return []
	return [
		noise.seed, noise.noise_type,
		noise.fractal_type, noise.fractal_octaves,
		noise.fractal_lacunarity, noise.fractal_gain,
	]


func _rebuild() -> void:
	if wander_noise == null or chase_noise == null:
		return
	_apply_frequency(wander_noise, wander_noise_frequency)
	_apply_frequency(chase_noise, chase_noise_frequency)
	_texture = _build_texture()
	_wander_path = _simulate_wander(Rect2(-bounds_size * 0.5, bounds_size))
	_chase_path = _simulate_chase(Vector2(chase_distance, 0.0))
	queue_redraw()


func _apply_frequency(noise: FastNoiseLite, frequency: float) -> void:
	if noise == null:
		return
	if not is_equal_approx(noise.frequency, frequency):
		noise.frequency = frequency


# --- 描画 ---

func _draw() -> void:
	var image_rect := Rect2(Vector2.ZERO, IMAGE_PANEL)
	var wave_rect := Rect2(Vector2(IMAGE_PANEL.x + GAP, 0.0), WAVE_PANEL)
	var wander_rect := Rect2(Vector2(0.0, IMAGE_PANEL.y + GAP), PATH_PANEL)
	var chase_rect := Rect2(Vector2(0.0, wander_rect.end.y + GAP), PATH_PANEL)
	_draw_noise_image(image_rect)
	_draw_waveform(wave_rect)
	_draw_wander_path(wander_rect)
	_draw_chase_path(chase_rect)


func _draw_noise_image(rect: Rect2) -> void:
	_draw_panel(rect, "2D noise（横軸は波形と同じ時間範囲）")
	if _texture == null:
		return
	draw_texture_rect(_texture, rect.grow(-1.0), false)
	var top := rect.position + Vector2(1.0, 1.0)
	draw_line(top, Vector2(rect.end.x - 1.0, top.y), COLOR_WANDER, 1.0)


func _build_texture() -> ImageTexture:
	if wander_noise == null:
		return null
	var image := Image.create_empty(TEXTURE_SIZE, TEXTURE_SIZE, false, Image.FORMAT_RGB8)
	var step := duration / float(TEXTURE_SIZE)
	for y in TEXTURE_SIZE:
		for x in TEXTURE_SIZE:
			var value := wander_noise.get_noise_2d(x * step, y * step) * 0.5 + 0.5
			image.set_pixel(x, y, Color(value, value, value))
	return ImageTexture.create_from_image(image)


func _draw_waveform(rect: Rect2) -> void:
	_draw_panel(rect, "1D noise 波形")
	var mid := rect.position.y + rect.size.y * 0.5
	draw_line(Vector2(rect.position.x, mid), Vector2(rect.end.x, mid), COLOR_GUIDE, 1.0)
	_draw_curve(rect, wander_noise, COLOR_WANDER, 0)
	_draw_curve(rect, chase_noise, COLOR_CHASE, 1)


func _draw_curve(rect: Rect2, noise: FastNoiseLite, color: Color, label_line: int) -> void:
	if noise == null:
		return
	var count := int(rect.size.x)
	var points := PackedVector2Array()
	var min_value := 1.0
	var max_value := -1.0
	for i in count:
		var ratio := float(i) / float(count - 1)
		var value := noise.get_noise_1d(duration * ratio)
		min_value = minf(min_value, value)
		max_value = maxf(max_value, value)
		points.append(Vector2(
			rect.position.x + rect.size.x * ratio,
			rect.position.y + rect.size.y * (0.5 - value * 0.5)
		))
	draw_polyline(points, color, 1.5)

	var text := "freq " + String.num(noise.frequency, 2) \
		+ "  range " + String.num(min_value, 2) \
		+ " 〜 " + String.num(max_value, 2)
	_draw_text(rect.position + Vector2(6.0, 16.0 + label_line * 14.0), text, color)


func _draw_wander_path(rect: Rect2) -> void:
	_draw_panel(rect, "Wander 経路（外枠 = bounds / 内枠 = margin）")
	if _wander_path.size() < 2:
		return
	var bounds := Rect2(-bounds_size * 0.5, bounds_size)
	var reference := _wander_path.duplicate()
	reference.append(bounds.position)
	reference.append(bounds.end)
	var fit := _fit_transform(reference, rect)
	var scale := fit.get_scale().x

	draw_rect(Rect2(fit * bounds.position, bounds.size * scale), COLOR_GUIDE, false, 1.0)
	var inner := bounds.grow(-boundary_margin)
	if inner.size.x > 0.0 and inner.size.y > 0.0:
		draw_rect(Rect2(fit * inner.position, inner.size * scale), Color(1, 1, 1, 0.3), false, 1.0)

	_draw_path(_wander_path, fit, COLOR_WANDER)

	var text := "freq " + String.num(wander_noise_frequency, 2) \
		+ "  turn_rate " + String.num(max_turn_rate, 1) \
		+ "  speed " + String.num(wander_speed, 0)
	_draw_text(rect.position + Vector2(6.0, 16.0), text, COLOR_WANDER)


func _draw_chase_path(rect: Rect2) -> void:
	_draw_panel(rect, "Chase 経路（灰線 = 直線 / ズレがジッター）")
	if _chase_path.size() < 2:
		return
	var target_position := Vector2(chase_distance, 0.0)
	var reference := _chase_path.duplicate()
	reference.append(target_position)
	var fit := _fit_transform(reference, rect)

	draw_line(fit * Vector2.ZERO, fit * target_position, COLOR_GUIDE, 1.0)
	draw_circle(fit * target_position, 5.0, Color(1, 1, 1, 0.5))
	_draw_path(_chase_path, fit, COLOR_CHASE)

	var arrival := "到達なし"
	if _chase_arrival_time >= 0.0:
		arrival = "到達 " + String.num(_chase_arrival_time, 2) + " s"
	var text := "freq " + String.num(chase_noise_frequency, 2) \
		+ "  jitter " + String.num(chase_jitter, 2) \
		+ "  speed " + String.num(chase_speed, 0) \
		+ "  " + arrival
	_draw_text(rect.position + Vector2(6.0, 16.0), text, COLOR_CHASE)


func _draw_path(path: PackedVector2Array, fit: Transform2D, color: Color) -> void:
	var screen := PackedVector2Array()
	for point in path:
		screen.append(fit * point)
	draw_polyline(screen, color, 1.5)
	draw_circle(screen[0], 3.0, Color.WHITE)
	draw_circle(screen[screen.size() - 1], 3.0, color)


func _draw_panel(rect: Rect2, title: String) -> void:
	draw_rect(rect, COLOR_BG)
	draw_rect(rect, COLOR_FRAME, false, 1.0)
	_draw_text(rect.position + Vector2(2.0, -6.0), title)


func _draw_text(position: Vector2, text: String, color: Color = COLOR_TEXT) -> void:
	draw_string(ThemeDB.fallback_font, position, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, color)


# --- シミュレーション ---

func _simulate_wander(bounds: Rect2) -> PackedVector2Array:
	var points := PackedVector2Array()
	if wander_noise == null:
		return points
	var delta := 1.0 / float(samples_per_second)
	var steps := int(duration * samples_per_second)
	var position := bounds.get_center()
	var heading := deg_to_rad(start_angle_degrees)
	var velocity := Vector2.ZERO
	points.append(position)
	for i in steps:
		var turn := wander_noise.get_noise_1d(float(i) * delta) * max_turn_rate * delta
		var direction := _steer_inward(Vector2.from_angle(heading + turn), position, bounds)
		var desired_velocity := direction * wander_speed
		if not desired_velocity.is_zero_approx():
			heading = desired_velocity.angle()
		velocity = velocity.move_toward(desired_velocity, wander_acceleration * delta)
		position += velocity * delta
		points.append(position)
	return points


func _simulate_chase(target_position: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array()
	_chase_arrival_time = -1.0
	if chase_noise == null:
		return points
	var delta := 1.0 / float(samples_per_second)
	var steps := int(duration * samples_per_second)
	var position := Vector2.ZERO
	var velocity := Vector2.ZERO
	points.append(position)
	for i in steps:
		var to_target := target_position - position
		if to_target.is_zero_approx():
			break
		if _chase_arrival_time < 0.0 and to_target.length() < 16.0:
			_chase_arrival_time = float(i) * delta
		var jitter := chase_noise.get_noise_1d(float(i) * delta) * chase_jitter
		var direction := Vector2.from_angle(to_target.angle() + jitter)
		velocity = velocity.move_toward(direction * chase_speed, chase_acceleration * delta)
		position += velocity * delta
		points.append(position)
	return points


func _steer_inward(direction: Vector2, position: Vector2, bounds: Rect2) -> Vector2:
	if bounds.size.is_zero_approx() or boundary_margin <= 0.0:
		return direction
	var inner := bounds.grow(-boundary_margin)
	var inward := Vector2.ZERO
	inward.x = _axis_overshoot(position.x, inner.position.x, inner.end.x)
	inward.y = _axis_overshoot(position.y, inner.position.y, inner.end.y)
	if inward.is_zero_approx():
		return direction
	return direction.slerp(inward.normalized(), minf(inward.length(), 1.0))


func _axis_overshoot(value: float, minimum: float, maximum: float) -> float:
	if value < minimum:
		return (minimum - value) / boundary_margin
	if value > maximum:
		return -(value - maximum) / boundary_margin
	return 0.0


# --- 補助 ---

func _fit_transform(points: PackedVector2Array, rect: Rect2, padding: float = 10.0) -> Transform2D:
	var min_point := points[0]
	var max_point := points[0]
	for point in points:
		min_point.x = minf(min_point.x, point.x)
		min_point.y = minf(min_point.y, point.y)
		max_point.x = maxf(max_point.x, point.x)
		max_point.y = maxf(max_point.y, point.y)
	var size := Vector2(maxf(max_point.x - min_point.x, 1.0), maxf(max_point.y - min_point.y, 1.0))
	var inner := rect.grow(-padding)
	var scale := minf(inner.size.x / size.x, inner.size.y / size.y)
	var origin := inner.position + (inner.size - size * scale) * 0.5 - min_point * scale
	return Transform2D(0.0, Vector2(scale, scale), 0.0, origin)
