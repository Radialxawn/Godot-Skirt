class_name BoneCollider
extends Node3D

@export var radius: float = 0.5:
	set(_value_):
		radius = clampf(_value_, 1e-5, 1e5)
		height = clampf(height, radius * 2.0 + 1e-5, 1e5)
@export var height: float = 2.0:
	set(_value_):
		height = clampf(_value_, radius * 2.0 + 1e-5, 1e5)
