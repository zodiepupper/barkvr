extends StaticBody3D



@export_enum("x", "y", "z", "xy", "xz", "yz") var axis: String = "x"

var prev_click_pos: Vector3

var interaction_index: int = -1

var offset := Vector3()

@onready var gizmo: Node3D = $".."


func laser_input(data: Dictionary) -> void:
	if data.pressed:
		interaction_index = data.index

	if gizmo.target and prev_click_pos != data.position and data.index == interaction_index:
		if prev_click_pos and data.pressed:
			#_set_colliders(true)
			var tmppos: Vector3 = gizmo.target.global_position
			match axis:
				"x", "y", "z":
					tmppos[axis] = data.position[axis] - offset[axis]
				"xz":
					tmppos["x"] = data.position["x"] - offset["x"]
					tmppos["z"] = data.position["z"] - offset["z"]
				"xy":
					tmppos["x"] = data.position["x"] - offset["x"]
					tmppos["y"] = data.position["y"] - offset["y"]
				"yz":
					tmppos["y"] = data.position["y"] - offset["y"]
					tmppos["z"] = data.position["z"] - offset["z"]
			gizmo.target.global_position = tmppos
			prev_click_pos = data.position
		else:
			interaction_index = -1
			#_set_colliders(false)
			prev_click_pos = data.position
			offset = data.position-gizmo.target.global_position
			if is_instance_valid(Engine.get_singleton(&"event_manager")):
				Engine.get_singleton(&"event_manager").set_property(
					get_tree().get_first_node_in_group(&"localworldroot").get_path_to(gizmo.target),
					"global_position",
					gizmo.target.global_position
				)

	elif data.has("hovering"):
		if !data.hovering:
			interaction_index = -1
			#_set_colliders(false)
			prev_click_pos = Vector3()
			offset = Vector3()
