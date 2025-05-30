extends Control

@onready var button = $Button
@onready var window_properties = $TabContainer/window_properties
@onready var resize = $resize
@onready var tab_container = $TabContainer

var big_height := 1200
var big_width := 1000
var small_height := 40
var expanded := true

var resizing := false
var resize_start_position := Vector2()

func _ready():
	Engine.register_singleton("local_menu", self)
	expanded = tab_container.visible
	get_viewport().get_parent().viewport_size = Vector2i(big_width, big_height)
	window_properties.visibility_changed.connect(func():
		window_properties.call_deferred("set_target",get_window())
		,4)
	if get_viewport().get_parent() is Panel3D:
		get_viewport().get_parent().minimum_viewport_size = Vector2i(small_height,small_height)
	button.pressed.connect(reveal)

func _input(event:InputEvent):
	if resize.button_pressed and event is InputEventMouseMotion and get_viewport().get_parent() is Panel3D:
		big_height = event.position.y
		big_width = event.position.x if event.position.x > tab_container.custom_minimum_size.x else tab_container.custom_minimum_size.x
		get_viewport().get_parent().viewport_size = Vector2i(big_width, big_height)

func reveal(force_open:bool=false) -> void:
	if force_open:
		expanded = true
		if get_viewport().get_parent() is Panel3D:
			get_viewport().get_parent().viewport_size.x = big_height
			get_viewport().get_parent().viewport_size.y = big_width
		resize.visible = expanded
		tab_container.visible = expanded
		return
	expanded = !expanded
	resize.visible = expanded
	tab_container.visible = expanded
	if get_viewport().get_parent() is Panel3D:
		get_viewport().get_parent().viewport_size.x = big_height if expanded else small_height
		get_viewport().get_parent().viewport_size.y = big_width if expanded else small_height
