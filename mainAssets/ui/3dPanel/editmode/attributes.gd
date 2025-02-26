extends Control

#TODO 	find a more optimized way to update field values
# This requires a PR to godot. they don't seem interested in the change
# but without it, it's impossible to do performant scene tracking

@onready var export: Button = $VBoxContainer/titlebar/HBoxContainer/HBoxContainer/export
@onready var dupbtn: Button = $VBoxContainer/titlebar/HBoxContainer/HBoxContainer3/dupbtn
@onready var delete: Button = $VBoxContainer/titlebar/HBoxContainer/HBoxContainer2/delete
@onready var properties_header_label: Label = $"VBoxContainer/titlebar/properties header/Panel9/properties header label"
@onready var activetoggle: CheckButton = $"VBoxContainer/titlebar/properties header/active/HBoxContainer/activetoggle"
@onready var targetname: LineEdit = $VBoxContainer/titlebar/HBoxContainer/Panel/targetname

@onready var v_box_container = $VBoxContainer/ScrollContainer/VBoxContainer

var vector_3_field = load("res://mainAssets/ui/3dPanel/editmode/attributes/vector3.tscn")
var vector_2_field = load("res://mainAssets/ui/3dPanel/editmode/attributes/vector2.tscn")
var number_field = load("res://mainAssets/ui/3dPanel/editmode/attributes/number.tscn")
var bool_field = load("res://mainAssets/ui/3dPanel/editmode/attributes/bool.tscn")
var enum_field = load("res://mainAssets/ui/3dPanel/editmode/attributes/enum.tscn")
var string_field = load("res://mainAssets/ui/3dPanel/editmode/attributes/string.tscn")
var object_field = load("res://mainAssets/ui/3dPanel/editmode/attributes/object.tscn")
var color_field = load("res://mainAssets/ui/3dPanel/editmode/attributes/color.tscn")
var array_field = load("res://mainAssets/ui/3dPanel/editmode/attributes/array.tscn")
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

var event_manager

#func _process(delta):
#	if !is_field_focused:
#		update_fields()

func set_target(new_target, above_targets=[]):
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
		for child in v_box_container.get_children():
			child.queue_free()
		var prop_list :Array[Dictionary]= new_target.get_property_list()
		#call_deferred("_add_fields", prop, new_target, above_targets)
		call_deferred("_add_fields", prop_list, new_target, above_targets)
#		update_fields()

#func _add_fields(prop, new_target, above_targets) -> void:
func _add_fields(prop_list, new_target, above_targets) -> void:
	for i in range(prop_list.size()):
		var prop = prop_list[i]
		if i % 4 == 0:
			await get_tree().process_frame
		var fieldname :String= prop.name
		if prop.name.contains("bones/") and new_target is Skeleton3D:
			fieldname = "bone: "+new_target.get_bone_name(int(prop.name.split("/")[1]))+" "+prop.name.split("/")[-1]
		match prop.type:
			TYPE_OBJECT:
				if prop.hint_string == "Node" or prop.class_name in ClassDB.get_inheriters_from_class("Node"):
					print('node don\'t add')
				else:
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
				var tmp :String_Attribute = string_field.instantiate()
				v_box_container.add_child(tmp)
				tmp.name = fieldname
				tmp.set_data(fieldname, new_target, prop.name)
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
					0:
						var tmp :Number_Attribute = number_field.instantiate()
						tmp.type = 1
						v_box_container.add_child(tmp)
						tmp.name = fieldname
						tmp.set_data(fieldname, new_target, prop.name)
					2:
						var tmp :Enum_Attribute = enum_field.instantiate()
						v_box_container.add_child(tmp)
						tmp.name = fieldname
						tmp.set_data(fieldname, new_target, prop.name, prop)
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

func update_fields():
	if target and is_instance_valid(target):
		if target.has_meta("display_name"):
			targetname.text = target.get_meta("display_name")
		else:
			targetname.text = target.name

func clear_fields():
	if target:
		if target.has_meta("display_name"):
			targetname.text = target.get_meta("display_name")
		else:
			targetname.text = target.name

func _ready():
	titlebar_top_row.visible = !hide_titlebar
	titlebar_active.visible = !hide_titlebar
	event_manager = Engine.get_singleton("event_manager")
	dupbtn.pressed.connect(func():
		if target:
			var tmp :Node=target.duplicate()
			target.get_parent().add_child(tmp)
			tmp.name = target.name
		)
	delete.pressed.connect(func():
		if target and is_instance_valid(target):
			event_manager.delete_node(event_manager.root.get_path_to(target))
			clear_fields()
		)
	activetoggle.toggled.connect(func(on:bool):
		if target and is_instance_valid(target) and target is Node:
			event_manager.set_property(event_manager.root.get_path_to(target),"visible",on)
			#target.visible = active.button_pressed
		)
	export.pressed.connect(func():
		var world_root = get_tree().get_first_node_in_group("localworldroot")
		if world_root and target:
			var thread = Thread.new()
			thread.start(_export_node.bind(target))
			BarkHelpers.rejoin_thread_when_finished(thread)
#			_export_node(target)
#			var tmp:PackedScene = PackedScene.new()
#			assert(tmp.pack(target)==OK)
#			var err = ResourceSaver.save(tmp,'user://objects/'+target.name+'.res')
#			print(err)
#			OS.shell_open(OS.get_user_data_dir())
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
		
