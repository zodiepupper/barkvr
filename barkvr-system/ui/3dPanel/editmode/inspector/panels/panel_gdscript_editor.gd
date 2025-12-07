extends InspectorPanel



const ScriptTemplate = preload("uid://cjfm48dxhjdhi")

var script_template_text : String

@onready var code_edit: CodeEdit = %CodeEdit



func _ready() -> void:
	code_edit.text_changed.connect(_on_code_edit_text_changed)

	script_template_text = ScriptTemplate.new().get_script().source_code



func _on_target_set(_new_target : Node) -> void:
	if not _new_target:
		code_edit.editable = false
		code_edit.focus_mode = Control.FOCUS_NONE
		return

	code_edit.editable = true
	code_edit.focus_mode = Control.FOCUS_ALL

	var script : Script = _new_target.get_script()
	if script and script.has_source_code():
		code_edit.text = script.source_code
	else:
		code_edit.text = (
				"extends " + str(target.get_class()) +
				"\n\n" +
				script_template_text)



func save_code() -> void:
	var new_script := GDScript.new()
	new_script.source_code = code_edit.text

	# Return on Error other than 0(OK).
	if new_script.reload(): return

	target.set_script(new_script)
	target.set_process(true)
	target.set_physics_process(true)



func _on_code_edit_text_changed() -> void:
	if not is_instance_valid(target): return

	save_code()
