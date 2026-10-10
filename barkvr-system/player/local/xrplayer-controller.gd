class_name BarkvrPlayerController
extends CharacterBody3D

# TODO plans:
# THIS WHOLE CLASS *STILL* NEEDS TO BE REWRITTEN THIS IS SUCH A MESS, FUCK

#controllers:
## hold a reference to the right hand so we can easily access it
@onready var righthand: BarkHand= %righthand
## hold a reference to the left hand so we can easily access it
@onready var lefthand: BarkHand= %lefthand
## the camera used for VR mode
@onready var xr_camera_3d: XRCamera3D = $xrplayer/XrCamera3d
## the camera used for flat mode
@onready var camera_3d: Camera3D = $xrplayer/Camera3D
## a reference to the XR origin, makes it easier to add things to the player's
## playspace
@onready var xrplayer: XROrigin3D = $xrplayer
## the collision shape of the player
@onready var collision_shape_3d: CollisionShape3D = %CollisionShape3D
## the flat mode InteractionRay
@onready var ui_ray: InteractionRay = %uiRay
## the context menu as it's attached to the hand
@onready var handmenu: Node3D = %handmenu
## this is used to lock menus to the playspace but also follow the player
## in an intuitive way. (keeps the menu in front of you without rotating with you)
@onready var menuoffset: Node3D = %menuoffset
## the offset head position for the avatar to use as it's target pos for the head
##[br][br]we need this so we can swap the ik between desktop and vr mode or move it around
## so they avatar head is positioned correctly
@onready var headiktarget: Node3D = %headiktarget
## a node to manually place where the 3d notifications should appear in your view
@onready var notificationparent: Node3D = %notificationparent
## the local ui (settings, matrix, etc.)
@onready var localui: Panel3D = %localui

var head_pos: =Vector3():
	get:
		return get_viewport().get_camera_3d().global_position

#controller input vars:
## variable to track the state of the XR controller's rightStick input
var rightStick :Vector2 = Vector2()
## variable to track the state of the XR controller's rightGrip input
var rightGrip :float
## variable to track the state of the XR controller's rightaxbtn input
var rightaxbtn :bool = false
## variable to track the state of the XR controller's leftStick input
var leftStick :Vector2 = Vector2()
## variable to track the state of the XR controller's leftGrip input
var leftGrip :float
## variable to track the state of the XR controller's leftaxbtn input
var leftaxbtn :bool = false

## used to track the camera offset so we can keep the player/playspace centered compared to the
## character controller. this is how we handle jank with the math involving rotation in vr
var camPrevPos : Vector3 = Vector3()

## movement speed
@export var SPEED := 5.0
## the velocity to use when jumping
@export var JUMP_VELOCITY := 4.5

## when on, this will put the player into flying mode (without enabling noclip)
@export var flymode := true:
	set(value):
		flymode = value
		if value:
			# if the user is flying, we switch the player controller to floating for godot
			# physics reasons
			motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
		else:
			# if the user is in noclip, turn it OFF so the user doesn't fall through the world
			if noclip:
				noclip = false
			motion_mode = CharacterBody3D.MOTION_MODE_GROUNDED

## when toggled on, this will put the player into flying mode (without enabling noclip)
@export var noclip := true:
	set(value):
		noclip = value
		# if the player isn't flying, set them to be flying so they don't fall through 
		if value and !flymode:
			flymode = true
		# if the collision shape still exists, then disable it while noclipping, obvi
		if collision_shape_3d:
			collision_shape_3d.disabled = value

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var grabbing : bool = false

# flat vars
## mouse sensitivity
var MOUSE_SPEED := .1
## joystick sensitivity
var JOY_SPEED := .05
# these are for touch input
# TODO DEPRECATED (THIS NEEDS TO BE REMOVED AND REPLACED WITH THE NEW GODOT
# TOUCH GAMEPAD STUFF)
## variable used to track touchscreen dragging for rotating the camera
var lookdrag : Dictionary = {} #{'index': -1,'relative': Vector2(),'velocity': Vector2()}x
## tracks the index of the touch event chain that is being used for the camera
var lastlookdragindex : int = -1
## variable used to track touchscreen dragging for moving the player
var movedrag : Dictionary = {} #{'index': -1,'relative': Vector2(),'velocity': Vector2()}
## tracks the index of the touch event cahin that is being used for the movement
var lastmovedragindex :int = -1
# i think these are self explanatory, yell at me if not (for player movement with touch)
var touch_move_left := 0.0
var touch_move_right := 0.0
var touch_move_forward := 0.0
var touch_move_backward := 0.0
## toggle to allow disabling touch controlling the camera
@export var touchsticklook := false
var grab_point := Vector3()
## tracks when the screen was last touched so we can drive the correct behaviors contextually
var screen_just_touched := false

