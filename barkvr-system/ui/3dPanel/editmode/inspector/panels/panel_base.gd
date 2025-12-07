class_name InspectorPanel
extends Control



## A theme containing all of Godot's default editor icons. From 4.6-dev5.
const GODOT_EDITOR_ICON_THEME = preload("uid://b34aw2colacks")

var target : Node



## Set the panel's current target.
func set_target(new_target : Node) -> void:
	target = new_target
	_on_target_set(new_target)

## Override class to be used to adjust panels on target change.
func _on_target_set(_new_target : Node) -> void:
	pass
