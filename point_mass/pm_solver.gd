class_name PMSolver
extends RefCounted

var _time_last: int
var _time: int
var _time_delta_msec: int
var _time_delta_msec_left_over: int
var _time_delta_sec: float
var _sub_step_count: int

var step_methods: Array[Callable]

func _init(_time_delta_msec_: int, _sub_step_count_: int) -> void:
	_time_delta_msec = clampi(_time_delta_msec_, 10, 33)
	_time_delta_msec_left_over = 0
	_time_delta_sec = float(_time_delta_msec) * 1e-3
	_sub_step_count = clampi(_sub_step_count_, 1, 10)

func process(_points_: Array[PMPoint]) -> void:
	_time = Time.get_ticks_msec()
	var delta_time_msec: int = _time - _time_last
	_time_last = _time
	var step_count: int = int(float(delta_time_msec + _time_delta_msec_left_over) / float(_time_delta_msec))
	step_count = mini(step_count, 5)
	_time_delta_msec_left_over = delta_time_msec - (step_count * _time_delta_msec)
	for step in step_count:
		for sub_step in _sub_step_count:
			for point: PMPoint in _points_:
				point.solve_constraints()
		for point: PMPoint in _points_:
			point.process(_time_delta_sec)
		for method: Callable in step_methods:
			method.call()
