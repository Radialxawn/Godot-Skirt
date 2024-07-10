class_name PMLink
extends RefCounted

var distance: float
var stiffness: float
var tear_distance: float
  
var _p1: PMPoint
var _p2: PMPoint

func _init(_p1_: PMPoint, _p2_: PMPoint, _distance_: float, _stiffness_: float, _tear_distance_: float) -> void:
	_p1 = _p1_
	_p2 = _p2_
	distance = _distance_
	stiffness = _stiffness_
	tear_distance = _tear_distance_

func solve() -> void:
	# calculate difference
	var delta_p: Vector3 = _p1.p - _p2.p
	var d: float = delta_p.length()
	if d > tear_distance:
		_p1.remove_link(self)
	var d_rest: float = (distance - d) / d;
	# inverse mass
	var im1: float = 1.0 / _p1.mass
	var im2: float = 1.0 / _p2.mass
	var scalar1: float = (im1 / (im1 + im2)) * stiffness
	var scalar2: float = stiffness - scalar1
	# push/pull
	_p1.p += delta_p * scalar1 * d_rest
	_p2.p -= delta_p * scalar2 * d_rest
