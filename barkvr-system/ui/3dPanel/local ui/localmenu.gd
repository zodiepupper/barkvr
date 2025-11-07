extends Control

@onready var close: Button = %close
@onready var window_properties = $TabContainer/window_properties
@onready var resize = $resize
@onready var tab_container = $TabContainer

var big_height := 1200
var big_width := 1000
var small_height := 40
var expanded := true

var resizing := false
var resize_start_position := Vector2()

## a holder for the previous user state when opening the menu
## for clearing this value, just set it equal to -1
var previous_player_state : int = -1

var viewport: Viewport:
	get:
		return get_viewport()

var panel: Panel3D:
	get:
		return viewport.get_parent() if viewport.get_parent() is Panel3D else null

func _ready():
	hide()
	Engine.register_singleton("local_menu", self)
	expanded = tab_container.visible
	get_viewport().get_parent().viewport_size = Vector2i(big_width, big_height)
	window_properties.visibility_changed.connect(func():
		window_properties.call_deferred("set_target", get_window()), 4)
	if get_viewport().get_parent() is Panel3D:
		get_viewport().get_parent().minimum_viewport_size = Vector2i(small_height,small_height)
	close.pressed.connect(_close)
	panel.visibility_changed.connect(func():
		if panel.visible:
			panel.colshape.disabled = false
		else:
			panel.colshape.disabled = true
		)

func _input(event:InputEvent):
	if resize.button_pressed and event is InputEventMouseMotion and get_viewport().get_parent() is Panel3D:
		big_height = event.position.y
		big_width = event.position.x if event.position.x > tab_container.custom_minimum_size.x else tab_container.custom_minimum_size.x
		get_viewport().get_parent().viewport_size = Vector2i(big_width, big_height)

func reveal(_force_open:bool=false) -> void:
	show()
	if panel:
		panel.show()
	previous_player_state = LocalGlobals.player_state

func _close() -> void:
	if panel:
		panel.visible = false
	visible = false
	if previous_player_state != -1:
		LocalGlobals.player_state = previous_player_state
		previous_player_state = -1
