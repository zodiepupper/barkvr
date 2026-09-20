class_name BarkvrImportManager
extends Node

static var current_instance : BarkvrImportManager

# BarkJournal.current_bark_journal.import_asset('file', FileAccess.get_file_as_bytes(dropped), filename, false, {"position":new_import_position,"scale":player_size_mult})
# func import_asset( type: String, asset_to_import: Variant, asset_name := '', recieved := false, data := {} ) -> void:
func _init() -> void:
	current_instance = self

class BarkvrImportFile:
	enum type {text, txt, glb, vrm, obj, res, image, img, audio, file, uri, zip, ogv}
	
	func stuff():
		0 == BarkvrImportManager.BarkvrImportFile.type.text

var root : Node

## chekcs if the shared root is valid and if it isn't, we try to find it
func check_root() -> void:
	if !is_instance_valid(root):
		_get_root()

## attempts to query the tree for the shared root
func _get_root() -> void:
	root = get_tree().get_first_node_in_group('localworldroot')
	
## Imports an asset and adds that to the action log unless it was a recieved action.
func import_asset( type: String, asset_to_import: Variant, asset_name := '', recieved := false, data := {} ) -> void:
	print(type)
	# Make sure root is valid.
	check_root()
	# if the loader isn't in the scene, add it
	if "loader" in data and data.loader is Node:
		if !data.loader.is_inside_tree():
			if recieved:
				data.loader = load("res://barkvr-system/ui/3dui/loading_halo.tscn").instantiate()
				data.loader.text = "remote asset"
			root.add_child(data.loader)
			data.loader.global_position = data.position
	# Generate an asset name if not given.
	if asset_name.is_empty():
		# If we have a string path for the asset import, use that instead.
		if asset_to_import is String:
			asset_name = asset_to_import.split('/')[-1]
		else:
			asset_name = str(Time.get_unix_time_from_system())
	# Get asset content if needed.
	var content := PackedByteArray()
	if type != "res":
		if asset_to_import is PackedByteArray:
			content = asset_to_import
		elif asset_to_import is String:
			content = FileAccess.get_file_as_bytes(asset_to_import)
			if content.is_empty():
				print(FileAccess.get_open_error())
		elif asset_to_import is Image:
			content = asset_to_import.data.data
	# Decide how to import asset based on type.
	# TODO pck support
	data.type = type
	match type:
		"text", "txt":
			if asset_to_import is PackedByteArray:
				asset_to_import = asset_to_import.get_string_from_utf8()
			_import_text(asset_to_import,asset_to_import, data)
		"glb", "vrm":
			_import_glb(asset_to_import, asset_name, data)
		"obj":
			_import_obj(asset_to_import, asset_name, data)
		"res":
			# TODO scenes and resources can't easily be sent to peers because of
			# possible dependencies in other files.
			_import_res(asset_name, asset_to_import, data)
		"image", "img":
			if asset_to_import is Image:
				_import_image_image(asset_name, asset_to_import, data)
			else:
				_import_image_bytes(asset_name, content, data)
		"audio":
			if !content.is_empty():
				_import_audio(asset_name, content, data)
			elif asset_to_import is String:
				pass
		"file":
			_import_file(asset_name, content, data)
		"uri":
			_import_uri(asset_to_import, data)
		"zip":
			_import_zip(asset_name, asset_to_import, data)
		"ogv":
			if asset_to_import is PackedByteArray:
				#var tmp_file := FileAccess.create_temp(FileAccess.WRITE_READ,"",".ogv")
				var tmp_file := FileAccess.open(OS.get_temp_dir()+"/"+str(asset_name.hash())+".ogv",FileAccess.WRITE_READ)
				tmp_file.store_buffer(asset_to_import)
				#tmp_file.close()
				asset_to_import = tmp_file.get_path_absolute()
			_import_video(asset_name, asset_to_import)
		_:
			if "loader" in data:
				data.loader.done('failed')
			if asset_to_import is PackedByteArray:
				asset_to_import = asset_to_import.get_string_from_utf8()
			_import_text(asset_to_import,asset_to_import, data)

## imports a video TODO: we need more video formats supported, asap
func _import_video(asset_name:String, asset_path:String) -> void:
	var tmp_video_player: Panel3D = (load("res://barkvr-system/ui/3dPanel/2d scenes/video3d.tscn") as PackedScene).instantiate()
	root.add_child(tmp_video_player)
	_post_import_video(asset_name, asset_path, tmp_video_player)

