extends Control
@onready var tree : hashed_tree_list = %Tree
@onready var tree_root : TreeItem = tree.create_item()

signal selected(item)
var root:Node

var create_node := preload("res://mainAssets/ui/3dPanel/editmode/popup/add_node.tscn")

@onready var delete: Button = $HBoxContainer/VBoxContainer/delete
@onready var export: Button = $HBoxContainer/VBoxContainer/export
@onready var duplicate: Button = $HBoxContainer/VBoxContainer/duplicate
@onready var cut: Button = $HBoxContainer/VBoxContainer/cut
@onready var copy: Button = $HBoxContainer/VBoxContainer/copy
@onready var paste: Button = $HBoxContainer/VBoxContainer/paste

func _ready():
	delete.pressed.connect(func():
		var selected = get_all_selected()
		for item in selected:
			if "node" in item.get_metadata(0):
				item.get_metadata(0).node.queue_free()
		pass
		)
	
	#print(tree.get_class())
	tree.cell_selected.connect(func():
		selected.emit(tree.get_selected().get_metadata(0).node)
		LocalGlobals.clear_gizmos.emit()
		var node = tree.get_selected().get_metadata(0).node
		if !is_instance_valid(node):
			tree.check_children()
			return
		if node is Node3D:
			var giz = load("res://mainSystem/scenes/objects/tools/gizmo/gizmo.tscn").instantiate()
			root.add_child(giz)
			giz.global_position = node.global_position
			giz.target = node
			giz.name = "gizmo"
		)
	#var root = get_tree().get_first_node_in_group('localworldroot')
	root = get_window()
	tree.add_item(root.name,{
		'node':root
	})
	_check_tree_for_updates()
	get_tree().node_added.connect(func(node:Node):
		await get_tree().process_frame
		if root:
			if is_instance_valid(node) and root.is_ancestor_of(node):
				var nodename :String = node.name
				if node.has_meta('display_name'):
					nodename = node.get_meta('display_name')
				tree.add_item(nodename, {
					'node':node,
					'parent':node.get_parent()
				})
		)
	get_tree().node_renamed.connect(func(node:Node):
		#print('node renamed')
		await get_tree().process_frame
		if root:
			if is_instance_valid(node):
				tree.update_item(node)
		)
	get_tree().node_removed.connect(func(node:Node):
		tree.remove_item(node)
		)

func _check_tree_for_updates():
	if is_instance_valid(root):
		setRoot(root)
		tree.check_children()

func init():
#	tree.clear()
	tree_root = tree.create_item()
	tree_root.set_text(0,"")

func setRoot(item:Node):
	addchildren(item)

func addchildren(node:Node, parent:Node=null):
	var nodename :String = node.name
	if node.has_meta("display_name"):
		nodename = node.get_meta("display_name")
	if parent:
		tree.add_item(nodename, {
			'node':node,
			'parent':parent,
		})
	else:
		tree.add_item(nodename,{
			'node':node
		})
	if node.get_child_count() > 0:
		await get_tree().process_frame
		if is_instance_valid(node):
			for i in node.get_children():
				addchildren(i,node)

func get_all_selected(previous_item: TreeItem = null) -> Array:
	var out = Array()
	var next = tree.get_next_selected(previous_item)
	if next:
		out.append(next)
		out.append_array(get_all_selected(next))
	return out

#func export_selected() -> void:
	#var world_root = get_tree().get_first_node_in_group("localworldroot")
	#if world_root and target:
		#var thread = Thread.new()
		#thread.start(_export_node.bind(target))
		#BarkHelpers.rejoin_thread_when_finished(thread)
