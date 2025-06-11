@tool
@icon("res://addons/Panel3D/icon.svg")
class_name Panel3D
extends RigidBody3D
var viewport : SubViewport
var mesh : MeshInstance3D
var colshape : CollisionShape3D
var material : StandardMaterial3D

var last_input_position : Vector2

var ui : Node
var tex : ViewportTexture

var popouts: Array[Window] = []

## material rendered in "next_pass" of the default material good for backgrounds
## behind transparent panels
@export var background_material : Material:
	set(val):
		background_material = val
		if background_material:
			material.next_pass = background_material
		else:
			material.next_pass = null

## PackedScene of the scene you want to load into the panel (you can also use the "set_viewport_scene(Node)")
@export var _auto_load_ui : PackedScene:
	set(val):
		_auto_load_ui = val
		if _auto_load_ui:
			set_viewport_scene(_auto_load_ui.instantiate())
		else:
			for child in viewport.get_children():
				child.queue_free()

## Sets the panel to transparent (Panel3Ds are automatically opaque on Android and Web)
@export var transparent : bool = true:
	set(val):
		transparent = val
		if transparent:
			viewport.transparent_bg = transparent
			material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS
		else:
			viewport.transparent_bg = transparent
			material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED

## Sets the viewport size in pixels
@export var viewport_size:Vector2i=Vector2i(1024,1024):
	set(val):
		val.x = val.x if val.x > minimum_viewport_size.x else minimum_viewport_size.x
		val.y = val.y if val.y > minimum_viewport_size.y else minimum_viewport_size.y
		match ANCHOR_POSITION:
			TOP_LEFT:
				var offset := Vector3()
				offset.x -= ((pixel_size/1000.0)*(viewport.size.x-val.x))/2.0
				offset.y += ((pixel_size/1000.0)*(viewport.size.y-val.y))/2.0
				global_position = to_global(offset)
			MIDDLE_LEFT:
				var offset := Vector3()
				offset.x -= ((pixel_size/1000.0)*(viewport.size.x-val.x))/2.0
				global_position = to_global(offset)
			BOTTOM_LEFT:
				var offset := Vector3()
				offset.x -= ((pixel_size/1000.0)*(viewport.size.x-val.x))/2.0
				offset.y -= ((pixel_size/1000.0)*(viewport.size.y-val.y))/2.0
				global_position = to_global(offset)
			MIDDLE_TOP:
				var offset := Vector3()
				offset.y += ((pixel_size/1000.0)*(viewport.size.y-val.y))/2.0
				global_position = to_global(offset)
			MIDDLE_MIDDLE:
				pass
			TOP_RIGHT:
				var offset := Vector3()
				offset.x += ((pixel_size/1000.0)*(viewport.size.x-val.x))/2.0
				offset.y += ((pixel_size/1000.0)*(viewport.size.y-val.y))/2.0
				global_position = to_global(offset)
			MIDDLE_RIGHT:
				var offset := Vector3()
				offset.x += ((pixel_size/1000.0)*(viewport.size.x-val.x))/2.0
				global_position = to_global(offset)
			BOTTOM_RIGHT:
				print('bottom right')
				var offset := Vector3()
				offset.x += ((pixel_size/1000.0)*(viewport.size.x-val.x))/2.0
				offset.y -= ((pixel_size/1000.0)*(viewport.size.y-val.y))/2.0
				global_position = to_global(offset)
		viewport_size = val
		viewport.size = viewport_size
		mesh.mesh.size.x = (pixel_size/1000.0)*viewport.size.x
		mesh.mesh.size.y = (pixel_size/1000.0)*viewport.size.y
		#mesh.mesh.size.z = (pixel_size/1000.0)
		mesh.position.z = panel_thickness*.5
		colshape.shape.size = Vector3((pixel_size/1000.0)*viewport.size.x,(pixel_size/1000.0)*viewport.size.y,panel_thickness)

## sets the thickness of the collider
@export var panel_thickness := .05

const TOP_LEFT = 0
const MIDDLE_LEFT = 1
const BOTTOM_LEFT = 2
const MIDDLE_TOP = 3
const MIDDLE_MIDDLE = 4
const MIDDLE_BOTTOM = 5
const TOP_RIGHT = 6
const MIDDLE_RIGHT = 7
const BOTTOM_RIGHT = 8
@export_enum("TOP_LEFT", "MIDDLE_LEFT", "BOTTOM_LEFT", "MIDDLE_TOP", "MIDDLE_MIDDLE", "MIDDLE_BOTTOM", "TOP_RIGHT", "MIDDLE_RIGHT", "BOTTOM_RIGHT") var ANCHOR_POSITION := MIDDLE_MIDDLE

## Restricts the viewport sizing to be above a specific height
@export var minimum_viewport_size:Vector2i=Vector2i(50,50)

## Sets the size of each pixel[br][code]meters/100[/code]
@export var pixel_size:float=.5:
	set(val):
		pixel_size = val
		viewport_size = viewport_size

