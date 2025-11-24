extends Control

## The left side of the inspector, a scene inspector.
@onready var split_left: PanelContainer = %SplitLeft
## Container holding all the context-sensitive panels on the right side of the inspector.
@onready var tab_container: TabContainer = %TabContainer
## Custom tab buttons used to navigate the right side of the inspector.
@onready var tab_button_container: HBoxContainer = %HBoxContainer

## Button group used to have only one tab button pressed at a time.
var tab_button_group : ButtonGroup



func _ready() -> void:
	split_left.selection_changed.connect(_on_node_selection_change)

	tab_button_group = ButtonGroup.new()
	setup_tab_buttons()

## Called when a new node gets selected from the scene inspector.
func _on_node_selection_change(new_selection : Node) -> void:
	# Unsure as to what this is used for.
	LocalGlobals.is_inspector_loading = false
	# Set target on all tabs.
	for tab : Control in tab_container.get_children():
		if tab.has_method(&"set_target"):
			tab.set_target(new_selection)

## Set up auto-generated tab buttons to navigate the tab container.
func setup_tab_buttons() -> void:
	# Clear existing buttons out of the list.
	for button in tab_button_container.get_children():
		button.queue_free()
	# Add each tab as a button.
	for tab : Control in tab_container.get_children():
		var button : Button = Button.new()
		button.toggle_mode = true
		button.text = tab.name
		button.focus_mode = Control.FOCUS_NONE
		button.button_group = tab_button_group
		tab_button_container.add_child(button)
		button.pressed.connect(_on_tab_button_pressed.bind(tab.get_index()))
	# Select the 0th button by default.
	if !tab_button_group.get_buttons().is_empty():
		tab_button_group.get_buttons()[0].button_pressed = true
		_on_tab_button_pressed(0)

## Set tab to index of selected button.
func _on_tab_button_pressed(index : int) -> void:
	tab_container.set_current_tab(index)
