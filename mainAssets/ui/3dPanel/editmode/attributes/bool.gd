class_name Bool_Attribute
extends Control

@onready var label :Label= $VBoxContainer/Panel2/Label
@onready var val :Button= $VBoxContainer/position/v/val

var target:Object
var _is_editing:bool = false:
	get:
		return _check_focus()
var property_name:String = ''

var event_supplier : Bark_Journal

var above_targets : Array

func _ready():
	event_supplier = Engine.get_singleton("event_manager")
	val.toggled.connect(func(on):
		if is_instance_valid(target) and is_instance_valid(event_supplier):
			if on:
				val.text = "true"
			else:
				val.text = "false"
			target[property_name] = on
			#event_supplier.set_property(
				#event_supplier.root.get_path_to(above_targets[0]),
				#property_name+":x",
				#on
			#)
		)

func _process(_delta):
	var scrollparentrect = get_parent_control().get_parent_control().get_global_rect()
	var scrollparent = get_parent_control().get_parent_control()
	if scrollparent is ScrollContainer:
		var rect = get_global_rect()
		if (rect.end.y > scrollparentrect.position.y and rect.position.y < scrollparentrect.end.y):
				update_fields()

func build_path_to_property() -> String:
	var out := ""
	if above_targets and above_targets.size() > 1:
		for i in above_targets.size():
			if i > 0:
				out += "/"
			if "name" in above_targets[i]:
				out += above_targets[i].name
			elif "resource_name" in above_targets[i]:
				out += above_targets[i].resource_name
			else:
				print("couldn't add this object to the node+resource path: "+str(above_targets[i]))
	return out

func update_fields():
	#print('bool: ', property_name)
	if target and !property_name.is_empty() and !_is_editing and property_name in target and is_instance_valid(target) and !_check_focus():
		val.button_pressed = (target[property_name])
	elif !is_instance_valid(target):
		target = null
		val.button_pressed = false
		val.text = ''

func _check_focus():
	if val.has_focus():
		return true
	return false

## sets the name, field target node, and the property name for the field to look for
## name:String, new_target:Node, new_property_name:String
func set_data(new_name:String, new_target:Object, new_property_name:String, new_above_targets=[]):
	above_targets = new_above_targets
	label.text = new_name
	target = new_target
	property_name = new_property_name
	if property_name in target:
		if property_name.contains("/"):
			queue_free()
			return
		val.button_pressed = (target[property_name])
		build_path_to_property()
	
