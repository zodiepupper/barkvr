extends Node3D
@onready var pointer = $pointer
@onready var physics = $physics
@onready var cursor = $cursor

@export var path3d : Path3D 
@export var mouse_cursor := false
## a global position that can be used to 
@export var global_laser_origin_override := Vector3():
	set(val):
		global_laser_origin_override = val
		if "global_origin_offset" in path3d:
			path3d.global_origin_offset = val

var cursor_size_factor = 50.0

var target := Vector3():
	set(val):
		target = val
		proc_rayvis()

func proc_rayvis():
	if get_tree().get_first_node_in_group("player"):
		#global_laser_origin_override = global_laser_origin_override
		if mouse_cursor:
			global_laser_origin_override = (get_tree().get_first_node_in_group("player") as BarkvrPlayerController).righthand.global_position
		var current_camera = get_viewport().get_camera_3d()
		var dist = target.distance_to(current_camera.global_position)
		cursor.scale = Vector3(1,1,1)*dist/cursor_size_factor
		cursor.global_position = target
		cursor.look_at(current_camera.global_position,Vector3.UP,true)
		if path3d and "new_pos" in path3d:
			path3d.new_pos = to_local(target)

func setType(_type:String):
	cursor.show()
