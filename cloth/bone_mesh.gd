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

var force: Vector3

func initialize() -> void:
	_chains = []
	_pm_solver = PMSolver.new()
	_pm_solver.step_methods.append(_solve_collisions)
	_pm_solver.step_methods.append(_solve_constraints)
	_pm_solver.step_methods.append(_apply)

func parent_set(_value_: Node3D):
	_parent = _value_

func colliders_set(_value_: Array[BoneCollider]):
	_colliders = _value_

func skeleton_set(_skeleton_: Skeleton3D, _skeleton_offset_: Vector3):
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

func generate() -> void:
	_triangles = []
	for i_c in _chains.size():
		var chain_last: Chain = _chains[i_c - 1]
		var chain: Chain = _chains[i_c]
		var count: int = mini(chain_last.indexs.size(), chain.indexs.size())
		for i in count:
			var ia: int = chain_last.pm_point_indexs[i]
			var ib: int = chain_last.pm_point_indexs[i + 1]
			var ic: int = chain.pm_point_indexs[i]
			var id: int = chain.pm_point_indexs[i + 1]
			_triangles.append_array([ia, ic, ib, ib, ic, id])

func solve() -> void:
	for pm_point: PMPoint in _pm_points:
		pm_point.apply_force(force)
	_pm_solver.process(_pm_points)

func _solve_collisions() -> void:
	pass

func _solve_constraints() -> void:
	pass

func _apply() -> void:
	pass

#region debug
func debug_draw():
	DebugDraw3D.scoped_config().set_thickness(0.001)
	for chain: Chain in _chains:
		for tail: Vector3 in chain.position_tail_local_bases:
			DebugDraw3D.draw_sphere(tail, 0.002, Color.BLACK)
		for tf: Transform3D in chain.transform_local_bases:
			DebugDraw3D.draw_box_xf(tf.scaled_local(Vector3(0.01, 0.01, 0.01)), Color.BLACK)
		for pmi: int in chain.pm_point_indexs:
			DebugDraw3D.draw_sphere(_pm_points[pmi].p, 0.004, Color.GREEN)
	for i in range(0, _triangles.size(), 3):
		_draw_triangle(
			_parent.to_global(_pm_points[_triangles[i]].p),
			_parent.to_global(_pm_points[_triangles[i + 1]].p),
			_parent.to_global(_pm_points[_triangles[i + 2]].p),
			0.9,
			Color.from_hsv(1.0 * i / _triangles.size(), 0.8, 0.9)
			)

static func _draw_triangle(_a_: Vector3, _b_: Vector3, _c_: Vector3, _scale_: float, _color_: Color):
	var center = (_a_ + _b_ + _c_) / 3.0
	_a_ = center + (_a_ - center) * _scale_
	_b_ = center + (_b_ - center) * _scale_
	_c_ = center + (_c_ - center) * _scale_
	DebugDraw3D.draw_line(_a_, _b_, _color_)
	DebugDraw3D.draw_line(_b_, _c_, _color_)
	DebugDraw3D.draw_line(_c_, _a_, _color_)
	DebugDraw3D.draw_line(center, center + (_c_ - _a_).cross(_b_ - _a_).normalized() * 0.03, _color_)
#endregion
