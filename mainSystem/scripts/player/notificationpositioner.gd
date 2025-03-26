extends Node3D

var offset = 0

func _process(delta) -> void:
	var vr_offset := Vector2(
		get_viewport().size.x*Engine.get_singleton("settings_manager").vr_notification_offset.x,
		get_viewport().size.y*Engine.get_singleton("settings_manager").vr_notification_offset.y
		)
	global_position = get_viewport().get_camera_3d().project_position(vr_offset, 10.0)
	Engine.get_singleton("settings_manager")
	offset = 0
	for i in get_children():
		i.position.y = offset
		offset += i.get_aabb().size.y
