extends CharacterBody3D

# TODO plans:
# use child nodes to modularize player abilities like grabbing and movement

#controllers:
@onready var righthand: BarkHand= %righthand
@onready var lefthand: BarkHand= %lefthand
@onready var xr_camera_3d: XRCamera3D = $xrplayer/XrCamera3d
@onready var camera_3d: Camera3D = $xrplayer/Camera3D
@onready var xrplayer: XROrigin3D = $xrplayer
@onready var playercamoffset: Node3D = $playercamoffset
@onready var collision_shape_3d: CollisionShape3D = %CollisionShape3D
@onready var ui_ray: InteractionRay = %uiRay
@onready var handmenu: Node3D = %handmenu
@onready var menuoffset: Node3D = %menuoffset
@onready var headiktarget: Node3D = %headiktarget
@onready var notificationparent: Node3D = %notificationparent
@onready var localui: Panel3D = %localui

var head_pos: =Vector3():
	get:
		return get_viewport().get_camera_3d().global_position

#controller input vars:
var rightStick :Vector2 = Vector2()
var rightGrip :float
var rightaxbtn :bool = false
var leftStick :Vector2 = Vector2()
var leftGrip :float
var leftaxbtn :bool = false

var camPrevPos : Vector3 = Vector3()

@export var SPEED := 5.0
@export var JUMP_VELOCITY := 4.5

@export var flymode := true:
	set(value):
		flymode = value
		if value:
			motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
		else:
			if noclip:
				noclip = false
			motion_mode = CharacterBody3D.MOTION_MODE_GROUNDED

@export var noclip := false:
	set(value):
		if value and !flymode:
			flymode = true
		noclip = value
		if collision_shape_3d:
			collision_shape_3d.disabled = value

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var selected : Array = []
var grabbed : Dictionary = {}
var grabbing : bool = false

# flat vars
var MOUSE_SPEED := .1
var JOY_SPEED := .05
var lookdrag : Dictionary = {} #{'index': -1,'relative': Vector2(),'velocity': Vector2()}
var lastlookdragindex : int = -1
var movedrag : Dictionary = {} #{'index': -1,'relative': Vector2(),'velocity': Vector2()}
var lastmovedragindex :int = -1
var touch_move_left := 0.0
var touch_move_right := 0.0
var touch_move_forward := 0.0
var touch_move_backward := 0.0
@export var touchsticklook := false
var grab_point := Vector3()
var screen_just_touched := false

@export var force_set_vr_enabled := false

var vr_mode_enabled := false:
	set(value):
		if force_set_vr_enabled:
			value = true
		vr_mode_enabled = value
		Notifyvr.send_notification("vrmode: "+str(value))
		_toggle_xr(value)

func _toggle_xr(value):
	if LocalGlobals:
		LocalGlobals.vr_supported = value
	if is_instance_valid(lefthand) and is_instance_valid(righthand):
		lefthand.rays_disabled = !value
		righthand.rays_disabled = !value
		ui_ray.enabled = !value
		ui_ray.visible = !value
	
	if !localui.is_node_ready():
		await localui.ready
	if value:
		localui.ui.reparent(localui.viewport)
		localui.colshape.disabled = false
		headiktarget.reparent(xr_camera_3d,false)
		if OS.get_name() != "Web":
			get_viewport().use_xr = true
		xr_camera_3d.current = true
	else:
		localui.ui.reparent(get_tree().root)
		localui.colshape.disabled = true
		headiktarget.reparent(camera_3d,false)
		Notifyvr.send_notification("DISABLING XR")
		collision_shape_3d.shape.height = 1.0
		collision_shape_3d.shape.radius = .1
		if OS.get_name() != "Web":
			get_viewport().use_xr = false
		camera_3d.current = true
		if get_viewport().get_camera_3d() is XRCamera3D:
			get_viewport().get_camera_3d()
		camera_3d.position.y = .9
		righthand.position = Vector3(.2,.6,-.2)
		lefthand.position = Vector3(-.2,.6,0.0)
		lefthand.rotation_degrees = Vector3(-90.0,0,0)
		ui_ray.enabled = true
		ui_ray.show()

func respawn_player():
	velocity = Vector3()
	var spawnLoc = get_tree().get_nodes_in_group("PlayerSpawnLocation").pick_random()
	if spawnLoc:
		global_position = spawnLoc.global_position
	else:
		global_position = Vector3(0,4,0)

