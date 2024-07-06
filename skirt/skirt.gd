class_name Skirt
extends Node3D

@export var _rope: Rope
@export var _skeleton: Skeleton3D
@export var _chains: Array[Vector2i]
@export var _colliders: Array[BoneCollider]

var _bone_chains: Array[BoneChain]

var _mouse_button_index: int
var _mouse_data_begin: Dictionary
var _mouse_motion_time_msec_last: int
var _solve_auto: bool

func _ready() -> void:
	for v_i in _chains.size():
		var bone_chain: BoneChain = BoneChain.new()
		_bone_chains.append(bone_chain)
		bone_chain.initialize()
		bone_chain.parent_set(self)
		bone_chain.colliders_set(_colliders)
		bone_chain.skeleton_set(_skeleton, _skeleton.get_parent().position)
		var i_s: int = _chains[v_i][0]
		var i_e: int = _chains[v_i][0] + _chains[v_i][1]
		for i in range(i_s, i_e):
			if i == i_s:
				bone_chain.bone_root_set(i)
			elif i == i_e - 1:
				bone_chain.bones_add(i, 0.1)
			else:
				var tf_i: Transform3D = _skeleton.get_bone_global_rest(i)
				var tf_i_n: Transform3D = _skeleton.get_bone_global_rest(i + 1)
				bone_chain.bones_add(i, tf_i.origin.distance_to(tf_i_n.origin))
		bone_chain.snap_back_setup(0.005)
	_rope.initialize()
	_solve_auto = true

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
		_mouse_data_begin.target_quaternion = quaternion
		_mouse_data_begin.target_position = global_position
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
				KEY_M:
					_solve_auto = not _solve_auto
				KEY_R:
					_reset()

func _input_mouse_move(_mouse_motion_: InputEventMouseMotion) -> void:
	var camera: Camera3D = get_viewport().get_camera_3d()
	var delta: Vector3 = (_camera_project_position(camera, _mouse_motion_.position, global_position)
		- _camera_project_position(camera, _mouse_data_begin.position, global_position)
		)
	global_position = _mouse_data_begin.target_position + delta
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
		_camera_project_position(camera, _mouse_data_begin.position, global_position)
			.direction_to(_camera_project_position(camera, _mouse_data_begin.position + n, global_position)),
		delta_rad
		)
	quaternion = quat * _mouse_data_begin.target_quaternion

func _camera_project_position(_camera_: Camera3D, _screen_position_: Vector2, _position_: Vector3) -> Vector3:
	var distance = (_position_ - _camera_.global_position).dot(-_camera_.global_basis.z)
	return _camera_.project_position(_screen_position_, distance)

func _physics_process(_delta_: float) -> void:
	if _solve_auto:
		_solve(_delta_)
	_debug_draw()
	_rope.apply_gravity(Vector3(0.0, -9.8, 0.0))
	_rope.solve(_delta_)
	if Input.is_key_pressed(KEY_LEFT):
		_rope.root_move(Vector3.LEFT * _delta_ * 0.3)
	if Input.is_key_pressed(KEY_RIGHT):
		_rope.root_move(Vector3.RIGHT * _delta_ * 0.3)
	if Input.is_key_pressed(KEY_DOWN):
		_rope.root_move(Vector3.DOWN * _delta_ * 0.3)
	if Input.is_key_pressed(KEY_UP):
		_rope.root_move(Vector3.UP * _delta_ * 0.3)

func _solve(_delta_: float) -> void:
	for chain in _bone_chains:
		chain.force = to_local(global_position + Vector3(0.0, -9.8, 0.0))
		chain.solve()

func _reset():
	for chain in _bone_chains:
		chain.reset()

#region debug
func _debug_draw():
	for chain in _bone_chains:
		chain.debug_draw(global_transform)
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
#endregion
