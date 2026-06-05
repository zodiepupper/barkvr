extends Node3D
@onready var pointer = $pointer
@onready var physics = $physics
@onready var cursor = $cursor

@export var path3d : Path3D
## tells the laser to originate from the desktop_laser_origin
@export var mouse_cursor := false
## a global position that can be used to make the laser originate from
## somewhere else. this is used to make the desktop laser come from a 
## hand
@export var global_laser_origin_override := Vector3():
	set(val):
		global_laser_origin_override = val
		if "global_origin_offset" in path3d:
			path3d.global_origin_offset = val

var cursor_size_factor = 50.0

## target position (global)
var target := Vector3():
	set(val):
		target = val
		proc_rayvis()

signal target_updated()

func proc_rayvis():
	if get_tree().get_first_node_in_group("player"):
		if mouse_cursor:
			match SettingsSingleton.instance.desktop_laser_origin:
				0:
					global_laser_origin_override = (get_tree().get_first_node_in_group("player") as BarkvrPlayerController).lefthand.global_position
				1:
					global_laser_origin_override = (get_tree().get_first_node_in_group("player") as BarkvrPlayerController).righthand.global_position
				2:
					global_laser_origin_override = Vector3()
		var current_camera = get_viewport().get_camera_3d()
		var dist = target.distance_to(current_camera.global_position)
		cursor.scale = Vector3(1,1,1)*dist/cursor_size_factor
		cursor.global_position = target
		# this check avoids the "colinear UP and target" issue by only performing the lookat
		# if the operation inputs are valid
		if abs(current_camera.global_position.dot(Vector3.UP)) < 1.0 :
			cursor.look_at(current_camera.global_position,Vector3.UP,true)
		if path3d and "new_pos" in path3d:
			path3d.new_pos = to_local(target)

func setType(_type:String):
	cursor.show()
