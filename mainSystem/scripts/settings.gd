extends Node
class_name SettingsSingleton

signal changed(name: StringName)

const PATH := "user://config.json"

var vr_passthrough: bool:
	set(value):
		vr_passthrough = value
		if XRServer.primary_interface and XRServer.primary_interface.is_passthrough_supported():
			if value:
				XRServer.primary_interface.start_passthrough()
			else:
				XRServer.primary_interface.stop_passthrough()
		save_and_emit(&"vr_passthrough", value)
var hand_tracking_enabled: bool:
	set(value):
		hand_tracking_enabled = value
		save_and_emit(&"hand_tracking_enabled", value)
var ui_local_menu_lookat_x: bool:
	set(value):
		ui_local_menu_lookat_x = value
		save_and_emit(&"ui_local_menu_lookat_x", value)
var ui_local_menu_lookat_y: bool:
	set(value):
		ui_local_menu_lookat_y = value
		save_and_emit(&"ui_local_menu_lookat_y", value)
var ui_local_menu_lookat_z: bool:
	set(value):
		ui_local_menu_lookat_z = value
		save_and_emit(&"ui_local_menu_lookat_z", value)
## inspector fields update at a specific interval starting from their instantiation.
## this changes the interval length in seconds. 
var inspector_update_interval: float:
	set(value):
		inspector_update_interval = value
		save_and_emit(&"inspector_update_interval", value)
## the multiplier that is used for the speed held items should be scaled at
var grabbed_object_scale_factor: float:
	set(value):
		grabbed_object_scale_factor = value
		save_and_emit(&"grabbed_object_scale_factor", value)
## sets whether chat messages should be sent with ctrl+enter as opposed
## to the default which is just by pressing enter
var send_messages_with_ctrl_enter: bool:
	set(value):
		send_messages_with_ctrl_enter = value
		save_and_emit(&"send_messages_with_ctrl_enter", value)
var viewport_scaling: float:
	set(value):
		viewport_scaling = value
		get_window().get_viewport().scaling_3d_scale = value
		save_and_emit(&"viewport_scaling", value)

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

func save_and_emit(key: StringName, value: Variant) -> void:
	changed.emit(key)
	save()

func reload() -> void:
	var json_file := FileAccess.open(PATH, FileAccess.READ)
	if FileAccess.get_open_error() != OK:
		printerr("failure to load config.json")
		return
	
	var json_string := json_file.get_as_text()
	json_file.close()
	json_file = null
	var json_parsed = JSON.parse_string(json_string)
	if not json_parsed is Dictionary:
		printerr("failure to load config.json, not valid json")
		return
	var json_dict := json_parsed as Dictionary
	
	for key in DEFAULT_VALUES:
		set(key, json_dict[key] if json_dict.has(key) and typeof(json_dict[key]) == typeof(DEFAULT_VALUES[key]) else DEFAULT_VALUES[key])

func save() -> void:
	var json_file := FileAccess.open(PATH, FileAccess.WRITE)
	if FileAccess.get_open_error() != OK:
		printerr("failure to save config.json")
		return
	var dict_to_save := {}
	for key in DEFAULT_VALUES:
		dict_to_save[key] = get(key)
	json_file.store_string(JSON.stringify(dict_to_save))
	json_file.close()