## track the most recently spawned inspector so we can re-summon it instead of spawning one if the
## user has the inspector as singleton setting enabled
var last_spawned_inspector : Panel3D

## variable to set whether the player is in vr mode or not
var vr_mode_enabled := false:
	set(value):
		vr_mode_enabled = value
		Notifyvr.send_notification("vrmode: "+str(value))
		_toggle_xr(value)

## helper variable that actually just obtains the player scale (as a single float)
## so we can use it to have the game adjust to the player scale
var player_scale_multiplier :float:
	get:
		return get_tree().get_first_node_in_group("player").global_basis.get_scale().length()

## toggles vr mode (true = vr enabled)
func _toggle_xr(value:bool):
	# checks whether the hands exist and then sets them up if they do
	if is_instance_valid(lefthand) and is_instance_valid(righthand):
		lefthand.rays_disabled = !value
		righthand.rays_disabled = !value
		ui_ray.enabled = !value
		ui_ray.visible = !value
	# if the localui is not ready and in the scene yet then we will wait for it
	# so we can set it up appropriately
	if !localui.is_node_ready():
		await localui.ready
	# if in vr
	if value:
		Notifyvr.send_notification("ENABLING XR")
		# make sure the localui ui elements are placed under the Panel3D for the localui
		localui.ui.reparent(localui.viewport)
		# enable the collider for the 3d ui
		localui.colshape.disabled = false
		# moved the headiktarget to be under the xr camera so avatars put their head there
		headiktarget.reparent(xr_camera_3d,false)
		# if not on web
		if OS.get_name() != "Web":
			# then we need to re-enable use_xr on the viewport
			get_viewport().use_xr = true
		# tell the engine to use the xr camera
		xr_camera_3d.current = true
	# if not in vr
	else:
		# notify the user they disabled xr mode
		Notifyvr.send_notification("DISABLING XR")
		# move the localui to the main window
		localui.ui.reparent(get_tree().root)
		# disable the 3d ui collider
		localui.colshape.disabled = true
		# move the head ik target to the flat camera
		headiktarget.reparent(camera_3d,false)
		# set the player collider height and width to the current default
		collision_shape_3d.shape.height = 1.0
		collision_shape_3d.shape.radius = .1
		# if not on web
		if OS.get_name() != "Web":
			# disbale xr mode on the viewport
			get_viewport().use_xr = false
		# tell engine to use the flat camera
		camera_3d.current = true
		# move camera to the correct position relative to the player collider
		camera_3d.position.y = .9
		# place the hands in a *natural* position (yes they're bad, this'll be replace 
		# by the new avatar update when it happens)
		righthand.position = Vector3(.2,.6,-.2)
		lefthand.position = Vector3(-.2,.6,0.0)
		lefthand.rotation_degrees = Vector3(-90.0,0,0)

		# Fix incorrect player transform in desktop mode
		xrplayer.position = Vector3.ZERO

## allows us to respawn the player (good for when the player is positioned poorly or something)
func respawn_player():
	# reset the velocity
	velocity = Vector3()
	# find the possible spawn locations (designated by the helper node)
	var spawn_locations : Array = get_tree().get_nodes_in_group("PlayerSpawnLocation")
	# hold the random selection from the possible options
	var spawn_location : Node3D
	# if there are at least one then pick a random one to use
	if !spawn_locations.is_empty():
		spawn_location = spawn_locations.pick_random()
	# if it's valid, then put the player there
	if spawn_location:
		global_position = spawn_location.global_position
	# if not, place the player slightly above the origin (not at the origin 
	# for usability reasons)
	else:
		global_position = Vector3(0,4,0)

