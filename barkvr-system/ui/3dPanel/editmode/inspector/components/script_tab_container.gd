class_name ScriptTabContainer
extends TabContainer
## A tab container used for the main content in the script editor.



## The GDScriptCodeEdit scene.
const GDSCRIPT_CODE_EDIT = preload("uid://cqsr3h08uq076")
## The GDScriptDocumentation scene.
const GDSCRIPT_DOCUMENTATION = preload("uid://bn8lqjy8e3pqr")



## Add a tab, input type can either be String or Node.
func add_tab(tab_target : Variant) -> Control:
	if not GDSCRIPT_CODE_EDIT or not GDSCRIPT_DOCUMENTATION: return

	var new_tab : Control

	if tab_target is Node:
		var code_edit : GDScriptCodeEdit = GDSCRIPT_CODE_EDIT.instantiate()

		code_edit.set_script_from_node(tab_target)
		new_tab = code_edit

	elif tab_target is String:
		# TODO: Actually send the documentation what it should be showing.
		var documentation_page : GDScriptDocumentation = GDSCRIPT_DOCUMENTATION.instantiate()

		new_tab = documentation_page
	else: return

	add_child(new_tab)
	set_current_tab(get_tab_count() - 1)
	return new_tab

## Check if a tab for target already exists, returns tab index. -1 if not found.
func check_for_tab(tab_target : Variant) -> int:
	if tab_target is Node:
		for index in get_tab_count():
			var tab : Control = get_tab_control(index)
			if tab is GDScriptCodeEdit:
				if tab_target == tab.node_target: return index

	elif tab_target is String:
		return -1 # TODO: Documentation search

	return -1

## Close the current tab.
func close_current_tab() -> void:
	var current_control : Control = get_current_tab_control()
	if not current_control: return

	current_control.queue_free()
