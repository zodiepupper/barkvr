class_name BarkvrImportManager
extends Node

static var current_instance : BarkvrImportManager

## an enum to contain each type of supported import type
## [br]TODO: specify which types require which fields
enum TYPE {text, glb, vrm, obj, fbx, res, pck, img, audio, file, uri, zip, ogv}

# BarkJournal.current_bark_journal.import_asset('file', FileAccess.get_file_as_bytes(dropped), filename, false, {"position":new_import_position,"scale":player_size_mult})
# func import_asset( type: String, asset_to_import: Variant, asset_name := '', recieved := false, data := {} ) -> void:
func _init() -> void:
	current_instance = self

## the class for holding all the data necessary to import a file
##
## if you need to know what feels are supported by which types, check the docs
## for the BarkvrImportManager.TYPE
class BarkvrImportFile:
	extends Node
	
	## track what type we think this file is for the current instance
	var type : BarkvrImportManager.TYPE
	## the path to the file we are importing
	## [br]optional, only used if imported from a file
	## [br]some file types only support being imported from an actual file path 
	var asset_path : StringName
	## the bytes of the asset we are importing 
	## [br] some types don't support this and some only support this
	var asset_bytes : PackedByteArray
	## the name the imported asset will be called once it is added to the tree
	var asset_name : String
	## optional path to store the loaded resource at
	var asset_base_path 
	## the global position where this asset wants to be placed once imported
	var asset_import_global_position : Vector3
	## the global scale this assets wants to be set to after finished importing
	var asset_import_global_scale : Vector3
	## holds a reference to the loader in the world so we can free it or cancel 
	## when it's freed
	var loader : LoadingHalo
	## track the number of times the file has attempted to import (this can be useful
	## in some cases)
	var import_attempts : int = 0
	
	func _init() -> void:
		loader = load("res://barkvr-system/ui/3dui/loading_halo.tscn").instantiate()
	
	## a function that allows us to easily create a 
	static func create(new_type : BarkvrImportManager.TYPE,\
		new_asset_path : StringName = "",\
		new_asset_bytes : PackedByteArray = PackedByteArray(),\
		new_asset_name : String = "",\
		new_asset_base_path : String = "",\
		new_asset_import_global_position : Vector3 = Vector3(),\
		new_asset_import_global_scale : Vector3 = Vector3.ONE,\
		new_loader : LoadingHalo = null,\
		new_import_attempts : int = 0) -> BarkvrImportFile:
			var tmp := BarkvrImportFile.new()
			tmp.type = new_type
			if !new_asset_path.is_empty():
				tmp.asset_path = new_asset_path
			if !new_asset_bytes.is_empty():
				tmp.asset_bytes = new_asset_bytes
			if !new_asset_name.is_empty():
				tmp.asset_name = new_asset_name
			if !new_asset_base_path.is_empty():
				tmp.asset_base_path = new_asset_base_path
			tmp.asset_import_global_position = new_asset_import_global_position
			tmp.asset_import_global_scale = new_asset_import_global_scale
			tmp.loader = new_loader
			tmp.import_attempts = new_import_attempts
			return tmp

class BarkvrImportImage:
	extends BarkvrImportFile
	var image : Image
	## a function that allows us to easily create a 
	static func create_with_image(new_type : BarkvrImportManager.TYPE,\
		new_asset_image : Image,\
		new_asset_path : StringName = "",\
		new_asset_bytes : PackedByteArray = PackedByteArray(),\
		new_asset_name : String = "",\
		new_asset_base_path : String = "",\
		new_asset_import_global_position : Vector3 = Vector3(),\
		new_asset_import_global_scale : Vector3 = Vector3.ONE,\
		new_loader : LoadingHalo = null,\
		new_import_attempts : int = 0) -> BarkvrImportFile:
			var tmp := BarkvrImportImage.new()
			tmp.type = new_type
			if !new_asset_image.is_empty():
				tmp.image = new_asset_image
			if !new_asset_path.is_empty():
				tmp.asset_path = new_asset_path
			if !new_asset_bytes.is_empty():
				tmp.asset_bytes = new_asset_bytes
			if !new_asset_name.is_empty():
				tmp.asset_name = new_asset_name
			if !new_asset_base_path.is_empty():
				tmp.asset_base_path = new_asset_base_path
			tmp.asset_import_global_position = new_asset_import_global_position
			tmp.asset_import_global_scale = new_asset_import_global_scale
			tmp.loader = new_loader
			tmp.import_attempts = new_import_attempts
			return tmp