func _ready():
	get_window().gui_focus_changed.connect(func(_node):
		if LocalGlobals.player_state != LocalGlobals.PLAYER_STATE_TYPING:
			LocalGlobals.player_state = LocalGlobals.PLAYER_STATE_TYPING
		)
	# release focus of panels when certain player states are set (this is part of the logic
	# to make interacting with Panel3D UI more intuitive by releasing the mouse in an expected
	# way like in most other apps)
	LocalGlobals.player_state_changed.connect(func(state):
		match state:
			#LocalGlobals.PLAYER_STATE_TYPING:
				#LocalGlobals.emit_signal("playerreleaseuifocus")
			LocalGlobals.PLAYER_STATE_PLAYING:
				LocalGlobals.emit_signal("playerreleaseuifocus")
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			LocalGlobals.PLAYER_STATE_PAUSED:
				LocalGlobals.emit_signal("playerreleaseuifocus")
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		)
	# set the player node name to be the system unique id for easier reference when dealing with
	# networking stuff
	name = OS.get_unique_id()
	# add the player collider as an exception to the ray that is inside the camera 
	# (without this the player can't click anything lol)
	ui_ray.add_exception(self)
	# reset the vr enabled variables so the setter runs the proper setup
	vr_mode_enabled = LocalGlobals.vr_supported
	# force enable the hands because the setter misses them on first launch sometimes 
	# TODO (this might not occur anymore as it was an old godot issue, but needs testing)
	lefthand.rays_disabled = !vr_mode_enabled
	righthand.rays_disabled = !vr_mode_enabled
	# spawn the player so they are positioned correctly in the world
	respawn_player()
	# if the project settings have vr disabled, then force it here 
	# TODO also needs testing as this may not be needed anymore
	if !ProjectSettings.get_setting("xr/openxr/enabled"):
		vr_mode_enabled = false
	# disable vr by default on web because the user needs to click the button for the browser
	# to be allowed access to the xr runtime
	if OS.get_name() == "Web":
		vr_mode_enabled = false
	
	# grab the controller changes and set the variables to be tracked by the player controller
	righthand.connect("button_pressed",func(input_name):
		if input_name == "ax_button":
			rightaxbtn = true
		)
	# grab the controller changes and set the variables to be tracked by the player controller
	righthand.connect("button_released",func(input_name):
		if input_name == "ax_button":
			rightaxbtn = false
		)
	# grab the controller changes and set the variables to be tracked by the player controller
	righthand.input_vector2_changed.connect(func(input_name:String,value):
		if input_name == "primary":
			rightStick = value
		)
	# grab the controller changes and set the variables to be tracked by the player controller
	lefthand.connect("button_pressed",func(input_name):
		if input_name == "ax_button":
			leftaxbtn = true
		)
	# grab the controller changes and set the variables to be tracked by the player controller
	lefthand.connect("button_released",func(input_name):
		if input_name == "ax_button":
			leftaxbtn = false
		)
	# grab the controller changes and set the variables to be tracked by the player controller
	lefthand.input_vector2_changed.connect(func(input_name:String,value):
		if input_name == "primary":
			leftStick = value
		)

