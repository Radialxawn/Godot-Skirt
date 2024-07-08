class_name SkirtBoneMesh
extends Node3D

@export var _skeleton: Skeleton3D
@export var _chains: Array[Vector2i]
@export var _colliders: Array[BoneCollider]

var _bone_mesh: BoneMesh = BoneMesh.new()

func intialize() -> void:
	pass

func physics_process(_delta_: float) -> void:
	pass
