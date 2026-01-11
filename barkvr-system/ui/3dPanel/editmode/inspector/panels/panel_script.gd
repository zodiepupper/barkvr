extends InspectorPanel



## A setting on whether the code should be saved on any text change in the CodeEdit.
var save_on_edit: bool = true
var sort_method_list_alphabetically: bool = false

## A menu bar used to display script and documentation related options.
## Buttons in the bar and their submenus adjust based on current context.
@onready var top_menu_bar: ScriptMenuBar = %TopMenuBar

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
@onready var sidebar_methods: VBoxContainer = %SidebarMethods
@onready var search_methods: LineEdit = %SearchMethods
@onready var button_sort_methods: Button = %ButtonSortMethods
@onready var list_methods: ItemList = %ListMethods

## The central TabContainer holding GDScriptCodeEdits and GDScriptDocumentations.
@onready var script_tab_container: ScriptTabContainer = %ScriptTabContainer

## A button to toggle the sidebar, uses an icon that changes based on sidebar state.
@onready var button_toggle_sidebar: Button = %ButtonToggleSidebar
## A container for all script-specific elements.
## These might actually be part of each ScriptTabContainer child in the original.
## However this results in the loss of the sidebar toggle when none are present.
@onready var bottom_elements_right: HBoxContainer = %BottomElementsRight
## A manual save button.
@onready var button_save: Button = %ButtonSave
## A toggle-able button to enable/disable auto saving.
@onready var button_auto_save: CheckBox = %ButtonAutoSave
## A label to display the current position of the caret.
@onready var label_caret_location: Label = %LabelCaretLocation
## A RichTextLabel used to inform the user of an uneditable script.
@onready var internal_class_warning_label: RichTextLabel = %InternalClassWarningLabel



func _ready() -> void:
	_setup_signals()

	# Ensure buttons are set correctly for the current context.
	_on_script_tab_container_tab_changed(0)

	# Sync toggle button with setting.
	button_auto_save.set_pressed_no_signal(save_on_edit)

## Set up all the signals needed for interactive components.
func _setup_signals() -> void:
	button_online_docs.pressed.connect(_on_button_online_docs_pressed)

	list_scripts.item_selected.connect(_on_script_list_item_selected)

	list_methods.item_selected.connect(_on_method_list_item_selected)
	button_sort_methods.toggled.connect(_on_button_sort_methods_toggled)

	button_toggle_sidebar.pressed.connect(_on_button_toggle_sidebar_pressed)
	button_save.pressed.connect(save_current_content)

	button_auto_save.toggled.connect(_on_button_auto_save_toggled)

	script_tab_container.child_order_changed.connect(update_script_list)
	script_tab_container.tab_changed.connect(_on_script_tab_container_tab_changed)

	# ScriptMenuBar signals.
	top_menu_bar.file_save.connect(save_current_content)
	top_menu_bar.file_save_all.connect(save_all_content)
	top_menu_bar.file_close.connect(script_tab_container.close_current_tab)
	top_menu_bar.file_close_all.connect(close_tabs_all)
	top_menu_bar.file_close_other.connect(close_tabs_other)
	top_menu_bar.file_close_below.connect(close_tabs_below)
	top_menu_bar.file_toggle_side_panel.connect(_on_button_toggle_sidebar_pressed)



## Override function from the InspectorPanel class.
func _on_target_set(new_target: Node) -> void:
	if not new_target: return

	var tab_index: int = script_tab_container.check_for_tab(new_target)

	# Open existing tab if it already exists.
	if tab_index != -1:
		script_tab_container.set_current_tab(tab_index)

	# Make a new tab.
	else:
		var new_tab: Control = script_tab_container.add_tab(new_target)
		if new_tab is GDScriptCodeEdit:
			# Connect signals.
			new_tab.caret_changed.connect(_on_code_edit_caret_changed)
			new_tab.script_data_updated.connect(update_method_list)
			new_tab.script_name_updated.connect(update_script_name)
			new_tab.request_save_confirm.connect(_on_code_edit_request_save_confirm)

		elif new_tab is GDScriptDocumentation:
			pass # TODO: This here.



## Update the current script name in all places.
func update_script_name() -> void:
	var current_tab: Control = script_tab_container.get_current_tab_control()

	if current_tab is GDScriptCodeEdit:
		label_script_name.text = current_tab.get_script_name_unsaved()
	update_script_list()

## Used to display pseudo tab buttons in the script list.
func update_script_list() -> void:
	list_scripts.clear()

	# Generate a button for each tab in the switcher.
	for i: int in script_tab_container.get_tab_count():
		# Defaults.
		var icon_name := &"NodeWarning"
		var tab_name := "ERROR"

		var tab: Control = script_tab_container.get_tab_control(i)

		if tab is GDScriptCodeEdit:
			# Only internal/classless files are editable.
			icon_name = &"GDScriptInternal" if tab.editable else &"GDScript"
			tab_name = tab.get_script_name_unsaved()
		elif tab is GDScriptDocumentation:
			icon_name = &"Help"
			# TODO: Doc stuff.
			#tab_name = "Placeholder"

		list_scripts.add_item(tab_name, get_editor_icon(icon_name))

	if list_scripts.item_count > 0:
		list_scripts.select(script_tab_container.current_tab)