func _post_import_video(asset_name:String, asset_path:String, video_player:Panel3D):
	if "video" in video_player.ui and video_player.ui.video:
		var tmp := VideoStreamTheora.new()
		tmp.file = asset_path
		video_player.ui.video.stream = tmp
		video_player.ui.video.play()

## imports a remote uri (currently only http[s])
func _import_uri(uri:String, data:Dictionary={}):
	# generate a temp directory to hold the data
	var temp_file_path :String = "user://tmp/"+str(hash(uri))
	# here we wanna track the number of iterations so we can
	# have a limit on the number of times we will attempt
	# to import the uri
	if !("iterations" in data):
		data.iterations = 0
	# ensure the uri is a valid http[s] url
	if uri.begins_with("http://") or uri.begins_with("https://"):
		# if we have already tried 4 times then we wanna say it failed
		if "iterations" in data and data.iterations > 4:
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
		req.request_completed.connect(_uri_request_completed.bind(req,data,uri))
		var headers = Engine.get_singleton("user_manager").headers
		req.request(uri, headers)

## finishing method for importing a uri
func _uri_request_completed(_result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray, req:HTTPRequest, data:Dictionary, uri:String):
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
							if data.iterations > 4:
								data.loader.done()
								return
							data.iterations += 1
							body = (FileAccess.get_file_as_bytes(req.download_file))
						_import_image_bytes(uri, body, data)
						data.loader.done()
						return
					elif trimmed == "application/json":
						print('woof')
						data.loader.done()
						return
					elif trimmed.contains("gltf-binary"):
						content_type = "gltf-binary"
					elif trimmed.contains("vrm") or uri.ends_with("vrm"):
						content_type = "vrm"
			print('uri returned text')
			print('uri: '+uri)
			if uri.contains('.gltf') or uri.contains('.glb') or content_type == "gltf-binary":
				WorkerThreadPool.add_task(import_asset.bind('glb', req.download_file, uri, false, data))
			elif uri.contains('.vrm') or content_type == "vrm":
				WorkerThreadPool.add_task(import_asset.bind('vrm', req.download_file, uri, false, data))
			elif uri.contains('.obj'):
				import_asset('obj', req.download_file, uri, false, data)
			elif uri.contains('.res') or uri.contains('.tres') or uri.contains('.scn') or uri.contains('.tscn'):
				import_asset('res',req.download_file, uri, false, data)
			#elif dropped.ends_with('.zip') or dropped.ends_with('.pck'):
			elif uri.contains('.pck'):
				import_asset('pck', req.download_file, uri, false, data)
			elif uri.contains('.png') or \
				uri.contains('.jpg') or \
				uri.contains('.jpeg') or \
				uri.contains('.bmp') or \
				uri.contains('.svg') or \
				uri.contains('.tga') or \
				uri.contains('.ktx') or \
				uri.contains('.webp'):
				import_asset('image', req.download_file, uri, false, data)
			else:
				# hit "https://image.thum.io/get/" to grab an image of the website
				if !uri.begins_with("https://image.thum.io/get/"):
					uri = "https://image.thum.io/get/"+uri
				if "iterations" in data:
					data.iterations += 1
				else:
					data.iterations = 1
				print("get preview:\n"+uri)
				_import_uri(uri,data)
				#elif dropped.ends_with(".zip"):
					#import_asset('zip', reader.read_file(dropped), asset_name, false, data)
				#else:
					#import_asset('file', reader.read_file(dropped), asset_name, false, data)
			req.queue_free()

