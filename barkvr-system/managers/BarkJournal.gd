## BarkJournal is the class that manages all the actions and history that happens
## during a session, whether it be only a local scene or a shared session with 
## other players
##
## rigth now, this handles the journal and imports. this will be changed in the future to move
## the import stuff to a different class. the goal is to make it so, instead of 
## sending the full file that we imported and allowing each client to import that
## file locally to replicate the netwroked scene, we want to process it (hopefully
## outside of the tree or something) so we can turn it into events compatible with 
## the journal. this sentiment may change in the future, but that's the thought right now.
## this journal implementation is a prototype of our initial approach to concepting
## how we could build out a PAXOS-like datamodel for the shared environment.
class_name BarkJournal
extends Node

#TODO: REWRITE
# basically, the goals are to build a journal that accepts events and attempts to apply
# those events to the scene in a way that is consistent on every machine
#
# we want events for script stuff
# we want the ability to add custom events (for worlds)
# apply instantly, locally
# (MAYBE) rollback
# if a collision happens, take them in order of seniority (otherwise, pick random)
# branching
# exporting as a file

# TODO WHY THE FUCK DID I PUT THE IMPORT LOGIC IN HERE UGHHHHH

## base class for journal events in barkvr
class BarkJournalEvent:
	enum type{ADD_NODE, DELETE_NODE, REMOVE_NODE_FROM_TREE, REPARENT_NODE, CALL_ON_NODE, SET_PROPERTY}

static var current_bark_journal: BarkJournal

## tracks all historical actions
var actions: Array[Dictionary] = []
## holder for actions that have been undone (intended to be used for the redo operation)
var undid_actions: Array[Dictionary] = []
## holder for incoming actions that need to be processed
var new_actions: Array[Dictionary] = []

## mutex for processing actions for multithreaded stability
var actions_mutex := Mutex.new()

# TODO: this still needs to actually be implemented. ideally, we want to use the journal 
# to process the shared state so we can have inspectors and other stuff just ask
# the journal for the current state of the tree. right now, we just have the inspector as
# a self contained object that reads the tree and operates against it on it's own. but that
# isn't the best design, so we intend to move it here so it can be central and processed
# immediately rather than latently, which reduces a massive amount of performance overhead 
# with the inspectors.
## holder which loads the journal_tree class
var JournalTreeClass = load("uid://km5yk6l5xyvc")
## holder for the actual instance of the journal tree
var journal_tree: Node 

## a list of extra classes that can be considered when processing some events.
## this allows us to have pre-made stuff available without needing to serialize them
## although we will turn these into bark journal assets that can be loaded within
## the journal context fully. this is currently used to allow the add_node stuff
## to show and instantiate bark-specific classes
static var extra_classes : PackedStringArray = [
	"Panel3D",
	"ParticlePen",
	"LinePen",
	"WindowCamera3D"
]

## accompanying list of where to get the files associated with the classes
## in the array above
static var extra_classes_spawn : Array[PackedScene] = [
	load("res://addons/Panel3D/Panel3D.tscn"),
	load("uid://og3t2qnt8ukh"), # particle pen
	load("uid://dj84bcm2jv1wq"), # linepen
	load("uid://bay38na2jeq1o") # placeable camera (WindowCamera3D)
]

# TODO: we should simplify this because we definitely don't need a check_root, _get_root, and a getter for the root variable lol
## holder for finding the shared root "localworldroot"
var root: Node:
	get:
		if !is_instance_valid(root):
			_get_root()
		return root

## holder for the root of the client scenetree itself (normally the main window)
var local_root: Node:
	get:
		return get_tree().root

## this is written a little confusingly, but this just is a quick check
## for us to know if the journal event we recieved is properly contained within
## the shared root and isn't a remote change to the local portion of the tree
func is_path_remote(path:NodePath):
	# create holder for the target node
	var target_node :Node
	# try to get the target node
	target_node = root.get_node_or_null(path)
	# if we find a node with the path, then we check if the shared root is
	# an ancestor of it
	if target_node != null and root.is_ancestor_of(target_node):
		# if it is an ancestor, then return true
		return true
	# otherwise, return false
	return false

func _ready() -> void:
	# when the journal is ready we want to find the shared root
	check_root()
	# and create our journal tree (for centrally tracking the local tree)
	journal_tree = JournalTreeClass.new()
	add_child(journal_tree)
	# set the static variable to this instance so we can access it from anywhere
	current_bark_journal = self

## this is a helper to add a new event into the journal
## accepts the action requested and whether it is an undo operation
func _add_action(data:Dictionary, undid:=false) -> void:
	actions_mutex.lock()
	if undid:
		#undid_actions.append(data)
		new_actions.append(data)
	else:
		actions.append(data)
		new_actions.append(data)
	actions_mutex.unlock()

