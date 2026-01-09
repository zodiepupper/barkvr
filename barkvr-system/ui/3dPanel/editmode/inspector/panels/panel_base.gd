class_name InspectorPanel
extends Control



var target: Node



## Set the panel's current target.
func set_target(new_target: Node) -> void:
	target = new_target
	_on_target_set(new_target)

## Override class to be used to adjust panels on target change.
func _on_target_set(_new_target: Node) -> void:
	pass

## Returns the basic editor icon under the given icon_name.
## Returns NodeWarning icon instead if no icon exists under that name.
## This could be expanded to also do custom icons eventually.
func get_editor_icon(icon_name: StringName) -> Texture2D:
	var icon_path: String = "res://barkvr-system/assets/icons/editor-icons/"+icon_name+".svg"
	if ResourceLoader.exists(icon_path, "Texture2D"):
		return ResourceLoader.load(icon_path, "Texture2D")

	return ResourceLoader.load("res://barkvr-system/assets/icons/editor-icons/NodeWarning.svg", "Texture2D")
