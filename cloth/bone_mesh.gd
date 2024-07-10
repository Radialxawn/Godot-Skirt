class_name BoneMesh
extends RefCounted

class Chain extends RefCounted:
	var indexs: Array[int]
	var lengths: Array[float]
	var transform_local_bases: Array[Transform3D]
	var position_tail_local_bases: Array[Vector3]
	var pm_point_indexs: Array[int]

var _parent: Node3D
var _skeleton: Skeleton3D
var _skeleton_offset: Vector3
var _chains: Array[Chain]
var _colliders: Array[BoneCollider]
var _triangles: Array[int]
var _pm_solver: PMSolver
var _pm_points: Array[PMPoint]

var _collision_result: BoneCollider.TriangleCapsuleResult

var force: Vector3

func initialize() -> void:
	_chains.clear()
	_pm_solver = PMSolver.new(16, 3)
	_pm_points.clear()
	_pm_solver.step_methods.append(_solve_collisions)
	_pm_solver.step_methods.append(_solve_constraints)
	_pm_solver.step_methods.append(_apply)
	_collision_result = BoneCollider.TriangleCapsuleResult.new()

func parent_set(_value_: Node3D) -> void:
	_parent = _value_

func colliders_set(_value_: Array[BoneCollider]) -> void:
	_colliders = _value_

func skeleton_set(_skeleton_: Skeleton3D, _skeleton_offset_: Vector3) -> void:
	_skeleton = _skeleton_
	_skeleton_offset = _skeleton_offset_

func bones_add(_index_: int, _length_: float) -> void:
	if _length_ == 0.0:
		_chains.append(Chain.new())
	var chain: Chain = _chains[-1]
	chain.indexs.append(_index_)
	var tf: Transform3D = _skeleton.get_bone_global_rest(_index_)
	tf.origin += _skeleton_offset
	chain.transform_local_bases.append(tf)
	_pm_points.append(PMPoint.new(tf.origin))
	chain.pm_point_indexs.append(_pm_points.size() - 1)
	if chain.indexs.size() > 1:
		chain.position_tail_local_bases.append(tf.origin)
		var distance: float = _pm_points[-2].p.distance_to(_pm_points[-1].p)
		_pm_points[-2].links_add(_pm_points[-1], distance, 1.0, 1e8)
		chain.lengths.append(distance)
	if _length_ == 0.0: # first bone in chain
		_pm_points[-1].pin_to(_pm_points[-1].p)
	elif _length_ > 0.0: # last bone in chain
		var tail: Vector3 = tf.origin + tf.basis.y * _length_
		_pm_points.append(PMPoint.new(tail))
		chain.pm_point_indexs.append(_pm_points.size() - 1)
		chain.position_tail_local_bases.append(tail)
		_pm_points[-2].links_add(_pm_points[-1], _pm_points[-2].p.distance_to(_pm_points[-1].p), 1.0, 1e8)
		chain.lengths.append(_length_)

func generate_triangles() -> void:
	_triangles = []
	for ci: int in _chains.size():
		var chain_last: Chain = _chains[ci - 1]
		var chain: Chain = _chains[ci]
		var count: int = mini(chain_last.indexs.size(), chain.indexs.size())
		for i: int in count:
			var ia: int = chain_last.pm_point_indexs[i]
			var ib: int = chain_last.pm_point_indexs[i + 1]
			var ic: int = chain.pm_point_indexs[i]
			var id: int = chain.pm_point_indexs[i + 1]
			_triangles.append_array([ia, ic, ib, ib, ic, id])

func generate_cross_links(_stiffness_: float) -> void:
	for ci: int in _chains.size():
		var chain_last: Chain = _chains[ci - 1]
		var chain: Chain = _chains[ci]
		var count: int = mini(chain_last.indexs.size() - 1, chain.indexs.size() - 1)
		for i: int in count:
			var ia: PMPoint = _pm_points[chain_last.pm_point_indexs[i]]
			var ib: PMPoint = _pm_points[chain_last.pm_point_indexs[i + 1]]
			var ic: PMPoint = _pm_points[chain.pm_point_indexs[i]]
			var id: PMPoint = _pm_points[chain.pm_point_indexs[i + 1]]
			# cross
			ia.links_add(id, ia.p.distance_to(id.p), _stiffness_, 1e8)
			ib.links_add(ic, ib.p.distance_to(ic.p), _stiffness_, 1e8)
			# parallel
			ia.links_add(ic, ia.p.distance_to(ic.p), _stiffness_, 1e8)
			ib.links_add(id, ib.p.distance_to(id.p), _stiffness_, 1e8)

