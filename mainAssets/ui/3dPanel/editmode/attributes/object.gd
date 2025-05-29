class_name Object_Attribute
extends Control

@onready var label :Label= $VBoxContainer/Panel2/Label
@onready var expand: Button = $VBoxContainer/Panel2/expand
var ATTRIBUTES_SCENE = load("res://mainAssets/ui/3dPanel/editmode/attributes.tscn")
var attributes: Control
@onready var field_parent: HBoxContainer = $VBoxContainer/MarginContainer/object
@onready var color_rect: ColorRect = $VBoxContainer/MarginContainer/ColorRect
@onready var margin_container: MarginContainer = $VBoxContainer/MarginContainer
@onready var create: Button = $VBoxContainer/Panel2/create
@onready var copy: Button = $VBoxContainer/Panel2/copy
@onready var paste: Button = $VBoxContainer/Panel2/paste

@export var full_height := false

var target:Object
var property_name:String = '':
	set(val):
		property_name = val
		var col := Color.from_hsv(
			fmod(hash(property_name)/1000.0,1.0),
			clamp(fmod(hash(property_name)/1000.0,1.0), .6, .9),
			clamp(fmod(hash(property_name)/1000.0,1.0), .6, .9),
			1.0
			)
		#color_rect.color = col
		col.v = .8
		#margin_container.modulate = col
		color_rect.color.r = col.r
		color_rect.color.g = col.g
		color_rect.color.b = col.b
		#print(property_name + " " + str( fmod(hash(property_name)/1000.0,1.0) ) + "\n" + str(hash(property_name)))

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

## sets the name, field target node, and the property name for the field to look for
## name:String, new_target:Node, new_property_name:String
func set_data(new_name:String, new_target:Object, new_property_name:String, above_targets=[]):
	if new_property_name in new_target:
		above_targets.append(new_target)
		label.text = new_name
		target = new_target
		property_name = new_property_name
		attributes = ATTRIBUTES_SCENE.instantiate()
		attributes.hide_titlebar = true
		attributes.full_height = full_height
		attributes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		field_parent.add_child(attributes)
		attributes.call_deferred("set_target",target[property_name], above_targets)
