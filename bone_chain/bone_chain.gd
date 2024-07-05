class_name BoneChain
extends RefCounted

var _skeleton: Skeleton3D
var _skeleton_offset: Vector3
var _bone_root: int
var _bone_root_transform_local_base: Transform3D
var _bones: Array[int]
var _bones_length: Array[float]
var _bones_transform_local_base: Array[Transform3D]
var _bones_position_tail_local_base: Array[Vector3]
var _colliders: Array[BoneCollider]

var _pm_solver: PMSolver = PMSolver.new()
var _pm_points: Array[PMPoint] = []

var force: Vector3

func initialize():
	_pm_solver.step_head_methods.append(_solve_collisions)
	_pm_solver.step_head_methods.append(_solve_constraints)
	_pm_solver.step_tail_methods.append(_apply)

func colliders_set(_value_: Array[BoneCollider]):
	_colliders = _value_

func skeleton_set(_skeleton_: Skeleton3D, _skeleton_offset_: Vector3):
	_skeleton = _skeleton_
	_skeleton_offset = _skeleton_offset_

func bone_root_set(_index_: int) -> void:
	var tf: Transform3D = _skeleton.get_bone_global_rest(_index_)
	tf.origin += _skeleton_offset
	_bone_root = _index_
	_bone_root_transform_local_base = tf
	var pm_point_new: PMPoint = PMPoint.new(tf.origin)
	pm_point_new.pin_to(pm_point_new.p)
	_pm_points.append(pm_point_new)

func bones_add(_index_: int, _length_: float) -> void:
	_bones.append(_index_)
	_bones_length.append(_length_)
	var tf: Transform3D = _skeleton.get_bone_global_rest(_index_)
	tf.origin += _skeleton_offset
	_bones_transform_local_base.append(tf)
	_bones_position_tail_local_base.append(tf.origin + tf.basis.y * _length_)
	var pm_point_new: PMPoint = PMPoint.new(_bones_position_tail_local_base[-1])
	pm_point_new.links_add(_pm_points[-1], pm_point_new.p.distance_to(_pm_points[-1].p), 1.0, 1e8)
	_pm_points.append(pm_point_new)

func snap_back_setup(_strength_: float) -> void:
	for i in _bones.size():
		var pm_point_new: PMPoint = PMPoint.new(_bones_position_tail_local_base[i] + Vector3(0.0, -1e-3, 0.0))
		pm_point_new.pin_to(pm_point_new.p)
		pm_point_new.links_add(_pm_points[i + 1], 1e-3, _strength_, 1e8)
		_pm_points.append(pm_point_new)

func reset() -> void:
	for i in _bones.size():
		_skeleton.reset_bone_pose(_bones[i])
		_pm_points[i + 1].p = _bones_position_tail_local_base[i]
	_apply()

func solve():
	for pm_point: PMPoint in _pm_points:
		pm_point.apply_force(force)
	_pm_solver.process(_pm_points)

func _solve_collisions():
	var i_range = range(_bones.size())
	for collider: BoneCollider in _colliders:
		for i in i_range:
			var p_tail: Vector3 = _pm_points[i + 1].p
			var p: Vector3 = _nearest_point_on_capsule_line(
				p_tail,
				collider.position,
				collider.basis.y,
				collider.radius,
				collider.height,
				)
			if p.distance_squared_to(p_tail) < collider.radius**2:
				p_tail = _move_toward_unclamp(p, p_tail, collider.radius)
				_pm_points[i + 1].p = _move_toward_unclamp(_pm_points[i].p, p_tail, _bones_length[i])

func _solve_constraints() -> void:
	for i in _bones.size():
		var p_tail: Vector3 = _pm_points[i + 1].p
		var plane_o: Vector3 = _bones_transform_local_base[i].origin
		var plane_n: Vector3 = _bones_transform_local_base[i].basis.x
		var p_tail_on_plane: Vector3 = p_tail - plane_n * (p_tail - plane_o).dot(plane_n)
		_pm_points[i + 1].p = p_tail.lerp(p_tail_on_plane, 0.5)

func _apply() -> void:
	var count = _bones.size()
	for i in count:
		var p_head: Vector3 = _pm_points[i].p
		var p_tail: Vector3 = _pm_points[i + 1].p
		'''My skirt bone forward direction is y axis, I still not make this universal'''
		var tf = _look_axis_y(
			p_head - _skeleton_offset,
			p_tail - p_head,
			_bone_root_transform_local_base.basis.x
			)
		_skeleton.set_bone_global_pose_override(_bones[i], tf, 1.0, true)

func _nearest_point_on_capsule_line(_p_: Vector3, _co_: Vector3, _cd_: Vector3, _cr_: float, _ch_: float) -> Vector3:
	var d_ab = _ch_ - 2.0 * _cr_
	var d_ao = d_ab * 0.5
	var a = _co_ - _cd_ * d_ao
	var b = _co_ + _cd_ * d_ao
	var ap = _p_ - a
	var ap_dot_cd = ap.dot(_cd_)
	if ap_dot_cd <= 0.0:
		return a
	if ap_dot_cd >= d_ab:
		return b
	return a + _cd_ * ap_dot_cd

func _look_axis_y(_from_: Vector3, _y_: Vector3, _x_: Vector3) -> Transform3D:
	_y_ = _y_.normalized()
	var z: Vector3 = _y_.cross(_x_).normalized()
	_x_ = _y_.cross(z).normalized()
	return Transform3D(_x_, _y_, z, _from_)

func _move_toward_unclamp(_from_: Vector3, _to_: Vector3, _delta_: float):
	return _from_ + (_to_ - _from_).normalized() * _delta_

func _move_toward_on_sphere(_from_: Vector3, _to_: Vector3, _center_: Vector3, _delta_: float) -> Vector3:
	var cf: Vector3 = _from_ - _center_
	var ct: Vector3 = _to_ - _center_
	var alpha: float = cf.angle_to(ct)
	if alpha < 1e-4:
		return _to_
	var r_f: float = cf.length()
	var r_t: float = ct.length()
	var r_a: float = (r_f + r_t) * 0.5
	var delta_alpha: float = _delta_ / r_a
	if delta_alpha >= alpha:
		return _to_
	var r_n: float = r_f + (r_t - r_f) * (delta_alpha / alpha)
	return _center_ + cf.rotated(cf.cross(ct).normalized(), delta_alpha).normalized() * r_n

#region debug
func debug_draw(_parent_: Transform3D):
	DebugDraw3D.scoped_config().set_thickness(0.001)
	for i in _pm_points.size():
		DebugDraw3D.draw_sphere(
			_parent_ * _pm_points[i].p,
			0.01,
			Color.from_hsv(float(i) / _pm_points.size(), 0.8, 1.0)
			)
#endregion