func _physics_process(delta:float) -> void:
	# if the scaling bind is pressed, then scale the player accordingly
	if Input.is_action_just_pressed("scale_up"):
		scale *= 1.1
	if Input.is_action_just_pressed("scale_down"):
		scale *= .9
	# if the window isn't focused, then set the player to paused but don't change anything else
	if !DisplayServer.window_is_focused(0) and LocalGlobals.player_state != LocalGlobals.PLAYER_STATE_PAUSED:
		LocalGlobals.player_state = LocalGlobals.PLAYER_STATE_PAUSED
	# if the player is too far from the origin, respawn them and put them in fly mode incase there 
	# is no ground there (TODO we should replace this at some point with more contextual code)
	if global_position.length() > 100000:
		respawn_player()
		flymode = true

	# Flat mode toggle
	if Input.is_action_just_pressed("desktoptoggle"):
		if not LocalGlobals.vr_supported:
			Notifyvr.send_notification("vr not available")
		else:
			vr_mode_enabled = !vr_mode_enabled

	# if the player is in vr, then do the vr movement
	if vr_mode_enabled:
		vr_movement(delta)
	# if not, then do the flat movement
	if !vr_mode_enabled:
		flat_movement(delta)

	# this is to preserve the vertical velocity when falling and moving
	var prevyvel = velocity.y
	velocity = velocity.move_toward(Vector3(), SPEED*.5)

	# Add the gravity.
	if not is_on_floor() and not flymode:
		velocity.y = prevyvel
		velocity.y -= (gravity*1.0*( (scale.x+scale.y+scale.z)/3.0 )) * delta

	# Handle Jump.
	if (Input.is_action_just_pressed("jump") or (flymode and Input.is_action_pressed("jump")) or\
	rightaxbtn) and (is_on_floor() or flymode) and (LocalGlobals.player_state == LocalGlobals.PLAYER_STATE_PLAYING or\
	!movedrag.is_empty()):
		velocity.y = (JUMP_VELOCITY*1*( (scale.x+scale.y+scale.z)/3.0 ))

	move_and_slide()

func vr_movement(delta:float) -> void:
	# move the playspace to keep the camera centered at the player controller
	xrplayer.position.x = -xr_camera_3d.position.x
	xrplayer.position.z = -xr_camera_3d.position.z
	# translate the whole controller by the same offset so the player actuall moves in the world
	# without leaving the center of the character controller
	position.x += (transform.basis*(xr_camera_3d.position-camPrevPos)).x
	position.z += (transform.basis*(xr_camera_3d.position-camPrevPos)).z
	camPrevPos = xr_camera_3d.position
	# rotate the player if they're trying to rotate
	transform = transform.rotated_local(Vector3.UP,-rightStick.x*delta)
	xrplayer.position = xrplayer.position.rotated(Vector3.UP,rightStick.x*delta)
	
	# move the player based on the left stick input
	var input_dir = leftStick
	var direction: Vector3
	# convert the input axis to be oriented according to the camera 
	# TODO add the ability to use the controllers (or anything else ig) instead of the camera
	direction = ((xr_camera_3d.global_basis) * Vector3(input_dir.x, 0, -input_dir.y))
	# if not flying, then flatten the movement
	if !flymode:
		var tmpscale = direction.length()
		direction.y = 0
		direction = direction.normalized()*tmpscale
	if direction:
		var motion = direction*SPEED
		velocity.x = motion.x
		if flymode:
			velocity.y = motion.y
		velocity.z = motion.z

