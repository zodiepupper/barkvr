class_name InteractionRay
extends Node3D

@export var interaction_index :int = 0

@onready var line_3d = $Line3D
@onready var vis: Node3D = $rayvis
var vispos := Vector3()

var prevHover:Node
var prevPressed:Node
var clickedObject:Node
var pressed := false:
	set(val):
		pressed = val

var using_touch := false
var touch_timer := Timer.new()

var otherray : InteractionRay

var last_point := Vector3()
var last_dist := float()

## set whether the node should cast a ray every frame or not
@export var enabled := true

## sets whether the ray should follow the mouse cursor position
## intended to easily keep the target aligned with controllers
@export var follow_mouse := true

## enables smoothing which applys a lerp to the
## target position to smooth out jittery controller
## movements when aiming at things
@export var smoothing_enabled := false

## this controls the speed at which the lerp function
## interpolates toward the new target point
@export var smoothing_speed := .1

## used to track previous position the raycast casted to
## so we can use it as the `from` in the lerpf for smoothing
var last_to_position : Vector3

## only works if `enabled = true`
## sets whether the raycast being run every frame should run on
## the process loop (true) or the physics_process loop (false)
@export var query_on_process := false

## the global position the raycast will query to 
## for collisions the start position is always
## the current global position of the node itself
## (this can be made into a local position if
## `target_position_is_local = true`
@export var target_position := Vector3(0,0,-1)

@export var target_position_is_local := true

## a list of RIDs that the raycast query will
## exclude when checking for collisions
var query_exceptions : Array[RID]

## a list of CollisionObject3D nodes to be excluded
## when the raycast queries for collisions 
## (this is mostly an editor helper so you can set
## excluded nodes in the editor)
@export var query_exception_nodes : Array[CollisionObject3D]:
	set(val):
		query_exception_nodes = val
		for i : CollisionObject3D in val:
			if i.get_rid() not in query_exceptions:
				query_exceptions.append(i.get_rid())

## the collision layers the ui raycast should collide with
@export_flags_3d_physics var private_ui_collision_layers : int

## the collision layers the ui raycast should collide with
@export_flags_3d_physics var edit_ui_collision_layers : int

## the collision layers the world raycast should collide with
@export_flags_3d_physics var world_collision_layers : int

## Dictionary to keep the data from the raycast query results
## and assign them to the helper values to make it close to 
## a drop-in for raycast3d nodes
var query_collision_data : Dictionary:
	set(val):
		query_collision_data = val
		if query_collision_data.is_empty():
			query_collider = null
			query_collider_id = -1
			query_normal = Vector3()
			query_position = Vector3()
			query_face_index = -1
			query_rid = RID()
			query_shape = -1
			query_is_colliding = false
		else:
			query_collider = query_collision_data["collider"]
			query_collider_id = query_collision_data["collider_id"]
			query_normal = query_collision_data["normal"]
			query_position = query_collision_data["position"]
			query_face_index = query_collision_data["face_index"]
			query_rid = query_collision_data["rid"]
			query_shape = query_collision_data["shape"]
			query_is_colliding = true
var query_collider : Node
var query_collider_id : int
var query_normal : Vector3
var query_position : Vector3
var query_face_index : int
var query_rid : RID
var query_shape : int
var query_is_colliding : bool

#func _ready() -> void:
	#query_exception_nodes = query_exception_nodes

## runs the physics query for the raycast
## this now uses 2 raycasts to enforce a selection bias
## on what object is being interacted with (ui, vs world objects)
func query_raycast() -> Dictionary:
	query_collision_data = Dictionary()
	var physspace := get_world_3d().direct_space_state
	var rayquery := PhysicsRayQueryParameters3D.new()
	#last_to_position # TODO finish raycast smoothing
	rayquery.from = global_position
	if target_position_is_local:
		rayquery.to = to_global(target_position)
	else:
		rayquery.to = target_position
	rayquery.exclude = query_exceptions
	rayquery.collision_mask = private_ui_collision_layers
	query_collision_data = physspace.intersect_ray(rayquery)
	if query_collision_data.is_empty():
		rayquery.collision_mask = edit_ui_collision_layers
		query_collision_data = physspace.intersect_ray(rayquery)
	if query_collision_data.is_empty():
		rayquery.collision_mask = world_collision_layers
		query_collision_data = physspace.intersect_ray(rayquery)
	return query_collision_data

## returns the query position from the last raycast
func get_collision_point() -> Vector3:
	return query_position

func is_colliding() -> bool:
	return query_is_colliding

func get_collider() -> CollisionObject3D:
	return query_collider

func add_exception(node : CollisionObject3D) -> void:
	if node not in query_exception_nodes:
		query_exception_nodes.append(node)

func remove_exception(node : CollisionObject3D) -> void:
	if node in query_exception_nodes:
		query_exception_nodes.erase(node)
	var node_rid : RID = node.get_rid()
	if query_exceptions.has(node_rid):
		query_exceptions.erase(node_rid)

func add_exception_rid(rid : RID) -> void:
	if query_exceptions.has(rid):
		query_exceptions.erase(rid)

func _ready() -> void:
	add_child(touch_timer)
	touch_timer.timeout.connect(func():
		using_touch = false
		)

func _process(_delta):
	if enabled and query_on_process:
		query_raycast()
		# updates the raycast visuals
		procrayvis()
		# run the interaction function
		interact()

