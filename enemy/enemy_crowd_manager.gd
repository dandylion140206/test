class_name EnemyCrowdManager
extends Node

@export_group("Grid")
@export_range(1.0, 1000.0, 1.0, "or_greater") var cell_size: float = 80.0

@export_group("Separation")
@export_range(0.0, 1000.0, 10.0, "or_greater") var separation_speed: float = 100.0

@export_group("PBD")
@export_range(1, 10, 1) var solver_iterations: int = 3
@export_range(0.05, 1.0, 0.05) var stiffness: float = 0.8
# NOTE: 重なり解消が1フレームで動かせる速度の上限。分離力とは独立して制限する。
@export_range(0.0, 1000.0, 10.0, "or_greater") var max_push_speed: float = 50.0

# --- 登録データ ---

var _enemies: Array[Enemy] = []
var _body_radii: Array[float] = []
var _avoidance_radii: Array[float] = []
var _broadphase_radii: Array[float] = []
var _inverse_masses: Array[float] = []
var _scatter_angles: Array[float] = []

# --- フレーム処理データ ---

var _positions: Array[Vector2] = []
var _positions_before_pbd: Array[Vector2] = []
var _separation_velocities: Array[Vector2] = []
var _corrections: Array[Vector2] = []
var _contact_counts: Array[int] = []
var _minimum_cells: Array[Vector2i] = []
var _maximum_cells: Array[Vector2i] = []
var _grid: Dictionary = {}
var _pairs: Array[Vector2i] = []
var _max_push_distance: float = 0.0


# --- ライフサイクル ---

func _ready() -> void:
	if cell_size <= 0.0:
		push_error("EnemyCrowdManager: cell_sizeが0以下のためCrowd処理を無効にします")
		set_physics_process(false)


func _physics_process(delta: float) -> void:
	if _enemies.size() < 2:
		return

	_max_push_distance = max_push_speed * delta

	_copy_positions()
	_build_grid()
	_build_pairs()
	_apply_separation(delta)
	_solve_pbd()
	_write_positions()


# --- Enemy登録 ---

func register_enemy(enemy: Enemy) -> void:
	var stats := enemy.stats
	if stats == null:
		push_error("EnemyCrowdManager: EnemyStatsが未設定のEnemyは登録できません")
		return
	if stats.mass <= 0.0:
		push_error("EnemyCrowdManager: massが0以下のEnemyは登録できません")
		return

	# NOTE: Statsは登録時にキャッシュするため、実行中にResourceを変更しても反映されない。
	_enemies.append(enemy)
	_body_radii.append(stats.body_radius)
	_avoidance_radii.append(stats.avoidance_radius)
	_broadphase_radii.append(maxf(stats.body_radius, stats.avoidance_radius))
	_inverse_masses.append(stats.inverse_mass)
	# NOTE: 完全同位置での分離方向に使う。個体ごとに固定して毎フレームの向き変化を防ぐ。
	_scatter_angles.append(randf() * TAU)


func unregister_enemy(enemy: Enemy) -> void:
	# NOTE: Enemyを先に解放すると参照が残るため、削除にはSpawner.despawn()を使用する。
	var index := _enemies.find(enemy)
	assert(index >= 0, "EnemyCrowdManagerに登録されていないEnemyです")

	# NOTE: 各配列は同じインデックスで対応しているため、必ずまとめて削除する。
	_enemies.remove_at(index)
	_body_radii.remove_at(index)
	_avoidance_radii.remove_at(index)
	_broadphase_radii.remove_at(index)
	_inverse_masses.remove_at(index)
	_scatter_angles.remove_at(index)


# --- フレーム準備 ---

func _copy_positions() -> void:
	var enemy_count := _enemies.size()
	_positions.resize(enemy_count)
	_positions_before_pbd.resize(enemy_count)
	_separation_velocities.resize(enemy_count)
	_corrections.resize(enemy_count)
	_contact_counts.resize(enemy_count)
	_minimum_cells.resize(enemy_count)
	_maximum_cells.resize(enemy_count)

	for index in enemy_count:
		_positions[index] = _enemies[index].global_position
		_separation_velocities[index] = Vector2.ZERO


# --- 近傍検索 ---

func _build_grid() -> void:
	_grid.clear()

	for enemy_index in _enemies.size():
		# NOTE: 半径に対してcell_sizeが小さすぎると、1体あたりのセル登録数が増加する。
		var radius := _broadphase_radii[enemy_index]
		var radius_vector := Vector2(radius, radius)
		var minimum_cell := _world_to_cell(_positions[enemy_index] - radius_vector)
		var maximum_cell := _world_to_cell(_positions[enemy_index] + radius_vector)
		_minimum_cells[enemy_index] = minimum_cell
		_maximum_cells[enemy_index] = maximum_cell

		for cell_x in range(minimum_cell.x, maximum_cell.x + 1):
			for cell_y in range(minimum_cell.y, maximum_cell.y + 1):
				var cell := Vector2i(cell_x, cell_y)
				var cell_indices: Array = _grid.get(cell, [])
				cell_indices.append(enemy_index)
				_grid[cell] = cell_indices


