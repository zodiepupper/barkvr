extends Node
class_name SettingsSingleton

signal changed(name: StringName)

const PATH := "user://settings.json"

static var instance : SettingsSingleton

## toggles camera passthrough if it is supported by the current platform
var vr_passthrough: bool = false:
	set(value):
		vr_passthrough = value
		if XRServer.primary_interface and XRServer.primary_interface.is_passthrough_supported():
			if value:
				XRServer.primary_interface.start_passthrough()
			else:
				XRServer.primary_interface.stop_passthrough()
		save_and_emit(&"vr_passthrough")

## toggles hang tracking in code if supported by the current platform
var hand_tracking_enabled: bool = true:
	set(value):
		hand_tracking_enabled = value
		save_and_emit(&"hand_tracking_enabled")

## these 3 make the primary menu panel look at the local user on the specified axis
var ui_local_menu_lookat_x: bool:
	set(value):
		ui_local_menu_lookat_x = value
		save_and_emit(&"ui_local_menu_lookat_x")
var ui_local_menu_lookat_y: bool = true:
	set(value):
		ui_local_menu_lookat_y = value
		save_and_emit(&"ui_local_menu_lookat_y")
var ui_local_menu_lookat_z: bool = true:
	set(value):
		ui_local_menu_lookat_z = value
		save_and_emit(&"ui_local_menu_lookat_z")

## inspector fields update at a specific interval starting from their instantiation.
## this changes the interval length in seconds. 
var inspector_update_interval: float = .1:
	set(value):
		inspector_update_interval = value
		save_and_emit(&"inspector_update_interval")

## changes the size of the 3d notifications that appear on screen and in vr
var vr_notification_size: float = 40.0:
	set(value):
		vr_notification_size = value
		save_and_emit(&"vr_notification_size")

## changes the offset position of the 3d notifications
var vr_notification_offset: Vector2 = Vector2(.1,.9):
	set(value):
		vr_notification_offset = value
		save_and_emit(&"vr_notification_offset")
		
## changes the size of all ui elements
var interface_scaling_factor: float = 1.0:
	set(value):
		interface_scaling_factor = value
		get_window().content_scale_factor = value
		save_and_emit(&"interface_scaling_factor")
		
## the multiplier that is used for the speed held items should be scaled at
var grabbed_object_scale_factor: float = 1.1:
	set(value):
		grabbed_object_scale_factor = value
		save_and_emit(&"grabbed_object_scale_factor")
		
## sets whether chat messages should be sent with ctrl+enter as opposed
## to the default which is just by pressing enter
var send_messages_with_ctrl_enter: bool = false:
	set(value):
		send_messages_with_ctrl_enter = value
		save_and_emit(&"send_messages_with_ctrl_enter")
		
## sets the anti-aliasing mode
var anti_aliasing: int = 0:
	set(value):
		anti_aliasing = value
		get_window().msaa_3d = value as Viewport.MSAA
		save_and_emit(&"anti_aliasing")
		
## sets the screen space anti-aliasing mode
var screen_space_anti_aliasing: int = 0:
	set(value):
		screen_space_anti_aliasing = value
		get_window().screen_space_aa = value as Viewport.ScreenSpaceAA
		save_and_emit(&"screen_space_anti_aliasing")

## sets whether the primary viewport should render 3d or not
## [br]this is meant to be expanded, soon, into the UI only mode
## where barkvr acts as a normal GUI based client
var viewport_disable_3d : bool = false:
	set(value):
		viewport_disable_3d = value
		get_viewport().disable_3d = value
		save_and_emit(&"viewport_disable_3d")

## this changes the actual rendering resolution for the primary viewport
## can be used to save performance or increase visual quality
var viewport_scaling: float = 1.0:
	set(value):
		viewport_scaling = value
		get_window().scaling_3d_scale = value
		save_and_emit(&"viewport_scaling")

## toggles whether the inspector is a singleton (only one can exist)
## if `true` the buttons to spawn an inspector will instead summon your 
## last spawned inspector and spawns one if none exist. if `false`	
## the inspector buttons spawn a new inspector
var inspector_as_singleton: bool = false:
	set(value):
		inspector_as_singleton = value
		save_and_emit(&"inspector_as_singleton")

## this setting enables or disables the InteractionRay smoothing functionality
var laser_smoothing: bool = false:
	set(value):
		laser_smoothing = value
		save_and_emit(&"laser_smoothing")

var laser_smoothing_speed: float = .3:
	set(value):
		laser_smoothing_speed = value
		save_and_emit(&"laser_smoothing_speed")

## initialization dictionary which defines the schema of the settings file
## exists to reduce ambiguity in how the settings file is organized
const DEFAULT_VALUES := {
	vr_passthrough = false,
	hand_tracking_enabled = true,
	ui_local_menu_lookat_x = true,
	ui_local_menu_lookat_y = true,
	ui_local_menu_lookat_z = true,
	inspector_update_interval = 0.1,
	grabbed_object_scale_factor = 1.1,
	send_messages_with_ctrl_enter = false,
	anti_aliasing = 0.0, # float instead of int because typeof on a number from json is always a float, meaning the typeof comparison in reload would always be false if this were an int
	screen_space_anti_aliasing = RenderingServer.ViewportScreenSpaceAA.VIEWPORT_SCREEN_SPACE_AA_DISABLED,
	viewport_disable_3d = false,
	viewport_scaling = 1.0,
	interface_scaling_factor = 1.0,
	vr_notification_size = 40.0,
	vr_notification_offset = Vector2(.1,.9),
	inspector_as_singleton = false,
	laser_smoothing = false,
	laser_smoothing_speed = .3
}

var inspectors := []:
	set(val):
		inspectors = val
		for inspector in inspectors:
			if !is_instance_valid(inspector):
				inspectors.erase(inspector)

func _init() -> void:
	instance = self

func _ready() -> void:
	if FileAccess.file_exists(PATH):
		reload()
	else:
		for key in DEFAULT_VALUES:
			set(key, DEFAULT_VALUES[key])
		save()

func save_and_emit(key: StringName) -> void:
	changed.emit(key)
	save()

func reload() -> void:
	var json_file := FileAccess.open(PATH, FileAccess.READ)
	if FileAccess.get_open_error() != OK:
		printerr("failure to load settings.json")
		return
	
	var json_string := json_file.get_as_text()
	json_file.close()
	json_file = null
	var json_parsed = JSON.parse_string(json_string)
	if not json_parsed is Dictionary:
		printerr("failure to load settings.json, not valid json")
		return
	
	for key in DEFAULT_VALUES:
		if DEFAULT_VALUES[key] is Vector2:
			var tmp: String = json_parsed[key]
			tmp = tmp.lstrip("(")
			tmp = tmp.rstrip(")")
			json_parsed[key] = Vector2(float(tmp.split(",")[0]),float(tmp.split(",")[1]))
		set(key, json_parsed[key] if json_parsed.has(key) and typeof(json_parsed[key]) == typeof(DEFAULT_VALUES[key]) else DEFAULT_VALUES[key])

func save() -> void:
	var json_file := FileAccess.open(PATH, FileAccess.WRITE)
	if FileAccess.get_open_error() != OK:
		printerr("failure to save settings.json")
		return
	var dict_to_save := {}
	for key in DEFAULT_VALUES:
		dict_to_save[key] = get(key)
	json_file.store_string(JSON.stringify(dict_to_save))
	json_file.close()
