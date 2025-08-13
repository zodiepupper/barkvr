extends Control

#TODO 	find a more optimized way to update field values
# This requires a PR to godot. they don't seem interested in the change
# but without it, it's impossible to do performant scene tracking

@onready var closepanelbtn: Button = %closepanelbtn
@onready var closepanel: HBoxContainer = %closepanel

@onready var properties_header_label: Label = $"VBoxContainer/titlebar/properties header/Panel9/properties header label"
@onready var activetoggle: CheckButton = $"VBoxContainer/titlebar/properties header/active/HBoxContainer/activetoggle"
@onready var targetname: LineEdit = $VBoxContainer/titlebar/HBoxContainer/Panel/targetname

@onready var scroll_container: ScrollContainer = %ScrollContainer
@onready var v_box_container: VBoxContainer = %VBoxContainer

var vector_3_field = load("res://barkvr-system/ui/3dPanel/editmode/attributes/vector3.tscn")
var vector_2_field = load("res://barkvr-system/ui/3dPanel/editmode/attributes/vector2.tscn")
var number_field = load("res://barkvr-system/ui/3dPanel/editmode/attributes/number.tscn")
var bool_field = load("res://barkvr-system/ui/3dPanel/editmode/attributes/bool.tscn")
var enum_field = load("res://barkvr-system/ui/3dPanel/editmode/attributes/enum.tscn")
var string_field = load("res://barkvr-system/ui/3dPanel/editmode/attributes/string.tscn")
var object_field = load("res://barkvr-system/ui/3dPanel/editmode/attributes/object.tscn")
var color_field = load("res://barkvr-system/ui/3dPanel/editmode/attributes/color.tscn")
var array_field = load("res://barkvr-system/ui/3dPanel/editmode/attributes/array.tscn")
var is_field_focused = false
var target : Object = null

#titlebar stuffs
@onready var titlebar: VBoxContainer = $VBoxContainer/titlebar
@onready var titlebar_top_row: HBoxContainer = $VBoxContainer/titlebar/HBoxContainer
@onready var properties_header: HBoxContainer = $"VBoxContainer/titlebar/properties header"
@onready var titlebar_active: ColorRect = $"VBoxContainer/titlebar/properties header/active"

var hide_titlebar := false:
	set(val):
		hide_titlebar = val
		if is_instance_valid(titlebar_top_row):
			titlebar_top_row.visible = !hide_titlebar
		if is_instance_valid(titlebar_active):
			titlebar_active.visible = !hide_titlebar

@export var full_height := false:
	set(val):
		full_height = val
		set_full_height_deferred.call_deferred()

func set_full_height_deferred():
	if full_height:
		scroll_container.hide()
		custom_minimum_size.y = get_child(0).size.y
		v_box_container.reparent(scroll_container.get_parent())
	else:
		scroll_container.show()
		v_box_container.reparent(scroll_container)

var event_manager

func set_target(new_target, above_targets:=[]):
	if !above_targets.is_empty():
		#print("first above_targets: " + str(above_targets[0]))
		#print("above_targets: " + str(above_targets) + "\n")
		var num_of_resources_above: int = 0
		for i in above_targets:
			if i is Resource:
				num_of_resources_above += 1
		if num_of_resources_above > 1:
			print(above_targets.filter(func(val):
				if val is Resource:
					return true
				return false
				))
	if new_target and new_target is Object and new_target not in above_targets:
		target = new_target
		if "name" in new_target and new_target.name:
			targetname.text = new_target.name
		if new_target.has_meta("display_name"):
			targetname.text = new_target.get_meta("display_name")
		if "visible" in new_target and new_target.visible != null:
			activetoggle.disabled = false
			activetoggle.button_pressed = new_target.visible
		else:
			activetoggle.button_pressed = true
			activetoggle.disabled = true
		properties_header_label.text = new_target.get_class()+" Properties:"
		
		var start_time : float = Time.get_ticks_msec()
		for child in v_box_container.get_children():
			if start_time + 1 < Time.get_ticks_msec():
				await get_tree().process_frame
				start_time = Time.get_ticks_msec()
			child.queue_free()
		var prop_list :Array[Dictionary]= new_target.get_property_list()
		#call_deferred("_add_fields", prop, new_target, above_targets)
		call_deferred("_add_fields", prop_list, new_target, above_targets)
#		update_fields()