var root : Node

## chekcs if the shared root is valid and if it isn't, we try to find it
func check_root() -> void:
	if !is_instance_valid(root):
		_get_root()

## attempts to query the tree for the shared root
func _get_root() -> void:
	root = get_tree().get_first_node_in_group('localworldroot')
	
## Imports an asset and adds that to the action log unless it was a recieved action.
func import_asset( import_file : BarkvrImportFile ) -> void:
	print(import_file.type)
	# Make sure root is valid.
	check_root()
	# if the loader isn't in the scene, add it
	if import_file.loader:
		if !import_file.loader.is_inside_tree():
			root.add_child(import_file.loader)
			import_file.loader.set_deferred("global_position",import_file.position)
	# Generate an asset name if not given.
	if import_file.asset_name.is_empty():
		# If we have a string path for the asset import, use that instead.
		if import_file.asset_path:
			import_file.asset_name = import_file.asset_path.split('/')[-1]
		else:
			import_file.asset_name = str(Time.get_unix_time_from_system())
	# Decide how to import asset based on type.
	# TODO pck support
	match import_file.type:
		TYPE.text:
			_import_text(import_file)
			return
		TYPE.glb, TYPE.vrm, TYPE.fbx:
			_import_glb(import_file)
			return
		TYPE.obj:
			_import_obj(import_file)
			return
		#TYPE.res:
			## TODO scenes and resources can't easily be sent to peers because of
			## possible dependencies in other files.
			#_import_res(import_file)
		TYPE.img:
			if import_file is BarkvrImportImage:
				_import_image_image(import_file)
				return
			_import_image_bytes(import_file.asset_name, import_file.asset_bytes if !import_file.asset_bytes.is_empty() else FileAccess.get_file_as_bytes(import_file.asset_path), import_file)
		TYPE.audio:
			_import_audio(import_file)
			return
		TYPE.file:
			_import_file(import_file)
			return
		TYPE.uri:
			_import_uri(import_file)
			return
		TYPE.zip:
			_import_zip(import_file)
			return
		TYPE.ogv:
			if !import_file.asset_bytes.is_empty():
				#var tmp_file := FileAccess.create_temp(FileAccess.WRITE_READ,"",".ogv")
				var tmp_file := FileAccess.open(OS.get_temp_dir()+"/"+str(import_file.asset_name.hash())+".ogv",FileAccess.WRITE_READ)
				tmp_file.store_buffer(import_file.asset_bytes)
				#tmp_file.close()
				import_file.asset_path = tmp_file.get_path_absolute()
			_import_video(import_file)
		_:
			if import_file.loader:
				import_file.loader.call_deferred("failed")
			#if asset_to_import is PackedByteArray:
				#asset_to_import = asset_to_import.get_string_from_utf8()
			_import_text(import_file)

## imports a video TODO: we need more video formats supported, asap
func _import_video(import_file:BarkvrImportFile) -> void:
	var tmp_video_player: Panel3D = (load("res://barkvr-system/ui/3dPanel/2d scenes/video3d.tscn") as PackedScene).instantiate()
	root.add_child(tmp_video_player)
	_post_import_video(import_file.asset_name, import_file.asset_path, tmp_video_player)

func _post_import_video(asset_name:String, asset_path:String, video_player:Panel3D):
	if "video" in video_player.ui and video_player.ui.video:
		var tmp := VideoStreamTheora.new()
		tmp.file = asset_path
		video_player.ui.video.stream = tmp
		video_player.ui.video.play()

