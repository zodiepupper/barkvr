extends StaticBody3D

@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D
@onready var mesh_instance_3d: MeshInstance3D = $MeshInstance3D
@onready var audio_stream_player_3d: AudioStreamPlayer3D = $AudioStreamPlayer3D

var audio_strem : AudioStream

func _ready() -> void:
	pass

## loads an audio clip from bytes
## accpets bytes:PackedByteArray which is the bytes of the audio file
## and a type:String which can be mp3, wav, ogg
func load_audio_from_bytes(bytes:PackedByteArray, type:String):
	pass

func laser_input(data: Dictionary):
	print(data)
