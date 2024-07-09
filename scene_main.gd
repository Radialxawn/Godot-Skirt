class_name SceneMain
extends Node3D

@export var _camera_origin: Node3D
@export var _rope: Rope
@export var _skirt_bone_chain: SkirtBoneChain
@export var _skirt_bone_mesh: SkirtBoneMesh
@export var _colliders: Array[BoneCollider]

var _mouse_button_index: int
var _mouse_data_begin: Dictionary
var _mouse_motion_time_msec_last: int

func _ready() -> void:
	_rope.initialize()
	_skirt_bone_chain.initialize()
	_skirt_bone_mesh.initialize()

func _process(_delta_: float) -> void:
	_skirt_bone_chain.process(_delta_)
	_skirt_bone_mesh.process(_delta_)
	_debug_draw()

func _physics_process(_delta_: float) -> void:
	_rope.apply_gravity(Vector3(0.0, -9.8, 0.0))
	_rope.solve(_delta_)
	_skirt_bone_chain.physics_process(_delta_)
	_skirt_bone_mesh.physics_process(_delta_)

func _input(_event_: InputEvent) -> void:
	if _event_ is InputEventMouseButton:
		var mb: InputEventMouseButton = _event_
		if mb.pressed:
			_mouse_button_index = mb.button_index
			if mb.button_index == 4:
				_colliders[-1].radius += 0.01
			elif mb.button_index == 5:
				_colliders[-1].radius -= 0.01
		else:
			_mouse_button_index = 0
		_mouse_data_begin.position = mb.position
		_mouse_data_begin.target_quaternion = _camera_origin.quaternion
		_mouse_data_begin.target_position = _skirt_bone_chain.global_position
		_mouse_data_begin.target_position_collider = _colliders[-1].global_position
		_mouse_motion_time_msec_last = Time.get_ticks_msec()
	elif _event_ is InputEventMouseMotion:
		match _mouse_button_index:
			1:
				_input_mouse_move(_event_)
			2:
				_input_mouse_move_collider(_event_)
			3:
				_input_mouse_rotate(_event_)
	elif  _event_ is InputEventKey:
		var k: InputEventKey = _event_
		if k.is_pressed():
			match k.keycode:
				KEY_R:
					_skirt_bone_chain.reset()

func _input_mouse_move(_mouse_motion_: InputEventMouseMotion) -> void:
	var camera: Camera3D = get_viewport().get_camera_3d()
	var delta: Vector3 = (_camera_project_position(camera, _mouse_motion_.position, _skirt_bone_chain.global_position)
		- _camera_project_position(camera, _mouse_data_begin.position, _skirt_bone_chain.global_position)
		)
	_skirt_bone_chain.global_position = _mouse_data_begin.target_position + delta
	var time_delta_msec: int = Time.get_ticks_msec() - _mouse_motion_time_msec_last
	if time_delta_msec > 0:
		_rope.apply_force(-delta * (100.0 / time_delta_msec))
	_mouse_motion_time_msec_last = Time.get_ticks_msec()

func _input_mouse_move_collider(_mouse_motion_: InputEventMouseMotion) -> void:
	var camera = get_viewport().get_camera_3d()
	var target = _colliders[-1]
	var delta = (_camera_project_position(camera, _mouse_motion_.position, target.global_position)
		- _camera_project_position(camera, _mouse_data_begin.position, target.global_position)
		)
	target.global_position = _mouse_data_begin.target_position_collider + delta

func _input_mouse_rotate(_mouse_motion_: InputEventMouseMotion) -> void:
	var camera = get_viewport().get_camera_3d()
	var delta_mouse: Vector2 = _mouse_motion_.position - _mouse_data_begin.position
	var u: Vector2 = delta_mouse.normalized()
	var n: Vector2 = Vector2(u.y, -u.x)
	var size: Vector2 = get_viewport().get_visible_rect().size
	var delta_rad = remap(delta_mouse.length(), 0, size.x, 0, PI)
	var quat = Quaternion(
		_camera_project_position(camera, _mouse_data_begin.position, _camera_origin.global_position)
			.direction_to(_camera_project_position(camera, _mouse_data_begin.position + n, _camera_origin.global_position)),
		-delta_rad
		)
	_camera_origin.quaternion = quat * _mouse_data_begin.target_quaternion

func _camera_project_position(_camera_: Camera3D, _screen_position_: Vector2, _position_: Vector3) -> Vector3:
	var distance = (_position_ - _camera_.global_position).dot(-_camera_.global_basis.z)
	return _camera_.project_position(_screen_position_, distance)

func _debug_draw():
	DebugDraw3D.scoped_config().set_thickness(0.001)
	for collider: BoneCollider in _colliders:
		var a: Vector3 = collider.global_basis.y * (collider.height * 0.5 - collider.radius)
		DebugDraw3D.draw_cylinder_ab(
			collider.global_position - a,
			collider.global_position + a,
			collider.radius,
			Color.INDIAN_RED
			)
		DebugDraw3D.draw_sphere(
			collider.global_position - a,
			collider.radius,
			Color.INDIAN_RED
			)
		DebugDraw3D.draw_sphere(
			collider.global_position + a,
			collider.radius,
			Color.INDIAN_RED
			)