## imports a remote uri (currently only http[s])
func _import_uri(import_file:BarkvrImportFile):
	# generate a temp directory to hold the data
	var temp_file_path :String = "user://tmp/"+str(hash(import_file.asset_path))
	# here we wanna track the number of iterations so we can
	# have a limit on the number of times we will attempt
	# to import the uri
	# ensure the uri is a valid http[s] url
	if import_file.asset_path.begins_with("http://") or import_file.asset_path.begins_with("https://"):
		# if we have already tried 4 times then we wanna say it failed
		if import_file.iterations > 4:
			print("loop while trying to import uri, cancelling import")
			return
		# create a new request object
		var req := HTTPRequest.new()
		# set the request to write to disk using the temp file path
		req.download_file = temp_file_path
		# add the request to the tree so it can be polled automatically by the engine
		call_deferred("add_child",req)
		# we wait for the node to be ready for some reason.
		if !req.is_node_ready():
			await req.ready
		req.request_completed.connect(_uri_request_completed.bind(req,import_file,import_file.asset_path))
		var headers = Engine.get_singleton("user_manager").headers
		req.request(import_file.asset_path, headers)

## finishing method for importing a uri
func _uri_request_completed(_result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray, req:HTTPRequest, import_file:BarkvrImportFile, uri:String):
	pass
	print('req completed')
	print('response code: '+str(response_code))
	var content_type:String = ""
	var _msg = body.get_string_from_ascii()
	for header in headers:
		if header.begins_with("Content-Type:"):
			print('content')
			print(header.trim_prefix("Content-Type: "))
			var trimmed := header.trim_prefix("Content-Type: ")
			if trimmed.begins_with("image") and !trimmed.contains("gif"):
				print('importing uri image')
				while body.size() < 1:
					if import_file.iterations > 4:
						import_file.loader.call_deferred("woh, what happened @_@")
						return
					import_file.iterations += 1
					body = (FileAccess.get_file_as_bytes(req.download_file))
				_import_image_bytes(uri, body, import_file)
				import_file.loader.call_deferred("haiii ;3")
				return
			elif trimmed == "application/json":
				print('woof')
				import_file.loader.call_deferred("thx for playing my game o.o")
				return
			elif trimmed.contains("gltf-binary"):
				content_type = "gltf-binary"
			elif trimmed.contains("vrm") or uri.ends_with("vrm"):
				content_type = "vrm"
	print('uri returned text')
	print('uri: '+uri)
	if uri.contains('.gltf') or uri.contains('.glb') or content_type == "gltf-binary":
		WorkerThreadPool.add_task( import_asset.bind( BarkvrImportFile.create(TYPE.glb, req.download_file, PackedByteArray(), import_file.asset_name) ) )
	elif uri.contains('.vrm') or content_type == "vrm":
		WorkerThreadPool.add_task( import_asset.bind( BarkvrImportFile.create(TYPE.vrm, req.download_file, PackedByteArray(), import_file.asset_name) ) )
	elif uri.contains('.obj'):
		import_asset( BarkvrImportFile.create(TYPE.vrm, req.download_file, PackedByteArray(), import_file.asset_name) )
	elif uri.contains('.res') or uri.contains('.tres') or uri.contains('.scn') or uri.contains('.tscn'):
		import_asset( BarkvrImportFile.create(TYPE.res, req.download_file, PackedByteArray(), import_file.asset_name))
	#elif dropped.ends_with('.zip') or dropped.ends_with('.pck'):
	elif uri.contains('.pck'):
		import_asset( BarkvrImportFile.create(TYPE.pck, req.download_file, PackedByteArray(), import_file.asset_name))
	elif uri.contains('.png') or \
		uri.contains('.jpg') or \
		uri.contains('.jpeg') or \
		uri.contains('.bmp') or \
		uri.contains('.svg') or \
		uri.contains('.tga') or \
		uri.contains('.ktx') or \
		uri.contains('.webp'):
		import_asset( BarkvrImportFile.create(TYPE.img, req.download_file, PackedByteArray(), import_file.asset_name) )
	else:
		# hit "https://image.thum.io/get/" to grab an image of the website
		if !uri.begins_with("https://image.thum.io/get/"):
			uri = "https://image.thum.io/get/"+uri
		import_file.iterations += 1
		print("get preview:\n"+uri)
		_import_uri(import_file)
		#elif dropped.ends_with(".zip"):
			#import_asset('zip', reader.read_file(dropped), asset_name, false, data)
		#else:
			#import_asset('file', reader.read_file(dropped), asset_name, false, data)
	req.queue_free()

