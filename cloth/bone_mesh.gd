class_name BoneMesh
extends RefCounted

var _parent: Node3D
var _skeleton: Skeleton3D
var _skeleton_offset: Vector3
var _bones: Array[int]
var _bones_length: Array[float]
var _bones_transform_local_base: Array[Transform3D]
var _bones_position_tail_local_base: Array[Vector3]

var _colliders: Array[BoneCollider]

var _pm_solver: PMSolver = PMSolver.new()
var _pm_points: Array[PMPoint] = []

var force: Vector3

func initialize():
	_pm_solver.step_methods.append(_solve_collisions)
	_pm_solver.step_methods.append(_solve_constraints)
	_pm_solver.step_methods.append(_apply)

func _solve_collisions():
	pass

func _solve_constraints():
	pass

func _apply():
	pass
