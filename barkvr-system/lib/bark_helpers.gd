class_name BarkvrHelpers
extends Node

## this function allows us to take in the bytes of a file and pattern match to see
## if it can be identified by the magics below (magics being our known headers for each
## filetype)
func detect_file_type_from_header(content:PackedByteArray) -> String:
	
	var format_signatures = [
		### barkjournal (.bj)
		{
			"type":'bj',
			"magics": [
				
			]
		},
		### WEBP
		{
			"type":'img',
			"magics": [
				[0x52, 0x49, 0x46, 0x46, null, null, null, null, 0x57, 0x45, 0x42, 0x50],
				]
		},
		### PNG
		{
			"type":'img',
			"magics": [
				[0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A],
				]
		},
		### BMP
		{
			"type":'img',
			"magics": [
				[0x42, 0x4D],
				]
		},
		### TGA does not have a static header
		
		### JPG
		{
			"type":'img',
			# I think there are other possible magics
			# This could possibly miss some kinds of JPEGs!
			# TODO: Add more JPEG magics
			"magics": [
				[0xFF, 0xD8, 0xFF, 0xE0],
				]
		},
		### SVG does not have a static header
		
		### KTX
		{
			"type":'img',
			"magics": [
				[0xAB, 0x4B, 0x54, 0x58, 0x20, 0x31, 0x31, 0xBB, 0x0D, 0x0A, 0x1A, 0x0A],
				]
		},
		
		### MeshX
		{
			"type":'rpkg',
			"magics": [
				[0x05, 0x4d, 0x65, 0x73, 0x68, 0x58],
				]
		}
	]
	
	# Check each signature on the image to find a match
	for signature in format_signatures:
		var magics = signature.magics
					
		# loop over all known magic numbers for the filetype
		for magic in magics:
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
					# return the corresponding type string
					if signature.type == "meshx":
						Notifyvr.send_notification("meshx detected")
					return signature.type
	
	return ""

func normalize_float32_array(array:PackedFloat32Array):
	# holder for normalized array
	var norm_array :PackedFloat32Array = PackedFloat32Array(array)
	# magnitude
	var mag = 0.0
	# create some vars for intermediate math
	var a = 0.0
	# use pythagorian theorem to calculate the ^2 length of vector
	for i in array:
		a += pow(i,2)
	# root the ^2 length of the array to get it's length
	mag = sqrt(a)
	for i in norm_array.size():
		norm_array[i] = norm_array[i]/mag
	return norm_array

func normalize_float64_array(array:PackedFloat64Array):
	# holder for normalized array
	var norm_array :PackedFloat64Array = PackedFloat64Array(array)
	# magnitude
	var mag = 0.0
	# create some vars for intermediate math
	var a = 0.0
	# use pythagorian theorem to calculate the ^2 length of vector
	for i in array:
		a += pow(i,2)
	# root the ^2 length of the array to get it's length
	mag = sqrt(a)
	for i in norm_array.size():
		norm_array[i] = norm_array[i]/mag
	return norm_array

func float64_array_size(array:PackedFloat64Array):
	# magnitude
	var mag = 0.0
	# create some vars for intermediate math
	var a = 0.0
	# use pythagorian theorem to calculate the ^2 length of vector
	for i in array:
		a += pow(i,2)
	# root the ^2 length of the array to get it's length
	mag = sqrt(a)
	return mag

func float32_array_size(array:PackedFloat32Array):
	# magnitude
	var mag = 0.0
	# create some vars for intermediate math
	var a = 0.0
	# use pythagorian theorem to calculate the ^2 length of vector
	for i in array:
		a += pow(i,2)
	# root the ^2 length of the array to get it's length
	mag = sqrt(a)
	return mag

## a helper to automatically join threads that are finished processing
## back with the main thread. 
func rejoin_thread_when_finished(thread: Thread) -> void:
	# if the thread has been started and is still alive...
	if thread and thread.is_started() and thread.is_alive():
		# create a timer that runs this function again once the time runs out
		get_tree().create_timer(1).timeout.connect(rejoin_thread_when_finished.bind(thread))
		# return to break out of this instance of the function
		return
	# otherwise, rejoin the thread with the main thread
	thread.wait_to_finish()


