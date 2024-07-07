class_name BoneCollider
extends Node3D

class CapsuleCapsuleResult extends RefCounted:
	var depth: float
	var aa: Vector3
	var ab: Vector3
	var ba: Vector3
	var bb: Vector3
	var nearest_on_a: Vector3
	var nearest_on_b: Vector3
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
	var ba_on_a = closest_point_on_line_segment(ba, aa, ab)
	var bb_on_a = closest_point_on_line_segment(bb, aa, ab)
	var aa_on_b = closest_point_on_line_segment(aa, ba, bb)
	var ab_on_b = closest_point_on_line_segment(ab, ba, bb)
	var d0: float = (aa_on_b - ba_on_a).length_squared()
	var d1: float = (ab_on_b - ba_on_a).length_squared()
	var d2: float = (aa_on_b - bb_on_a).length_squared()
	var d3: float = (ab_on_b - bb_on_a).length_squared()
	#
	var nearest_on_a: Vector3
	var nearest_on_b: Vector3
	var d_min: float = 1e16
	if d0 < d_min:
		d_min = d0
		nearest_on_a = ba_on_a
		nearest_on_b = aa_on_b
	if d1 < d_min:
		d_min = d1
		nearest_on_a = ba_on_a
		nearest_on_b = ab_on_b
	if d2 < d_min:
		d_min = d2
		nearest_on_a = bb_on_a
		nearest_on_b = aa_on_b
	if d3 < d_min:
		nearest_on_a = bb_on_a
		nearest_on_b = ab_on_b
	#
	_result_.normal = nearest_on_a - nearest_on_b
	var distance: float = _result_.normal.length()
	_result_.normal /= distance
	_result_.depth = _ar_ + _br_ - distance
	#
	_result_.aa = aa
	_result_.ab = ab
	_result_.ba = aa
	_result_.bb = ab
	_result_.nearest_on_a = nearest_on_a
	_result_.nearest_on_b = nearest_on_b
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
