class_name BarkGizmo
extends Node3D
## A custom gizmo to modify 3D nodes at runtime.



## The source of this gizmo, usually a scene view.
@export var source: Node
## The target of this gizmo.
@export var target: Node

## Size factor by which to multiply the camera scale of this gizmo.
var size_factor: float = 7.5

@onready var x = $x
@onready var y = $y
@onready var z = $z



func _ready():
	LocalGlobals.clear_gizmos.connect(queue_free)
	#_physics_process(0)



func _physics_process(_delta: float) -> void:
	# Free gizmo if target or source is invalid.
	if not is_instance_valid(target) or not is_instance_valid(source):
		queue_free()
		return

	# Scale gizmo by distance to the camera.
	var camera_distance: float = get_viewport().get_camera_3d().global_position.distance_to(global_position)
	var newscale: Vector3 = Vector3.ONE * camera_distance / size_factor

	# Ensure minimum scale.
	if newscale.length() < 0.01:
		newscale = Vector3(0.01, 0.01, 0.01)

	# Apply scale & position.
	global_position = target.global_position
	global_basis = target.global_basis
	scale = newscale
