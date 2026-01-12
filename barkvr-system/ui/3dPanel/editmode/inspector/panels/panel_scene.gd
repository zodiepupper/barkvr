extends InspectorPanel



## Signal for node tree selection change.
signal selection_changed(new_selection: Node)

## The 3D gizmo scene.
const GIZMO_SCENE = preload("uid://cv0sjbxpqjy6h")

## The tree's root node.
var root_node: Node

## State on whether reparenting is currently in progress.
var is_reparenting: bool = false
## Array of the last selections in the node tree.
var last_selection_list: Array
## The currently active gizmo on the selected item.
var current_gizmo: BarkGizmo

## The tree used to display the nodes in the scene.
@onready var node_tree: InspectorNodeTree = %NodeTree
## The popup menu used as a context menu.
@onready var local_context_menu: PopupMenu = %PopupMenu
## The menu used to add a node as a child of it's target.
@onready var add_node_menu: Panel = %AddNodeMenu

@onready var search: LineEdit = %Search
@onready var button_add: Button = %ButtonAdd
@onready var button_focus_parent: Button = %ButtonFocusParent



func _ready() -> void:
	_setup_tree()
	_setup_context_menu()

## Set up the node tree, it's root and signals.
func _setup_tree() -> void:
	# Give the node tree a core root, hidden in the actual tree.
	node_tree.create_item()

	# Set local world root as the focus of the tree.
	root_node = get_tree().get_first_node_in_group(&"localworldroot")
	if root_node:
		node_tree.add_item(root_node.name, { "node" : root_node })
	else:
		root_node = get_viewport()
		node_tree.add_item(root_node.name, { "node" : root_node })
	_check_tree_for_updates()

	button_add.pressed.connect(selection_add_child)
	button_focus_parent.pressed.connect(_on_focus_parent_pressed)

	node_tree.cell_selected.connect(_on_tree_cell_selected)
	node_tree.cell_selected.connect(func() -> void: local_context_menu.hide())
	node_tree.button_clicked.connect(_on_tree_button_clicked)

	# SceneTree node changes, to keep the node_tree updated.
	get_tree().node_added.connect(_on_scene_tree_node_added)
	get_tree().node_removed.connect(_on_scene_tree_node_removed)
	get_tree().node_renamed.connect(_on_scene_tree_node_renamed)

## Set up the context menu to be used in the node tree.
func _setup_context_menu() -> void:
	local_context_menu.add_icon_item(get_editor_icon(&"Add"), "Add Child", 11)
	local_context_menu.add_separator()
	local_context_menu.add_icon_item(get_editor_icon(&"Duplicate"), "Duplicate", 21)
	local_context_menu.add_icon_item(get_editor_icon(&"Reparent"), "Reparent", 22)
	local_context_menu.add_separator()
	local_context_menu.add_icon_item(get_editor_icon(&"NewRoot"), "Make Focus", 31)
	local_context_menu.add_separator()
	local_context_menu.add_icon_item(get_editor_icon(&"ExternalLink"), "Export Scene", 41)
	local_context_menu.add_icon_item(get_editor_icon(&"ExternalLink"), "Export GLTF", 42)
	local_context_menu.add_separator()
	local_context_menu.add_icon_item(get_editor_icon(&"Remove"), "Delete", 51)
	local_context_menu.add_separator()
	local_context_menu.add_icon_item(get_editor_icon(&"Close"), "Close Menu")

	local_context_menu.id_pressed.connect(func(index) -> void:
		match index:
			11: selection_add_child()
			21: selection_duplicate()
			22: selection_reparent()
			31: selection_focus()
			41: selection_export()
			42: selection_export(true)
			51: selection_delete()
	)

## Add a child to the currently selected item, opens a new menu for selection.
func selection_add_child() -> void:
	var selected: TreeItem = node_tree.get_next_selected(null)
	if not selected: return

	var selected_node: Node = selected.get_metadata(0).node
	add_node_menu.set_target(selected_node)

	# Reparent AddNodeMenu to the root of the inspector, if it is one.
	# Not foolproof yet, will be improved once custom inspector classes are set up.
	var viewport: Viewport = get_viewport()
	if viewport is SubViewport:
		if viewport.get_child(0) is Control:
			add_node_menu.reparent(viewport.get_child(0))

	add_node_menu.show()