func _import_zip(import_file : BarkvrImportFile):
	var reader := ZIPReader.new()
	if reader.open(import_file.asset_path) == 0:
		for dropped in reader.get_files():
			print('dropped: '+dropped)
			if reader.file_exists(dropped):
				print('is file')
				var type = BarkHelpers.detect_file_type_from_header(reader.read_file(dropped))
				import_file.asset_import_global_position = import_file.asset_import_global_position+Vector3(0,0,-.01*get_tree().get_first_node_in_group("player").scale.length())
				if dropped.contains('.gltf') or dropped.contains('.glb'):
					import_asset( BarkvrImportFile.create(TYPE.glb, "", reader.read_file(dropped), dropped, "", import_file.asset_import_global_position, import_file.asset_import_global_scale) )
				elif dropped.ends_with(".fbx"):
					import_asset( BarkvrImportFile.create(TYPE.fbx, "", reader.read_file(dropped), dropped, "", import_file.asset_import_global_position, import_file.asset_import_global_scale) )
				elif dropped.contains('.vrm'):
					import_asset( BarkvrImportFile.create(TYPE.vrm, "", reader.read_file(dropped), dropped, "", import_file.asset_import_global_position, import_file.asset_import_global_scale) )
				elif dropped.ends_with('.res') or dropped.ends_with('.tres') or dropped.ends_with('.scn') or dropped.ends_with('.tscn'):
					import_asset( BarkvrImportFile.create(TYPE.res, "", reader.read_file(dropped), dropped, "", import_file.asset_import_global_position, import_file.asset_import_global_scale) )
				#elif dropped.ends_with('.zip') or dropped.ends_with('.pck'):
				elif dropped.ends_with('.pck'):
					import_asset(BarkvrImportFile.create(TYPE.pck, "", reader.read_file(dropped), dropped, "", import_file.asset_import_global_position, import_file.asset_import_global_scale))
				elif dropped.ends_with('.png') or \
					dropped.ends_with('.jpg') or \
					dropped.ends_with('.jpeg') or \
					dropped.ends_with('.bmp') or \
					dropped.ends_with('.svg') or \
					dropped.ends_with('.tga') or \
					dropped.ends_with('.ktx') or \
					dropped.ends_with('.webp') or \
					type == "img":
					import_asset( BarkvrImportFile.create(TYPE.img, "", reader.read_file(dropped), dropped, "", import_file.asset_import_global_position, import_file.asset_import_global_scale) )
				elif dropped.ends_with('.obj'):
					import_asset( BarkvrImportFile.create(TYPE.obj, "", reader.read_file(dropped), dropped, "", import_file.asset_import_global_position, import_file.asset_import_global_scale) )
				elif dropped.ends_with('.txt'):
					import_asset( BarkvrImportFile.create(TYPE.text, "", reader.read_file(dropped), dropped, "", import_file.asset_import_global_position, import_file.asset_import_global_scale))
				#elif dropped.ends_with(".zip"):
					#import_asset('zip', reader.read_file(dropped), asset_name, false, data)
				#else:
					#import_asset('file', reader.read_file(dropped), asset_name, false, data)

func _check_loaded(path: String, asset_name:String, data:Dictionary={}, _last_time:float=0.0) -> void:
	check_root()
	while ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		pass
		#get_tree().create_timer(1).timeout.connect(_check_loaded.bind(path, asset_name, position))
	if ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_LOADED:
		var res := ResourceLoader.load_threaded_get(path)
		if res != null:
			var node = res.instantiate()
			_post_import.call_deferred(root,node,asset_name,data)

#
var gltf_document_extension_class = load("res://addons/vrm/vrm_extension.gd")
const SAVE_DEBUG_GLTFSTATE_RES: bool = false

#COPIED FROM https://github.com/godotengine/godot/blob/c4279fe3e0b27d0f40857c00eece7324a967285f/modules/gltf/gltf_document.cpp#L62
#define GLTF_IMPORT_GENERATE_TANGENT_ARRAYS 8
#define GLTF_IMPORT_USE_NAMED_SKIN_BINDS 16
#define GLTF_IMPORT_DISCARD_MESHES_AND_MATERIALS 32
#define GLTF_IMPORT_FORCE_DISABLE_MESH_COMPRESSION 64

