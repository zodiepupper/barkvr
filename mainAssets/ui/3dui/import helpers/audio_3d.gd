extends StaticBody3D
class_name Audio3D

@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D
@onready var mesh_instance_3d: MeshInstance3D = $MeshInstance3D
@onready var audio_stream_player_3d: AudioStreamPlayer3D = $AudioStreamPlayer3D

var audio_stream : AudioStream

var loaded_audio : Dictionary

func _ready() -> void:
	if loaded_audio:
		_load_audio_from_bytes(loaded_audio.bytes, loaded_audio.type)

## loads an audio clip from bytes
## accpets bytes:PackedByteArray which is the bytes of the audio file
## and a type:String which can be mp3, wav, ogg
func load_audio_from_bytes(bytes:PackedByteArray, type:String):
	if is_node_ready():
		_load_audio_from_bytes(bytes, type)
	else:
		loaded_audio.bytes = bytes
		loaded_audio.type = type

func _load_audio_from_bytes(bytes:PackedByteArray, type:String):
	#audio_stream = AudioStreamMP3.load_from_buffer(bytes)
	printerr(type)
	audio_stream = AudioStreamMP3.new()
	audio_stream.data = bytes
	audio_stream_player_3d.stream = audio_stream
	audio_stream_player_3d.play()