## undoes the most recent action that is able to be undone
func undo_action() -> void:
	# checks that the shared root is still valid
	check_root()
	# lock mutex for thread safety
	actions_mutex.lock()
	# if the list of actions isn't empty
	if !actions.is_empty():
		# pop the most recent action to remove and return it
		var action_to_undo :Dictionary = actions.pop_back()
		# if it's valid
		if action_to_undo and "action_name" in action_to_undo:
			# run appropriate method to actualize the action
			match action_to_undo.action_name:
				'set_property':
					set_property(action_to_undo.target, action_to_undo.prop_name, action_to_undo.previous_value, false, true)
				'delete_node':
					pass
				'add_node':
					pass
	# unlock mutex so something else can run
	actions_mutex.unlock()

## this is a helper function used by the networking code to ask for all the new actions
## that need to be sent over the network
func get_actions() -> Array[Dictionary]:
	actions_mutex.lock()
	var tmp := new_actions.duplicate(true)
	new_actions.clear()
	actions_mutex.unlock()
	return tmp

## chekcs if the shared root is valid and if it isn't, we try to find it
func check_root() -> void:
	if !is_instance_valid(root):
		_get_root()

## attempts to query the tree for the shared root
func _get_root() -> void:
	root = get_tree().get_first_node_in_group('localworldroot')

# TODO create function to iterate over the current scene and prepare it for remote syncing
func _prepare_existing_tree_for_remote_sync() -> void:
	pass

## this runs the action of reparenting a node in the shared root
func set_parent(target: NodePath, new_parent: NodePath) -> void:
	# is the shared root valid?
	check_root()
	# find the node we are operating on
	var target_node := root.get_node(target)
	# find the new parent
	var np_node := root.get_node(new_parent)
	# reparent the targeted node to the new parent
	target_node.reparent(np_node)
	# add the action to the journal
	actions.append({
		'action_name': 'set_parent',
		'target': target,
		'new_parent': new_parent
	})

# TODO: we should do some of this in a gdextension so we can have direct memory creation access.
# doing so will allow us to create the nodes with the correct data immediately rather than doing it
# in gdscript and facing issues where gdscript is intentionally restricted (reasonably so in many cases)
# from some things since this is beyond the scope of what gdscript is intended to do.
## Adds a node to the scene[br]
## should provide the nodepath for the node that will be the parent of the added
## nodes.[br]
## the nodes dictionary should be a heirarchy that directly reflects the desired
## node heirarchy once added to the scene and have parameters as follows:
## [code] {node_class: "ClassStringForThisNode", properties: ArrayOfPropertyDictionaries, children: ArrayOfChildren}
## [br]the array of property dictionaries should be an array of dictionaries 
## where each dictionary contains {name: "property_name", value: "property_value"}
## [br]the array of children should be an array of nodes with an identical format
## to the example dictionary.
## [br]if you do not wish to change the properties from default you can exclude the properties array
## [br]if you do not wish to have children added to a given node, you can exclude the children array
## [br]node_class is always required
## [br]if you would like to add metadata to the node use "metadata/property_name"
## as the name for the property so it will get parsed as a metadata property
func add_node(parent: NodePath, nodes:Dictionary, recieved := false, undid := false):
	# check root validity
	check_root()
	# get the node we are attempting to operate on/under
	var p_node := root.get_node(parent)
	# if it returns a valid node...
	if is_instance_valid(p_node):
		# process the action into nodes outside of the tree
		var target_node :Node = _read_add_node_nodes_dict(nodes, recieved)
		# if the event isn't remote
		if !recieved:
			# i don't even know, this is some schizo bullshit that we need to rewrie i think.
			# even if this is valid code, this sucks and we shouldn't write code like this ngl
			while p_node.has_node("./"+target_node.name):
				# intended to generate a sufficient hash name for the node to mitigate 
				# node path struggles from years ago.
				var placeholder_name :String=  str(str(str(nodes.node_class) + str( str(nodes) + str( Time.get_unix_time_from_system() + float(Time.get_ticks_usec()) ))).hash())
				# set the new node's name
				target_node.name = placeholder_name
				# process the node properties and apply them to the node we just created.
				# some more crazy shit i wrote that needs to be fixed
				if "properties" in nodes:
					nodes.properties.append({"name":"name","value":placeholder_name})
				else:
					nodes.properties = [{"name":"name","value":placeholder_name}]
		# add the new node as a child of the designated parent node
		p_node.add_child(target_node)
		# if not a remote action and not an undo, then add it to the journal such that it will be
		# synced over the network
		if !recieved and !undid:
			_add_action({
				'action_name': 'add_node',
				'parent': parent,
				'added_node_path': root.get_path_to(target_node),
				'nodes': nodes
			})
		# if it is an undo, then add it to the journal with the undid flag enabled
		if undid:
			_add_action({
				'action_name': 'add_node',
				'parent': parent,
				'added_node_path': root.get_path_to(target_node),
				'nodes': nodes
			},true)

