extends Control

## Signal for node tree selection change.
signal selection_changed(new_selection : Node)

## A theme containing all of the godot default icons, might be best to make this global someday.
const GODOT_EDITOR_ICON_THEME = preload("uid://b34aw2colacks")
## The 3D gizmo scene.
const GIZMO_SCENE = preload("uid://cv0sjbxpqjy6h")

## The tree's root node.
var root_node : Node

## State on whether reparenting is currently in progress.
var is_reparenting : bool = false
## Array of the last selections in the node tree.
var last_selection_list : Array

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
	search.set_right_icon(GODOT_EDITOR_ICON_THEME.get_icon(&"Search", &"EditorIcons"))

	_setup_tree()
	_setup_context_menu()

## Set up the node tree, it's root and signals.
func _setup_tree() -> void:
	# Give the node tree a core root, hidden in the actual tree.
	node_tree.create_item()

	# Set local world root as the focus of the tree.
	root_node = get_tree().get_first_node_in_group(&"localworldroot")
	node_tree.add_item(root_node.name, { "node" : root_node })
	_check_tree_for_updates()

	button_add.pressed.connect(selection_add_child)
	button_focus_parent.pressed.connect(_on_focus_parent_pressed)

	node_tree.cell_selected.connect(_on_tree_cell_selected)
	node_tree.cell_selected.connect(func() -> void: local_context_menu.hide())
	node_tree.button_clicked.connect(_on_tree_button_clicked)

	get_tree().node_added.connect(_on_scene_tree_node_added)
	get_tree().node_removed.connect(_on_scene_tree_node_removed)
	get_tree().node_renamed.connect(_on_scene_tree_node_renamed)

## Set up the context menu to be used in the node tree.
func _setup_context_menu() -> void:
	local_context_menu.add_icon_item(GODOT_EDITOR_ICON_THEME.get_icon(&"Add", &"EditorIcons"), "Add Child", 11)
	local_context_menu.add_separator()
	local_context_menu.add_icon_item(GODOT_EDITOR_ICON_THEME.get_icon(&"Duplicate", &"EditorIcons"), "Duplicate", 21)
	local_context_menu.add_icon_item(GODOT_EDITOR_ICON_THEME.get_icon(&"Reparent", &"EditorIcons"), "Reparent", 22)
	local_context_menu.add_separator()
	local_context_menu.add_icon_item(GODOT_EDITOR_ICON_THEME.get_icon(&"NewRoot", &"EditorIcons"), "Make Focus", 31)
	local_context_menu.add_separator()
	local_context_menu.add_icon_item(GODOT_EDITOR_ICON_THEME.get_icon(&"ExternalLink", &"EditorIcons"), "Export Scene", 41)
	local_context_menu.add_icon_item(GODOT_EDITOR_ICON_THEME.get_icon(&"ExternalLink", &"EditorIcons"), "Export GLTF", 42)
	local_context_menu.add_separator()
	local_context_menu.add_icon_item(GODOT_EDITOR_ICON_THEME.get_icon(&"Remove", &"EditorIcons"), "Delete", 51)
	local_context_menu.add_separator()
	local_context_menu.add_icon_item(GODOT_EDITOR_ICON_THEME.get_icon(&"Close", &"EditorIcons"), "Close Menu")

	local_context_menu.id_pressed.connect(func(index) -> void:
		match index:
			11: selection_add_child()
			21: selection_duplicate()
			22: is_reparenting = !is_reparenting
			31: selection_focus()
			41: selection_export()
			42: selection_export(true)
			51: selection_delete()
	)

func selection_add_child() -> void:
	var selected : TreeItem = node_tree.get_next_selected(null)
	if !selected: return

	var target : Node = selected.get_metadata(0).node
	add_node_menu.set_target(target)
	add_node_menu.show()

func selection_duplicate() -> void:
	var selections : Array = get_all_selected()
	for selected_target in selections:
		if "node" in selected_target.get_metadata(0):
			selected_target.get_metadata(0).node.get_parent().add_child(selected_target.get_metadata(0).node.duplicate())

