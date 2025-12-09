extends InspectorPanel



const ScriptTemplate = preload("uid://cjfm48dxhjdhi")

var script_template_text : String

var save_on_edit : bool = false # TODO: True by default, false for testing.

@onready var label_script_name: Label = %LabelScriptName

@onready var button_online_docs: Button = %ButtonOnlineDocs
@onready var button_search_help: Button = %ButtonSearchHelp
@onready var button_history_previous: Button = %ButtonHistoryPrevious
@onready var button_history_next: Button = %ButtonHistoryNext

@onready var sidebar: VSplitContainer = %Sidebar
@onready var search_scripts: LineEdit = %SearchScripts
@onready var list_scripts: ItemList = %ListScripts
@onready var search_methods: LineEdit = %SearchMethods
@onready var button_sort_methods: Button = %ButtonSortMethods
@onready var list_methods: ItemList = %ListMethods

@onready var code_edit: CodeEdit = %CodeEdit

@onready var button_toggle_sidebar: Button = %ButtonToggleSidebar
@onready var button_save: Button = %ButtonSave


func _ready() -> void:
	code_edit.text_changed.connect(_on_code_edit_text_changed)

	script_template_text = ScriptTemplate.new().get_script().source_code

	_setup_icons()

	button_online_docs.pressed.connect(_on_button_online_docs_pressed)

	button_toggle_sidebar.pressed.connect(_on_button_toggle_sidebar_pressed)
	button_save.pressed.connect(save_code)

func _setup_icons() -> void:
	button_history_previous.set_button_icon(GODOT_EDITOR_ICON_THEME.get_icon(&"Back", &"EditorIcons"))
	button_history_next.set_button_icon(GODOT_EDITOR_ICON_THEME.get_icon(&"Forward", &"EditorIcons"))

	button_online_docs.set_button_icon(GODOT_EDITOR_ICON_THEME.get_icon(&"ExternalLink", &"EditorIcons"))
	button_search_help.set_button_icon(GODOT_EDITOR_ICON_THEME.get_icon(&"HelpSearch", &"EditorIcons"))

	search_scripts.set_right_icon(GODOT_EDITOR_ICON_THEME.get_icon(&"Search", &"EditorIcons"))
	search_methods.set_right_icon(GODOT_EDITOR_ICON_THEME.get_icon(&"Search", &"EditorIcons"))
	button_sort_methods.set_button_icon(GODOT_EDITOR_ICON_THEME.get_icon(&"Sort", &"EditorIcons"))

	button_toggle_sidebar.set_button_icon(GODOT_EDITOR_ICON_THEME.get_icon(&"Back", &"EditorIcons"))

	button_save.set_button_icon(GODOT_EDITOR_ICON_THEME.get_icon(&"Save", &"EditorIcons"))



# Override function from the InspectorPanel class.
func _on_target_set(new_target : Node) -> void:
	if not new_target:
		code_edit.editable = false
		code_edit.focus_mode = Control.FOCUS_NONE
		return

	code_edit.editable = true
	code_edit.focus_mode = Control.FOCUS_ALL

	var target_script : Script = new_target.get_script()
	var target_class : String = new_target.get_class()

	if target_script and target_script.has_source_code():
		code_edit.text = target_script.source_code

		var script_name : String = target_script.get_global_name()
		if script_name.is_empty():
			label_script_name.text = target_class.to_snake_case() + ".script.gd"
		else:
			label_script_name.text = script_name.to_snake_case() + ".gd"

	else:
		code_edit.text = (
				"extends " + target_class +
				"\n\n" +
				script_template_text)

		label_script_name.text = target_class.to_snake_case() + ".script.gd(*)"



func save_code() -> void:
	if not is_instance_valid(target): return

	var new_script := GDScript.new()
	new_script.source_code = code_edit.text

	# Return on Error other than 0(OK).
	if new_script.reload(): return

	target.set_script(new_script)
	target.set_process(true)
	target.set_physics_process(true)

	if label_script_name.text.ends_with("(*)"):
		label_script_name.text = label_script_name.text.left(-3)



func _on_button_online_docs_pressed() -> void:
	var version_info : Dictionary = Engine.get_version_info()
	OS.shell_open("https://docs.godotengine.org/en/%s.%s/" % [version_info.major, version_info.minor])

func _on_button_toggle_sidebar_pressed() -> void:
	sidebar.visible = !sidebar.visible
	if sidebar.visible:
		button_toggle_sidebar.set_button_icon(GODOT_EDITOR_ICON_THEME.get_icon(&"Back", &"EditorIcons"))
	else:
		button_toggle_sidebar.set_button_icon(GODOT_EDITOR_ICON_THEME.get_icon(&"Forward", &"EditorIcons"))

func _on_code_edit_text_changed() -> void:
	if not label_script_name.text.ends_with("(*)"):
		label_script_name.text += "(*)"

	if save_on_edit: save_code()
