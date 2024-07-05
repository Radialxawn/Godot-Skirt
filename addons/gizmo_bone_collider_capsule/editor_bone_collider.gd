@tool
extends EditorPlugin

const GizmoPlugin := preload("res://addons/gizmo_bone_collider_capsule/editor_gizmo_bone_collider.gd")
var gizmo_plugin: GizmoPlugin = GizmoPlugin.new()

func _enter_tree() -> void:
	add_node_3d_gizmo_plugin(gizmo_plugin)

func _exit_tree() -> void:
	remove_node_3d_gizmo_plugin(gizmo_plugin)
