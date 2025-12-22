class_name GDScriptCodeEdit
extends CodeEdit
## A custom CodeEdit meant for editing GDScript in the inspector's code panel.



signal script_name_updated()
signal script_data_updated()
signal request_save_confirm()

const GDSCRIPT_HIGHLIGHTER: CodeHighlighter = preload("uid://dgk2x876348oy")

## The name of the currently selected script.
var script_name: String:
	set(value):
		script_name = value
		script_name_updated.emit()
## A copy of the currently saved script, used for the method list.
var script_data: GDScript

var has_unsaved_changes: bool = false:
	set(value):
		has_unsaved_changes = value
		script_name_updated.emit()
var typing_stopped_timer: SceneTreeTimer

## The node this script belongs to, used as a semi-temporary means to connect scripts.
## Preferrably scripts should be just a script and have some connection system instead.
var node_target: Node



func _ready() -> void:
	# This is done to ensure that the CodeHighlighter is unique.
	# Using the same highlighter multiple times causes issues.
	syntax_highlighter = GDSCRIPT_HIGHLIGHTER.duplicate()

	text_changed.connect(_on_text_changed)



## Sets the script in the CodeEdit from a target node.
## Generates a new template script if node doesn't have one.
func set_script_from_node(target: Node) -> void:
	if not target: return

	node_target = target

	var target_script: Script = target.get_script()
	var target_class: String = target.get_class()

	# If target already has a script get it and show it.
	if target_script and target_script.has_source_code():
		text = target_script.source_code

		# Assign current script name based on global name, alternatively on class name.
		var global_script_name: String = target_script.get_global_name()
		if not global_script_name.is_empty():
			script_name = global_script_name.to_snake_case()
			# Global script names can "try" to override already existing ones.
			# This crashes the game in editor builds.
			# This causes saves to fail without notifying the user in export builds.
			editable = false
		else:
			script_name = target_class.to_snake_case() + ".script"
		update_script_data(target_script)

	# In case there is no script present get the template and extend from current.
	else:
		# Load script template file and get store its source code.
		var script_template_text: String = load("uid://cjfm48dxhjdhi").new().get_script().source_code
		# Dynamically add class to the script file and set as text.
		text = (
				"extends " + target_class +
				"\n\n" +
				script_template_text)

		script_name = target_class.to_snake_case() + ".script"
		has_unsaved_changes = true
		update_script_data()

## Update the current script data, reloads text into a script if none is provided.
## Crashes the game in editor builds with the reload function, if code is invalid.
func update_script_data(script: GDScript = null) -> GDScript:
	# Only reload editable scripts.
	if not script and editable:
		script = GDScript.new()
		script.source_code = text

		# Return on Error other than 0(OK).
		if script.reload(): return

	script_data = script
	script_data_updated.emit()
	return script

## Returns the script name with "(*)" appended if there are unsaved changes.
func get_script_name_unsaved() -> String:
	if has_unsaved_changes:
		return script_name + ".gd(*)"
	else:
		return script_name + ".gd"

## Get a list of all methods that are actually present in the script.
func get_script_method_list() -> Array[Dictionary]:
	if not script_data: return []
	var method_list: Array[Dictionary] = script_data.get_script_method_list()

	# Discard methods that are in-built or inherited.
	var filtered_method_list = method_list.filter(
			func(method): return search("func " + method.name + "(", 0, 0, 0).y != -1)

	return filtered_method_list



## Save the code currently in text.
func save_code() -> void:
	if not is_instance_valid(node_target): return
	if not editable: return

	update_script_data()

	# Update/Set script on target.
	node_target.set_script(script_data)
	# Ensure process and physics_process are running.
	node_target.set_process(true)
	node_target.set_physics_process(true)

	has_unsaved_changes = false

## Set the caret to the line that the given method is in.
func jump_to_method(method: String) -> void:
	var method_line: int = search("func " + method + "(", 0, 0, 0).y
	# Despite what the 4.5 documentation might suggest, "adjust_viewport" does not actually center.
	# As such, it has been disabled and center_viewport_to_caret is being used instead.
	set_caret_line(method_line, false)
	center_viewport_to_caret()



## Called when the text has been changed in any way.
func _on_text_changed() -> void:
	# Update unsaved status.
	if !has_unsaved_changes: has_unsaved_changes = true

	# Clear timeout to reset.
	if typing_stopped_timer:
		typing_stopped_timer.timeout.disconnect(_on_text_changed_timeout)
	# Create timer to request saving on timeout.
	typing_stopped_timer = get_tree().create_timer(1.2)
	typing_stopped_timer.timeout.connect(_on_text_changed_timeout)

## A timeout from text_changed to prevent saving on every tiny change.
func _on_text_changed_timeout() -> void:
	typing_stopped_timer = null
	request_save_confirm.emit()

## Returns the current caret position as a Vector2i.
## X: Line, Y: Column
func get_caret_position() -> Vector2i:
	var caret_position := Vector2i(
			get_caret_line(),
			get_caret_column())
	return caret_position