func selection_focus() -> void:
	if !is_instance_valid(node_tree.get_next_selected(null)): return

	var new_target = node_tree.get_next_selected(null).get_metadata(0).node
	node_tree.hashed_tree_clear()
	node_tree.create_item().set_text(0, "")
	set_root(new_target)
	node_tree.check_children()

func selection_export(as_gltf : bool = false) -> void:
	var world_root : Node = get_tree().get_first_node_in_group(&"localworldroot")
	var target: Node = node_tree.get_selected().get_metadata(0).node
	if world_root and target:
		WorkerThreadPool.add_task(_export_node.bind(target, as_gltf))

func selection_delete() -> void:
	var selections : Array = get_all_selected()
	for item in selections:
		if "node" in item.get_metadata(0):
			item.get_metadata(0).node.queue_free()

func _on_tree_cell_selected() -> void:
	var new_selection = node_tree.get_selected().get_metadata(0).node
	selection_changed.emit(new_selection)
	if last_selection_list and new_selection not in last_selection_list and is_reparenting:
		for item : TreeItem in last_selection_list:
			item.get_metadata(0).node.owner = item.get_metadata(0).node.get_parent()
			item.get_metadata(0).node.reparent(new_selection)
		_check_tree_for_updates()
		is_reparenting = false
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
		var giz = GIZMO_SCENE.instantiate()
		root_node.add_child(giz)
		giz.global_position = node.global_position
		giz.target = node
		giz.name = "Gizmo"

## Called upon a TreeItem's button getting pressed.
func _on_tree_button_clicked(item: TreeItem, _column: int, _id: int, _mouse_button_index: int) -> void:
	# Select item that the button belongs to, this is used so the selected item can be used for context actions.
	# The button's item could be stored by itself to be used independently, but this is fine for now.
	node_tree.set_selected(item, 0)

	# Calculate position of the context menu.
	var button_rect : Rect2i = node_tree.get_item_area_rect(item, 0)
	@warning_ignore("integer_division")
	var local_context_menu_position : Vector2i = Vector2i(
		int(node_tree.get_global_rect().position.x + button_rect.end.x),
		int(node_tree.get_global_rect().position.y + button_rect.end.y - (button_rect.size.y / 2))
	)
	# TODO: Popup function should make the menu disappear when user clicks outside of popup, however, it does not.
	# It appears as if any form of 3DUI via a SubViewport breaks popups this way.
	local_context_menu.popup(Rect2i(local_context_menu_position, Vector2i.ZERO))

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

func _on_focus_parent_pressed() -> void:
	if !root_node.get_parent(): return

	node_tree.hashed_tree_clear()
	node_tree.create_item().set_text(0, "")
	set_root(root_node.get_parent())
	node_tree.check_children()

## Export the target hierarchy to the user's download folder, either as a scene or gltf.
func _export_node(target : Node, to_gltf : bool = false):
	Thread.set_thread_safety_checks_enabled(false)

	var download_folder_path : String = OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS) + "/"
	print("Export save path: " + download_folder_path + target.name + ".tscn")

	if not OS.get_name() == "Web" and not DirAccess.dir_exists_absolute(download_folder_path): return

	Engine.get_singleton(&"event_manager").take_owner_of_node_and_all_children(target, target)

	if to_gltf:
		var gltf_doc := GLTFDocument.new()
		var gltf_state := GLTFState.new()
		gltf_doc.append_from_scene(target, gltf_state)
		if OS.get_name() == "Web":
			JavaScriptBridge.download_buffer(gltf_doc.generate_buffer(gltf_state), target.name + ".res")
		else:
			gltf_doc.write_to_filesystem(gltf_state, download_folder_path + target.name + ".glb")
			# Left over from before rewrite.
			#var err = ResourceSaver.save(packed, downpath+tmp_target.name+".tscn",ResourceSaver.FLAG_BUNDLE_RESOURCES)

	else:
		var packed := PackedScene.new()
		packed.pack(target)
		if OS.get_name() == "Web":
			JavaScriptBridge.download_buffer(var_to_bytes_with_objects(packed), target.name + ".res")
		else:
			var err : Error = ResourceSaver.save(packed, download_folder_path + target.name + ".tscn", ResourceSaver.FLAG_BUNDLE_RESOURCES)
			if err: print("Export error: " + str(err))
