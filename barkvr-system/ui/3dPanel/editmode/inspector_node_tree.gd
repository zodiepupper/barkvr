class_name InspectorNodeTree
extends Tree

## Dictionary to hold all objects, data & TreeItem.
var tree_dict : Dictionary[int, Dictionary] = {}

## Clear TreeItems & internal dictionary.
func hashed_tree_clear():
	tree_dict.clear()
	clear()

## Add an item to the tree.
func add_item(text : String, metadata : Variant, _replace : String = '') -> TreeItem:
	# Return if node in metadata is missing/invalid.
	if !metadata: return
	if !metadata.has('node'): return
	if !is_instance_valid(metadata.node): return

	# TreeItem to return at the end of the function.
	var return_tree_item : TreeItem

	var item_id = metadata.node.get_instance_id()
	# Update & reparent item if it already exists in the tree.
	if tree_dict.has(item_id):
		if metadata.has('parent'):
			var parent_item : TreeItem = tree_dict[item_id].tree_item.get_parent()
			if is_instance_valid(parent_item):
				parent_item.remove_child(tree_dict[item_id].tree_item)
			tree_dict[metadata.parent.get_instance_id()].tree_item.add_child(tree_dict[item_id].tree_item)

		return_tree_item = tree_dict[item_id].tree_item
		return_tree_item.set_text(0, text)
		return_tree_item.set_metadata(0, metadata)

	# Create item if it doesn't exist in tree yet.
	else:
		tree_dict[item_id] = {
			'node' : metadata.node
		}
		if metadata.has('parent'):
			if !tree_dict.has(metadata.parent.get_instance_id()):
				add_item(metadata.parent.name, {
					'node' : metadata.parent,
					'parent' : metadata.parent.get_parent()
				})

			var parent_item : TreeItem = tree_dict[metadata.parent.get_instance_id()].tree_item
			return_tree_item = create_item(parent_item)
			#return_tree_item.add_button(0,load("res://assets/icons/teenyicons/solid/bin.svg"))
			tree_dict[item_id].tree_item = return_tree_item

		else:
			tree_dict[item_id].tree_item = create_item()
			#tree_dict[item_id].tree_item.add_button(0,load("res://assets/icons/teenyicons/solid/bin.svg"))
		#if metadata.node.has_method('equip_to_local_user'):
			#tree_dict[item_id].tree_item.add_button(0, load("res://assets/icons/teenyicons/outline/drag.svg"), -1, false, "equip avatar")

		var target_item : TreeItem = tree_dict[item_id].tree_item
		target_item.collapsed = true
		get_root().get_child(0).collapsed = false
		target_item.set_text(0, text)
		target_item.set_metadata(0, metadata)

	return return_tree_item

## Remove invalid children with node metadata.
func check_children() -> void:
	for key : int in tree_dict:
		if !tree_dict[key].has('node') ||\
			is_instance_valid(tree_dict[key].node): return

		if is_instance_valid(tree_dict[key].tree_item):
			tree_dict[key].tree_item.free()
		tree_dict.erase(key)

## Remove an item from the tree, target can either be Node or String.
func remove_item(target : Variant) -> void:
	if target is Node:
		var node : Node = target
		var item_id := node.get_instance_id()
		if tree_dict.has(item_id):
			if is_instance_valid(tree_dict[item_id].tree_item):
				tree_dict[item_id].tree_item.free()
			tree_dict.erase(item_id)

	# Why String?
	elif target is String:
		if tree_dict.has(target):
			if is_instance_valid(tree_dict[target].tree_item):
				tree_dict[target].tree_item.free()
			tree_dict.erase(target)

## Update text of a certain node's TreeItem.
func update_item(node : Node) -> void:
	var item_id : int = node.get_instance_id()
	if !tree_dict.has(item_id): return
	if !is_instance_valid(tree_dict[item_id].tree_item): return

	if node.has_meta("display_name"):
		tree_dict[item_id].tree_item.set_text(0, node.get_meta("display_name"))
	else:
		tree_dict[item_id].tree_item.set_text(0, node.name)
