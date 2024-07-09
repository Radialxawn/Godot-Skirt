@tool
class_name SkirtBoneChain
extends Node3D

@export var _skeleton: Skeleton3D
@export var _chains: Array[Vector2i]
@export var _colliders: Array[BoneCollider]

var _bone_chains: Array[BoneChain]

func initialize() -> void:
	_bone_chains = []
	for v_i in _chains.size():
		var bone_chain: BoneChain = BoneChain.new()
		_bone_chains.append(bone_chain)
		bone_chain.initialize()
		bone_chain.parent_set(self)
		bone_chain.colliders_set(_colliders)
		bone_chain.skeleton_set(_skeleton, _skeleton.get_parent().position)
		var bone_radius = 0.01
		var i_s: int = _chains[v_i][0]
		var i_e: int = _chains[v_i][0] + _chains[v_i][1]
		for i in range(i_s, i_e):
			if i == i_s:
				bone_chain.bone_root_set(i)
			elif i == i_e - 1:
				bone_chain.bones_add(i, 0.1, bone_radius)
			else:
				var tf_i: Transform3D = _skeleton.get_bone_global_rest(i)
				var tf_i_n: Transform3D = _skeleton.get_bone_global_rest(i + 1)
				bone_chain.bones_add(i, tf_i.origin.distance_to(tf_i_n.origin), bone_radius)
		bone_chain.snap_back_setup([20e-3, 20e-3, 20e-3], [20e-3, 10e-3, 5e-3])
	if not Engine.is_editor_hint():
		set_process(false)
		set_physics_process(false)

func physics_process(_delta_: float) -> void:
	for chain in _bone_chains:
		chain.force = global_basis.inverse() * Vector3(0.0, -9.8, 0.0)
		chain.solve()

func process(_delta_: float) -> void:
	if not _debug:
		return
	for chain in _bone_chains:
		chain.debug_draw(global_transform)

func reset():
	for chain in _bone_chains:
		chain.reset()

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
