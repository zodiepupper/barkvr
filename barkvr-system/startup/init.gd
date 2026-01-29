extends Node3D

var vrm_ext_vrm_extension_0 = load("res://addons/vrm/vrm_extension.gd")
var vrm_ext_emmissive_multiplier = load("res://addons/vrm/1.0/VRMC_materials_hdr_emissiveMultiplier.gd")
var vrm_ext_materials_mtoon = load("res://addons/vrm/1.0/VRMC_materials_mtoon.gd")
var vrm_ext_node_constraint = load("res://addons/vrm/1.0/VRMC_node_constraint.gd")
var vrm_ext_springbone = load("res://addons/vrm/1.0/VRMC_springBone.gd")
var vrm_ext_vrm = load("res://addons/vrm/1.0/VRMC_vrm.gd")
var vrm_ext_vrm_animation = load("res://addons/vrm/1.0/VRMC_vrm_animation.gd")

@export var game_startup_scene :PackedScene

func _ready():
	GLTFDocument.register_gltf_document_extension(vrm_ext_vrm_extension_0.new(),true)
	GLTFDocument.register_gltf_document_extension(vrm_ext_emmissive_multiplier.new(), true)
	GLTFDocument.register_gltf_document_extension(vrm_ext_materials_mtoon.new(), true)
	GLTFDocument.register_gltf_document_extension(vrm_ext_node_constraint.new(), true)
	GLTFDocument.register_gltf_document_extension(vrm_ext_springbone.new(), true)
	GLTFDocument.register_gltf_document_extension(vrm_ext_vrm.new(), true)
	GLTFDocument.register_gltf_document_extension(vrm_ext_vrm_animation.new(), true)
	
	#OS.set_use_file_access_save_and_swap(true)
	#OS.request_permissions()
	if game_startup_scene:
		call_deferred("add_child",game_startup_scene.instantiate())
	
	print("we are here: ", DirAccess.open('./').get_current_dir(true))
	
	var dir = DirAccess.open('user://')
	print("user:// -> "+str(dir.get_current_dir(true))+" :: "+str(dir))
	if !dir.dir_exists('./tmp'):
		dir.make_dir('./tmp')
	if !dir.dir_exists('./objects'):
		dir.make_dir('./objects')
	if !dir.dir_exists('./worlds'):
		dir.make_dir('./worlds')
	if !dir.dir_exists('./logins'):
		dir.make_dir('./logins')
	
	get_window().files_dropped.connect(func(files:PackedStringArray):
		var loader :LoadingHalo= load("res://barkvr-system/ui/3dui/loading_halo.tscn").instantiate()
		var player_size_mult:float=1.0
		if is_instance_valid(get_tree().get_first_node_in_group("player")):
			var tmpscale = get_tree().get_first_node_in_group("player").global_basis.get_scale()
			player_size_mult = (tmpscale.x+tmpscale.y+tmpscale.z)/3.0
		var import_position :Vector3= get_viewport().get_camera_3d().to_global(Vector3(0,0,-2.0)*player_size_mult)
		if !OS.get_name() == "Web":
			#var thread := Thread.new()
			WorkerThreadPool.add_task(func():
				Thread.set_thread_safety_checks_enabled(false)
				import(files,loader,import_position,player_size_mult)
				, true, "importing: "+str(files))
			#BarkHelpers.rejoin_thread_when_finished(thread)
			get_tree().get_first_node_in_group("localworldroot").add_child(loader)
			if loader.text.is_empty():
				loader.text = "nothing?"
			loader.global_position = import_position
		else:
			import(files,loader,import_position,player_size_mult)
			get_tree().get_first_node_in_group("localworldroot").add_child(loader)
			if loader.text.is_empty():
				loader.text = "nothing?"
			loader.global_position = import_position
	)# end of files dropped

#func _process(_delta:float) -> void:
	#if !is_instance_valid(get_tree().get_first_node_in_group("player")):
		#var tmp_target_parent = get_tree().get_first_node_in_group("localworldroot")
		#if is_instance_valid(tmp_target_parent):
			#tmp_target_parent.add_child(load("res://barkvr-system/player/local/xrplayer.tscn").instantiate())
		#else:
			#get_tree().root.add_child(load("res://barkvr-system/player/local/xrplayer.tscn").instantiate())