func _import_zip(asset_name:String, asset_path:String, data:Dictionary={}):
	var reader := ZIPReader.new()
	data.nolookatuser = true
	if reader.open(asset_path) == 0:
		for dropped in reader.get_files():
			print('dropped: '+dropped)
			if reader.file_exists(dropped):
				print('is file')
				var type = BarkHelpers.detect_file_type_from_header(reader.read_file(dropped))
				data.position = data.position+Vector3(0,0,-.01*get_tree().get_first_node_in_group("player").scale.length())
				if dropped.contains('.gltf') or dropped.contains('.glb'):
					import_asset('glb', reader.read_file(dropped), asset_name, false, data)
				elif dropped.contains('.vrm'):
					import_asset('vrm',reader.read_file(dropped), asset_name, false, data)
				elif dropped.ends_with('.res') or dropped.ends_with('.tres') or dropped.ends_with('.scn') or dropped.ends_with('.tscn'):
					import_asset('res',reader.read_file(dropped), asset_name, false, data)
				#elif dropped.ends_with('.zip') or dropped.ends_with('.pck'):
				elif dropped.ends_with('.pck'):
					import_asset('pck', reader.read_file(dropped), asset_name, false, data)
				elif dropped.ends_with('.png') or \
					dropped.ends_with('.jpg') or \
					dropped.ends_with('.jpeg') or \
					dropped.ends_with('.bmp') or \
					dropped.ends_with('.svg') or \
					dropped.ends_with('.tga') or \
					dropped.ends_with('.ktx') or \
					dropped.ends_with('.webp') or \
					type == "img":
					import_asset('image', reader.read_file(dropped), asset_name, false, data)
				elif dropped.ends_with('.obj'):
					import_asset('obj', reader.read_file(dropped), asset_name, false, data)
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
			_post_import.call_deferred(root,node,asset_name,data, !data.has("nolookatuser"))

#
var gltf_document_extension_class = load("res://addons/vrm/vrm_extension.gd")
const SAVE_DEBUG_GLTFSTATE_RES: bool = false

#COPIED FROM https://github.com/godotengine/godot/blob/c4279fe3e0b27d0f40857c00eece7324a967285f/modules/gltf/gltf_document.cpp#L62
#define GLTF_IMPORT_GENERATE_TANGENT_ARRAYS 8
#define GLTF_IMPORT_USE_NAMED_SKIN_BINDS 16
#define GLTF_IMPORT_DISCARD_MESHES_AND_MATERIALS 32
#define GLTF_IMPORT_FORCE_DISABLE_MESH_COMPRESSION 64

func _import_glb(content: Variant, asset_name := '', data := {}) -> void:
	check_root()
	#Thread.set_thread_safety_checks_enabled(false)
	var logging_prefix := asset_name+" : "
	print("Import VRM/GLTF/GLB/FBX: " + asset_name + " ----------------------")
	var gltf : GLTFDocument
	var flags := 16+8
	var state : GLTFState
	if "type" in data and data.type == 'fbx':
		gltf = FBXDocument.new()
		state = FBXState.new()
		#state.allow_geometry_helper_nodes = true
	else:
		gltf = GLTFDocument.new()
		state = GLTFState.new()
		if data.type != "vrm":
			state.set_additional_data(&"vrm/already_processed",true)
	
	#if content is String and asset_name in content:
		#state.base_path = content.trim_suffix(asset_name)
	var err :int
	if content is String:
		err = gltf.append_from_file(content, state, flags)
	elif content is PackedByteArray:
		err = gltf.append_from_buffer(content, '', state, flags)
	match err:
		43:
			if "alreadytried" in data:
				return
			data.type = "fbx"
			data.alreadytried = 1
			_import_glb(content, asset_name, data)
			return
	if err != OK:
		if "loader" in data:
			data.loader.done('failed')
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
	data.nolookatuser = true
	_post_import.call_deferred(root, generated_scene, asset_name, data, !data.has("nolookatuser"))