func _import_glb(import_file : BarkvrImportFile) -> void:
	check_root()
	var logging_prefix := import_file.asset_name+" : "
	print("Import VRM/GLTF/GLB/FBX: " + import_file.asset_name + " ----------------------")
	var gltf : GLTFDocument
	var flags := 16+8
	var state : GLTFState
	if import_file.type == TYPE.vrm:
		BarkvrHelpers.enable_vrm_gltf()
	if import_file.type == TYPE.fbx:
		gltf = FBXDocument.new()
		state = FBXState.new()
		#state.allow_geometry_helper_nodes = true
	else:
		gltf = GLTFDocument.new()
		state = GLTFState.new()
		if import_file.type != TYPE.vrm:
			state.set_additional_data(&"vrm/already_processed",true)
	var err :int
	if import_file.asset_path:
		err = gltf.append_from_file(import_file.asset_path, state, flags)
	elif import_file.asset_bytes:
		err = gltf.append_from_buffer(import_file.asset_bytes, '', state, flags)
	match err:
		43:
			if import_file.import_attempts > 0:
				return
			import_file.type = TYPE.fbx
			import_file.alreadytried = 1
			_import_glb(import_file)
			return
	if err != OK:
		if import_file.loader:
			import_file.loader.call_deferred("done",'failed')
		return
	for mesh in state.meshes:
			if mesh.mesh.get_surface_lod_count(0) == 0:
				print(logging_prefix+'generating lods')
				mesh.mesh.generate_lods(25,60,[])
	print("generated scene")
	var generated_scene = gltf.generate_scene(state)
	var packed_scene_workaround := PackedScene.new()
	packed_scene_workaround.pack(generated_scene)
	generated_scene = packed_scene_workaround.instantiate()
	#if SAVE_DEBUG_GLTFSTATE_RES and content != "":
		#if !ResourceLoader.exists(content + ".res"):
			#state.take_over_path(content + ".res")
			#ResourceSaver.save(state, content + ".res")
	print('post importing glb/gltf/vrm')
	_post_import.call_deferred(root, generated_scene, import_file)
	if import_file.type == TYPE.vrm:
		BarkvrHelpers.disable_vrm_gltf()

## Import Wavefront .obj files
func _import_obj(import_file:BarkvrImportFile) -> void:
	# load the file into a mesh
	var logging_prefix := import_file.asset_name+" : "
	print("Import OBJ: " + import_file.asset_name + " ----------------------")
	
	var mesh_data := MeshInstance3D.new()
	#this basically checks if its "local"-ish or if it's being fed through the network
	#assuming transmitting the object between clients will become a string
	if(import_file.asset_path.is_absolute_path() || import_file.asset_path.is_relative_path()):
		mesh_data.mesh = ObjParse.from_path(import_file.asset_path)
	else:
		mesh_data.mesh = ObjParse.from_obj_string(import_file.asset_path)

	#TODO: figure out a way to generate LOD's 
	
	#create the collision node
	var tmpbody := StaticBody3D.new()
	tmpbody.set_meta("grabbable",true)
	var tmpcol := CollisionShape3D.new()
	var tmpcolshape := SphereShape3D.new()
	tmpcol.scale = mesh_data.get_aabb().size
	
	tmpcol.shape = tmpcolshape
	tmpbody.add_child(tmpcol)
	tmpbody.collision_layer = 2
	tmpbody.collision_mask = 2

	tmpbody.add_child(mesh_data)

	#var compressed := content.compress()
	#print(compressed)
	#print(content)
	_post_import.call_deferred(root, tmpbody, import_file)