@export_group('Graphics Settings')

## sets the render priority
@export var render_priority := 0:
	set(val):
		if val < -128:
			val = -128
		if val > 127:
			val = 127
		render_priority = val
		material.render_priority = render_priority

## makes the panel render on top of everything else
@export var on_top := false:
	set(val):
		on_top = val
		material.no_depth_test = on_top

## The shading mode for the canvas
@export_enum("Unshaded:0", "Per Pixel:1", "Per Vertex:2") var shading_mode: int = 0:
	set(val):
		shading_mode = val
		material.shading_mode = shading_mode
		
## enables using the screen texture as a depth texture
@export var heightmap_enabled:bool=false:
	set(val):
		heightmap_enabled = val
		material.heightmap_enabled = heightmap_enabled

## enabled deep parallax for the heightmap
@export var heightmap_deep_parallax:bool=false:
	set(val):
		heightmap_deep_parallax = val
		material.heightmap_deep_parallax = heightmap_deep_parallax

## sets the minimum layers for heightmap
@export_range(1,10000) var heightmap_min_layers:int=8:
	set(val):
		heightmap_min_layers = val
		material.heightmap_min_layers = heightmap_min_layers

## sets the maximum layers for heightmap
@export_range(1,10000) var heightmap_max_layers:int=32:
	set(val):
		heightmap_max_layers = val
		material.heightmap_max_layers = heightmap_max_layers

## sets the scale for heightmap (it's basically how exaggerated the depth is)
@export var heightmap_scale:float=5.0:
	set(val):
		heightmap_scale = val
		material.heightmap_scale = heightmap_scale

func _init():
	# since we use a rigid body for funny options we need to free the body
	freeze = true
	# this makes it so when the frozen body is moved manually, it preserves
	# calculations like velocity for collisions making it feel more natural
	freeze_mode = FREEZE_MODE_KINEMATIC
	# initialize and assign the subviewport
	viewport = SubViewport.new()
	# capture subwindows to prevent issues with popups like with OptionButton
	viewport.gui_embed_subwindows = true
	# isolates the physics and world inside the viewport 
	viewport.own_world_3d = true
	# set the viewport to only update when visible, intended as an optimization
	viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	# create and assign the visuals and collision stuff
	mesh = MeshInstance3D.new()
	mesh.mesh = QuadMesh.new()
	colshape = CollisionShape3D.new()
	colshape.shape = BoxShape3D.new()
	# setup for the material to apply all the settings listed in the exports
	material = StandardMaterial3D.new()
	mesh.mesh.surface_set_material(0,material)
	if is_instance_valid(find_child("3dpanel_viewport")):
		viewport = find_child("3dpanel_viewport")
	else:
		add_child(viewport,false)
		viewport.name = "3dpanel_viewport"
	if is_instance_valid(find_child("3dpanel_mesh")):
		mesh = find_child("3dpanel_mesh")
		mesh.mesh.surface_set_material(0, material)
	else:
		add_child(mesh,false)
		mesh.name = "3dpanel_mesh"
	if is_instance_valid(find_child("3dpanel_colshape")):
		colshape = find_child("3dpanel_colshape")
	else:
		add_child(colshape,false)
		colshape.name = "3dpanel_colshape"
	# set the viewport to not repeat by default to prevent weird visual issues
	# at the edges of the mes
	material.texture_repeat = false
	material.albedo_texture = viewport.get_texture()
	material.metallic_specular = 0.0
	material.roughness = 1.0
	# disabled culling to make it visible on both sides of the quad
	# this was an issue before because the panels were invisible from the back
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.heightmap_texture = material.albedo_texture
	# UNUSED: automatically disable transparency on android for performance
	# reasons
	#if transparent and OS.get_name() != "Android" and OS.get_name() != 'Web':
		#viewport.transparent_bg = true
	#else:
		#viewport.transparent_bg = false
	_auto_load_ui = _auto_load_ui
	transparent = transparent
	viewport_size = viewport_size
	shading_mode = shading_mode
	heightmap_enabled = heightmap_enabled
	heightmap_deep_parallax = heightmap_deep_parallax
	heightmap_min_layers = heightmap_min_layers
	heightmap_max_layers = heightmap_max_layers
	heightmap_scale = heightmap_scale
	viewport.handle_input_locally = true

func _ready():
#grab any non-mouse input from the window and pass it through directly to the
# viewport this is necessary because removing the SubViewportContainer makes
# it so inptus are not automatically passed to the SubViewport
	if !Engine.is_editor_hint():
		get_tree().root.window_input.connect(func(event):
			#viewport.push_input(event, true)
			if (event is InputEventKey):
				viewport.push_input(event)
			)
		viewport.gui_focus_changed.connect(func(node):
			if LocalGlobals.player_state != LocalGlobals.PLAYER_STATE_TYPING:
				LocalGlobals.player_state = LocalGlobals.PLAYER_STATE_TYPING
			get_window().grab_focus()
			)
		LocalGlobals.playerreleaseuifocus.connect(func():
			viewport.gui_release_focus()
			)

