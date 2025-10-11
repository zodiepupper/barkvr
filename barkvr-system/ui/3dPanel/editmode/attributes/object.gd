class_name Object_Attribute
extends Control

@onready var label :Label= $VBoxContainer/Panel2/Label
@onready var expand: Button = $VBoxContainer/Panel2/expand
var ATTRIBUTES_SCENE = load("res://barkvr-system/ui/3dPanel/editmode/attributes.tscn")
var ATTRIBUTES_POPUP_SCENE = load("res://barkvr-system/ui/3dPanel/editmode/popup/attributes_popup.tscn")
var attributes: Control
@onready var create: Button = %create
@onready var copy: Button = %copy
@onready var paste: Button = %paste

@export var full_height := false

var target:Object
var property_name:String = '':
	set(val):
		property_name = val

func _ready() -> void:
	create.pressed.connect(func():
		pass
		)
	copy.pressed.connect(func():
		if target[property_name]:
			DisplayServer.clipboard_set(str(target[property_name].get_instance_id()))
		)
	paste.pressed.connect(func():
		var pasted := DisplayServer.clipboard_get()
		if !pasted.is_empty() and pasted.is_valid_int():
			var derived = instance_from_id(pasted.to_int())
			if is_instance_valid(derived) and typeof(derived) == typeof(target[property_name]):
				target[property_name] = derived
				print('pasted')
		)
	get_child(0).resized.connect(func():
		if full_height and expand.button_pressed:
			custom_minimum_size.y = get_child(0).size.y
		)
	expand.toggled.connect(func(on:bool):
		if on:
			if full_height:
				custom_minimum_size.y = get_child(0).size.y
				return
			custom_minimum_size.y = 1000
		else:
			custom_minimum_size.y = 100
		)
	expand.pressed.connect(func():
		var tmp : Control = ATTRIBUTES_POPUP_SCENE.instantiate()
		tmp.hide_titlebar = true
		#tmp.full_height = full_height
		tmp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		get_parent().get_parent().get_parent().get_parent().add_child(tmp)
		tmp.set_deferred("target", target[property_name])
		print('opened single object inspector: ',target)
		)

## sets the name, field target node, and the property name for the field to look for
## name:String, new_target:Node, new_property_name:String
func set_data(new_name:String, new_target:Object, new_property_name:String, above_targets=[]):
	if new_property_name in new_target:
		above_targets.append(new_target)
		label.text = new_name
		target = new_target
		property_name = new_property_name

func show_attributes_modal() -> void:
		attributes = ATTRIBUTES_SCENE.instantiate()
		attributes.hide_titlebar = true
		attributes.full_height = full_height
		attributes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		attributes.call_deferred("set_target",target[property_name])