## Imports a Godot resource.
func _import_res(asset_name: String, asset_to_import: Variant, data:Dictionary={}) -> void:
	check_root()
	# If asset to import is not a path, create a path.
	# Note that this may mean assets might not load for peers.
	if asset_to_import is PackedByteArray:
		# Write the content to a temporary file.
		# TODO cleanup of the file?
		var path := "user://tmp/" + str(str(asset_to_import).hash()) + ".res"
		var file := FileAccess.open(path, FileAccess.WRITE)
		file.store_buffer(asset_to_import)
		file.flush()
		file.close()
		asset_to_import = path
	ResourceLoader.set_abort_on_missing_resources(false)
	print(asset_to_import)
	#var res :Resource
	#print(ResourceLoader.get_dependencies(asset_to_import)[0])
	#print(asset_to_import)
	print(ResourceLoader.get_recognized_extensions_for_type(asset_to_import))
	var res = ResourceLoader.load(asset_to_import,'obj',ResourceLoader.CACHE_MODE_IGNORE)
	
	# var res = load(asset_to_import)
	#print(res.resource_path)
	#res = _load_res_with_dependencies(asset_to_import)
	if res != null:
		var node = res.instantiate()
		_post_import.call_deferred(root,node,asset_name)
	ResourceLoader.load_threaded_request(asset_to_import, 'tres', false, ResourceLoader.CACHE_MODE_IGNORE)
	_check_loaded(asset_to_import,asset_name,data)

func _load_res_with_dependencies(path:String) -> Resource:
	var res :Resource
	for dep in ResourceLoader.get_dependencies(path):
		_load_res_with_dependencies(dep)
	res = ResourceLoader.load(path)
	return res

func _load_image_bytes_from_header(content: PackedByteArray) -> Image:
	var img := Image.new()
	
	var format_signatures = [
		# WEBP
		{
			"callable": Callable(img, "load_webp_from_buffer"),
			"magic": [0x52, 0x49, 0x46, 0x46, null, null, null, null, 0x57, 0x45, 0x42, 0x50]
		},
		# PNG
		{
			"callable": Callable(img, "load_png_from_buffer"),
			"magic": [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]
		},
		# BMP
		{
			"callable": Callable(img, "load_bmp_from_buffer"),
			"magic": [0x42, 0x4D]
		},
		# TGA does not have a static header
		
		# JPG
		{
			"callable": Callable(img, "load_jpg_from_buffer"),
			# I think there are other possible magics
			# This could possibly miss some kinds of JPEGs!
			# TODO: Add more JPEG magics
			"magic": [0xFF, 0xD8, 0xFF, 0xE0]
		},
		# SVG does not have a static header
		
		# KTX
		{
			"callable": Callable(img, "load_ktx_from_buffer"),
			"magic": [0xAB, 0x4B, 0x54, 0x58, 0x20, 0x31, 0x31, 0xBB, 0x0D, 0x0A, 0x1A, 0x0A]
		}
	]
	
	# Check each signature on the image to find a match
	for signature in format_signatures:
		var magic = signature.magic
		
		# Check to make sure there are enough bytes to read
		if content.size() >= magic.size():
			var matches = true
			
			# Loop over bytes until our signature is done
			# or there is a mismatch
			for i in range(magic.size()):
				# Dont read null (wildcard) magic bytes
				if magic[i] == null:
					continue
				
				if content[i] != magic[i]:
					# There was a mismatch
					matches = false
					break
			
			if matches:
				# We have a signature match!
				# Load the image
				signature.callable.call(content)
	
	return img

## Imports an image from bytes.
func _import_image_bytes(asset_name: String, content: PackedByteArray, import_file: BarkvrImportFile) -> void:
	check_root()
	
	var img: Image = _load_image_bytes_from_header(content)
	var err: Error
	
	# `img` will be empty if no signature was matched or loading failed
	if img.is_empty():
		# The image did not have a signature
		# The image could be TGA, SVG, or in the data dict
		
		err = img.load_tga_from_buffer(content)
		if err != OK:
			err = img.load_svg_from_buffer(content)
		#if err != OK and image_data and image_image_alt:
			## Image was not TGA or SVG, test the data argument for image data
			#img = bytes_to_var_with_objects(image_data)
			#if !img.is_empty():
				#err = OK
		#if err != OK and image_data:
			#img = null
			#img = Image.new()
			#img.data.data = image_data
			#print('create image from data:')
			#print(img.data.size())
			#print(img.is_empty())
			#err = OK
	
	if err != OK or img.is_empty():
		if is_instance_valid(import_file.loader):
			import_file.loader.call_deferred("done",'failed')
			printerr("image failed to load:\n",import_file)
		return
	
	var tex := ImageTexture.create_from_image(img)
	var plane := MeshInstance3D.new()
	var tmpmesh := PlaneMesh.new()
	var tmpmat := StandardMaterial3D.new()
	tmpmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	tmpmesh.size.y = 1.0
	tmpmesh.size.x = ((tex.get_size()).x/(tex.get_size()).y)
	tmpmat.albedo_texture = tex
	tmpmat.cull_mode = BaseMaterial3D.CULL_DISABLED
	tmpmat.shading_mode = tmpmat.SHADING_MODE_UNSHADED
	tmpmesh.material = tmpmat
	tmpmesh.orientation = PlaneMesh.FACE_Z
	plane.mesh = tmpmesh
	
	var tmpbody := StaticBody3D.new()
	tmpbody.set_meta("grabbable",true)
	tmpbody.set_meta("image_texture", tex)
	var tmpcol := CollisionShape3D.new()
	var tmpcolshape := BoxShape3D.new()
	tmpcolshape.size.y = 1.0
	tmpcolshape.size.x = ((tex.get_size()).x/(tex.get_size()).y)
	tmpcolshape.size.z = .001
	tmpcol.shape = tmpcolshape
	tmpbody.add_child(tmpcol)
	tmpbody.collision_layer = 2
	tmpbody.collision_mask = 2
	
	tmpbody.add_child(plane)
	_post_import.call_deferred(root, tmpbody, import_file)


