class_name message_bubble
extends Control

var panel:Panel
@onready var body_lbl: RichTextLabel = %body
@onready var time_lbl: Label = %time
@onready var username_lbl: Label = %username

@export var text = '':
	set(val):
		text = val
		if body_lbl:
			body_lbl.text = text
@export var sender = '':
	set(val):
		sender = val
		if username_lbl:
			username_lbl.text = sender
@export var time = '':
	set(val):
		time = val
		if time_lbl:
			time_lbl.text = time

@export var leftside:bool = true:
	set(value):
		leftside = value
		var par := get_parent_control()
		if is_instance_valid(par):
			print('sizing')
			if leftside:
				add_theme_constant_override("margin_right",par.size.x*.3)
				return
			add_theme_constant_override("margin_left",par.size.x*.3)

func _ready() -> void:
	leftside = leftside
	if text:
		body_lbl.text = text
	body_lbl.text = text
	username_lbl.text = sender
	time_lbl.text = time
