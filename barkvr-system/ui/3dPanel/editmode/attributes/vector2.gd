class_name Vector2_Attribute
extends Control

@onready var label = $VBoxContainer/Panel2/Label
@onready var xval: LineEdit = $VBoxContainer/position/x/xval
@onready var yval: LineEdit = $VBoxContainer/position/y/yval

var target:Object
var _is_editing:bool = false
var property_name:String = ''


func _ready():
	xval.text_changed.connect(func(new_text):
		var expression := Expression.new()
		print(expression.get_error_text())
		if expression.parse(new_text) == 0:
			new_text = str(expression.execute())
		target[property_name].x = float(new_text)
		)
	yval.text_changed.connect(func(new_text):
		var expression := Expression.new()
		print(expression.get_error_text())
		if expression.parse(new_text) == 0:
			new_text = str(expression.execute())
		target[property_name].y = float(new_text) # change these fields to use the journal instead of directly setting values so they work correctly
		)
	_go()

func _go() -> void:
	var scrollparentrect = get_parent_control().get_parent_control().get_global_rect()
	var rect = get_global_rect()
	if (rect.end.y > scrollparentrect.position.y and rect.position.y < scrollparentrect.end.y):
			update_fields()
	create_tween().tween_callback(_go).set_delay(Engine.get_singleton("settings_manager").inspector_update_interval)

func update_fields():
	#print('vec2: ', property_name)
	if target and !property_name.is_empty() and !_is_editing and is_instance_valid(target) and !_check_focus():
		xval.text = str(target.get(property_name).x)
		yval.text = str(target.get(property_name).y)
	elif !is_instance_valid(target):
		target = null
		xval.text = ''
		yval.text = ''

func _check_focus():
	if xval.has_focus() or yval.has_focus():
		return true
	return false

## sets the name, field target node, and the property name for the field to look for
## name:String, new_target:Node, new_property_name:String
func set_data(new_name:String, new_target:Object, new_property_name:String):
	label.text = new_name
	target = new_target
	property_name = new_property_name

func set_value(new_value:Vector2):
	xval.text = str(new_value.x)
	yval.text = str(new_value.y)