## movement code specifically for flat mode (touch and desktop modes)
func flat_movement(_delta:float) -> void:
	var joy_look_vector = Input.get_vector('lookleft','lookright','lookdown','lookup')
	# if the joystick vector isn't 0 then use it to rotate to player (prevents axis locking)
	if !joy_look_vector.is_zero_approx():
		# rotate the player accordingly
		rotate_y(-joy_look_vector.x*JOY_SPEED)
		camera_3d.rotate_x(joy_look_vector.y*JOY_SPEED)
	# if a button is pressed/released, forward that to the held object[s]
	if Input.is_action_just_pressed("click"):
		if ui_ray.grabbed_nodes.size() > 0:
			var did_activate_held := false
			for item : InteractionRay.GrabbedNode3D in ui_ray.grabbed_nodes.values():
				if 'button_pressed' in item.target:
					item.target.button_pressed("click")
					continue
				# DEPRECATED the following are only for backward compatibility!
				if 'primary' in item.target:
					item.target.primary()
					continue
				if 'primary_pressed' in item.target:
					item.target.primary_pressed()
					continue
				if "trigger_pressed" in item.target:
					item.target.trigger_pressed = true
					continue
				did_activate_held = true
			if !did_activate_held:
				ui_ray.click()
		else:
			if LocalGlobals.player_state == LocalGlobals.PLAYER_STATE_TYPING:
				if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
					print_debug("set to playing")
					LocalGlobals.player_state = LocalGlobals.PLAYER_STATE_PLAYING
			ui_ray.click()
	# if a button is pressed/released, forward that to the held object[s]
	if Input.is_action_just_released("click"):
		for item : InteractionRay.GrabbedNode3D in ui_ray.grabbed_nodes.values():
			if 'button_released' in item.target:
				item.target.button_released("click")
				continue
			# DEPRECATED the following are only for backward compatibility!
			if 'released' in item.target:
				item.target.released()
				continue
			if 'primary_released' in item.target:
				item.target.primary_released()
				continue
			if 'trigger_released' in item.target:
				item.target.trigger_released()
				continue
		ui_ray.release()
	# if the user presses the bind, then execute grab TODO rename this bind
	if Input.is_action_just_pressed("rightclick"):
		if vr_mode_enabled:
			righthand.grip()
		else:
			grip()
	# release grabbing when button released TODO rename this bind
	if Input.is_action_just_released("rightclick"):
		if vr_mode_enabled:
			righthand.ungrip()
		else:
			ungrip()
	# summon the context menu if the bind is pressed TODO rename this bind
	if Input.is_action_just_pressed("middleclick"):
		if vr_mode_enabled:
			righthand.contextMenuSummon()
		else:
			contextMenuSummon()
	
	# TODO REPLACE THIS TO USE THE ui_ray INSTEAD SINCE THIS ISN'T USED ANYMORE
	if ui_ray.is_colliding():
		grab_point = camera_3d.to_local(ui_ray.get_collision_point())
	else:
		grab_point = camera_3d.to_local(camera_3d.project_position(get_viewport().size/2.0, 10.0))
	if Input.is_action_just_pressed("desktop_secondary") and LocalGlobals.player_state != LocalGlobals.PLAYER_STATE_TYPING:
		summon_inspector.call_deferred()

	righthand.look_at(camera_3d.to_global(ui_ray.target_position))

	# get the direction for keyboard movement
	var input_dir : Vector2
	if LocalGlobals.player_state == LocalGlobals.PLAYER_STATE_PLAYING:
		input_dir = Input.get_vector("left", "right", "up", "down")

	# if the user is using touch controls, then move them accordingly
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
		# in flymode, we preserve vertical velocity
		direction = (camera_3d.global_basis * Vector3(input_dir.x, 0.0, input_dir.y))
	else:
		# otherwise we use the basis of the collider because it's aligned, horizontally, 
		# with the camera when in flat mode
		direction = (global_basis * Vector3(input_dir.x, 0.0, input_dir.y))
	if direction:
		# used a ternary to preserve the y velocity if they player is not flying
		# this prevents this lazy ass code from exponentially increasing vertical
		# speed while flying
		velocity = (direction*SPEED)+Vector3(0, velocity.y, 0) if !flymode else (direction*SPEED)
	# if the player is trying to rotate the camera using touch:
	if lookdrag:
		if touchsticklook:
			rotate_y( -(lookdrag.position.x-lookdrag.startposition.x)*(MOUSE_SPEED/800) )
			camera_3d.rotate_x( -(lookdrag.position.y-lookdrag.startposition.y)*(MOUSE_SPEED/800) )


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action("clear_gizmos"):
		LocalGlobals.clear_gizmos.emit()
	# this is complicted but self-explanatory. 
	# if you need to work on this and are stuck, yell at zodie
	# the pause button releases the mouse and spawns the localmenu accordingly
	elif event.is_action("pause"):
		if event.is_pressed():
			match LocalGlobals.player_state:
				LocalGlobals.PLAYER_STATE_TYPING:
					if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
						LocalGlobals.player_state = LocalGlobals.PLAYER_STATE_PLAYING
					else:
						LocalGlobals.player_state = LocalGlobals.PLAYER_STATE_PAUSED
				LocalGlobals.PLAYER_STATE_PLAYING:
					localui.ui.reveal()
					LocalGlobals.player_state = LocalGlobals.PLAYER_STATE_PAUSED
					Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
				LocalGlobals.PLAYER_STATE_PAUSED:
					LocalGlobals.player_state = LocalGlobals.PLAYER_STATE_PLAYING
					localui.ui.close_menu()
					Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	# toggles locking the mouse to the window, this is great for editing while in desktop mode
	elif event.is_action("toggle_mouse_lock"):
		if event.is_released():
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE else Input.MOUSE_MODE_VISIBLE
		

	# Handles Mouselook while also having a switch to handling rotation	given a couple modifiers
	# Rotates held nodes (by right hand if done while VR is active) when rotateHeld (default: E)
	# Axis of rotation is locked to the y axis when modifier key (default: Left Shift)
	# TODO(?): Does this work as expected when the player is rotated? Axis might need to be WRT the
	# Player's root
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		#Mouselook, should rotation not be active
		rotate_y(-event.relative.x*(MOUSE_SPEED/100))
		xr_camera_3d.rotate_x(-event.relative.y*(MOUSE_SPEED/100))
		camera_3d.rotate_x(-event.relative.y*(MOUSE_SPEED/100))

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

