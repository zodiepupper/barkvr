class_name rayvisscript
extends RayCast3D

var rayvis = preload("res://mainSystem/scenes/player/rayvis.tscn")
var vis
var vispos := Vector3()

var query_collision_data : Dictionary:
	set(val):
		query_collision_data = val
		if !query_collision_data.is_empty():
			query_collider = query_collision_data["collider"]
			query_collider_id = query_collision_data["collider_id"]
			query_normal = query_collision_data["normal"]
			query_position = query_collision_data["position"]
			query_face_index = query_collision_data["face_index"]
			query_rid = query_collision_data["rid"]
			query_shape = query_collision_data["shape"]
			query_is_colliding = true
		else:
			query_is_colliding = false
var query_collider : CollisionObject3D
var query_collider_id : int
var query_normal : Vector3
var query_position : Vector3
var query_face_index : int
var query_rid : RID
var query_shape : CollisionShape3D
var query_is_colliding : bool

func _init():
	vis = rayvis.instantiate()
	add_child.call_deferred(vis)

func procrayvis():
	vispos = get_collision_point()
	query_collision_data = Dictionary()
	if enabled:
		var physspace := get_world_3d().direct_space_state
		var rayquery := PhysicsRayQueryParameters3D.new()
		rayquery.from = global_position
		rayquery.to = to_global(Vector3(0,0,-10000))
		query_collision_data = physspace.intersect_ray(rayquery)
	if query_is_colliding:
		if is_instance_valid(query_collider):
			if query_collider.is_class("RigidBody3D"):
				vis.setType('rigidbody')
			else:
				vis.setType('pointer')
	else:
		vispos = to_global(Vector3(0,0,-10))
	vis.target = vispos
#	vis.target.x = lerpf(vis.target.x, vispos.x, .9)
#	vis.target.z = lerpf(vis.target.z, vispos.z, .9)
#	vis.target.y = lerpf(vis.target.y, vispos.y, .9)
	
