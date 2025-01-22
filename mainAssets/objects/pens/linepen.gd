extends StaticBody3D

var pressed := false
var drawing := false

var vertices : PackedVector3Array
var current_meshinstance : MeshInstance3D
var current_amesh : ArrayMesh
var mesh_arrays : Array
var material := StandardMaterial3D.new()

@onready var tippoint: Node3D = $tippoint

func primary() -> void:
	drawing = true
	current_amesh = ArrayMesh.new()
	vertices = PackedVector3Array()
	current_meshinstance = MeshInstance3D.new()
	mesh_arrays = []
	mesh_arrays.resize(Mesh.ARRAY_MAX)
	mesh_arrays[Mesh.ARRAY_VERTEX] = vertices
	get_parent().add_child(current_meshinstance)
	current_meshinstance.material_override = material
	vertices.push_back(current_meshinstance.to_local(tippoint.global_position))
	current_amesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINE_STRIP,mesh_arrays)
	current_meshinstance.mesh = current_amesh

func primary_released() -> void:
	drawing = false

func _process(delta: float) -> void:
	if drawing:
		mesh_arrays[Mesh.ARRAY_VERTEX] = vertices
		vertices.push_back(current_meshinstance.to_local(tippoint.global_position))
		current_amesh.clear_surfaces()
		current_amesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINE_STRIP,mesh_arrays)
		current_meshinstance.mesh = current_amesh