func _ready():
	get_window().gui_focus_changed.connect(func(node):
		if LocalGlobals.player_state != LocalGlobals.PLAYER_STATE_TYPING:
			LocalGlobals.player_state = LocalGlobals.PLAYER_STATE_TYPING
		)
	LocalGlobals.player_state_changed.connect(func(state):
		match state:
			LocalGlobals.PLAYER_STATE_TYPING:
				LocalGlobals.emit_signal("playerreleaseuifocus")
			LocalGlobals.PLAYER_STATE_PLAYING:
				LocalGlobals.emit_signal("playerreleaseuifocus")
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			LocalGlobals.PLAYER_STATE_PAUSED:
				LocalGlobals.emit_signal("playerreleaseuifocus")
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		)
	name = OS.get_unique_id()
	ui_ray.add_exception(self)
	vr_mode_enabled = LocalGlobals.vr_supported
	lefthand.rays_disabled = !vr_mode_enabled
	righthand.rays_disabled = !vr_mode_enabled
	respawn_player()
	if !ProjectSettings.get_setting("xr/openxr/enabled"):
		vr_mode_enabled = false
	
	if OS.get_name() == "Web":
		vr_mode_enabled = false
	
	righthand.connect("button_pressed",func(input_name):
		if input_name == "ax_button":
			rightaxbtn = true
		)
	righthand.connect("button_released",func(input_name):
		if input_name == "ax_button":
			rightaxbtn = false
		)
	righthand.input_vector2_changed.connect(func(input_name:String,value):
		if input_name == "primary":
			rightStick = value
		)
	lefthand.connect("button_pressed",func(input_name):
		if input_name == "ax_button":
			leftaxbtn = true
		)
	lefthand.connect("button_released",func(input_name):
		if input_name == "ax_button":
			leftaxbtn = false
		)
	lefthand.input_vector2_changed.connect(func(input_name:String,value):
		if input_name == "primary":
			leftStick = value
		)

func _physics_process(delta:float) -> void:
	if !DisplayServer.window_is_focused(0) and LocalGlobals.player_state != LocalGlobals.PLAYER_STATE_PAUSED:
		LocalGlobals.player_state = LocalGlobals.PLAYER_STATE_PAUSED
	if !vr_mode_enabled:
		menuoffset.global_rotation = Vector3()
	if global_position.length() > 100000:
		respawn_player()
		flymode = true
	
	# Flat mode toggle
	if Input.is_action_just_pressed("desktoptoggle"):
		vr_mode_enabled = !vr_mode_enabled

	if vr_mode_enabled:
		vr_movement(delta)
	
	if !vr_mode_enabled:
		flat_movement(delta)
	
	var prevyvel = velocity.y
	velocity = velocity.move_toward(Vector3(), SPEED*.5)
	
	# Add the gravity.
	if not is_on_floor() and not flymode:
		velocity.y = prevyvel
		velocity.y -= (gravity*1.0*( (scale.x+scale.y+scale.z)/3.0 )) * delta
	
	# Handle Jump.
	if (Input.is_action_just_pressed("jump") or (flymode and Input.is_action_pressed("jump")) or rightaxbtn) and (is_on_floor() or flymode) and (LocalGlobals.player_state == LocalGlobals.PLAYER_STATE_PLAYING or !movedrag.is_empty()):
		velocity.y = (JUMP_VELOCITY*1*( (scale.x+scale.y+scale.z)/3.0 ))
	
	move_and_slide()

func vr_movement(delta:float) -> void:
	xrplayer.position.x = -xr_camera_3d.position.x
	xrplayer.position.z = -xr_camera_3d.position.z
	position.x += (transform.basis*(xr_camera_3d.position-camPrevPos)).x
	position.z += (transform.basis*(xr_camera_3d.position-camPrevPos)).z
	playercamoffset.global_position.x -= (transform.basis*(xr_camera_3d.position-camPrevPos)).x
	playercamoffset.global_position.z -= (transform.basis*(xr_camera_3d.position-camPrevPos)).z
	camPrevPos = xr_camera_3d.position
	transform = transform.rotated_local(Vector3.UP,-rightStick.x*delta)
	xrplayer.position = xrplayer.position.rotated(Vector3.UP,rightStick.x*delta)
	
	var input_dir = leftStick
	var direction: Vector3
	if flymode:
		direction = ((xr_camera_3d.global_basis) * Vector3(input_dir.x, 0, -input_dir.y))
	else:
		direction = ((global_basis) * Vector3(input_dir.x, 0, -input_dir.y))

