extends Node3D
@onready var x = $x
@onready var y = $y
@onready var z = $z
@export var target:Node

var size_factor = 7.5

func _ready():
	LocalGlobals.clear_gizmos.connect(func():
		queue_free()
		)

func _physics_process(delta):
	if is_instance_valid(target):
		var dist = get_viewport().get_camera_3d().global_position.distance_to(global_position)
		var newscale :Vector3 = Vector3(1,1,1)*dist/size_factor
		
		newscale = Vector3(.01,.01,.01) if newscale.length() < .01 else newscale
		
		scale = newscale
		global_position = target.global_position
	else:
		queue_free()
