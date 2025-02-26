class_name Array_Attribute
extends Control

@onready var label :Label= $VBoxContainer/Panel2/Label
@onready var expand: Button = $VBoxContainer/Panel2/expand
@onready var field_parent: VBoxContainer = %object
@onready var margin_container: MarginContainer = $VBoxContainer/MarginContainer

var vector_3_field = load("res://mainAssets/ui/3dPanel/editmode/attributes/vector3.tscn")
var vector_2_field = load("res://mainAssets/ui/3dPanel/editmode/attributes/vector2.tscn")
var number_field = load("res://mainAssets/ui/3dPanel/editmode/attributes/number.tscn")
var bool_field = load("res://mainAssets/ui/3dPanel/editmode/attributes/bool.tscn")
var enum_field = load("res://mainAssets/ui/3dPanel/editmode/attributes/enum.tscn")
var string_field = load("res://mainAssets/ui/3dPanel/editmode/attributes/string.tscn")
var object_field = load("res://mainAssets/ui/3dPanel/editmode/attributes/object.tscn")
var color_field = load("res://mainAssets/ui/3dPanel/editmode/attributes/color.tscn")

var target:Object
var property_name:String = '':
	set(val):
		property_name = val
		#print(property_name + " " + str( fmod(hash(property_name)/1000.0,1.0) ) + "\n" + str(hash(property_name)))

func _ready() -> void:
	expand.toggled.connect(func(on:bool):
		if on:
			custom_minimum_size.y = 1000
		else:
			custom_minimum_size.y = 100
		)

## sets the name, field target node, and the property name for the field to look for
## name:String, new_target:Node, new_property_name:String
func set_data(new_name:String, new_target:Object, new_property_name:String, above_targets=[]):
	label.text = new_name
	target = new_target
	property_name = new_property_name
	var attributes_target = target[property_name]
	if attributes_target is Array:
		for i in attributes_target.size():
			if i%4 == 0:
				await get_tree().process_frame
			var prop = attributes_target[i]
			match typeof(prop):
				TYPE_OBJECT:
					if "hint_string" in prop and prop.hint_string == "Node" or "class_name" in prop and prop.class_name in ClassDB.get_inheriters_from_class("Node"):
						print('node don\'t add')
					else:
						var tmp :Object_Attribute = object_field.instantiate()
						field_parent.add_child(tmp)
						tmp.call_deferred("set_data",str(i), attributes_target, str(i),above_targets)
				TYPE_STRING_NAME:
					var tmp :String_Attribute = string_field.instantiate()
					field_parent.add_child(tmp)
					tmp.set_data(str(i), attributes_target, str(i))
				TYPE_STRING:
					var tmp :String_Attribute = string_field.instantiate()
					field_parent.add_child(tmp)
					tmp.set_data(str(i), attributes_target, str(i))
				TYPE_COLOR:
					var tmp :Color_Attribute = color_field.instantiate()
					field_parent.add_child(tmp)
					tmp.set_data(str(i), attributes_target, str(i))
				TYPE_BOOL:
					var tmp :Bool_Attribute = bool_field.instantiate()
					field_parent.add_child(tmp)
					tmp.set_data(str(i), attributes_target, str(i))
				TYPE_FLOAT:
					var tmp :Number_Attribute = number_field.instantiate()
					tmp.type = 0
					field_parent.add_child(tmp)
					tmp.set_data(str(i), attributes_target, i)
				TYPE_INT:
					match prop.hint:
						0:
							var tmp :Number_Attribute = number_field.instantiate()
							tmp.type = 1
							field_parent.add_child(tmp)
							tmp.set_data(str(i), attributes_target, str(i))
						2:
							var tmp :Enum_Attribute = enum_field.instantiate()
							field_parent.add_child(tmp)
							tmp.set_data(str(i), attributes_target, str(i), prop)
				TYPE_VECTOR3:
					var tmp :Vector3_Attribute = vector_3_field.instantiate()
					field_parent.add_child(tmp)
					tmp.set_data(str(i), attributes_target, str(i))
				TYPE_VECTOR2:
					var tmp :Vector2_Attribute = vector_2_field.instantiate()
					field_parent.add_child(tmp)
					tmp.set_data(str(i), attributes_target, str(i))