func flat_movement(delta:float) -> void:
	place_grabbed_nodes()
	var joy_look_vector = Input.get_vector('lookleft','lookright','lookdown','lookup')
	if joy_look_vector.length()>.05:
		rotate_y(-joy_look_vector.x*JOY_SPEED)
		xr_camera_3d.rotate_x(joy_look_vector.y*JOY_SPEED)
		camera_3d.rotate_x(joy_look_vector.y*JOY_SPEED)
	if Input.is_action_just_pressed("click"):
		if grabbed.size() > 0:
			var did_activate_held := false
			for item in grabbed.values():
				if "node" in item and "primary" in item.node:
					item.node.primary()
					did_activate_held = true
			if !did_activate_held:
				ui_ray.click()
		else:
			if LocalGlobals.player_state == LocalGlobals.PLAYER_STATE_TYPING:
				if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
					LocalGlobals.player_state = LocalGlobals.PLAYER_STATE_PLAYING
				else:
					LocalGlobals.player_state = LocalGlobals.PLAYER_STATE_PAUSED
			ui_ray.click()
	if Input.is_action_just_released("click"):
		if grabbed.size() > 0:
			for item in grabbed.values():
				if "node" in item and "primary_released" in item.node:
					item.node.primary_released()
		ui_ray.release()
	if Input.is_action_just_pressed("rightclick"):
		if vr_mode_enabled:
			righthand.grip()
		else:
			grip()
	if Input.is_action_just_released("rightclick"):
		if vr_mode_enabled:
			righthand.ungrip()
		else:
			ungrip()
	if Input.is_action_just_pressed("middleclick"):
		if vr_mode_enabled:
			righthand.contextMenuSummon()
		else:
			contextMenuSummon()
	if ui_ray.is_colliding():
		grab_point = camera_3d.to_local(ui_ray.get_collision_point())
	else:
		grab_point = camera_3d.to_local(camera_3d.project_position(get_viewport().size/2.0, 10.0))
	if Input.is_action_just_pressed("desktop_secondary") and LocalGlobals.player_state != LocalGlobals.PLAYER_STATE_TYPING:
		#vreditor = load("res://barkvr-system/ui/3dPanel/editmode/vreditor.tscn").instantiate()
		var vreditor = load("res://barkvr-system/ui/3dPanel/editmode/unified editor/unified_inspector_3d.tscn").instantiate()
		get_tree().get_first_node_in_group("localworldroot").add_child(vreditor)
		vreditor.global_position = camera_3d.to_global(Vector3(0,0,-.5))
		vreditor.look_at(camera_3d.global_position, Vector3.UP, true)
	
	righthand.look_at(camera_3d.to_global(grab_point))
	
	var input_dir : Vector2
	if LocalGlobals.player_state == LocalGlobals.PLAYER_STATE_PLAYING:
		input_dir = Input.get_vector("left", "right", "up", "down")
	
	if !movedrag.is_empty():
		if -touch_move_left > input_dir.x:
			input_dir.x = -touch_move_left
		if touch_move_right < input_dir.x:
			input_dir.x = touch_move_right
		if -touch_move_forward > input_dir.y:
			input_dir.y = -touch_move_forward
		if touch_move_backward < input_dir.y:
			input_dir.y = touch_move_backward
	var direction: Vector3
	if flymode:
		direction = (camera_3d.global_basis * Vector3(input_dir.x, 0.0, input_dir.y))
	else:
		direction = (global_basis * Vector3(input_dir.x, 0.0, input_dir.y))
	if direction:
		# used a ternary to preserve the y velocity if they player is not flying
		# this prevents this lazy ass code from exponentially increasing vertical
		# speed while flying
		velocity = (direction*SPEED)+Vector3(0, velocity.y, 0) if !flymode else (direction*SPEED)
	if lookdrag:
		if touchsticklook:
			rotate_y( -(lookdrag.position.x-lookdrag.startposition.x)*(MOUSE_SPEED/800) )
			xr_camera_3d.rotate_x( -(lookdrag.position.y-lookdrag.startposition.y)*(MOUSE_SPEED/800) )
			camera_3d.rotate_x( -(lookdrag.position.y-lookdrag.startposition.y)*(MOUSE_SPEED/800) )

