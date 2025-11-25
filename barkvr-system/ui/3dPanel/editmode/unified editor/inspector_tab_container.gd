extends TabContainer

## A boxcontainer to hold the buttons for the tabs.
@export var button_container : BoxContainer

## Button group used to have only one tab button pressed at a time.
var tab_button_group : ButtonGroup



func _ready() -> void:
	tab_button_group = ButtonGroup.new()

	setup_tab_buttons()

## Set up auto-generated tab buttons to navigate the tab container.
func setup_tab_buttons() -> void:
	if !button_container: return
	# Clear existing buttons out of the list.
	for button in button_container.get_children():
		button.queue_free()

	# Add each tab as a button.
	for tab : Control in get_children():
		var button : Button = Button.new()
		button.toggle_mode = true
		button.text = tab.name
		button.focus_mode = Control.FOCUS_NONE
		button.button_group = tab_button_group
		button_container.add_child(button)
		button.pressed.connect(_on_tab_button_pressed.bind(tab.get_index()))

	# Select the 0th button by default.
	if !tab_button_group.get_buttons().is_empty():
		tab_button_group.get_buttons()[0].button_pressed = true
		_on_tab_button_pressed(0)

## Set tab to index of selected button.
func _on_tab_button_pressed(index : int) -> void:
	set_current_tab(index)
