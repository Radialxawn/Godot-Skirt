class_name PMPoint
extends RefCounted

var p: Vector3
var mass: float = 1.0
var _pin: bool = false
var _pin_p: Vector3
var _p_last: Vector3
var _accel: Vector3
var _links: Array = []

func _init(_position_: Vector3) -> void:
	p = _position_
	_p_last = p
	_accel = Vector3.ZERO

func process(_delta_: float) -> void:
	var v: Vector3 = p - _p_last
	v *= 0.99
	var delta_sq: float = _delta_ * _delta_
	var p_next: Vector3 = p + v + 0.5 * _accel * delta_sq
	_p_last = p
	p = p_next
	_accel = Vector3.ZERO

func solve_constraints() -> void:
	for link: PMLink in _links:
		link.solve()
	if _pin:
		p = _pin_p

func links_add(_target_: PMPoint, _distance_: float, _stiffness_: float, _tear_sensitivity_: float) -> void:
	var link: PMLink = PMLink.new(self, _target_, _distance_, _stiffness_, _tear_sensitivity_)
	_links.append(link)

func links_remove(_link_: PMLink) -> void:
	_links.erase(_link_)

func apply_force(_value_: Vector3) -> void:
	_accel += _value_ / mass;

func pin_to(_position_: Vector3) -> void:
	_pin = true
	_pin_p = _position_