## Duplicate currently selected item.
func selection_duplicate() -> void:
	var selections: Array = get_all_selected()

	for selected_target: TreeItem in selections:
		var target_metadata = selected_target.get_metadata(0)
		if not "node" in target_metadata: continue

		target_metadata.node.get_parent().add_child(target_metadata.node.duplicate())

## Begin reparenting, enables reparenting on next selection.
func selection_reparent() -> void:
	is_reparenting = not is_reparenting

	if is_reparenting:
		snackbar_new("Reparenting, select node to reparent to.", 0)

## Focus currently selected item in the tree (make visible root).
func selection_focus() -> void:
	if !is_instance_valid(node_tree.get_next_selected(null)): return

	var new_target = node_tree.get_next_selected(null).get_metadata(0).node
	node_tree.tree_clear()
	node_tree.create_item().set_text(0, "")
	set_root(new_target)
	node_tree.check_children()

## Export currently selected hierarchy.
func selection_export(as_gltf: bool = false) -> void:
	var world_root: Node = get_tree().get_first_node_in_group(&"localworldroot")
	var target_node: Node = node_tree.get_selected().get_metadata(0).node
	if world_root and target_node:
		WorkerThreadPool.add_task(_export_node.bind(target_node, as_gltf))

## Delete current selection.
func selection_delete() -> void:
	var selections: Array = get_all_selected()

	for item in selections:
		if not "node" in item.get_metadata(0): continue

		item.get_metadata(0).node.queue_free()

## Called upon the Tree's TreeItem being selected.
func _on_tree_cell_selected() -> void:
	# Discard on no selection.
	if !node_tree.get_selected():
		node_tree.check_children()
		return

	var new_selection: Node = node_tree.get_selected().get_metadata(0).node

	# Discard on invalid selected node.
	if !is_instance_valid(new_selection):
		node_tree.check_children()
		return

	selection_changed.emit(new_selection)

	if last_selection_list and new_selection not in last_selection_list and is_reparenting:
		snackbar_clear()

		for item: TreeItem in last_selection_list:
			var item_node: Node = item.get_metadata(0).node
			item_node.owner = item.get_metadata(0).node.get_parent()

			if item_node == new_selection or item_node.is_ancestor_of(new_selection):
				snackbar_new.call_deferred("Cannot reparent node to itself.", 3, get_editor_icon(&"StatusError"))
				continue
			item.get_metadata(0).node.reparent(new_selection)

		_check_tree_for_updates()
		is_reparenting = false

	# Prevent re-generating the gizmo of an already selected item.
	if last_selection_list.size() > 0:
		if node_tree.get_selected() == last_selection_list[0]: return

	last_selection_list = get_all_selected()

	# Clears the currently linked gizmo.
	if is_instance_valid(current_gizmo):
		current_gizmo.queue_free()

	# If the selected node is a Node3D, attach a 3D gizmo.
	if new_selection is Node3D:
		var gizmo: BarkGizmo = GIZMO_SCENE.instantiate()

		gizmo.source = self
		gizmo.target = new_selection
		gizmo.name = "Gizmo"

		root_node.add_child(gizmo)
		current_gizmo = gizmo

## Called upon a TreeItem's button getting pressed.
func _on_tree_button_clicked(item: TreeItem, _column: int, _id: int, _mouse_button_index: int) -> void:
	# Select item that the button belongs to, this is used so the selected item can be used for context actions.
	# The button's item could be stored by itself to be used independently, but this is fine for now.
	node_tree.set_selected(item, 0)

	# Calculate position of the context menu.
	var button_rect: Rect2i = node_tree.get_item_area_rect(item, 0)
	@warning_ignore("integer_division")
	var local_context_menu_position: Vector2i = Vector2i(
		int(node_tree.get_global_rect().position.x + button_rect.end.x),
		int(node_tree.get_global_rect().position.y + button_rect.end.y - (button_rect.size.y / 2))
	)
	# TODO: Popup function should make the menu disappear when user clicks outside of popup, however, it does not.
	# It appears as if any form of 3DUI via a SubViewport breaks popups this way.
	local_context_menu.popup(Rect2i(local_context_menu_position, Vector2i.ZERO))



