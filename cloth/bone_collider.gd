@tool
class_name BoneCollider
extends Node3D

class CapsuleCapsuleResult extends RefCounted:
	var depth: float
	var aa: Vector3
	var ab: Vector3
	var ba: Vector3
	var bb: Vector3
	var closest_on_a: Vector3
	var closest_on_b: Vector3
	var normal: Vector3

class TriangleCapsuleResult extends RefCounted:
	var depth: float
	var normal: Vector3
	var hit_color: Color

@export var enabled: bool = false:
	set(_value_):
		enabled = _value_
		if (_value_
			and is_instance_valid(_skeleton)
			and _bone_index > -1
			and _bone_index < _skeleton.get_bone_count()
			):
			set_physics_process(true)
		else:
			set_physics_process(false)
@export var _skeleton: Skeleton3D
@export var _bone_name: String:
	set(_value_):
		_bone_name = _value_
		if is_instance_valid(_skeleton):
			var bone_index: int = _skeleton.find_bone(_value_)
			if bone_index != -1:
				_bone_index = bone_index
				_bone_name = _value_
@export var _bone_index: int = -1
@export var offset: Vector3 = Vector3.ZERO
@export var radius: float = 0.5:
	set(_value_):
		radius = clampf(_value_, 1e-5, 1e5)
		height = clampf(height, radius * 2.0 + 1e-5, 1e5)
@export var height: float = 2.0:
	set(_value_):
		height = clampf(_value_, radius * 2.0 + 1e-5, 1e5)

func _physics_process(_delta_: float) -> void:
	if enabled:
		var tf: Transform3D = _skeleton.get_bone_global_pose(_bone_index)
		transform = tf.scaled_local(Vector3.ONE / tf.basis.get_scale()).translated_local(offset)

static func capsule_capsule_check(
	_ao_: Vector3, _au_: Vector3, _ar_: float, _ah_: float,
	_bo_: Vector3, _bu_: Vector3, _br_: float, _bh_: float,
	_result_: CapsuleCapsuleResult
	) -> bool:
	var a_offset: Vector3 = (_ah_ * 0.5 - _ar_) * _au_
	var aa: Vector3 = _ao_ - a_offset
	var ab: Vector3 = _ao_ + a_offset
	var b_offset: Vector3 = (_bh_ * 0.5 - _br_) * _bu_
	var ba: Vector3 = _bo_ - b_offset
	var bb: Vector3 = _bo_ + b_offset
	#
	var closests: Array[Vector3] = closest_points_on_line_segments(aa, ab, ba, bb)
	var closest_on_a: Vector3 = closests[0]
	var closest_on_b: Vector3 = closests[1]
	_result_.normal = closest_on_a - closest_on_b
	var distance: float = _result_.normal.length()
	_result_.normal /= distance
	_result_.depth = _ar_ + _br_ - distance
	#
	_result_.aa = aa
	_result_.ab = ab
	_result_.ba = aa
	_result_.bb = ab
	_result_.closest_on_a = closest_on_a
	_result_.closest_on_b = closest_on_b
	return _result_.depth > 0.0

