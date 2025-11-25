extends Control

## The tree used to display the nodes in the scene.
@onready var node_tree: InspectorNodeTree = $NodeTree

var root_node : Node

var is_reparenting : bool = false
var last_selection_list : Array

signal selection_changed(new_selection : Node)



func _ready() -> void:
	_setup_tree()

## Set up the node tree, it's root and signals.
func _setup_tree() -> void:
	# Give the node tree a core root, hidden in the actual tree.
	node_tree.create_item()

	# Set local world root as the focus of the tree.
	root_node = get_tree().get_first_node_in_group(&"localworldroot")
	node_tree.add_item(root_node.name, {'node' : root_node})
	_check_tree_for_updates()

	node_tree.cell_selected.connect(_on_tree_cell_selected)

	get_tree().node_added.connect(_on_scene_tree_node_added)
	get_tree().node_removed.connect(_on_scene_tree_node_removed)
	get_tree().node_renamed.connect(_on_scene_tree_node_renamed)

func _on_tree_cell_selected() -> void:
	var new_selection = node_tree.get_selected().get_metadata(0).node
	selection_changed.emit(new_selection)
	if last_selection_list and new_selection not in last_selection_list and is_reparenting:
		for item : TreeItem in last_selection_list:
			item.get_metadata(0).node.owner = item.get_metadata(0).node.get_parent()
			item.get_metadata(0).node.reparent(new_selection)
		_check_tree_for_updates()
		#reparent_btn.button_pressed = false
	last_selection_list = get_all_selected()
	LocalGlobals.clear_gizmos.emit()
	if !node_tree.get_selected():
		node_tree.check_children()
		return
	var node = node_tree.get_selected().get_metadata(0).node
	if !is_instance_valid(node):
		node_tree.check_children()
		return
	if node is Node3D:
		var giz = load("res://barkvr-system/objects/tools/gizmo/gizmo.tscn").instantiate()
		root_node.add_child(giz)
		giz.global_position = node.global_position
		giz.target = node
		giz.name = "gizmo"

func _on_scene_tree_node_added(node : Node) -> void:
	if is_inside_tree():
		await get_tree().process_frame
		if root_node:
			if is_instance_valid(node) and root_node.is_ancestor_of(node):
				var nodename :String = node.name
				if node.has_meta('display_name'):
					nodename = node.get_meta('display_name')
				node_tree.add_item(nodename, {
					'node':node,
					'parent':node.get_parent()
				})

func _on_scene_tree_node_removed(node : Node) -> void:
	node_tree.remove_item(node)

func _on_scene_tree_node_renamed(node : Node) -> void:
	if root_node:
		if is_instance_valid(node):
			node_tree.update_item(node)

func _check_tree_for_updates():
	if is_instance_valid(root_node):
		set_root(root_node)
		node_tree.check_children()

func set_root(item : Node):
	root_node = item
	add_children(item)

func add_children(node : Node, parent : Node = null):
	var nodename :String = node.name
	var _tree_item: TreeItem
	if node.has_meta("display_name"):
		nodename = node.get_meta("display_name")
	if parent:
		_tree_item = node_tree.add_item(nodename, {
			'node':node,
			'parent':parent,
		})
	else:
		_tree_item = node_tree.add_item(nodename,{
			'node':node
		})
	if node.get_child_count() > 0:
		while !is_inside_tree():
			pass
		await get_tree().process_frame
		if is_instance_valid(node):
			for i in node.get_children():
				add_children(i, node)

func get_all_selected(previous_item : TreeItem = null) -> Array:
	var out : Array = []
	var next = node_tree.get_next_selected(previous_item)
	if next:
		out.append(next)
		out.append_array(get_all_selected(next))
	return out