# TODO: replace the use of a dictionary with a class so it can have a fixed and documentable schema
## this method is intended to accept a dictionary of nodes to be added to the shared root
## and turn them from a dictionary of data into actual nodes to add
## documenting this method is a bit of a frivilous effort, look at the inline doc of the above function 
## for more info on what this is looking for
func _read_add_node_nodes_dict(node_dict:Dictionary, recieved:=false) -> Node:
	# check that the shared root is valid
	check_root()
	if "node_class" in node_dict and (ClassDB.can_instantiate(node_dict.node_class) or node_dict.node_class in extra_classes):
		var node : Node
		if node_dict.node_class in extra_classes:
			node = extra_classes_spawn[extra_classes.find(node_dict.node_class)].instantiate()
		node = ClassDB.instantiate(node_dict.node_class) if !node else node
		var _node_props = node.get_property_list()
		if "properties" in node_dict and node_dict.properties is Array:
			for prop in node_dict.properties:
				if prop is Dictionary and "name" in prop and "value" in prop:
					if prop.name in node and !(typeof(node[prop.name]) in [TYPE_CALLABLE, TYPE_OBJECT, TYPE_SIGNAL]):
						node[prop.name] = prop.value
					elif prop.name.begins_with('metadata/'):
						node.set_meta(prop.name.trim_prefix("metadata/"), prop.value)
		if !recieved:
			var placeholder_name :String= str(str(str(node_dict.node_class) + str( str(node) + str( Time.get_unix_time_from_system() + float(Time.get_ticks_usec()) ))).hash())
			if "properties" in node_dict:
				node_dict.properties.append({"name":"name","value":placeholder_name})
			else:
				node_dict.properties = [{"name":"name","value":placeholder_name}]
			node.name = placeholder_name
		if "children" in node_dict:
			for child in node_dict.children:
				node.add_child(_read_add_node_nodes_dict(child))
				
		return node
	var tmp = Node.new()
	tmp.name = "ERROR"
	return tmp

## runs the delete node action
func delete_node(target: NodePath, recieved := false, undid := false) -> void:
	# check if root is valid
	check_root()
	# find the target node
	var target_node := root.get_node(target)
	# this is intended to pack the node into a scene so it can used when the
	# user wants to undo a deletion but this is tough in gdscript and a lil fickle
	# create packed scene we will use
	var deleted_node_as_packed_scene := PackedScene.new()
	# call our helper to set the node as "owner" of all the nodes beneath it.
	# we do this because a node packed into a scene will only include nodes that have
	# it set as their owner (and *allegedly* all the nodes that those are owners of
	# but that didn't work when i created this)
	take_owner_of_node_and_all_children(target_node, target_node)
	# TODO: do something with this packedscene ffs
	# pack the node into the PackedScene so we can save it
	deleted_node_as_packed_scene.pack(target_node)
	# delete the node
	target_node.queue_free()
	# if not remote add the actuion to the queue
	if !recieved:
		_add_action({
			'action_name': 'delete_node',
			'target': target,
			'deleted_node': target_node.name#Marshalls.variant_to_base64(deleted_node_as_packed_scene,true)
		})

## sets a property of the target node in the shared scene
func set_property(target: NodePath, prop_name: String, value: Variant, recieved := false, undid := false) -> void:
	check_root()
	# get the target node
	var target_node := root.get_node(target)
	# if the node is valid and the property path exists in the target...
	if is_instance_valid(target_node) and prop_name.split(':')[0] in target_node:
		# capture the previous value for undoing
		var previous_value = target_node.get_indexed(prop_name)
		# this sets the property to the value we have
		target_node.set_indexed(prop_name,value)
		# if not remote or undid, then we add it to the journal
		if !recieved and !undid:
			_add_action({
				'action_name': 'set_property',
				'target': target,
				'prop_name': prop_name,
				'value': value,
				'previous_value': previous_value
			})
		# if it's an undo, we add it with the journal with the undo flag
		if undid:
			_add_action({
				'action_name': 'set_property',
				'target': target,
				'prop_name': prop_name,
				'value': value,
				'previous_value': previous_value
			},true)

## helper method to set a node as the owner of all nested nodes
func take_owner_of_node_and_all_children(node:Node,new_owner:Node):
	check_root()
	# set owner of targeted node
	node.owner = new_owner
	# iterate over all children recursively
	if node.get_child_count() > 0:
		for child in node.get_children():
			take_owner_of_node_and_all_children(child, new_owner)

## this is deprecated and will be removed soon. it's need will vanish once the networking overhaul is finished
func net_propagate_node(node_string: String, parent := ^'', node_name := '', recieved := false) -> void:
	check_root()
	if node_name.is_empty():
		node_name = node_string.sha256_text()
	var node = BarkHelpers.var_to_node(node_string)
	if parent:
		root.get_node(parent).add_child(node)
		if !recieved:
			actions.append({
				'action_name': 'net_propagate_node',
				'node_string': node_string,
				'parent': parent
			})
	else:
		root.add_child(node)
		if !recieved:
			actions.append({
				'action_name': 'net_propagate_node',
				'node_string': node_string
			})

## Accept an incoming network message and handle it appropriately.
func receive(action: Dictionary) -> void:
	check_root()
	if "content" in action and !action.content.is_empty():
		action.asset_to_import = action.content
	match action.action_name:
		"set_property":
			set_property(action.target, action.prop_name, action.value, true)
		"import_asset":
			BarkvrImportManager.current_instance.import_asset(action.type, action.asset_to_import, action.asset_name, true, action.data)
		"delete_node":
			delete_node(action.target, true)
		"add_node":
			add_node(action.parent,action.nodes,true)
