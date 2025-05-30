extends Node

@onready var scene_manager

func onclick():
	if scene_manager is OpenXRFbSceneManager:
		if scene_manager.is_scene_capture_enabled():
			scene_manager.request_scene_capture()
			print('starting scene capture')
		else:
			scene_manager.request_scene_capture()
			print('scene capture not enabled')
	else:
		print('no scene manager set')

func _ready():
	if ClassDB.class_exists("OpenXRFbSceneManager"):
		scene_manager = ClassDB.instantiate("OpenXRFbSceneManager")
		get_tree().get_first_node_in_group("player_xr_origin").call_deferred("add_child",scene_manager)
		#scene_manager.openxr_fb_scene_data_missing.connect(_scene_data_missing)
		scene_manager.openxr_fb_scene_capture_completed.connect(_scene_capture_completed)

#func _scene_data_missing() -> void:
	#scene_manager.request_scene_capture()

func _scene_capture_completed(success: bool) -> void:
	if success == false:
		return

	# Delete any existing anchors, since the user may have changed them.
	if scene_manager.are_scene_anchors_created():
		scene_manager.remove_scene_anchors()

	# Create scene_anchors for the freshly captured scene
	scene_manager.create_scene_anchors()
	
	var anchors = scene_manager.get_anchor_uuids()
	for anchor in anchors:
		if anchor is OpenXRFbSpatialEntity:
			get_tree().root.add_child(anchor.create_mesh_instance())
