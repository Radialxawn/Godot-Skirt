@tool
class_name TriangleCapsule
extends Node3D

@export var _enabled: bool
@export var _triangle: CollisionShape3D
@export var _capsule: CollisionShape3D

var _result: BoneCollider.TriangleCapsuleResult = BoneCollider.TriangleCapsuleResult.new()

func _physics_process(_delta_: float) -> void:
	if not _enabled:
		return
	var tri: ConvexPolygonShape3D = _triangle.shape
	var cs: CapsuleShape3D = _capsule.shape
	DebugDraw3D.scoped_config().set_thickness(0.003)
	var hit: bool = BoneCollider.triangle_capsule_check(
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
