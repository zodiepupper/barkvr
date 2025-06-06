extends Node

var editor_refs : Dictionary = {}
var interface : XRInterface
var webxr_interface
var vr_supported = false

var local_uis:Array = []

var keyboard:StaticBody3D

var discord_world = 'loading'
var discord_login_status = 'not logged in'

var VRMC_node_constraint = load("res://addons/vrm/1.0/VRMC_node_constraint.gd")
var VRMC_node_constraint_inst = VRMC_node_constraint.new()
var VRMC_springBone = load("res://addons/vrm/1.0/VRMC_springBone.gd")
var VRMC_springBone_inst = VRMC_springBone.new()
var VRMC_materials_mtoon = load("res://addons/vrm/1.0/VRMC_materials_mtoon.gd")
var VRMC_materials_mtoon_inst = VRMC_materials_mtoon.new()
var VRMC_materials_hdr_emissiveMultiplier = load("res://addons/vrm/1.0/VRMC_materials_hdr_emissiveMultiplier.gd")
var VRMC_materials_hdr_emissiveMultiplier_inst = VRMC_materials_hdr_emissiveMultiplier.new()
var VRMC_vrm = load("res://addons/vrm/1.0/VRMC_vrm.gd")
var VRMC_vrm_inst = VRMC_vrm.new()
var VRMC_vrm_animation = load("res://addons/vrm/1.0/VRMC_vrm_animation.gd")
var VRMC_vrm_animation_inst = VRMC_vrm_animation.new()

signal player_state_changed(state:int)

@export_enum("PAUSED", "PLAYING", "TYPING") var player_state : int = 0:
	set(value):
		player_state = value
		player_state_changed.emit(value)
const PLAYER_STATE_PAUSED := 0
const PLAYER_STATE_PLAYING:= 1
const PLAYER_STATE_TYPING := 2

@export_enum("EDITING", "PLAYING", "VIEWING", "SELECTING") var world_state : int = 0
const WORLD_STATE_EDITING := 0
const WORLD_STATE_PLAYING := 1
const WORLD_STATE_VIEWING := 2
const WORLD_STATE_SELECTING := 3

var voice_analyzer :AudioEffectSpectrumAnalyzerInstance:
	get:
		if !is_instance_valid(voice_analyzer):
			for effect_index in AudioServer.get_bus_effect_count(AudioServer.get_bus_index("mic")):
				var ceffect := AudioServer.get_bus_effect(AudioServer.get_bus_index("mic"),effect_index)
				if ceffect.resource_name == "voiceanalyzer":
					voice_analyzer = AudioServer.get_bus_effect_instance(AudioServer.get_bus_index("mic"),effect_index)
		return voice_analyzer

var voice_capture :GDOpusEncoder:
	get:
		if !is_instance_valid(voice_capture):
			for effect_index in AudioServer.get_bus_effect_count(AudioServer.get_bus_index("mic")):
				var ceffect := AudioServer.get_bus_effect(AudioServer.get_bus_index("mic"),effect_index)
				if ceffect.resource_name == "voicecapture":
					voice_capture = ceffect
					break
		return voice_capture

signal playerinit(isvr: bool)
signal playerreleaseuifocus
signal clear_gizmos

func player_init(isvr:bool):
	playerinit.emit(isvr)

func clear_gizmos_func():
	clear_gizmos.emit()

var is_inspector_loading: bool = false