## Update the list of methods in the bottom of the sidebar.
func update_method_list() -> void:
	list_methods.clear()

	var current_tab: Control = script_tab_container.get_current_tab_control()

	# Generate a list of all methods in the current script to jump to.
	if current_tab is GDScriptCodeEdit:
		var script_method_list: Array[Dictionary]
		script_method_list = current_tab.get_script_method_list()

		for method: Dictionary in script_method_list:
			list_methods.add_item(method.name)

	# Generate a list of every category in the doc to jump to.
	elif current_tab is GDScriptDocumentation:
		return # TODO: This right here.

	# Sort method list if sorting is enabled and possible(button visible).
	if sort_method_list_alphabetically && button_sort_methods.visible:
		list_methods.sort_items_by_text()

## Save the content of the current tab.
func save_current_content() -> void:
	var current_tab: Control = script_tab_container.get_current_tab_control()

	if current_tab is GDScriptCodeEdit:
		current_tab.save_code()

## Save the content of all currently opened tabs.
func save_all_content() -> void:
	for index: int in script_tab_container.get_tab_count():
		var index_control: Control = script_tab_container.get_tab_control(index)

		if index_control is GDScriptCodeEdit:
			index_control.save_code()

## Close all currently opened tabs.
## This could be improved by making "close tab" a function on each tab,
## maybe with a confirm popup of some sorts.
func close_tabs_all() -> void:
	for index: int in script_tab_container.get_tab_count():
		script_tab_container.get_tab_control(index).queue_free()

## Close all tabs other than the currently selected one.
func close_tabs_other() -> void:
	var current_index: int = script_tab_container.current_tab
	for index: int in script_tab_container.get_tab_count():
		if index == current_index: continue
		script_tab_container.get_tab_control(index).queue_free()

## Close all tabs below the currently focused one.
func close_tabs_below() -> void:
	var current_index_offset: int = script_tab_container.current_tab + 1
	for index: int in script_tab_container.get_tab_count() - current_index_offset:
		script_tab_container.get_tab_control(index + current_index_offset).queue_free()



## Called when the active tab in the tab container changes.
## Updates context-based buttons.
func _on_script_tab_container_tab_changed(index: int) -> void:
	var current_tab: Control = script_tab_container.get_tab_control(index)
	var is_type_code_edit: bool = current_tab is GDScriptCodeEdit
	var is_type_documentation: bool = current_tab is GDScriptDocumentation

	# Prevent OOB errors if there is no tab for the current index.
	if current_tab and list_scripts.item_count > 0: list_scripts.select(index)

	# Disable menu bar options that are exclusive to CodeEdit.
	# Disabled due to the respective options being disabled by default already.
	#top_menu_bar.set_menu_hidden(1, not is_type_code_edit)
	#top_menu_bar.set_menu_hidden(3, not is_type_code_edit)

	# Show method search & sorting only if type is CodeEdit.
	button_sort_methods.get_parent_control().set_visible(is_type_code_edit)
	# Hide method list if neither type fits.
	sidebar_methods.set_visible(is_type_code_edit or is_type_documentation)

	# Disable script-sensitive items in the bottom bar.
	# In the actual engine it seems like these items are part of the tabswitcher.
	# That's the cause for the sidebar not having a toggle button,
	# when nothing is selected in the editor.
	bottom_elements_right.set_visible(is_type_code_edit)

	# Reset non-editable warning label.
	internal_class_warning_label.set_visible(false)

	# Change current name at the top of the script editor.
	if current_tab is GDScriptCodeEdit:
		label_script_name.text = current_tab.get_script_name_unsaved()
		# Make warning label visible if the current tab is non-editable.
		internal_class_warning_label.set_visible(not current_tab.editable)
	elif current_tab is GDScriptDocumentation:
		pass # TODO: This right here.
	else:
		label_script_name.text = ""

	update_method_list()

## Called when the CodeEdit's caret moves.
func _on_code_edit_caret_changed() -> void:
	var current_tab: Control = script_tab_container.get_current_tab_control()

	if current_tab is GDScriptCodeEdit:
		var caret_position: Vector2i = current_tab.get_caret_position()
		label_caret_location.text = "%4d:%4d" % [caret_position.x, caret_position.y]

## Called by the currently active code edit to confirm saving when using auto-save.
func _on_code_edit_request_save_confirm() -> void:
	if not save_on_edit: return
	save_current_content()

## Opens the online Godot documentation for the current engine version.
func _on_button_online_docs_pressed() -> void:
	var version_info: Dictionary = Engine.get_version_info()
	OS.shell_open("https://docs.godotengine.org/en/%s.%s/" % [version_info.major, version_info.minor])

## Toggles the sidebar and changes the button's icon to reflect sidebar state.
func _on_button_toggle_sidebar_pressed() -> void:
	sidebar.visible = !sidebar.visible
	if sidebar.visible:
		button_toggle_sidebar.set_button_icon(get_editor_icon(&"Back"))
	else:
		button_toggle_sidebar.set_button_icon(get_editor_icon(&"Forward"))

## Toggle auto saving.
func _on_button_auto_save_toggled(toggled_on: bool) -> void:
	save_on_edit = toggled_on
	if toggled_on: save_current_content()

## Pseudo tab buttons to navigate the central tab switcher.
func _on_script_list_item_selected(index: int) -> void:
	script_tab_container.set_current_tab(index)

## Move to selected method, called when a method item is clicked in the list.
func _on_method_list_item_selected(index: int) -> void:
	var current_tab: Control = script_tab_container.get_current_tab_control()
	var target_method: String = list_methods.get_item_text(index)

	if current_tab is GDScriptCodeEdit:
		current_tab.jump_to_method(target_method)

## Toggle sorting of the method list, actual sorting happens with the list update.
func _on_button_sort_methods_toggled(toggled_on: bool) -> void:
	sort_method_list_alphabetically = toggled_on
	update_method_list()