## Imports an image from an existing image resource.
func _import_image_image(import_file: BarkvrImportImage) -> void:
	check_root()
	
	if !import_file.image:
		import_file.loader.call_deferred("done", "_import_image_image: failed to load image")
		import_file.free()
		return
	var tex := ImageTexture.create_from_image(import_file.image)
	var plane := MeshInstance3D.new()
	var tmpmesh := PlaneMesh.new()
	var tmpmat := StandardMaterial3D.new()
	tmpmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	tmpmesh.size.y = 1.0
	tmpmesh.size.x = ((tex.get_size()).x/(tex.get_size()).y)
	tmpmat.albedo_texture = tex
	tmpmat.cull_mode = BaseMaterial3D.CULL_DISABLED
	tmpmat.shading_mode = tmpmat.SHADING_MODE_UNSHADED
	tmpmesh.material = tmpmat
	tmpmesh.orientation = PlaneMesh.FACE_Z
	plane.mesh = tmpmesh
	
	var tmpbody := StaticBody3D.new()
	tmpbody.set_meta("grabbable",true)
	var tmpcol := CollisionShape3D.new()
	var tmpcolshape := BoxShape3D.new()
	tmpcolshape.size.y = 1.0
	tmpcolshape.size.x = ((tex.get_size()).x/(tex.get_size()).y)
	tmpcolshape.size.z = .001
	tmpcol.shape = tmpcolshape
	tmpbody.add_child(tmpcol)
	tmpbody.collision_layer = 2
	tmpbody.collision_mask = 2
	
	tmpbody.add_child(plane)
	_post_import.call_deferred(root, tmpbody, import_file)

## Imports an audio file.
func _import_audio(import_file:BarkvrImportFile) -> void:
	check_root()
	var audio3d: Audio3D = load("res://barkvr-system/ui/3dui/import helpers/audio3d.tscn").instantiate()
	audio3d.load_audio_from_bytes(import_file.asset_bytes, "mp3")
	_post_import.call_deferred(root, audio3d, import_file)

## Imports some text.
func _import_text(import_file : BarkvrImportFile) -> void:
	check_root()
	var tex := NoiseTexture2D.new()
	var noise := FastNoiseLite.new()
	noise.seed = import_file.asset_name.hash()
	tex.height = 100
	tex.width = 100
	tex.noise = noise
	var mesh := MeshInstance3D.new()
	#var tmpmesh := PlaneMesh.new()
	var tmpmesh := TextMesh.new()
	tmpmesh.text = import_file.asset_name
	tmpmesh.autowrap_mode = TextServer.AUTOWRAP_WORD
	tmpmesh.font_size = 4
	tmpmesh.depth = .01
	#tmpmesh.size = tex.get_size()*.001
	var tmpmat := StandardMaterial3D.new()
	
	var tmpbody := StaticBody3D.new()
	tmpbody.set_meta("grabbable",true)
	var tmpcol := CollisionShape3D.new()
	var tmpcolshape := BoxShape3D.new()
	#tmpcolshape.size.x = (tex.get_size()*.001).x
	#tmpcolshape.size.y = (tex.get_size()*.001).y
	tmpcolshape.size = tmpmesh.get_aabb().size
	
	#tmpcolshape.size.z = .001
	tmpcol.shape = tmpcolshape
	tmpbody.add_child(tmpcol)
	tmpbody.collision_layer = 2
	tmpbody.collision_mask = 2
	
	tmpmat.albedo_texture = tex
	tmpmat.shading_mode = tmpmat.SHADING_MODE_UNSHADED
	tmpmesh.material = tmpmat
	#tmpmesh.orientation = PlaneMesh.FACE_Z
	mesh.mesh = tmpmesh
	tmpbody.add_child(mesh)
	_post_import.call_deferred(root, tmpbody, import_file)

