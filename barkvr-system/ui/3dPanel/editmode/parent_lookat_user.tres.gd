extends Node

@export var flipped := true
@export var x: bool:
	get:
		return (Engine.get_singleton("settings_manager") as SettingsSingleton).ui_local_menu_lookat_x
@export var y: bool:
	get:
		return (Engine.get_singleton("settings_manager") as SettingsSingleton).ui_local_menu_lookat_y
@export var z: bool:
	get:
		return (Engine.get_singleton("settings_manager") as SettingsSingleton).ui_local_menu_lookat_z

func _ready() -> void:
	var settings_singleton := Engine.get_singleton("settings_manager")
	if settings_singleton is SettingsSingleton:
		(settings_singleton as SettingsSingleton).changed.connect(on_settings_changed)
	_position_the_thing()

func _position_the_thing() -> void:
	var prev_rot :Vector3= get_parent().rotation
	get_parent().look_at(get_tree().get_first_node_in_group('player').get_viewport().get_camera_3d().global_position, Vector3.UP, flipped)
	if !x:
		get_parent().rotation.x = prev_rot.x
	if !y:
		get_parent().rotation.y = prev_rot.y
	if !z:
		get_parent().rotation.z = prev_rot.z
	create_tween().tween_callback(_position_the_thing).set_delay(.05)

func on_settings_changed(setting_name: StringName) -> void:
	var settings_singleton := Engine.get_singleton("settings_manager")
	if settings_singleton is SettingsSingleton:
		match setting_name:
			&"ui_local_menu_lookat_x":
				x = (settings_singleton as SettingsSingleton).ui_local_menu_lookat_x
			&"ui_local_menu_lookat_y":
				y = (settings_singleton as SettingsSingleton).ui_local_menu_lookat_y
			&"ui_local_menu_lookat_z":
				z = (settings_singleton as SettingsSingleton).ui_local_menu_lookat_z
