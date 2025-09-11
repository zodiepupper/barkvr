@tool
class_name GridMenuButton
extends StaticBody3D

## DEPRECATED: only here for legacy support will be removed soon
signal clicked

## a signal to be thrown when pressed
signal pressed

## when the button is actively being clicked
signal button_down

## when the button is released
signal button_up

## signal for when the button is hovered
signal hovered

@onready var mesh_instance_3d : MeshInstance3D = $MeshInstance3D
@onready var label_3d :Label3D = $Label3D
@onready var collision_shape_3d :CollisionShape3D = $CollisionShape3D

## if this button is meant to spawn a scene,
## you can set that scene file with this variable
@export_file var itemToSpawn

## this allows you to set a global point where the
## spawned object should point toward when spawned
@export var look_at_point := Vector3()

## sets how many of the set item should be created
## each time the button is pressed
@export var item_spawn_multiplier:float = 1

## label for the text on the button
@export var text :String:
	set(value):
		text = value
		name = text
		if label_3d:
			label_3d.text = text

## Optionally add a script to be called when the button is pressed or hovered
## [br][br]The script is instantiated and the "onhover -> void" or
## "onclick -> void" methods will be called when the button is hovered or clicked
@export var callscript : Script:
	set(value):
		callscript = value
		# we need to immediately instantiate the callscript
		# so it can be tracked and continue to exist properly
		# for consistent behavior and access to the proper
		# object functions, like nodes needing to be in the tree
		if callscript and callscript.can_instantiate():
			callscriptinstance = callscript.new()

## sets whether the button should be activated upon
## button down (true) or button up (false)
@export var press_on_down := true

## the instantiated callscript
var callscriptinstance:
	set(value):
		callscriptinstance = value
		# if the instance is a Node, we add it as a child to the 
		# button so it can be in the scene and behave correctly
		if callscriptinstance is Node:
			add_child(callscriptinstance)

# target sizes for tweening the size of the quad
# at different states
var MESH_TARGET_SIZE_CLICKED := Vector2(.02,.02)
var MESH_TARGET_SIZE_HOVERED := Vector2(.11,.11)
var MESH_TARGET_SIZE_INACTIVE := Vector2(.09,.09)

# transition mode for the tweens
var trans_mode := Tween.TRANS_CIRC
# tween time
var tween_time := .5

# used to track the lable target position so the
# position can be lerped toward this value
var label_target_position := 0.0

# the alpha... idk
var alpha := 0.5

# for tracking whether the button is hovered
var hover := false:
	set(val):
		hover = val
		if val:
			hovered.emit()

# for tracking whether the button is currently
# being clicked
var isclicked := false:
	set(val):
		isclicked = val
		if val:
			button_down.emit()
			return
		button_up.emit()

# resets the label text once the node has
# entered the tree so it can run the proper
# initialization code for the value 
# (reduces duplicate code this way)
func _ready():
	label_3d.text = text
	# apply the endhover state on ready to make sure the buttons start off
	# with the correct visuals
	tween_endhover()

# checks if the callscript has already been setup
# and sets it up if it hasn't been already
func _check_callscriptinstance():
	if !is_instance_valid(callscriptinstance) and callscript != null and callscript.can_instantiate():
		callscriptinstance = callscript.new()

