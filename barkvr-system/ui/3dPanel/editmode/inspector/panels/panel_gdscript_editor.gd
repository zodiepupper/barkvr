extends InspectorPanel



## A GDScript template used to fill out the CodeEdit when no script is present.
const ScriptTemplate = preload("uid://cjfm48dxhjdhi")

## The ScriptTemplate as a String.
## "extends" is missing due to it being auto-generated upon selection.
var script_template_text : String

## A setting on whether the code should be saved on any text change in the CodeEdit.
var save_on_edit : bool = false # TODO: True by default, false for testing.

var sort_method_list_alphabetically : bool = false

## The name of the currently selected script.
## Suffixed with "(*)" when the script has unsaved changes.
var current_script_name : String:
	set(new_name):
		current_script_name = new_name
		label_script_name.text = new_name

## A label to show the current script name.
@onready var label_script_name: Label = %LabelScriptName

## TopBar buttons.
@onready var button_online_docs: Button = %ButtonOnlineDocs
@onready var button_search_help: Button = %ButtonSearchHelp
@onready var button_history_previous: Button = %ButtonHistoryPrevious
@onready var button_history_next: Button = %ButtonHistoryNext

## Toggle-able sidebar content.
@onready var sidebar: VSplitContainer = %Sidebar
@onready var search_scripts: LineEdit = %SearchScripts
@onready var list_scripts: ItemList = %ListScripts
@onready var search_methods: LineEdit = %SearchMethods
@onready var button_sort_methods: Button = %ButtonSortMethods
@onready var list_methods: ItemList = %ListMethods

## The central CodeEdit.
@onready var code_edit: CodeEdit = %CodeEdit

## A button to toggle the sidebar, uses an icon that changes based on sidebar state.
@onready var button_toggle_sidebar: Button = %ButtonToggleSidebar
## A manual save button.
@onready var button_save: Button = %ButtonSave
## A toggle-able button to enable/disable auto saving.
@onready var button_auto_save: CheckBox = %ButtonAutoSave
@onready var label_caret_location: Label = %LabelCaretLocation



func _ready() -> void:
	# Load script template text from file.
	script_template_text = ScriptTemplate.new().get_script().source_code

	_setup_icons()

	# Signal setup.
	code_edit.text_changed.connect(_on_code_edit_text_changed)
	code_edit.caret_changed.connect(_on_code_edit_caret_changed)

	button_online_docs.pressed.connect(_on_button_online_docs_pressed)

	list_methods.item_selected.connect(_on_method_list_item_selected)
	button_sort_methods.toggled.connect(_on_button_sort_methods_toggled)

	button_toggle_sidebar.pressed.connect(_on_button_toggle_sidebar_pressed)
	button_save.pressed.connect(save_code)

	button_auto_save.toggled.connect(_on_button_auto_save_toggled)
	button_auto_save.set_pressed_no_signal(save_on_edit)

## Set up dynamic icons loaded from the editor theme.
func _setup_icons() -> void:
	button_online_docs.set_button_icon(get_editor_icon(&"ExternalLink"))
	button_search_help.set_button_icon(get_editor_icon(&"HelpSearch"))
	button_history_previous.set_button_icon(get_editor_icon(&"Back"))
	button_history_next.set_button_icon(get_editor_icon(&"Forward"))

	search_scripts.set_right_icon(get_editor_icon(&"Search"))
	search_methods.set_right_icon(get_editor_icon(&"Search"))
	button_sort_methods.set_button_icon(get_editor_icon(&"Sort"))

	button_toggle_sidebar.set_button_icon(get_editor_icon(&"Back"))

	button_save.set_button_icon(get_editor_icon(&"Save"))



## Override function from the InspectorPanel class.
func _on_target_set(new_target : Node) -> void:
	# Change editable & focus depending on target state.
	if not new_target:
		code_edit.editable = false
		code_edit.focus_mode = Control.FOCUS_NONE
		return
	else:
		code_edit.editable = true
		code_edit.focus_mode = Control.FOCUS_ALL

	var target_script : Script = new_target.get_script()
	var target_class : String = new_target.get_class()

	# If target already has a script get it and show it.
	if target_script and target_script.has_source_code():
		code_edit.text = target_script.source_code

		# Assign current script name based on global name, alternatively on class name.
		var script_name : String = target_script.get_global_name()
		if not script_name.is_empty():
			current_script_name = script_name.to_snake_case() + ".gd"
		else:
			current_script_name = target_class.to_snake_case() + ".script.gd"

	# In case there is no script present get the template and extend from current.
	else:
		code_edit.text = (
				"extends " + target_class +
				"\n\n" +
				script_template_text)

		current_script_name = target_class.to_snake_case() + ".script.gd(*)"

	update_method_list()



## Save the code currently in the CodeEdit.
## Crashes the game in "Editor" builds with the reload function, if code is invalid.
func save_code() -> void:
	if not is_instance_valid(target): return

	var new_script := GDScript.new()
	new_script.source_code = code_edit.text

	# Return on Error other than 0(OK).
	if new_script.reload(): return

	# Update/Set script on target.
	target.set_script(new_script)
	# Ensure process and physics_process are running.
	target.set_process(true)
	target.set_physics_process(true)

	# Remove "unsaved changes" marker, if present.
	if current_script_name.ends_with("(*)"):
		current_script_name = current_script_name.left(-3)

	# TODO: Might move this and auto-saving on a timer, to reduce repeat calls.
	update_method_list()

func update_method_list() -> void:
	list_methods.clear()

	var script := GDScript.new()
	script.source_code = code_edit.text

	# Return on Error other than 0(OK).
	if script.reload(): return

	for method : Dictionary in script.get_script_method_list():
		list_methods.add_item(method.name)

	if sort_method_list_alphabetically:
		list_methods.sort_items_by_text()



## Called whenever edits are being made inside the CodeEdit.
func _on_code_edit_text_changed() -> void:
	# Append "unsaved changes" marker.
	if not current_script_name.ends_with("(*)"):
		current_script_name += "(*)"

	# Save if autosave is turned on.
	if save_on_edit: save_code()

## Called when the CodeEdit's caret moves.
func _on_code_edit_caret_changed() -> void:
	var new_text : String = "%4d:%4d" % [code_edit.get_caret_line(), code_edit.get_caret_column()]
	label_caret_location.text = new_text

## Opens the online Godot documentation for the current engine version.
func _on_button_online_docs_pressed() -> void:
	var version_info : Dictionary = Engine.get_version_info()
	OS.shell_open("https://docs.godotengine.org/en/%s.%s/" % [version_info.major, version_info.minor])

## Toggles the sidebar and changes the button's icon to reflect sidebar state.
func _on_button_toggle_sidebar_pressed() -> void:
	sidebar.visible = !sidebar.visible
	if sidebar.visible:
		button_toggle_sidebar.set_button_icon(get_editor_icon(&"Back"))
	else:
		button_toggle_sidebar.set_button_icon(get_editor_icon(&"Forward"))

## Toggle auto saving.
func _on_button_auto_save_toggled(toggled_on : bool) -> void:
	save_on_edit = toggled_on

## Move to selected method, called when a method item is clicked in the list.
func _on_method_list_item_selected(index : int) -> void:
	var target_function : String = list_methods.get_item_text(index)
	var result_line : int = code_edit.search(target_function + "(", 0, 0, 0).y
	code_edit.set_caret_line(result_line)

## Toggle sorting of the method list.
func _on_button_sort_methods_toggled(toggled_on : bool) -> void:
	sort_method_list_alphabetically = toggled_on
	update_method_list()
