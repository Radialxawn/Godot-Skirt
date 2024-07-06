class_name Rope
extends Node3D

var _root: Node3D
var _nodes: Array[MeshInstance3D]

var _pm_solver: PMSolver = PMSolver.new()
var _pm_points: Array[PMPoint] = []

var _local_gravity: Vector3
var _local_force: Vector3

func initialize() -> void:
	for child in get_children():
		if child.name.begins_with("node_"):
			_nodes.append(child)
		if child.name == "root":
			_root = child
	_pm_points.append(PMPoint.new(_root.position))
	for i in _nodes.size():
		var node_last: Node3D = _root if i == 0 else _nodes[i - 1]
		var pm_point_new: PMPoint = PMPoint.new(_nodes[i].position)
		_pm_points[-1].links_add(pm_point_new, node_last.position.distance_to(_nodes[i].position), 1.0, 1e8)
		_pm_points.append(pm_point_new)
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color.from_hsv(float(i) / _nodes.size(), 0.8, 1.0)
		_nodes[i].set_surface_override_material(0, mat)

func root_move(_delta_: Vector3):
	_root.position += _delta_

func apply_gravity(_value_: Vector3):
	_local_gravity = global_basis.inverse() * _value_

func apply_force(_value_: Vector3):
	_local_force = global_basis.inverse() * _value_

func solve(_delta_: float) -> void:
	_pm_points[0].pin_to(_root.position)
	for pm_point: PMPoint in _pm_points:
		pm_point.apply_force(_local_gravity + _local_force)
	_pm_solver.process(_pm_points)
	for i in _pm_points.size():
		if i > 0:
			_nodes[i - 1].position = _pm_points[i].p
	_local_force = Vector3.ZERO
