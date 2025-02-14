class_name Enum_Attribute
extends Control

@onready var label :Label= $VBoxContainer/Panel2/Label
@onready var val :OptionButton= $VBoxContainer/position/v/val

var target:Object
var _is_editing:bool = false:
	get:
		return _check_focus()
var property_name:String = ''

func _ready():
	val.get_popup().hide_on_item_selection=false
	val.get_popup().hide_on_checkable_item_selection=false
	val.get_popup().hide_on_state_item_selection=false
	val.item_selected.connect(func(index):
		if is_instance_valid(target):
			target[property_name] = index
		)

func _process(_delta):
	if target and !property_name.is_empty() and !_is_editing and is_instance_valid(target) and !_check_focus():
		var scrollparentrect = get_parent_control().get_parent_control().get_global_rect()
		var scrollparent = get_parent_control().get_parent_control()
		if scrollparent is ScrollContainer:
			var rect = get_global_rect()
			if (rect.end.y > scrollparentrect.position.y and rect.position.y < scrollparentrect.end.y):
					update_fields()
	elif !is_instance_valid(target):
		target = null
		val.button_pressed = false
		val.text = ''

func update_fields():
	#print('enum: ', property_name)
	if target and !property_name.is_empty() and !_is_editing and is_instance_valid(target) and !_check_focus():
		val.selected = (target[property_name])
	elif !is_instance_valid(target):
		target = null
		val.selected = -1
		val.text = ''

func _check_focus():
	if val.has_focus():
		return true
	return false

## sets the name, field target node, and the property name for the field to look for
## name:String, new_target:Node, new_property_name:String
func set_data(new_name:String, new_target:Object, new_property_name:String, prop_data:Dictionary):
	label.text = new_name
	property_name = new_property_name
	if "hint_string" in prop_data:
		var options :Array = prop_data.hint_string.split(',')
		for i in options.size():
			val.add_item(options[i], i)
	val.selected = (new_target[property_name])
	target = new_target
	name = new_name
