@tool
class_name TriangleCapsule
extends Node3D

class TriangleCapsuleResult extends RefCounted:
	var depth: float
	var nearest_on_a: Vector3
	var nearest_on_b: Vector3
	var normal: Vector3
	var hit_color: Color

@export var _enabled: bool
@export var _triangle: CollisionShape3D
@export var _capsule: CollisionShape3D

var _result: TriangleCapsuleResult = TriangleCapsuleResult.new()

func _physics_process(_delta_: float) -> void:
	if not _enabled:
		return
	var tri: ConvexPolygonShape3D = _triangle.shape
	var cs: CapsuleShape3D = _capsule.shape
	DebugDraw3D.scoped_config().set_thickness(0.003)
	var hit: bool = triangle_capsule_check(
		_triangle.to_global(tri.points[0]),
		_triangle.to_global(tri.points[1]),
		_triangle.to_global(tri.points[2]),
		_capsule.global_position, _capsule.global_basis.y, cs.radius, cs.height,
		_result
		)
	if hit:
		for i in 20:
			var s = float(i + 1) / 20.0
			for j in 3:
				DebugDraw3D.draw_line(
					_triangle.to_global(tri.points[wrapi(j, 0, 3)] * s) + _result.normal * _result.depth,
					_triangle.to_global(tri.points[wrapi(j + 1, 0, 3)] * s) + _result.normal * _result.depth,
					_result.hit_color
					)

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
	DebugDraw3D.draw_sphere(trace, 0.02, Color.YELLOW_GREEN)
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
		var p1: Vector3 = BoneCollider.closest_point_on_line_segment(center, _ta_, _tb_)
		var p2: Vector3 = BoneCollider.closest_point_on_line_segment(center, _tb_, _tc_)
		var p3: Vector3 = BoneCollider.closest_point_on_line_segment(center, _tc_, _ta_)
		var d1: float = (center - p1).length_squared()
		var d2: float = (center - p2).length_squared()
		var d3: float = (center - p3).length_squared()
		var d_min: float = d1
		var ta: Vector3 = _ta_
		var tb: Vector3 = _tb_
		if d2 < d_min:
			d_min = d2
			ta = _tb_
			tb = _tc_
		if d3 < d_min:
			ta = _tc_
			ta = _ta_
		#
		var closests: Array[Vector3] = BoneCollider.closest_points_on_line_segments(ta, tb, ca, cb)
		closest = closests[0]
		center = closests[1]
		d_min = center.distance_squared_to(closest)
		#
		if d_min < _cr_ * _cr_:
			_result_.depth = _cr_ - sqrt(d_min)
			_result_.normal = center.direction_to(closest)
			_result_.hit_color = Color.ORANGE_RED
	DebugDraw3D.draw_sphere(closest, 0.02, Color.BLACK)
	DebugDraw3D.draw_sphere(center, 0.02, Color.PALE_VIOLET_RED)
	return _result_.depth > 0.0