## Imports a file.
func _import_file(import_file:BarkvrImportFile) -> void:
	check_root()
	var tex := NoiseTexture2D.new()
	var noise := FastNoiseLite.new()
	noise.seed = import_file.asset_name.hash()
	tex.height = 100
	tex.width = 100
	tex.noise = noise
	var plane := MeshInstance3D.new()
	#var tmpmesh := PlaneMesh.new()
	var tmpmesh := TextMesh.new()
	tmpmesh.text = import_file.asset_name
	tmpmesh.autowrap_mode = TextServer.AUTOWRAP_WORD
	tmpmesh.font_size = 4
	tmpmesh.depth = .01
	#tmpmesh.size = tex.get_size()*.001
	var tmpmat := StandardMaterial3D.new()
	
	var tmpbody := StaticBody3D.new()
	tmpbody.set_meta("grabbable",true)
	var tmpcol := CollisionShape3D.new()
	var tmpcolshape := BoxShape3D.new()
	#tmpcolshape.size.x = (tex.get_size()*.001).x
	#tmpcolshape.size.y = (tex.get_size()*.001).y
	tmpcolshape.size = tmpmesh.get_aabb().size
	
	#tmpcolshape.size.z = .001
	tmpcol.shape = tmpcolshape
	tmpbody.add_child(tmpcol)
	tmpbody.collision_layer = 2
	tmpbody.collision_mask = 2
	
	tmpmat.albedo_texture = tex
	tmpmat.shading_mode = tmpmat.SHADING_MODE_UNSHADED
	tmpmesh.material = tmpmat
	#tmpmesh.orientation = PlaneMesh.FACE_Z
	plane.mesh = tmpmesh
	tmpbody.add_child(plane)

	#var compressed := content.compress()
	#print(compressed)
	#print(content)
	
	#tmpbody.set_meta("file_bytes",str(content.compress(2)))
	_post_import.call_deferred(root, tmpbody, import_file)

func _post_import(_rootarget_node:Node,node_to_add:Node,import_file:BarkvrImportFile):
	check_root()
	var position = Vector3()
	position = import_file.asset_import_global_position
	var scale = 1.0
	scale = import_file.asset_import_global_scale
	root.call_deferred("add_child", node_to_add)
	await get_tree().process_frame
	if node_to_add is Node3D:
		if !(import_file.type in [TYPE.glb, TYPE.vrm, TYPE.obj, TYPE.fbx]) :
			node_to_add.look_at_from_position(position,get_viewport().get_camera_3d().global_position,Vector3.UP,true)
		node_to_add.global_position = position
		node_to_add.scale *= scale
	node_to_add.name = import_file.asset_name
	print(import_file.asset_name)
	# add IK stuff if VRM
	if import_file.asset_name.ends_with(".vrm") or import_file.type == TYPE.vrm:
		print('attempting ik')
		var quickiksetup :Node3D = load("res://barkvr-system/ik/auto setup for avatars/quick_ik_setup.tscn").instantiate()
		node_to_add.add_child(quickiksetup)
		var skele :Skeleton3D=null
		for i in node_to_add.get_children():
			if skele:
				break
			if i is Skeleton3D:
				skele = i
			elif i.get_child_count() > 0:
				for a in i.get_children():
					if a is Skeleton3D:
						skele = a
			await get_tree().process_frame
		if skele:
			print('found skele')
			quickiksetup.armature_skeleton = skele
	if import_file.loader:
		import_file.loader.call_deferred("done")
	import_file.queue_free()