#func _add_fields(prop, new_target, above_targets) -> void:
func _add_fields(prop_list, new_target, above_targets:Array) -> void:
	while LocalGlobals.is_inspector_loading:
		await get_tree().process_frame
	LocalGlobals.is_inspector_loading = true
	var start_time : float = Time.get_ticks_msec()
	for i in range(prop_list.size()):
		if start_time + 1 < Time.get_ticks_msec():
			await get_tree().process_frame
			start_time = Time.get_ticks_msec()
		#await get_tree().process_frame
		var prop = prop_list[i]
		var fieldname :String= prop.name
		if prop.name.contains("bones/") and new_target is Skeleton3D:
			fieldname = "bone: "+new_target.get_bone_name(int(prop.name.split("/")[1]))+" "+prop.name.split("/")[-1]
		for targ in above_targets:
			if targ == new_target:
				return
		if above_targets.size() > 3:
			return
		if !is_instance_valid(new_target):
			return
		if prop.name == "owner":
			continue
		match prop.type:
			TYPE_OBJECT:
				var tmp :Object_Attribute = object_field.instantiate()
				v_box_container.add_child(tmp)
				tmp.name = fieldname
				tmp.set_data(fieldname, target, prop.name,above_targets.duplicate(true))
			TYPE_ARRAY:
				var tmp :Array_Attribute = array_field.instantiate()
				v_box_container.add_child(tmp)
				tmp.name = fieldname
				tmp.set_data(fieldname, new_target, prop.name)
			TYPE_STRING_NAME:
				match prop.hint:
					0:
						var tmp :String_Attribute = string_field.instantiate()
						v_box_container.add_child(tmp)
						tmp.name = fieldname
						tmp.set_data(fieldname, new_target, prop.name)
					2:
						var tmp :Enum_Attribute = enum_field.instantiate()
						v_box_container.add_child(tmp)
						tmp.name = fieldname
						tmp.set_data(fieldname, new_target, prop.name, prop, true)
			TYPE_STRING:
				var tmp :String_Attribute = string_field.instantiate()
				v_box_container.add_child(tmp)
				tmp.name = fieldname
				tmp.set_data(fieldname, new_target, prop.name)
			TYPE_COLOR:
				var tmp :Color_Attribute = color_field.instantiate()
				v_box_container.add_child(tmp)
				tmp.name = fieldname
				tmp.set_data(fieldname, new_target, prop.name)
			TYPE_BOOL:
				var tmp :Bool_Attribute = bool_field.instantiate()
				v_box_container.add_child(tmp)
				tmp.name = fieldname
				tmp.set_data(fieldname, new_target, prop.name, above_targets)
			TYPE_FLOAT:
				var tmp :Number_Attribute = number_field.instantiate()
				tmp.type = 0
				v_box_container.add_child(tmp)
				tmp.name = fieldname
				tmp.set_data(fieldname, new_target, prop.name)
			TYPE_INT:
				match prop.hint:
					2:
						var tmp :Enum_Attribute = enum_field.instantiate()
						v_box_container.add_child(tmp)
						tmp.name = fieldname
						tmp.set_data(fieldname, new_target, prop.name, prop)
					_:
						var tmp :Number_Attribute = number_field.instantiate()
						tmp.type = 1
						v_box_container.add_child(tmp)
						tmp.name = fieldname
						tmp.set_data(fieldname, new_target, prop.name)
			TYPE_VECTOR3:
				var tmp :Vector3_Attribute = vector_3_field.instantiate()
				v_box_container.add_child(tmp)
				tmp.name = fieldname
				tmp.set_data(fieldname, new_target, prop.name)
			TYPE_VECTOR2:
				var tmp :Vector2_Attribute = vector_2_field.instantiate()
				v_box_container.add_child(tmp)
				tmp.name = fieldname
				tmp.set_data(fieldname, new_target, prop.name)
	LocalGlobals.is_inspector_loading = false

func clear_fields():
	if target:
		if target.has_meta("display_name"):
			targetname.text = target.get_meta("display_name")
		else:
			targetname.text = target.name

func _ready():
	get_child(0).resized.connect(func():
		if full_height:
			custom_minimum_size.y = get_child(0).size.y
		)
	titlebar_top_row.visible = !hide_titlebar
	titlebar_active.visible = !hide_titlebar
	event_manager = Engine.get_singleton("event_manager")
	activetoggle.toggled.connect(func(on:bool):
		if target and is_instance_valid(target) and target is Node:
			event_manager.set_property(event_manager.root.get_path_to(target),"visible",on)
			#target.visible = active.button_pressed
		)
	targetname.text_changed.connect(func(new_text:String):
		if target:
			target.set_meta("display_name",new_text)
			target.name = target.name
		)
	targetname.focus_entered.connect(func():
		is_field_focused = true
		)
	targetname.focus_exited.connect(func():
		is_field_focused = false
		)
	closepanelbtn.pressed.connect(queue_free)

func _export_node(tmp_target:Node):
	Thread.set_thread_safety_checks_enabled(false)
	print('start export')
	var downpath :String=OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS)
	downpath += "/"
	if OS.get_name() == "Web":
		var packed := PackedScene.new()
		event_manager.take_owner_of_node_and_all_children(tmp_target,tmp_target)
		packed.pack(tmp_target)
		print("save path: "+downpath+tmp_target.name+".res")
		JavaScriptBridge.download_buffer(var_to_bytes_with_objects(packed),tmp_target.name+".res")
		#print("export error: "+str(err))
	elif DirAccess.dir_exists_absolute(downpath):
		var packed := PackedScene.new()
		event_manager.take_owner_of_node_and_all_children(tmp_target,tmp_target)
		packed.pack(tmp_target)
		var err = ResourceSaver.save(packed, downpath+tmp_target.name+".res",ResourceSaver.FLAG_BUNDLE_RESOURCES)
		print("export error: "+str(err))
		