## Import Wavefront .obj files
func _import_obj(path_or_asset: String, asset_name := '', data := {}) -> void:
	# load the file into a mesh
	var logging_prefix := asset_name+" : "
	print("Import OBJ: " + asset_name + " ----------------------")
	
	print(path_or_asset)
	
	var mesh_data := MeshInstance3D.new()
	#this basically checks if its "local"-ish or if it's being fed through the network
	#assuming transmitting the object between clients will become a string
	if(path_or_asset.is_absolute_path() || path_or_asset.is_relative_path()):
		mesh_data.mesh = ObjParse.from_path(path_or_asset)
	else:
		mesh_data.mesh = ObjParse.from_obj_string(path_or_asset)

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
	_post_import.call_deferred(root, tmpbody, asset_name, data, !data.has("nolookatuser"))

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
		_post_import.call_deferred(root,node,asset_name,data, !data.has("nolookatuser"))
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
func _import_image_bytes(asset_name: String, content: PackedByteArray, data:Dictionary={}) -> void:
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
		if err != OK and "image_data" in data and "image_image_alt" in data:
			# Image was not TGA or SVG, test the data argument for image data
			img = bytes_to_var_with_objects(data.image_data)
			if !img.is_empty():
				err = OK
		if err != OK and "image_data" in data:
			var _img_formats_lookup = {"FORMAT_BPTC_RGBA": 22,
			"FORMAT_BPTC_RGBF": 23,
			"FORMAT_BPTC_RGBFU": 24,
			"FORMAT_ETC": 25,
			"FORMAT_ETC2_R11": 26,
			"FORMAT_ETC2_R11S": 27,
			"FORMAT_ETC2_RG11": 28,
			"FORMAT_ETC2_RG11S": 29,
			"FORMAT_ETC2_RGB8": 30,
			"FORMAT_ETC2_RGBA8": 31,
			"FORMAT_ETC2_RGB8A1": 32,
			"FORMAT_ETC2_RA_AS_RG": 33,
			"FORMAT_DXT5_RA_AS_RG": 34,
			"FORMAT_ASTC_4x4": 35,
			"FORMAT_ASTC_4x4_HDR": 36,
			"FORMAT_ASTC_8x8": 37,
			"FORMAT_ASTC_8x8_HDR": 38}
			#for format in img_formats_lookup.keys():
				#if data.image_data.format in format:
					#data.image_data.format = format
					#break
			img = null
			img = Image.new()
			img.data.data = data.image_data
			print('create image from data:')
			print(img.data.size())
			print(img.is_empty())
			err = OK
	
	if err != OK or img.is_empty():
		if "loader" in data:
			data.loader.done('failed')
			printerr("image failed to load:\n",data)
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
	_post_import.call_deferred(root, tmpbody, asset_name, data, !data.has("nolookatuser"))


## Imports an image from an existing image resource.
func _import_image_image(asset_name: String, img: Image, data:Dictionary={}) -> void:
	check_root()
	
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
	_post_import.call_deferred(root, tmpbody, asset_name, data, !data.has("nolookatuser"))

## Imports an audio file.
func _import_audio(asset_name: String, content: PackedByteArray, data:Dictionary={} ) -> void:
	check_root()
	var audio3d: Audio3D = load("res://barkvr-system/ui/3dui/import helpers/audio3d.tscn").instantiate()
	audio3d.load_audio_from_bytes(content, "mp3")
	_post_import.call_deferred(root, audio3d, asset_name, data, !data.has("nolookatuser"))

## Imports some text.
func _import_text(asset_name: String, _content: String, data:Dictionary={} ) -> void:
	check_root()
	var tex := NoiseTexture2D.new()
	var noise := FastNoiseLite.new()
	noise.seed = asset_name.hash()
	tex.height = 100
	tex.width = 100
	tex.noise = noise
	var mesh := MeshInstance3D.new()
	#var tmpmesh := PlaneMesh.new()
	var tmpmesh := TextMesh.new()
	tmpmesh.text = asset_name
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
	_post_import.call_deferred(root, tmpbody, asset_name, data, !data.has("nolookatuser"))

## Imports a file.
func _import_file(asset_name: String, content: PackedByteArray, data:Dictionary={} ) -> void:
	check_root()
	var tex := NoiseTexture2D.new()
	var noise := FastNoiseLite.new()
	noise.seed = asset_name.hash()
	tex.height = 100
	tex.width = 100
	tex.noise = noise
	var plane := MeshInstance3D.new()
	#var tmpmesh := PlaneMesh.new()
	var tmpmesh := TextMesh.new()
	tmpmesh.text = asset_name
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
	
	tmpbody.set_meta("file_bytes",str(content.compress(2)))
	_post_import.call_deferred(root, tmpbody, asset_name, data, !data.has("nolookatuser"))


func _post_import(_rootarget_node:Node,node_to_add:Node,node_name:String,data:Dictionary={},lookatuser:bool=false):
	check_root()
	var position = Vector3()
	if "position" in data:
		position = data.position
	var scale = 1.0
	if "scale" in data:
		scale = data.scale
	root.call_deferred("add_child", node_to_add)
	await get_tree().process_frame
	if node_to_add is Node3D:
		if lookatuser:
			node_to_add.look_at_from_position(position,get_viewport().get_camera_3d().global_position,Vector3.UP,true)
		node_to_add.global_position = position
		node_to_add.scale *= scale
	node_to_add.name = node_name
	print(node_name)
	# add IK stuff if VRM
	if node_name.ends_with(".vrm") or data.type == "vrm":
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
	if "loader" in data:
		data.loader.done()