func _physics_process(_delta: float) -> void:
	if enabled and !query_on_process:
		query_raycast()
		# updates the raycast visuals
		procrayvis()
		# run the interaction function
		interact()

func interact() -> void:
	var tmpcol
	var point : Vector3
	if last_point.is_zero_approx():
		point = to_global(target_position)
	else:
		point = to_global( target_position.normalized()*( global_position.distance_to(last_point) ) )
	if is_instance_valid(prevHover):
		tmpcol = prevHover
		if query_is_colliding:
			if get_collider() == prevHover:
				point = get_collision_point()
				last_point = point
			elif !pressed:
				tmpcol = get_collider()
				if "laser_input" in prevHover:
					prevHover.laser_input({
						'hovering': prevHover == tmpcol,
						'pressed': false,
						'position': point,
						'action': 'hover',
						'index': interaction_index
					})
				prevHover = tmpcol
		else:
			if !pressed:
				if "laser_input" in prevHover:
					prevHover.laser_input({
						'hovering': prevHover == tmpcol,
						'pressed': false,
						'position': point,
						'action': 'hover',
						'index': interaction_index
					})
				last_point = Vector3()
				prevHover = null
	elif is_colliding():
		tmpcol = get_collider()
		point = get_collision_point()
		last_point = point
		prevHover = tmpcol
	if is_instance_valid(tmpcol) and "laser_input" in tmpcol:
		tmpcol.laser_input({
			'hovering': prevHover == tmpcol,
			'pressed': pressed,
			'position': point,
			'action': 'hover',
			'index': interaction_index
		})

func procrayvis():
	if query_is_colliding:
		vispos = query_position
		line_3d.target = line_3d.to_local(query_position)
		if is_instance_valid(query_collider):
			if query_collider.is_class("RigidBody3D"):
				vis.setType('rigidbody')
			else:
				vis.setType('pointer')
	else:
		vispos = target_position
		# set the endpoint of the line3d to the target_position of the raycast
		line_3d.target = target_position
	vis.target = vispos

func _input(event):
	using_touch = false
	if follow_mouse and event is InputEventScreenTouch or event is InputEventScreenDrag:
		using_touch = true
		target_position = to_local(get_viewport().get_camera_3d().project_position(event.position,10000))
	if event is InputEventGesture:
		if is_colliding() and prevHover is Panel3D:
			prevHover.laser_input({
				'action':'custom',
				'position':get_collision_point(),
				'event':event,
				'ray_origin': global_position,
				'ray_direction': to_global(target_position),
				'index': -1
			})
	if follow_mouse and event is InputEventMouse:
		# if we aren't in vr... (note, this function assumes that `target_position_is_local = true`)
		if !get_viewport().use_xr and !using_touch:
			# and the mouse is not captured by the window...
			if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
				# get the current viewport's camera and project a ray
				# from the camera based on the cursor position
				var cam = get_viewport().get_camera_3d()
				target_position = to_local(cam.project_position(get_viewport().get_mouse_position(),10000))
			# and the mouse is captured by the window...
			else:
				# set the target_position to be very far straight ahead
				target_position = Vector3(0,0,-10000)
		if event is InputEventMouseButton and event.pressed:
			match event.button_index:
				4:
					scrollup()
				5:
					scrolldown()
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		var cam = get_viewport().get_camera_3d()
		target_position = to_local(cam.project_position(get_viewport().size/2,10000))

#func _physics_process(_delta):
	#if enabled and !query_on_process:
		#query_raycast()
		## updates the raycast visuals
		#procrayvis()
		## run the interaction function
		#interact()

func scrollup():
	if query_is_colliding:
		var tmpcol = get_collider()
		if tmpcol.has_method("laser_input"):
			tmpcol.laser_input({
				"position": get_collision_point(),
				"pressed": true,
				"action": "scrollup",
				'index': interaction_index
				})
			tmpcol.laser_input({
				"position": get_collision_point(),
				"pressed": false,
				"action": "scrollup",
				'index': interaction_index
				})

func scrolldown():
	if is_colliding():
		var tmpcol = get_collider()
		if tmpcol.has_method("laser_input"):
			tmpcol.laser_input({
				"position": get_collision_point(),
				"pressed": true,
				"action": "scrolldown",
				'index': interaction_index
				})
			tmpcol.laser_input({
				"position": get_collision_point(),
				"pressed": false,
				"action": "scrolldown",
				'index': interaction_index
				})

func click():
	LocalGlobals.playerreleaseuifocus.emit()
	match LocalGlobals.player_state:
		LocalGlobals.PLAYER_STATE_PLAYING:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		LocalGlobals.PLAYER_STATE_PAUSED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if is_colliding():
		var tmpcol = get_collider()
		if tmpcol.has_method("laser_input"):
			tmpcol.laser_input({
				"position": query_position,
				"pressed": true,
				'action': 'click',
				'index': interaction_index
				})
			pressed = true
			prevPressed = tmpcol

func release():
	if is_colliding() and !prevPressed:
		var tmpcol = get_collider()
		if tmpcol.has_method("laser_input"):
			tmpcol.laser_input({
				"position": query_position,
				"pressed": false,
				'action': 'click',
				'index': interaction_index
				})
			pressed = false
	elif is_instance_valid(prevPressed):
		var tmpcol = prevPressed
		if tmpcol.has_method("laser_input"):
			tmpcol.laser_input({
				"position": query_position,
				"pressed": false,
				'action': 'click',
				'index': interaction_index
				})
			pressed = false
	prevPressed = null