func generate_clamp(_distance_curve_: Curve, _stiffness_curve_: Curve) -> void:
	for chain: Chain in _chains:
		for i in chain.indexs.size():
			var t: float = float(i) / (chain.indexs.size() - 1.0)
			var distance: float = _distance_curve_.sample(t)
			var stiffness: float = _stiffness_curve_.sample(t)
			var pm: PMPoint = _pm_points[chain.pm_point_indexs[i + 1]]
			var pmc: PMPoint = PMPoint.new(pm.p + chain.transform_local_bases[i].basis.z * distance)
			_pm_points.append(pmc)
			pmc.pin_to(pmc.p)
			pmc.links_add(pm, distance, stiffness, 1e8)

func solve() -> void:
	for pm_point: PMPoint in _pm_points:
		pm_point.apply_force(force)
	_pm_solver.process(_pm_points)

func _solve_collisions() -> void:
	for i: int in range(0, _triangles.size(), 3):
		for collider: BoneCollider in _colliders:
			var hit: bool = BoneCollider.triangle_capsule_check(
				_pm_points[_triangles[i]].p,
				_pm_points[_triangles[i + 1]].p,
				_pm_points[_triangles[i + 2]].p,
				_parent.to_local(collider.global_position),
				(_parent.global_basis.inverse() * collider.global_basis.y).normalized(),
				collider.radius,
				collider.height,
				_collision_result
				)
			if hit:
				var offset: Vector3 = _collision_result.normal * _collision_result.depth
				_pm_points[_triangles[i]].p += offset
				_pm_points[_triangles[i + 1]].p += offset
				_pm_points[_triangles[i + 2]].p += offset

func _solve_constraints() -> void:
	pass

func _apply() -> void:
	for chain: Chain in _chains:
		for i: int in chain.indexs.size():
			var p_head: Vector3 = _pm_points[chain.pm_point_indexs[i]].p
			var p_tail: Vector3 = _pm_points[chain.pm_point_indexs[i + 1]].p
			var tf: Transform3D = _transform_from_xy_look_y(
				p_head - _skeleton_offset,
				-chain.transform_local_bases[i].basis.x,
				p_tail - p_head
				)
			_skeleton.set_bone_global_pose_override(chain.indexs[i], tf, 1.0, true)

func _transform_from_xy_look_y(_origin_: Vector3, _x_: Vector3, _y_: Vector3) -> Transform3D:
	_y_ = _y_.normalized()
	var z: Vector3 = _y_.cross(_x_).normalized()
	_x_ = _y_.cross(z).normalized()
	return Transform3D(_x_, _y_, z, _origin_)

#region debug
func debug_draw() -> void:
	DebugDraw3D.scoped_config().set_thickness(0.001)
	for pm: PMPoint in _pm_points:
		DebugDraw3D.draw_sphere(_parent.to_global(pm.p), 0.002, Color.BLACK)
	for i: int in range(0, _triangles.size(), 3):
		_draw_triangle(
			_parent.to_global(_pm_points[_triangles[i]].p),
			_parent.to_global(_pm_points[_triangles[i + 1]].p),
			_parent.to_global(_pm_points[_triangles[i + 2]].p),
			0.9,
			Color.from_hsv(1.0 * i / _triangles.size(), 0.8, 0.9)
			)

static func _draw_triangle(_a_: Vector3, _b_: Vector3, _c_: Vector3, _scale_: float, _color_: Color) -> void:
	var center: Vector3 = (_a_ + _b_ + _c_) / 3.0
	_a_ = center + (_a_ - center) * _scale_
	_b_ = center + (_b_ - center) * _scale_
	_c_ = center + (_c_ - center) * _scale_
	DebugDraw3D.draw_line(_a_, _b_, _color_)
	DebugDraw3D.draw_line(_b_, _c_, _color_)
	DebugDraw3D.draw_line(_c_, _a_, _color_)
	#DebugDraw3D.draw_line(center, center + (_c_ - _a_).cross(_b_ - _a_).normalized() * 0.03, _color_)
#endregion
