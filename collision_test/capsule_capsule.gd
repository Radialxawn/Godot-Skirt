@tool
class_name CapsuleCapsule
extends Node3D

@export var _enabled: bool
@export var _capsule_a: CollisionShape3D
@export var _capsule_b: CollisionShape3D

var _result: BoneCollider.CapsuleCapsuleResult = BoneCollider.CapsuleCapsuleResult.new()

func _process(_delta_: float) -> void:
	if not _enabled:
		return
	var csa: CapsuleShape3D = _capsule_a.shape
	var csb: CapsuleShape3D = _capsule_b.shape
	var hit: bool = BoneCollider.capsule_capsule_check(
		_capsule_a.global_position, _capsule_a.global_basis.y, csa.radius, csa.height,
		_capsule_b.global_position, _capsule_b.global_basis.y, csb.radius, csb.height,
		_result
		)
	if hit:
		DebugDraw3D.scoped_config().set_hd_sphere(false)
		DebugDraw3D.scoped_config().set_thickness(0.003)
		var edge: Vector3 = _move_toward_unclamp(_result.nearest_on_b, _result.nearest_on_a, csb.radius)
		DebugDraw3D.draw_sphere(edge, 0.02, Color.BLACK)
		DebugDraw3D.scoped_config().set_thickness(0.012)
		DebugDraw3D.draw_line(
			edge,
			_move_toward_unclamp(edge, _result.nearest_on_b, _result.depth),
			Color.BLACK
			)
		DebugDraw3D.draw_line(
			edge,
			edge + _result.normal * _result.depth,
			Color.RED
			)
		var edge_out: Vector3 = edge + _result.normal * _result.depth
		DebugDraw3D.scoped_config().set_thickness(0.003)
		DebugDraw3D.draw_sphere(_result.aa, 0.02, Color.GREEN)
		DebugDraw3D.draw_sphere(edge_out, 0.02, Color.RED)
		var tf: Transform3D = _capsule_a.global_transform.translated(_result.normal * _result.depth)
		DebugDraw3D.draw_cylinder(tf.scaled_local(Vector3(csa.radius, csa.height - csa.radius * 2.0, csa.radius)), Color.ORANGE)
		DebugDraw3D.draw_sphere_xf(
			tf.translated_local(Vector3(0.0, -(csa.height * 0.5 - csa.radius), 0.0))
				.scaled_local(Vector3(csa.radius, csa.radius, csa.radius) * 2.0),
			Color.ORANGE
			)
		DebugDraw3D.draw_sphere_xf(
			tf.translated_local(Vector3(0.0, csa.height * 0.5 - csa.radius, 0.0))
				.scaled_local(Vector3(csa.radius, csa.radius, csa.radius) * 2.0),
			Color.ORANGE
			)

func _transform_from_xy_look_y(_origin_: Vector3, _x_: Vector3, _y_: Vector3) -> Transform3D:
	_y_ = _y_.normalized()
	var z: Vector3 = _y_.cross(_x_).normalized()
	_x_ = _y_.cross(z).normalized()
	return Transform3D(_x_, _y_, z, _origin_)

func _move_toward_unclamp(_from_: Vector3, _to_: Vector3, _delta_: float):
	return _from_ + (_to_ - _from_).normalized() * _delta_
