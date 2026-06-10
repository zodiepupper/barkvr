extends Node3D

func _ready() -> void:
	_go()

func _go() -> void:
	var last_rotation:=rotation
	# this check avoids the "colinear UP and target" issue by only performing the lookat
	# if the operation inputs are valid
	if abs(get_viewport().get_camera_3d().global_position.dot(Vector3.UP)) < 1.0 :
		look_at(get_viewport().get_camera_3d().global_position)
	rotation.x = lerp_angle(last_rotation.x,rotation.x,.1)
	rotation.y = lerp_angle(last_rotation.y,rotation.y,.1)
	rotation.z = lerp_angle(last_rotation.z,rotation.z,.1)
	create_tween().tween_callback(_go).set_delay(1/120)