func _input(event):
	if event is InputEventJoypadMotion:
		pass
	if event.is_action("cleargizmos"):
		LocalGlobals.clear_gizmos.emit()
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if Input.is_key_pressed(KEY_E):
			if vr_mode_enabled:
				for node in righthand.grabbed.values():
					var rotation_basis = (basis*Vector3.UP*node.node.basis).normalized()
					node.offset = node.offset.rotated_local(
						rotation_basis,
						-event.relative.x*(MOUSE_SPEED/100)
						)
					if !Input.is_key_pressed(KEY_SHIFT):
						rotation_basis = (basis*Vector3.RIGHT*node.node.basis)
						node.offset = node.offset.rotated_local(
							rotation_basis.normalized(),
							event.relative.y*(MOUSE_SPEED/100)
							)
			else:
				for node in grabbed.values():
					if is_instance_valid(node):
						var rotation_basis = (basis*Vector3.UP*node.node.basis).normalized()
						node.offset = node.offset.rotated_local(
							rotation_basis,
							-event.relative.x*(MOUSE_SPEED/100)
							)
						if !Input.is_key_pressed(KEY_SHIFT):
							rotation_basis = (basis*Vector3.RIGHT*node.node.basis)
							node.offset = node.offset.rotated_local(
								rotation_basis.normalized(),
								event.relative.y*(MOUSE_SPEED/100)
								)
		else:
			rotate_y(-event.relative.x*(MOUSE_SPEED/100))
			xr_camera_3d.rotate_x(-event.relative.y*(MOUSE_SPEED/100))
			camera_3d.rotate_x(-event.relative.y*(MOUSE_SPEED/100))
	if event.is_action("pause"):
		if event.is_pressed():
			match LocalGlobals.player_state:
				LocalGlobals.PLAYER_STATE_TYPING:
					if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
						LocalGlobals.player_state = LocalGlobals.PLAYER_STATE_PLAYING
					else:
						LocalGlobals.player_state = LocalGlobals.PLAYER_STATE_PAUSED
				LocalGlobals.PLAYER_STATE_PLAYING:
					LocalGlobals.player_state = LocalGlobals.PLAYER_STATE_PAUSED
					Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
				LocalGlobals.PLAYER_STATE_PAUSED:
					LocalGlobals.player_state = LocalGlobals.PLAYER_STATE_PLAYING
					Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event is InputEventMouseButton:
		if event.pressed:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.ctrl_pressed:
				scale *= 1.1
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.ctrl_pressed:
				scale *= .9
	if event is InputEventScreenTouch:
		if event.pressed:
			if event.position.x > get_viewport().size.x/2.0 and lookdrag.is_empty():
				lookdrag = {
					'index': event.index,
					'relative': Vector2(),
					'velocity': Vector2(),
					'startposition': event.position,
					'position': event.position,
					'dragstarttime': Time.get_ticks_msec()
				}
			else:
				movedrag = {
					'index': event.index,
					'relative': Vector2(),
					'velocity': Vector2(),
					'startposition': event.position,
					'position': event.position,
					'dragstarttime': Time.get_ticks_msec()
				}
				screen_just_touched = true
		
		if !lookdrag.is_empty() and event.index == lookdrag.index and event.pressed == false:
			if lookdrag.startposition.distance_to(event.position) < get_viewport().size.length()*.01\
			and Time.get_ticks_msec()-lookdrag.dragstarttime<100:
				_screen_tap_click(event)
			lookdrag = {}
		if !movedrag.is_empty() and event.index == movedrag.index and event.pressed == false:
			if movedrag.startposition.distance_to(event.position) < get_viewport().size.length()*.01\
			and Time.get_ticks_msec()-movedrag.dragstarttime<100:
				_screen_tap_click(event)
			movedrag = {}
			touch_move_left = 0.0
			touch_move_right = 0.0
			touch_move_forward = 0.0
			touch_move_backward = 0.0
	if event is InputEventScreenDrag:
		if movedrag and event.index == movedrag.index:
			movedrag = {
				'index': event.index,
				'relative': event.relative,
				'velocity': event.velocity,
				'startposition': movedrag.startposition,
				'position': event.position,
				'dragstarttime': movedrag.dragstarttime
			}
			touch_move_left = (movedrag.startposition.x-event.position.x)*.01
			touch_move_right = (event.position.x-movedrag.startposition.x)*.01
			touch_move_forward = (movedrag.startposition.y-event.position.y)*.01
			touch_move_backward = (event.position.y-movedrag.startposition.y)*.01
		if lookdrag and event.index == lookdrag.index:
			lookdrag = {
				'index': event.index,
				'relative': event.relative,
				'velocity': event.velocity,
				'startposition': lookdrag.startposition,
				'position': event.position,
				'dragstarttime': lookdrag.dragstarttime
			}
			if !touchsticklook:
				rotate_y( -(event.relative.x)*(MOUSE_SPEED/100) )
				xr_camera_3d.rotate_x(-event.relative.y*(MOUSE_SPEED/100))
				camera_3d.rotate_x(-event.relative.y*(MOUSE_SPEED/100))

