extends EditorNode3DGizmoPlugin

func _init() -> void:
	create_material("bone_collider", Color.INDIAN_RED)

func _get_gizmo_name() -> String:
	return "BoneCollider"

func _has_gizmo(node: Node3D) -> bool:
	return node is BoneCollider

func _redraw(gizmo: EditorNode3DGizmo) -> void:
	gizmo.clear()
	var node: BoneCollider = gizmo.get_node_3d()
	gizmo.add_lines(
		PackedVector3Array(_capsule(node.radius, node.height)),
		get_material("bone_collider", gizmo)
		)

func _capsule(_radius_: float, _height_: float) -> Array[Vector3]:
	var points: Array[Vector3] = []
	var d: Vector3 = Vector3(0.0, _height_ * 0.5 - _radius_, 0.0)
	
	for i in 360:
		var ra: float = deg_to_rad(float(i))
		var rb: float = deg_to_rad(float(i + 1.0))
		var a: Vector2 = Vector2(sin(ra), cos(ra)) * _radius_
		var b: Vector2 = Vector2(sin(rb), cos(rb)) * _radius_

		points.push_back(Vector3(a.x, 0, a.y) + d)
		points.push_back(Vector3(b.x, 0, b.y) + d)

		points.push_back(Vector3(a.x, 0, a.y) - d)
		points.push_back(Vector3(b.x, 0, b.y) - d)

		if i % 90 == 0:
			points.push_back(Vector3(a.x, 0, a.y) + d)
			points.push_back(Vector3(a.x, 0, a.y) - d)

		var dud: Vector3 = d if i < 180 else -d

		points.push_back(Vector3(0, a.x, a.y) + dud)
		points.push_back(Vector3(0, b.x, b.y) + dud)
		points.push_back(Vector3(a.y, a.x, 0) + dud)
		points.push_back(Vector3(b.y, b.x, 0) + dud)

	return points