static func triangle_capsule_check(
	_ta_: Vector3, _tb_: Vector3, _tc_: Vector3,
	_co_: Vector3, _cu_: Vector3, _cr_: float, _ch_: float,
	_result_: TriangleCapsuleResult
	) -> bool:
	var c_offset: Vector3 = (_ch_ * 0.5 - _cr_) * _cu_
	var ca: Vector3 = _co_ - c_offset
	var cb: Vector3 = _co_ + c_offset
	var tn: Vector3 = (_tb_ - _ta_).cross(_tc_ - _ta_).normalized()
	#
	var enter: float = _cu_.dot(tn)
	var trace: Vector3 = _ta_
	if abs(enter) >= 1e-8:
		enter = (_ta_ - _co_).dot(tn) / enter
		trace = _co_ + _cu_ * enter
	else:
		var p1: Vector3 = BoneCollider.closest_point_on_line_segment(_ta_, ca, cb)
		var p2: Vector3 = BoneCollider.closest_point_on_line_segment(_tb_, ca, cb)
		var p3: Vector3 = BoneCollider.closest_point_on_line_segment(_tc_, ca, cb)
		var d1: float = (_ta_ - p1).length_squared()
		var d2: float = (_tb_ - p2).length_squared()
		var d3: float = (_tc_ - p3).length_squared()
		var d_min: float = d1
		trace = p1
		if d2 < d_min:
			d_min = d2
			trace = p2
		if d3 < d_min:
			trace = p3
	var ia: Vector3 = (trace - _ta_).cross(_tb_ - _ta_)
	var ib: Vector3 = (trace - _tb_).cross(_tc_ - _tb_)
	var ic: Vector3 = (trace - _tc_).cross(_ta_ - _tc_)
	var inside: bool = ia.dot(tn) <= 0.0 && ib.dot(tn) <= 0.0 && ic.dot(tn) <= 0.0
	#
	var closest: Vector3 = trace
	if not inside:
		var p1: Vector3 = BoneCollider.closest_point_on_line_segment(trace, _ta_, _tb_)
		var p2: Vector3 = BoneCollider.closest_point_on_line_segment(trace, _tb_, _tc_)
		var p3: Vector3 = BoneCollider.closest_point_on_line_segment(trace, _tc_, _ta_)
		var d1: float = (trace - p1).length_squared()
		var d2: float = (trace - p2).length_squared()
		var d3: float = (trace - p3).length_squared()
		var d_min: float = d1
		closest = p1
		if d2 < d_min:
			d_min = d2
			closest = p2
		if d3 < d_min:
			closest = p3
	var center: Vector3 = BoneCollider.closest_point_on_line_segment(closest, ca, cb)
	#
	enter = (_ta_ - center).dot(tn)
	var center_on_plane: Vector3 = center + enter * tn
	ia = (center_on_plane - _ta_).cross(_tb_ - _ta_)
	ib = (center_on_plane - _tb_).cross(_tc_ - _tb_)
	ic = (center_on_plane - _tc_).cross(_ta_ - _tc_)
	inside = ia.dot(tn) <= 0.0 && ib.dot(tn) <= 0.0 && ic.dot(tn) <= 0.0
	#
	_result_.depth = -1.0
	if inside:
		_result_.depth = _cr_ - abs(enter)
		_result_.normal = center.direction_to(center_on_plane)
		_result_.hit_color = Color.SEA_GREEN
	else:
		var p1s: Array[Vector3] = BoneCollider.closest_points_on_line_segments(_ta_, _tb_, ca, cb)
		var p2s: Array[Vector3] = BoneCollider.closest_points_on_line_segments(_tb_, _tc_, ca, cb)
		var p3s: Array[Vector3] = BoneCollider.closest_points_on_line_segments(_tc_, _ta_, ca, cb)
		var d1: float = (p1s[0] - p1s[1]).length_squared()
		var d2: float = (p2s[0] - p2s[1]).length_squared()
		var d3: float = (p3s[0] - p3s[1]).length_squared()
		var d_min: float = d1
		closest = p1s[0]
		center = p1s[1]
		if d2 < d_min:
			d_min = d2
			closest = p2s[0]
			center = p2s[1]
		if d3 < d_min:
			closest = p3s[0]
			center = p3s[1]
		d_min = center.distance_squared_to(closest)
		if d_min < _cr_ * _cr_:
			_result_.depth = _cr_ - sqrt(d_min)
			_result_.normal = center.direction_to(closest)
			_result_.hit_color = Color.ORANGE_RED
	return _result_.depth > 0.0

static func closest_point_on_line_segment(_p_: Vector3, _a_: Vector3, _b_: Vector3) -> Vector3:
	var ap: Vector3 = _p_ - _a_
	var ab: Vector3 = _b_ - _a_
	var u: Vector3 = ab.normalized()
	var ap_dot_u: float = ap.dot(u)
	if ap_dot_u <= 0.0:
		return _a_
	if ap_dot_u >= ab.length():
		return _b_
	return _a_ + ap_dot_u * u

static func closest_points_on_line_segments(
	_a_: Vector3, _b_: Vector3, _c_: Vector3, _d_: Vector3
	) -> Array[Vector3]:
	var pn: Vector3 = _c_.direction_to(_d_)
	var a_on_p: Vector3 = _a_ + (_c_ - _a_).dot(pn) * pn
	var b_on_p: Vector3 = _b_ + (_c_ - _b_).dot(pn) * pn
	var ab_on_p: Vector3 = b_on_p - a_on_p
	var t: float = (_c_ - a_on_p).dot(ab_on_p) / ab_on_p.dot(ab_on_p)
	t = t if a_on_p.distance_squared_to(b_on_p) > 1e-8 else 0.0
	var ab_to_cd: Vector3 = _a_ + (_b_ - _a_) * clampf(t, 0.0, 1.0)
	var closest_on_cd: Vector3 = closest_point_on_line_segment(ab_to_cd, _c_, _d_)
	var closest_on_ab: Vector3 = closest_point_on_line_segment(closest_on_cd, _a_, _b_)
	return [closest_on_ab, closest_on_cd]
