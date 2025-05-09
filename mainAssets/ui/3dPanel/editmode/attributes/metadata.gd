class_name Metadata_Attribute
extends Control

@onready var label = $VBoxContainer/Panel2/Label

var target:Object
var property_name:String = ''

@onready var meta_name: LineEdit = %name
@onready var type: OptionButton = %type
@onready var add: Button = %add

func _ready() -> void:
	add.pressed.connect(add_metadata)

func add_metadata() -> void:
	target.set_meta(meta_name.text, "")
