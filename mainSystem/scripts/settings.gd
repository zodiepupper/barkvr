extends Node
class_name SettingsSingleton

signal changed(name: StringName)

const PATH := "user://config.ini"
const SECTION := "BarkVR"
var file := ConfigFile.new()

var vr_passthrough: bool:
	set(value):
		vr_passthrough = value
		if XRServer.primary_interface and XRServer.primary_interface.is_passthrough_supported():
			if value:
				XRServer.primary_interface.start_passthrough()
			else:
				XRServer.primary_interface.stop_passthrough()
		set_and_emit(&"vr_passthrough", value)
var hand_tracking_enabled: bool:
	set(value):
		hand_tracking_enabled = value
		set_and_emit(&"hand_tracking_enabled", value)
var ui_local_menu_lookat_x: bool:
	set(value):
		ui_local_menu_lookat_x = value
		set_and_emit(&"ui_local_menu_lookat_x", value)
var ui_local_menu_lookat_y: bool:
	set(value):
		ui_local_menu_lookat_y = value
		set_and_emit(&"ui_local_menu_lookat_y", value)
var ui_local_menu_lookat_z: bool:
	set(value):
		ui_local_menu_lookat_z = value
		set_and_emit(&"ui_local_menu_lookat_z", value)
## inspector fields update at a specific interval starting from their instantiation.
## this changes the interval length in seconds. 
var inspector_update_interval: float:
	set(value):
		inspector_update_interval = value
		set_and_emit(&"inspector_update_interval", value)
## the multiplier that is used for the speed held items should be scaled at
var grabbed_object_scale_factor: float:
	set(value):
		grabbed_object_scale_factor = value
		set_and_emit(&"grabbed_object_scale_factor", value)
## sets whether chat messages should be sent with ctrl+enter as opposed
## to the default which is just by pressing enter
var send_messages_with_ctrl_enter: bool:
	set(value):
		send_messages_with_ctrl_enter = value
		set_and_emit(&"send_messages_with_ctrl_enter", value)
var viewport_scaling: float:
	set(value):
		viewport_scaling = value
		get_window().get_viewport().scaling_3d_scale = value
		set_and_emit(&"viewport_scaling", value)

const DEFAULT_VALUES := {
	vr_passthrough = false,
	hand_tracking_enabled = true,
	ui_local_menu_lookat_x = true,
	ui_local_menu_lookat_y = true,
	ui_local_menu_lookat_z = true,
	inspector_update_interval = 0.1,
	grabbed_object_scale_factor = 1.1,
	send_messages_with_ctrl_enter = false,
	viewport_scaling = 1.0
}

func _ready() -> void:
	if FileAccess.file_exists(PATH):
		reload()
	else:
		for key in DEFAULT_VALUES:
			set(key, DEFAULT_VALUES[key])
		save()

func cast_or_default(key: String, to_type: int = -1) -> Variant:
	var default = DEFAULT_VALUES[key] if key in DEFAULT_VALUES else null
	return convert(file.get_value(SECTION, key, default), typeof(default) if to_type < 0 else to_type)

func set_and_emit(key: StringName, value: Variant) -> void:
	file.set_value(SECTION, String(key), value)
	changed.emit(key)
	save()

func reload() -> void:
	var file_error := file.load(PATH)
	if file_error != OK:
		printerr("failure to load config")
		return
	
	for key in DEFAULT_VALUES:
		set(key, cast_or_default(key))

func save() -> void:
	var error := file.save(PATH)
	if error != OK:
		printerr("failure to save config")
