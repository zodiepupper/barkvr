extends Control

## A theme containing all of the godot default icons, used to display node types in the item list.
const GODOT_EDITOR_ICON_THEME = preload("uid://b34aw2colacks")

var target : Node
var event_manager : Bark_Journal

## Used to track the time since the last item selection.
## item_activated signal in 3DUI issue workaround.
var double_click_timer : SceneTreeTimer
## Used to track the last selected class.
## item_activated signal in 3DUI issue workaround.
var last_selected_class : String

@onready var window_icon: TextureRect = %WindowIcon

@onready var search_bar: LineEdit = %SearchBar
@onready var item_list: ItemList = %ItemList

@onready var button_close: Button = %ButtonClose
@onready var button_confirm: Button = %ButtonConfirm
@onready var button_cancel: Button = %ButtonCancel



func _ready() -> void:
	event_manager = Engine.get_singleton(&"event_manager")
	print("event supplier: " + str(event_manager))

	_setup_icons()
	_load_class_list()

	button_close.pressed.connect(close)
	button_cancel.pressed.connect(close)
	button_confirm.pressed.connect(add_selected_node)

	search_bar.text_changed.connect(_on_search_bar_edited)
	search_bar.text_submitted.connect(_on_search_bar_submitted)
	item_list.item_selected.connect(_on_item_list_item_selected)

	# item_activated just does not work with 3DUI apparently, real fun.
	# Currently using a custom double click checker using item_selected.
	#item_list.item_activated.connect(_on_item_list_item_activated)

## Set up dynamic icons loaded from the editor theme or project settings.
func _setup_icons() -> void:
	window_icon.set_texture(load(ProjectSettings.get_setting("application/config/icon")))
	search_bar.set_right_icon(GODOT_EDITOR_ICON_THEME.get_icon(&"Search", &"EditorIcons"))
	button_close.set_button_icon(GODOT_EDITOR_ICON_THEME.get_icon(&"Close", &"EditorIcons"))

## Load the initial, unfiltered, class list.
func _load_class_list() -> void:
	for cls : String in ClassDB.get_class_list() + Bark_Journal.extra_classes:
		if not ClassDB.is_parent_class(cls, &"Node") and not cls in Bark_Journal.extra_classes: continue

		add_class_to_item_list(cls)

	item_list.select(0)



func set_target(item : Node) -> void:
	target = item



## Confirm selection and add it to the target as a child.
func add_selected_node() -> void:
	if not is_instance_valid(target): return
	if not is_instance_valid(event_manager): return

	var selected_item_list : PackedInt32Array = item_list.get_selected_items()
	if selected_item_list.is_empty(): return

	var selected_index : int = selected_item_list[0]
	var selected_class : String = item_list.get_item_text(selected_index)

	event_manager.add_node(event_manager.root.get_path_to(target),{
		"node_class" : selected_class,
		"properties" : [
			{
				"name" : "metadata/display_name",
				"value" : selected_class
			}
		]
	})
	close()

## Hide the menu and reset selection to the first list item.
func close() -> void:
	item_list.deselect_all()
	item_list.select(0)
	hide()

## Add an item to the item list with class_string as the type.
func add_class_to_item_list(class_string : String) -> void:
	if GODOT_EDITOR_ICON_THEME.has_icon(class_string, &"EditorIcons"):
		item_list.add_item(class_string, GODOT_EDITOR_ICON_THEME.get_icon(class_string, &"EditorIcons"))
	else: # Fallback.
		item_list.add_item(class_string, GODOT_EDITOR_ICON_THEME.get_icon(&"Node", &"EditorIcons"))



## Search through the item list.
func _on_search_bar_edited(search_text : String) -> void:
	search_text = search_text.to_lower()

	# Deselect items and clear list.
	item_list.deselect_all()
	item_list.clear()

	var filtered_list := Array()
	var class_list : PackedStringArray = ClassDB.get_class_list()
	class_list.append_array(Bark_Journal.extra_classes)

	for class_string : String in class_list:
		if ( # Discard unfit classes.
				not ClassDB.is_parent_class(class_string, &"Node")
				and not class_string in Bark_Journal.extra_classes
		): continue

		var contains_all_chars := true
		var class_string_lower := class_string.to_lower()
		for character in search_text:
			if !class_string_lower.contains(character):
				contains_all_chars = false
				break
		if (
				contains_all_chars
				or class_string_lower.contains(search_text)
				or class_string_lower.similarity(search_text) > .6
		):
			filtered_list.append(class_string)

	# Sort the list to make the "most accurate" result the top item.
	filtered_list.sort_custom(func(a : String, b : String) -> bool:
		return true if search_text.similarity(a.to_lower()) > search_text.similarity(b.to_lower()) else false
	)
	# Populate list with search matches.
	for item : String in filtered_list:
		add_class_to_item_list(item)

	# Select the first item to prevent no items being selected.
	if item_list.item_count > 0:
		item_list.select(0)

## Called when enter is pressed while the search bar is focused.
## Function exists due to add_selected_node not having any args.
func _on_search_bar_submitted(_text : String) -> void:
	add_selected_node()

## Called when an item is selected, used to detect double clicks.
func _on_item_list_item_selected(index :int) -> void:
	var current_selected_class : String = item_list.get_item_text(index)

	# Double click success.
	if double_click_timer and last_selected_class == current_selected_class:
		add_selected_node()
		double_click_timer = null
		return

	# Enable double click timer.
	last_selected_class = current_selected_class
	double_click_timer = get_tree().create_timer(0.5)
	double_click_timer.timeout.connect(func() -> void: double_click_timer = null)