# capture generic laser input from the interaction ray
func laser_input(data:Dictionary):
	# ensures the callscript instance is setup
	_check_callscriptinstance()
	# switch case for the interaction state
	match data.action:
		# if click event...
		"click":
			# check that the event is properly formatted with a pressed variable...
			if "pressed" in data:
				# run tweens for click visuals
				tween_click()
				# if a button is actually pressed in this event (otherwise it is a
				# button released event)
				if data.pressed:
					# set isclicked to true to track the clicked state
					# this was a holdover but is not used for the hover 
					# state tracking
					isclicked = true
					# throw clicked signal
					clicked.emit()
					# if a spawn item is set, spawn the item
					if itemToSpawn != null:
						# allow for spawning multiple if the button is configured to
						for i in range(item_spawn_multiplier):
							# insantiate the item to spawn
							var tmp = load(itemToSpawn).instantiate()
							# add item to the shared world root
							get_tree().get_first_node_in_group("localworldroot").add_child(tmp)
							# set the global position immediately to the location of the button
							tmp.global_position = global_position
							if tmp is Node3D:
								if look_at_point.is_zero_approx():
									tmp.look_at(to_global(Vector3(0,.1,0)), Vector3.UP, true)
									##tmp.global_position = global_position
									##tmp.global_rotation = global_rotation
								else:
									tmp.look_at(look_at_point)
					# if the callscript instance exists and has the onclick method...
					if callscriptinstance != null and 'onclick' in callscriptinstance:
						# call onclick on it
						callscriptinstance.onclick()
				# if this is a button release...
				else:
					# run tween for visuals
					tween_end_click()
					# set isclicked to false
					isclicked = false
		# if the event is a hover event...
		"hover":
			# if a button is not already clicked and it's the first event where the 
			# 3d button is hovered...
			if !isclicked and !hover:
				# run tweens for visual
				tween_end_click()
			# if callscript is valid and has onhover...
			if callscriptinstance != null and 'onhover' in callscriptinstance:
				# call onhover
				callscriptinstance.onhover()
			# if the hovering event is actually currently hovering...
			if data.has('hovering') and data['hovering'] == true:
				# run tweens for visuals
				tween_hover()
				# set hover to true
				hover = true
			# if the event has "hovering" set to false that means it is
			# an exiting hover event (the laser is leaving the collider)...
			else:
				# run tweens for visuals
				tween_endhover()
				# set hover to false
				hover = false

# these should probably be self explanatory (tell zodie to add comments if that's not true x3)

func tween_click():
	create_tween().tween_property(mesh_instance_3d,"mesh:size",MESH_TARGET_SIZE_CLICKED,tween_time).set_ease(Tween.EASE_OUT).set_trans(trans_mode)
	create_tween().tween_property(label_3d,"position:y",-.01,tween_time).set_ease(Tween.EASE_OUT).set_trans(trans_mode)

func tween_end_click():
	create_tween().tween_property(mesh_instance_3d,"mesh:size",MESH_TARGET_SIZE_HOVERED,tween_time).set_ease(Tween.EASE_OUT).set_trans(trans_mode)
	create_tween().tween_property(label_3d,"position:y",.01,tween_time).set_ease(Tween.EASE_OUT).set_trans(trans_mode)

func tween_hover():
	create_tween().tween_property(mesh_instance_3d.mesh.surface_get_material(0),"albedo_color:r",1.0,tween_time).set_ease(Tween.EASE_OUT).set_trans(trans_mode)
	create_tween().tween_property(mesh_instance_3d.mesh.surface_get_material(0),"albedo_color:g",1.0,tween_time).set_ease(Tween.EASE_OUT).set_trans(trans_mode)
	create_tween().tween_property(mesh_instance_3d.mesh.surface_get_material(0),"albedo_color:b",1.0,tween_time).set_ease(Tween.EASE_OUT).set_trans(trans_mode)
	create_tween().tween_property(mesh_instance_3d.mesh.surface_get_material(0),"albedo_color:a",1.0,tween_time).set_ease(Tween.EASE_OUT).set_trans(trans_mode)

func tween_endhover():
	create_tween().tween_property(mesh_instance_3d,"mesh:size",MESH_TARGET_SIZE_INACTIVE,tween_time).set_ease(Tween.EASE_OUT).set_trans(trans_mode)
	create_tween().tween_property(mesh_instance_3d.mesh.surface_get_material(0),"albedo_color:r",.5,tween_time).set_ease(Tween.EASE_OUT).set_trans(trans_mode)
	create_tween().tween_property(mesh_instance_3d.mesh.surface_get_material(0),"albedo_color:g",.5,tween_time).set_ease(Tween.EASE_OUT).set_trans(trans_mode)
	create_tween().tween_property(mesh_instance_3d.mesh.surface_get_material(0),"albedo_color:b",.5,tween_time).set_ease(Tween.EASE_OUT).set_trans(trans_mode)
	create_tween().tween_property(mesh_instance_3d.mesh.surface_get_material(0),"albedo_color:a",.5,tween_time).set_ease(Tween.EASE_OUT).set_trans(trans_mode)