func import(files:PackedStringArray, loader:LoadingHalo=null, import_position:Vector3=Vector3(), player_size_mult:float=1.0):
	var offset := -1.0
	var iteration :int= 0
	for dropped in files:
		iteration += 1
		offset += 1.0
		var filename:String
		if OS.get_name() == "Windows" or OS.get_name() == "UWP":
			filename = dropped.split('\\')[-1]
		else:
			filename = dropped.split('/')[-1]
		loader.text = filename + " (" + str(iteration) + "of" + str(files.size()) + ")"
		var file := FileAccess.open(dropped,FileAccess.READ)
		if !file:
			print('failed to open import file')
			continue
		# try to detect the file type:
		var type = BarkHelpers.detect_file_type_from_header(FileAccess.get_file_as_bytes(dropped))
		var new_import_position :Vector3=import_position+Vector3(0,0,offset)
		if dropped.to_lower().ends_with('.gltf') or \
			dropped.to_lower().ends_with('.glb'):
			Engine.get_singleton("event_manager").import_asset('glb', dropped, filename, false, {"base_path":dropped, "position":new_import_position,"scale":player_size_mult})
		elif dropped.to_lower().ends_with('.fbx'):
			Engine.get_singleton("event_manager").import_asset('glb', dropped, filename, false, {"base_path":dropped, "position":new_import_position,"scale":player_size_mult,"type":'fbx'})
		#elif dropped.to_lower().ends_with('.obj'):
			#Engine.get_singleton("event_manager").import_asset('glb', dropped, filename, false, {"base_path":dropped, "position":new_import_position,"scale":player_size_mult,"type":'fbx'})
		elif dropped.to_lower().ends_with('.vrm'):
			Engine.get_singleton("event_manager").import_asset('vrm',dropped, filename, false, {"position":new_import_position,"scale":player_size_mult})
		elif dropped.to_lower().ends_with('.obj'):
			Engine.get_singleton("event_manager").import_asset('obj',dropped, filename, false, {"position":new_import_position,"scale":player_size_mult})
		elif dropped.to_lower().ends_with('.res') or \
			dropped.to_lower().ends_with('.tres') or \
			dropped.to_lower().ends_with('.scn')  or \
			dropped.to_lower().ends_with('.tscn') or \
			dropped.to_lower().ends_with('.blend') or \
			dropped.to_lower().ends_with('.mtl'):
			Engine.get_singleton("event_manager").import_asset('res',dropped, filename, false, {"position":new_import_position,"scale":player_size_mult})
		#elif dropped.ends_with('.zip') or dropped.ends_with('.pck'):
		#elif dropped.to_lower().ends_with('.pck'):
			#Engine.get_singleton("event_manager").import_asset('pck', dropped, filename, false, {"position":new_import_position,"scale":player_size_mult})
		elif dropped.to_lower().ends_with('.png') or \
			dropped.to_lower().ends_with('.jpg')  or \
			dropped.to_lower().ends_with('.jpeg') or \
			dropped.to_lower().ends_with('.bmp')  or \
			dropped.to_lower().ends_with('.svg')  or \
			dropped.to_lower().ends_with('.tga')  or \
			dropped.to_lower().ends_with('.ktx')  or \
			dropped.to_lower().ends_with('.webp') or \
			type == "img":
			Engine.get_singleton("event_manager").import_asset('image', FileAccess.get_file_as_bytes(dropped), filename, false, {"position":new_import_position,"scale":player_size_mult})
		elif dropped.ends_with(".zip") or dropped.to_lower().ends_with('.pck') or dropped.to_lower().ends_with(".resonitepackage") or type == "rpkg":
			Engine.get_singleton("event_manager").import_asset('zip', dropped, filename, false, {"position":new_import_position,"scale":player_size_mult})
		elif dropped.ends_with(".mp3") or dropped.ends_with(".ogg") or dropped.ends_with(".wav"):
			Engine.get_singleton("event_manager").import_asset('audio', dropped, filename, false, {"position":new_import_position,"scale":player_size_mult})
		else:
			Engine.get_singleton("event_manager").import_asset('file', FileAccess.get_file_as_bytes(dropped), filename, false, {"position":new_import_position,"scale":player_size_mult})
	loader.done()

func import_clip(loader:LoadingHalo=null, import_position:Vector3=Vector3(), player_size_mult:float=1.0):
	if DisplayServer.clipboard_has_image():
		var clip = DisplayServer.clipboard_get_image()
		loader.set_deferred("text", "clipboard image")
		Engine.get_singleton("event_manager").import_asset('image', clip, '', false, {"loader":loader ,"position":import_position, "scale":player_size_mult})
	else:
		var clip = DisplayServer.clipboard_get()
		var trysvg = Image.new()
		if trysvg.load_svg_from_string(clip) == OK:
			trysvg.load_svg_from_string(clip, 1000.0/trysvg.get_size().length())
			print("imported svg final size: "+str(trysvg.get_size()))
			loader.set_deferred("text", "clipboard image")
			Engine.get_singleton("event_manager").import_asset('image', trysvg, '', false, {"loader":loader ,"position":import_position, "scale":player_size_mult})
		elif clip.begins_with("http://") or clip.begins_with("https://"):
			loader.set_deferred("text", "clipboard url")
			Engine.get_singleton("event_manager").import_asset('uri',clip,'', false, {"loader":loader ,"position":import_position, "scale":player_size_mult})
		else:
			loader.set_deferred("text", "clipboard text")
			Engine.get_singleton("event_manager").import_asset('text', clip, '', false, {"loader":loader ,"position":import_position, "scale":player_size_mult})
		

func _input(event):
	if event is InputEventKey:
		if event.physical_keycode == KEY_V and event.ctrl_pressed and event.pressed and LocalGlobals.player_state != LocalGlobals.PLAYER_STATE_TYPING:
			var player_size_mult:float=1.0
			if is_instance_valid(get_tree().get_first_node_in_group("player")):
				var tmpscale = get_tree().get_first_node_in_group("player").global_basis.get_scale()
				player_size_mult = (tmpscale.x+tmpscale.y+tmpscale.z)/3.0
			var import_position :Vector3= get_viewport().get_camera_3d().to_global(Vector3(0,0,-2.0)*player_size_mult)
			var loader :LoadingHalo= load("res://barkvr-system/ui/3dui/loading_halo.tscn").instantiate()
			get_tree().get_first_node_in_group("localworldroot").add_child(loader)
			var clipthread := Thread.new()
			clipthread.start(import_clip.bind(loader, import_position, player_size_mult))
			BarkHelpers.rejoin_thread_when_finished(clipthread)
			loader.global_position = import_position
		if event.physical_keycode == KEY_Z and event.ctrl_pressed and event.pressed:
			Engine.get_singleton("event_manager").undo_action()