## helper method to click the ui_ray when the screen is tapped 
func _screen_tap_click(_event:InputEvent) -> void:
	LocalGlobals.playerreleaseuifocus.emit()
	if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		LocalGlobals.player_state = LocalGlobals.PLAYER_STATE_PAUSED
	else:
		LocalGlobals.player_state = LocalGlobals.PLAYER_STATE_PLAYING
	ui_ray.click()
	ui_ray.release()

## summons the context menu to the player (look at the hand.gd for more info)
func contextMenuSummon():
	if LocalGlobals.player_state != LocalGlobals.PLAYER_STATE_TYPING:
		handmenu.summon(
			camera_3d.project_position(
				get_viewport().get_mouse_position(),
				player_scale_multiplier*.4
				) if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED else camera_3d.to_global(Vector3(0,0,-player_scale_multiplier*.4)),
			camera_3d.global_position)

## summons an inspector to the player
func summon_inspector():
	if LocalGlobals.player_state != LocalGlobals.PLAYER_STATE_TYPING:
		# check to see if the settings manager exists
		if Engine.has_singleton("settings_manager"):
			# if it does, we check to see if the inspector is set as a singleton (only one at a time)
			# or if the inspector reference is empty. if either of these are true, we spawn a new
			# inspector
			if (Engine.get_singleton("settings_manager") as SettingsSingleton).inspector_as_singleton and is_instance_valid(last_spawned_inspector):
				_post_summon_inspector()
			else:
				last_spawned_inspector = load("uid://ec0mqh35i2in").instantiate() # Load inspector from UID and instantiate it.
				get_tree().get_first_node_in_group("localworldroot").call_deferred("add_child",last_spawned_inspector)
				# since we deferred the add_child for the inspector for performance reasons,
				# we now need to wait until the inspector is in the scene before we can manipulate xforms
				# so we connect a oneshot signal (the "4" flag at the end) that finishes setup once
				# the node is in the tree
				last_spawned_inspector.tree_entered.connect(_post_summon_inspector,4)

## just finalizes the position of the inspector once it's placed in the tree
func _post_summon_inspector():
		last_spawned_inspector.global_position = camera_3d.to_global(Vector3(0,0,-.5))
		last_spawned_inspector.look_at(camera_3d.global_position, Vector3.UP, true)

## grabs with the flatmode camera
func grip():
	ui_ray.grab()

## ungrabs with the flatmode camera
func ungrip():
	ui_ray.release_grab()

## deletes the held item(s) for whichever hand is passed (0 for left, 1 for right, and
## we will handle detecting index for more arms in the future)
## relatively self explanatory
func delete_held(chirality: int = -1) -> void:
	for item : InteractionRay.GrabbedNode3D in ui_ray.grabbed_nodes.values():
		if is_instance_valid(item.target):
			item.target.queue_free()
	match chirality:
		# delete left hand held items
		0:
			if !lefthand.grabbed.is_empty():
				for item in lefthand.grabbed.values():
					item.target.queue_free()
		# delete right hand held items
		1:
			if !righthand.grabbed.is_empty():
				for item in righthand.grabbed.values():
					item.target.queue_free()
		# delete held items from both hands if no chirality is passed
		_:
			if !righthand.grabbed.is_empty():
				for item in righthand.grabbed.values():
					item.target.queue_free()
			if !lefthand.grabbed.is_empty():
				for item in lefthand.grabbed.values():
					item.target.queue_free()
	# clear the grabbed nodes
	righthand.grabbed.clear()
	lefthand.grabbed.clear()
	ui_ray.grabbed_nodes.clear()
