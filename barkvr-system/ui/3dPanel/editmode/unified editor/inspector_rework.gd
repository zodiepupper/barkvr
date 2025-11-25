extends Control

## The left side of the inspector, a scene inspector.
@onready var scene_inspector: Control = %SceneInspector
## Container holding all the context-sensitive panels on the right side of the inspector.
@onready var tab_container: TabContainer = %TabContainer



func _ready() -> void:
	scene_inspector.selection_changed.connect(_on_node_selection_change)

## Called when a new node gets selected from the scene inspector.
func _on_node_selection_change(new_selection : Node) -> void:
	# Prevent several attribute panels from loading at the same time.
	LocalGlobals.is_inspector_loading = false

	# Set target on all tabs.
	for tab : Control in tab_container.get_children():
		if tab.has_method(&"set_target"):
			tab.set_target(new_selection)
