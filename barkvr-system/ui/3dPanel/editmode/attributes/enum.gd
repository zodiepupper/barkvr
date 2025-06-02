class_name Enum_Attribute
extends Control

@onready var label :Label= $VBoxContainer/Panel2/Label
@onready var val :OptionButton= $VBoxContainer/position/v/val

var target:Object
var _is_editing:bool = false:
	get:
		return _check_focus()

var property_name:String = ''

var is_string_enum: bool = false

func _ready():
	val.get_popup().hide_on_item_selection=false
	val.get_popup().hide_on_checkable_item_selection=false
	val.get_popup().hide_on_state_item_selection=false
	val.item_selected.connect(func(index):
		if is_instance_valid(target):
			if is_string_enum:
				target[property_name] = val.get_item_text(index)
			else:
				target[property_name] = index
	)
	_go()

func _go() -> void:
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
	create_tween().tween_callback(_go).set_delay(Engine.get_singleton("settings_manager").inspector_update_interval)

func update_fields():
	#print('enum: ', property_name)
	if target and !property_name.is_empty() and !_is_editing and is_instance_valid(target) and !_check_focus():
		if is_string_enum:
			val.selected = find_item_index_from_string(target[property_name])
		else:
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
func set_data(new_name:String, new_target:Object, new_property_name:String, prop_data:Dictionary, _is_string_enum:bool=false):
	is_string_enum = _is_string_enum
	label.text = new_name
	property_name = new_property_name
	if "hint_string" in prop_data:
		var options :Array = prop_data.hint_string.split(',')
		if is_string_enum:
			val.add_item("none")
		for i in options.size():
			val.add_item(options[i], i)
	if is_string_enum:
		print("val selected:")
		print(val.selected)
		val.selected = find_item_index_from_string(new_target[property_name])
		print(val.selected)
	else:
		val.selected = (new_target[property_name])
	target = new_target
	name = new_name

func find_item_index_from_string(item_text:String) -> int:
	for i in val.item_count:
		if val.get_item_text(i) == item_text:
			return i
	return 0
