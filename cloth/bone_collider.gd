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

@export var radius: float = 0.5:
	set(_value_):
		radius = clampf(_value_, 1e-5, 1e5)
		height = clampf(height, radius * 2.0 + 1e-5, 1e5)
@export var height: float = 2.0:
	set(_value_):
		height = clampf(_value_, radius * 2.0 + 1e-5, 1e5)

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