func _build_pairs() -> void:
	_pairs.clear()

	for enemy_a_index in _enemies.size():
		var candidate_indices: Dictionary = {}
		var minimum_cell := _minimum_cells[enemy_a_index]
		var maximum_cell := _maximum_cells[enemy_a_index]

		for cell_x in range(minimum_cell.x, maximum_cell.x + 1):
			for cell_y in range(minimum_cell.y, maximum_cell.y + 1):
				var cell_indices: Array = _grid[Vector2i(cell_x, cell_y)]
				for cell_enemy_index in cell_indices:
					var enemy_b_index: int = cell_enemy_index
					if enemy_b_index > enemy_a_index:
						candidate_indices[enemy_b_index] = true

		var sorted_candidates: Array[int] = []
		for candidate_index in candidate_indices:
			sorted_candidates.append(candidate_index)
		sorted_candidates.sort()

		for enemy_b_index in sorted_candidates:
			_pairs.append(Vector2i(enemy_a_index, enemy_b_index))


func _world_to_cell(position: Vector2) -> Vector2i:
	return Vector2i(floori(position.x / cell_size), floori(position.y / cell_size))


# --- 分離力 ---

func _apply_separation(delta: float) -> void:
	for pair in _pairs:
		var enemy_a_index := pair.x
		var enemy_b_index := pair.y
		var minimum_distance := _body_radii[enemy_a_index] + _body_radii[enemy_b_index]
		var avoidance_distance := (
			_avoidance_radii[enemy_a_index] + _avoidance_radii[enemy_b_index]
		)
		if avoidance_distance <= minimum_distance:
			continue

		var offset := _positions[enemy_b_index] - _positions[enemy_a_index]
		var distance := offset.length()
		if distance >= avoidance_distance:
			continue

		var direction := (
			_scatter_direction(enemy_a_index, enemy_b_index)
			if offset.is_zero_approx()
			else offset / distance
		)
		var proximity := clampf(
			(avoidance_distance - distance) / (avoidance_distance - minimum_distance),
			0.0,
			1.0
		)
		var strength := proximity * proximity
		var pair_velocity := direction * separation_speed * strength
		var inverse_mass_sum := _inverse_masses[enemy_a_index] + _inverse_masses[enemy_b_index]
		var weight_a := _inverse_masses[enemy_a_index] / inverse_mass_sum
		var weight_b := _inverse_masses[enemy_b_index] / inverse_mass_sum

		_separation_velocities[enemy_a_index] -= pair_velocity * weight_a
		_separation_velocities[enemy_b_index] += pair_velocity * weight_b

	for enemy_index in _enemies.size():
		var velocity := _separation_velocities[enemy_index].limit_length(separation_speed)
		_positions[enemy_index] += velocity * delta


# --- PBDによる重なり補正 ---

func _solve_pbd() -> void:
	for enemy_index in _enemies.size():
		_positions_before_pbd[enemy_index] = _positions[enemy_index]

	# NOTE: 反復中は候補ペアを再構築しないため、新たな接触は次の物理フレームで処理する。
	for _iteration in solver_iterations:
		_accumulate_corrections()
		_apply_corrections()

	_limit_push_distance()


func _accumulate_corrections() -> void:
	for enemy_index in _enemies.size():
		_corrections[enemy_index] = Vector2.ZERO
		_contact_counts[enemy_index] = 0

	# NOTE: 反復ごとに全ペアの補正をまとめてから適用する(Jacobi法)。
	# 逐次適用では多数に囲まれた個体が補正を重ねがけされ、密集の外へ射出される。
	for pair in _pairs:
		var enemy_a_index := pair.x
		var enemy_b_index := pair.y
		var minimum_distance := _body_radii[enemy_a_index] + _body_radii[enemy_b_index]
		var offset := _positions[enemy_b_index] - _positions[enemy_a_index]
		var distance := offset.length()
		if distance >= minimum_distance:
			continue

		var direction := (
			_scatter_direction(enemy_a_index, enemy_b_index)
			if offset.is_zero_approx()
			else offset / distance
		)
		var penetration := minimum_distance - distance
		var correction := direction * penetration * stiffness
		var inverse_mass_sum := _inverse_masses[enemy_a_index] + _inverse_masses[enemy_b_index]
		var weight_a := _inverse_masses[enemy_a_index] / inverse_mass_sum
		var weight_b := _inverse_masses[enemy_b_index] / inverse_mass_sum

		_corrections[enemy_a_index] -= correction * weight_a
		_corrections[enemy_b_index] += correction * weight_b
		_contact_counts[enemy_a_index] += 1
		_contact_counts[enemy_b_index] += 1


func _apply_corrections() -> void:
	for enemy_index in _enemies.size():
		var contact_count := _contact_counts[enemy_index]
		if contact_count == 0:
			continue
		_positions[enemy_index] += _corrections[enemy_index] / float(contact_count)


func _limit_push_distance() -> void:
	for enemy_index in _enemies.size():
		# NOTE: 重なり解消による移動量のみを制限する。分離力はseparation_speedで制限済み。
		var origin := _positions_before_pbd[enemy_index]
		var push := _positions[enemy_index] - origin
		_positions[enemy_index] = origin + push.limit_length(_max_push_distance)


func _scatter_direction(enemy_a_index: int, enemy_b_index: int) -> Vector2:
	# NOTE: 角度の和を使うことで、ペアの順序によらず同じ軸に分離する。
	return Vector2.from_angle(_scatter_angles[enemy_a_index] + _scatter_angles[enemy_b_index])


# --- 位置反映 ---

func _write_positions() -> void:
	for enemy_index in _enemies.size():
		_enemies[enemy_index].global_position = _positions[enemy_index]
