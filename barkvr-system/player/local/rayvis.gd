extends Node3D
@onready var pointer = $pointer
@onready var physics = $physics
@onready var cursor = $cursor

@export var mouse_cursor := false

var cursor_size_factor = 50.0

var target := Vector3()

func _process(_delta):
	if get_tree().get_first_node_in_group("player"):
		var dist = target.distance_to(get_viewport().get_camera_3d().global_position)
		cursor.scale = Vector3(1,1,1)*dist/cursor_size_factor
		cursor.global_position = target
		cursor.look_at(get_viewport().get_camera_3d().global_position,Vector3.UP,true)

func setType(_type:String):
	cursor.show()
