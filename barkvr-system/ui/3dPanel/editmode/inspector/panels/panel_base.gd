class_name InspectorPanel
extends PanelContainer



const SNACKBAR = preload("uid://bvimj4dikvkhg")

var target: Node
var snackbar_container: VBoxContainer



## Generate the snackbar_container and the needed styling to make it look alright.
func _enter_tree() -> void:
	snackbar_container = VBoxContainer.new()

	snackbar_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	snackbar_container.set_name("SnackbarContainer")

	var margin_container := MarginContainer.new()

	margin_container.size_flags_vertical = Control.SIZE_SHRINK_END
	margin_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin_container.theme_type_variation = &"SnackbarHolder"

	add_child(margin_container)

	margin_container.add_child(snackbar_container)



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
## This also seems less efficient than the previously used GodotTheme with the editor icons in it.
## TODO: Can cause large stutters during mass-calls, maybe the icons don't get cached in time?
func get_editor_icon(icon_name: StringName) -> Texture2D:
	var icon_path: String = "res://barkvr-system/assets/icons/editor-icons/"+icon_name+".svg"
	if ResourceLoader.exists(icon_path, "Texture2D"):
		return ResourceLoader.load(icon_path, "Texture2D")

	# Default to NodeWarning if the requested icon wasn't found.
	return ResourceLoader.load("res://barkvr-system/assets/icons/editor-icons/NodeWarning.svg", "Texture2D")



## Create a snackbar with the given data, time in seconds.
func snackbar_new(text: String, time: float = 3, icon: Texture2D = null) -> void:
	var snackbar: Snackbar = SNACKBAR.instantiate()
	snackbar.set_data(text, icon, time)
	snackbar_container.add_child(snackbar)

## Clear all snackbars from the list.
func snackbar_clear() -> void:
	for child: Control in snackbar_container.get_children():
		child.queue_free()