func _screen_tap_click(_event:InputEvent) -> void:
	LocalGlobals.playerreleaseuifocus.emit()
	if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		LocalGlobals.player_state = LocalGlobals.PLAYER_STATE_PAUSED
	else:
		LocalGlobals.player_state = LocalGlobals.PLAYER_STATE_PLAYING
	ui_ray.click()
	ui_ray.release()

func contextMenuSummon():
	if LocalGlobals.player_state != LocalGlobals.PLAYER_STATE_TYPING:
		handmenu.summon(camera_3d.to_global(Vector3(0,0,-.5)), camera_3d.global_position)

func place_grabbed_nodes():
	var settings_singleton := Engine.get_singleton("settings_manager")
	for item in grabbed.values():
		if settings_singleton:
			if Input.is_action_just_pressed("scrollup"):
				if Input.is_physical_key_pressed(KEY_SHIFT):
					item.offset.basis.x *= settings_singleton.grabbed_object_scale_factor
					item.offset.basis.y *= settings_singleton.grabbed_object_scale_factor
					item.offset.basis.z *= settings_singleton.grabbed_object_scale_factor
				else:
					item.offset.origin *= settings_singleton.grabbed_object_scale_factor
			if Input.is_action_just_pressed("scrolldown"):
				if Input.is_physical_key_pressed(KEY_SHIFT):
					item.offset.basis.x *= 1.0/settings_singleton.grabbed_object_scale_factor
					item.offset.basis.y *= 1.0/settings_singleton.grabbed_object_scale_factor
					item.offset.basis.z *= 1.0/settings_singleton.grabbed_object_scale_factor
				else:
					item.offset.origin *= 1.0/settings_singleton.grabbed_object_scale_factor
		if is_instance_valid(item.node):
			item.node.global_transform = camera_3d.global_transform * item.offset
			if is_instance_valid(Engine.get_singleton("event_manager")):
					print("apply")
					Engine.get_singleton("event_manager").set_property(
						get_tree().get_first_node_in_group('localworldroot').get_path_to(item.node),
						"position",
						item.node.position
					)
					Engine.get_singleton("event_manager").set_property(
						get_tree().get_first_node_in_group('localworldroot').get_path_to(item.node),
						"rotation",
						item.node.rotation
					)
					Engine.get_singleton("event_manager").set_property(
						get_tree().get_first_node_in_group('localworldroot').get_path_to(item.node),
						"scale",
						item.node.scale
					)

func grip():
	print('grip')
	if ui_ray.is_colliding():
		var rayCollided = ui_ray.get_collider()
		if rayCollided.has_meta("grabbable"):
			grab(rayCollided,true)
	grabbing = true

func ungrip():
	for item in grabbed.values():
		if is_instance_valid(item.node):
			releasegrab(item.node)

func grab(node:Node, laser:bool=false):
	var tmpgrab = node.get_meta("grabbable")
	if tmpgrab:
		if node.is_class("RigidBody3D"):
			if !grabbed.has(node.name):
				grabbed[node.name] = {
					"parent": node.get_parent(),
					'offset': camera_3d.global_transform.affine_inverse() * node.global_transform,
					'rotoffset': node.global_rotation,
					'isfrozen': node.freeze,
					'node': node
				}
			node.freeze = true
		else:
			if laser:
				pass
			if !grabbed.has(node.name):
				grabbed[node.name] = {
					"parent": node.get_parent(),
					'offset': camera_3d.global_transform.affine_inverse() * node.global_transform,
					'rotoffset': node.global_rotation,
					'node': node
				}

func releasegrab(node:Node):
	if grabbed.has(node.name):
		if node is RigidBody3D:
			node.freeze = grabbed[node.name].isfrozen
		grabbed.erase(node.name)
		return
	grabbed.clear()

## deletes the held item(s) for whichever hand is
## passed (0 for left, 1 for right, and we will handle
## detecting index for more arms in the future)
func delete_held(chirality: int = -1) -> void:
	for item in grabbed.values():
		if is_instance_valid(item.node):
			item.node.queue_free()
	match chirality:
		0:
			if !lefthand.grabbed.is_empty():
				for item in lefthand.grabbed.values():
					item.node.queue_free()
		1:
			if !righthand.grabbed.is_empty():
				for item in righthand.grabbed.values():
					item.node.queue_free()
		_:
			if !righthand.grabbed.is_empty():
				for item in righthand.grabbed.values():
					item.node.queue_free()
			if !lefthand.grabbed.is_empty():
				for item in lefthand.grabbed.values():
					item.node.queue_free()