func _process(delta: float) -> void:
	var embedded := viewport.get_embedded_subwindows()
	for window in embedded:
		if false and !popouts.has(window) and !window.has_meta("already_moved"):
			window.set_meta("already_moved", true)
			popouts.append(window)
			var tmppanel := Panel3D.new()
			add_child(tmppanel)
			tmppanel.global_position = tmppanel.to_global(Vector3(0, 0, .1))
			tmppanel.viewport_size = window.size
			# TODO set world position to reflect relative position of the popout
			# on it's origin viewport
			
			# TODO make popout render on top of inspectors but only if it comes from an inspector
			# might be able to do this by grabbing the viewport from the node before reparenting
			window.get_parent().remove_child(window)
			tmppanel.viewport.add_child(window)

func laser_input(data:Dictionary):
	if viewport.gui_is_dragging():
		print("DRAGGING")
	var event
	# Setup event
	match data.action:
		"hover":
			event = InputEventMouseMotion.new()
		"scrollup":
			event = InputEventMouseButton.new()
			event.button_index = 4
		"scrolldown":
			event = InputEventMouseButton.new()
			event.button_index = 5
		"click":
			event = InputEventMouseButton.new()
			event.button_index = 1
			#event = InputEventScreenTouch.new()
		"custom":
			# Use this to pass a different event type or add event strings below
			event = data.event
		_:
			pass
	
	# Sets the position of the event to the calculated mouse position in 2D space.
	event.position = project_position_to_panel(data.position)
	
	if "pressed" in data and data.pressed and "button_mask" in event:
		event.button_mask = MOUSE_BUTTON_MASK_LEFT
		if data.action == "hover" and event is InputEventMouseMotion:
			event.relative = event.position - last_input_position
	if event is InputEventWithModifiers:
		if Input.is_key_pressed(KEY_CTRL):
			event.ctrl_pressed = true
		if Input.is_key_pressed(KEY_ALT):
			event.alt_pressed = true
		if Input.is_key_pressed(KEY_META):
			event.meta_pressed = true
		if Input.is_key_pressed(KEY_SHIFT):
			event.shift_pressed = true
	
	# Set event pressed value (should be false if not explicitly changed)
	if data.has('pressed') and "pressed" in event:
		event.pressed = data.pressed
	
	last_input_position = event.position
	
	# Set the event to be handled locally (workaround for Godot 4.x bug)
	#	The bug causes the viewport to not consistently receive input events
	viewport.handle_input_locally = true
	# Push the event to the viewport
	viewport.push_input(event,true)
	viewport.handle_input_locally = false

func project_position_to_panel(global_point:Vector3) -> Vector2:
	# Get the size of the quad mesh we're rendering to
	var quad_size = mesh.mesh.size
	global_point = to_local(global_point)
	# Convert GLOBAL collision point from to be in local space of the panel
	var mouse_pos2D = Vector2(global_point.x, -global_point.y)
	# Translate the 2D mouse position to the center of the quad
	#	by adding half of the quad size to both x and y coordinates.
	mouse_pos2D.x += quad_size.x / 2
	mouse_pos2D.y += quad_size.y / 2
	# Normalize the mouse position to be within the quad size
	mouse_pos2D.x = mouse_pos2D.x / quad_size.x
	mouse_pos2D.y = mouse_pos2D.y / quad_size.y
	# Convert the 2D mouse position to viewport coordinates
	mouse_pos2D.x = mouse_pos2D.x * viewport.size.x
	mouse_pos2D.y = mouse_pos2D.y * viewport.size.y
	return mouse_pos2D

func project_global_position_from_panel(panel_point:Vector2) -> Vector3:
	## TODO this doesn't return the exactly correct coordinate, needs to be fixed
	
	# Get the size of the quad mesh we're rendering to
	var quad_size = mesh.mesh.size
	
	var output2d := Vector2()
	output2d.x = (panel_point / Vector2(viewport.size)).x
	output2d.y = (panel_point / Vector2(viewport.size)).y
	
	output2d.x = output2d.x * quad_size.x
	output2d.y = output2d.y * quad_size.y
	
	output2d.x = output2d.x - quad_size.x/2
	output2d.y = output2d.y - quad_size.y/2
	
	var panel_pos_3d := Vector3(output2d.x, output2d.y, 0)
	
	return to_global(panel_pos_3d)

func set_viewport_scene(node):
	# Clears the current nodes from within the viewport first
	for child in viewport.get_children():
		child.queue_free()
	# Adds a child node to the viewport and sets it as the UI
	#	Then, gets the texture of the viewport.
	viewport.add_child(node)
	ui = node
	tex = viewport.get_texture()
	# Connects the 'action' signal of the given node to the 'action' signal of this node.
	if node.has_signal('action'):
		node.action.connect(func(data):
			emit_signal('action',data)
		)
	mesh.mesh.surface_get_material(0).albedo_texture = tex
