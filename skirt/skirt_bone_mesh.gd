@tool
class_name SkirtBoneMesh
extends Node3D

@export var _skeleton: Skeleton3D
@export var _chains: Array[Vector2i]
@export var _colliders: Array[BoneCollider]
@export var _distance_curve: Curve
@export var _stiffness_curve: Curve

var _bone_mesh: BoneMesh

func initialize() -> void:
	_bone_mesh = BoneMesh.new()
	_bone_mesh.initialize()
	_bone_mesh.parent_set(self)
	_bone_mesh.colliders_set(_colliders)
	_bone_mesh.skeleton_set(_skeleton, _skeleton.get_parent().position)
	for vi: int in _chains.size():
		var v: Vector2i = _chains[vi]
		for i: int in v[1]:
			if i == 0:
				_bone_mesh.bones_add(v[0] + i, 0.0)
			elif i < v[1] - 1:
				_bone_mesh.bones_add(v[0] + i, -1.0)
			else:
				_bone_mesh.bones_add(v[0] + i, 0.12)
	_bone_mesh.generate_triangles()
	_bone_mesh.generate_cross_links(1.0)
	_bone_mesh.generate_clamp(_distance_curve, _stiffness_curve)
	if not Engine.is_editor_hint():
		set_process(false)
		set_physics_process(false)

func physics_process(_delta_: float) -> void:
	_bone_mesh.force = global_basis.inverse() * Vector3(0.0, -9.8, 0.0)
	_bone_mesh.solve()

func process(_delta_: float) -> void:
	if not _debug:
		return
	_bone_mesh.debug_draw()

#region editor
@export var _debug: bool:
	set(_value_):
		_debug = _value_
		if _value_ and Engine.is_editor_hint():
			initialize()
			set_process(true)
			set_physics_process(true)

func _physics_process(_delta_: float) -> void:
	if not _debug:
		return
	physics_process(_delta_)

func _process(_delta_: float) -> void:
	process(_delta_)
#endregion
