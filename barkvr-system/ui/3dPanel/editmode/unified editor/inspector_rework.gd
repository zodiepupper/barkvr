extends Control



@onready var tab_left: TabContainer = %TabLeft
@onready var tab_right: TabContainer = %TabRight

## The left side of the inspector, a scene inspector.
@onready var scene_inspector: Control = %SceneInspector



func _ready() -> void:
	scene_inspector.selection_changed.connect(_on_node_selection_changed)



## Called when a new node gets selected from the scene inspector.
func _on_node_selection_changed(new_selection : Node) -> void:
	# Prevent several attribute panels from loading at the same time.
	LocalGlobals.is_inspector_loading = false

	# Get all currently attached tabs.
	var target_tabs : Array[Node] = tab_left.get_children() + tab_right.get_children()

	# Set target on all possible tabs.
	for tab : Node in target_tabs:
		if tab.has_method(&"set_target"):
			tab.set_target(new_selection)

## Unfinished concept function.
func _setup_tab_container_popout() -> void:
	# TODO: Set up "close" icons for the tab buttons, use their signal to pop them out into their own windows.
	pass
