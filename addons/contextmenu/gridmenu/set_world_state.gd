extends Node

@export_enum("WORLD_STATE_EDITING", "WORLD_STATE_PLAYING", "WORLD_STATE_VIEWING", "WORLD_STATE_SELECTING") var world_state_to_set: int

func _ready() -> void:
	LocalGlobals.world_state = world_state_to_set