## helpers to automatically load and unload the VRM plugin gltf stuff so it 
## doesn't get in the way when importing


# here we are just loading all the vrm extensions manually so they are bound for every import.
# we probably shouldn't do this but i found an interesting benefit in that if a user
# exports as a GLTF/GLB but the file data still includes the vrm metadata and nodes then
# having these available for every import means it will still import the avatar properly
## loading vrm extensions
static var vrm_ext_vrm_extension_0_script = load("res://addons/vrm/vrm_extension.gd")
static var vrm_ext_vrm_extension_0
## loading vrm extensions
static var vrm_ext_emmissive_multiplier_script = load("res://addons/vrm/1.0/VRMC_materials_hdr_emissiveMultiplier.gd")
static var vrm_ext_emmissive_multiplier
## loading vrm extensions
static var vrm_ext_materials_mtoon_script = load("res://addons/vrm/1.0/VRMC_materials_mtoon.gd")
static var vrm_ext_materials_mtoon
## loading vrm extensions
static var vrm_ext_node_constraint_script = load("res://addons/vrm/1.0/VRMC_node_constraint.gd")
static var vrm_ext_node_constraint
## loading vrm extensions
static var vrm_ext_springbone_script = load("res://addons/vrm/1.0/VRMC_springBone.gd")
static var vrm_ext_springbone
## loading vrm extensions
static var vrm_ext_vrm_script = load("res://addons/vrm/1.0/VRMC_vrm.gd")
static var vrm_ext_vrm
## loading vrm extensions
static var vrm_ext_vrm_animation_script = load("res://addons/vrm/1.0/VRMC_vrm_animation.gd")
static var vrm_ext_vrm_animation

static func enable_vrm_gltf():
	vrm_ext_vrm_extension_0 = vrm_ext_vrm_extension_0_script.new()
	vrm_ext_emmissive_multiplier = vrm_ext_emmissive_multiplier_script.new()
	vrm_ext_materials_mtoon = vrm_ext_materials_mtoon_script.new()
	vrm_ext_node_constraint = vrm_ext_node_constraint_script.new()
	vrm_ext_springbone = vrm_ext_springbone_script.new()
	vrm_ext_vrm = vrm_ext_vrm_script.new()
	vrm_ext_vrm_animation = vrm_ext_vrm_animation_script.new()
	# here we load the vrm extensions we reference at the top of the file
	GLTFDocument.register_gltf_document_extension(vrm_ext_vrm_extension_0,true)
	GLTFDocument.register_gltf_document_extension(vrm_ext_emmissive_multiplier, true)
	GLTFDocument.register_gltf_document_extension(vrm_ext_materials_mtoon, true)
	GLTFDocument.register_gltf_document_extension(vrm_ext_node_constraint, true)
	GLTFDocument.register_gltf_document_extension(vrm_ext_springbone, true)
	GLTFDocument.register_gltf_document_extension(vrm_ext_vrm, true)
	GLTFDocument.register_gltf_document_extension(vrm_ext_vrm_animation, true)

static func disable_vrm_gltf():
	# here we load the vrm extensions we reference at the top of the file
	GLTFDocument.unregister_gltf_document_extension(vrm_ext_vrm_extension_0)
	GLTFDocument.unregister_gltf_document_extension(vrm_ext_emmissive_multiplier)
	GLTFDocument.unregister_gltf_document_extension(vrm_ext_materials_mtoon)
	GLTFDocument.unregister_gltf_document_extension(vrm_ext_node_constraint)
	GLTFDocument.unregister_gltf_document_extension(vrm_ext_springbone)
	GLTFDocument.unregister_gltf_document_extension(vrm_ext_vrm)
	GLTFDocument.unregister_gltf_document_extension(vrm_ext_vrm_animation)
