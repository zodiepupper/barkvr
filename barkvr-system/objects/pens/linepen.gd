extends StaticBody3D

## this pen uses a linemesh to draw

# tracks if the primary button is pressed
var pressed := false
# tracks whether we are currently drawing
var drawing := false

# shared vertex array for keeping track of the mesh
# that is currently being edited
var vertices : PackedVector3Array
# tracks the meshinstance that is currently being edited
var current_meshinstance : MeshInstance3D
# tracks teh current arraymesh
var current_amesh : ArrayMesh
# shared mesh arrays like the vertex array
var mesh_arrays : Array
# shared material for all the drawn meshes
# instantiating this here makes it so all 
# the meshes created with this pen use the 
# same materail
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

func _process(_delta: float) -> void:
	if drawing:
		mesh_arrays[Mesh.ARRAY_VERTEX] = vertices
		vertices.push_back(current_meshinstance.to_local(tippoint.global_position))
		current_amesh.clear_surfaces()
		current_amesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINE_STRIP,mesh_arrays)
		# TODO replace the above two lines with a thing that dynamically extends the
		# length of the vertex array by 1000 and use the update_region function so we 
		# have to update the full surface less often
		current_meshinstance.mesh = current_amesh