func _on_scene_tree_node_added(node: Node) -> void:
	if not is_inside_tree(): return

	await get_tree().process_frame

	if not root_node: return
	if not is_instance_valid(node): return
	if not root_node.is_ancestor_of(node): return

	var node_name: String = node.name
	if node.has_meta(&"display_name"):
		node_name = node.get_meta(&"display_name")

	node_tree.add_item(node_name, {
		"node" : node,
		"parent" : node.get_parent()
	})

## Sync tree with scene tree by removing deleted nodes.
func _on_scene_tree_node_removed(node: Node) -> void:
	node_tree.remove_item(node)

## Sync tree when nodes are renamed.
func _on_scene_tree_node_renamed(node: Node) -> void:
	if not root_node: return
	if not is_instance_valid(node): return

	node_tree.update_item(node)



func _check_tree_for_updates():
	if not is_instance_valid(root_node): return

	set_root(root_node)
	node_tree.check_children()

## Set the root of the tree and generate its children.
func set_root(item: Node):
	root_node = item
	add_children(item)

func add_children(node: Node, parent: Node = null):
	var nodename: String = node.name
	if node.has_meta("display_name"):
		nodename = node.get_meta("display_name")

	if parent:
		node_tree.add_item(nodename, {
			"node" : node,
			"parent" : parent,
		})
	else:
		node_tree.add_item(nodename, {
			"node" : node,
		})

	if node.get_child_count() > 0:
		while !is_inside_tree(): pass
		await get_tree().process_frame

		if not is_instance_valid(node): return

		for i: Node in node.get_children():
			add_children(i, node)

## Get all currently selected items as an array.
func get_all_selected(previous_item: TreeItem = null) -> Array:
	var return_array := Array()
	var next = node_tree.get_next_selected(previous_item)
	if next:
		return_array.append(next)
		return_array.append_array(get_all_selected(next))
	return return_array



## Focus the parent of the currently focused node (make visible root).
func _on_focus_parent_pressed() -> void:
	if !root_node.get_parent(): return

	node_tree.tree_clear()
	node_tree.create_item().set_text(0, "")
	set_root(root_node.get_parent())
	node_tree.check_children()

## Export the target node's hierarchy to the user's download folder, either as a scene or gltf.
func _export_node(target_node: Node, to_gltf: bool = false):
	Thread.set_thread_safety_checks_enabled(false)

	var download_folder_path: String = OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS) + "/"

	if not OS.get_name() == "Web" and not DirAccess.dir_exists_absolute(download_folder_path):
		snackbar_new.call_deferred("Error during export. Couldn't access download folder.", 3, get_editor_icon(&"StatusError"))
		return

	Engine.get_singleton(&"event_manager").take_owner_of_node_and_all_children(target_node, target_node)

	if to_gltf: # Export as GLTF.
		var gltf_doc := GLTFDocument.new()
		var gltf_state := GLTFState.new()
		gltf_doc.append_from_scene(target_node, gltf_state)
		if OS.get_name() == "Web":
			JavaScriptBridge.download_buffer(gltf_doc.generate_buffer(gltf_state), target_node.name + ".res")
		else:
			gltf_doc.write_to_filesystem(gltf_state, download_folder_path + target_node.name + ".glb")
			snackbar_new.call_deferred("Export saved as: " + download_folder_path + target_node.name + ".glb", 3, get_editor_icon(&"StatusSuccess"))

	else: # Export as scene.
		var packed := PackedScene.new()
		packed.pack(target_node)
		if OS.get_name() == "Web":
			JavaScriptBridge.download_buffer(var_to_bytes_with_objects(packed), target_node.name + ".res")
		else:
			var err: Error = ResourceSaver.save(packed, download_folder_path + target_node.name + ".tscn", ResourceSaver.FLAG_BUNDLE_RESOURCES)
			if err:
				snackbar_new.call_deferred("Error during export. " + str(err), 3, get_editor_icon(&"StatusError"))
			else:
				snackbar_new.call_deferred("Export saved as: " + download_folder_path + target_node.name + ".tscn", 3, get_editor_icon(&"StatusSuccess"))
