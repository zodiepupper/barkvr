class_name ScriptMenuBar
extends MenuBar
## A custom class to handle popup management in the script editor.
## Due to the impractical ID system that popup items use,
## this file has been made to manage all of it in one place.



signal file_save
signal file_save_all
signal file_close
signal file_close_all
signal file_close_other
signal file_close_below
signal file_close_docs
signal file_toggle_side_panel

@onready var file: PopupMenu = %File
@onready var edit: PopupMenu = %Edit
@onready var search: PopupMenu = %Search
@onready var go_to: PopupMenu = %"Go To"
@onready var debug: PopupMenu = %Debug



func _ready() -> void:
	_setup_file_menu()
	_setup_edit_menu()
	_setup_search_menu()
	_setup_go_to_menu()
	_setup_debug_menu()

	_setup_signals()

	#disable_all_items()



func _setup_signals() -> void:
	file.id_pressed.connect(_on_file_id_pressed)
	edit.id_pressed.connect(_on_edit_id_pressed)
	search.id_pressed.connect(_on_search_id_pressed)
	go_to.id_pressed.connect(_on_go_to_id_pressed)
	debug.id_pressed.connect(_on_debug_id_pressed)

func _setup_file_menu() -> void:
	var popup: PopupMenu = file

	popup.add_item("New Script...", 11)
	popup.add_item("New Text File...", 12)
	popup.add_item("Open...", 13)
	popup.add_item("Reopen Closed Script", 14)
	# TODO: Auto-generate sub-popup list.
	var sub_popup_recent := PopupMenu.new()
	popup.add_submenu_node_item("Open Recent", sub_popup_recent, 15)

	popup.add_separator()
	popup.add_item("Save", 21)
	popup.add_item("Save As...", 22)
	popup.add_item("Save All", 23)

	popup.add_separator()
	popup.add_item("Soft Reload Tool Script", 31)
	popup.add_item("Copy Script Path", 32)
	popup.add_item("Copy Script UID", 33)
	popup.add_item("Show in FileSystem", 34)

	popup.add_separator()
	popup.add_item("History Previous", 41)
	popup.add_item("History Next", 42)

	popup.add_separator()
	var sub_popup_theme := PopupMenu.new()
	sub_popup_theme.add_item("Import Theme...")
	sub_popup_theme.add_item("Reload Theme")
	sub_popup_theme.add_separator()
	sub_popup_theme.add_item("Save Theme As...")
	popup.add_submenu_node_item("Theme", sub_popup_theme, 51)

	popup.add_separator()
	popup.add_item("Close", 61)
	popup.add_item("Close All", 62)
	popup.add_item("Close Other Tabs", 63)
	popup.add_item("Close Tabs Below", 64)
	popup.add_item("Close Docs", 65)

	popup.add_separator()
	popup.add_item("Run", 71)

	popup.add_separator()
	popup.add_item("Toggle Files Panel", 81)

func _setup_edit_menu() -> void:
	var popup: PopupMenu = edit

	popup.add_item("Undo", 11)
	popup.add_item("Redo", 12)

	popup.add_separator()
	popup.add_item("Cut", 21)
	popup.add_item("Copy", 22)
	popup.add_item("Paste", 23)

	popup.add_separator()
	popup.add_item("Select All", 31)
	popup.add_item("Duplicate Selection", 32)
	popup.add_item("Duplicate Lines", 33)
	popup.add_item("Evaluate Selection", 34)
	popup.add_item("Toggle Word Wrap", 35)

	popup.add_separator()
	var sub_popup_line := PopupMenu.new()
	sub_popup_line.add_item("Move Up")
	sub_popup_line.add_item("Move Down")
	sub_popup_line.add_item("Indent")
	sub_popup_line.add_item("Unindent")
	sub_popup_line.add_item("Delete Line")
	sub_popup_line.add_item("Toggle Comment")
	popup.add_submenu_node_item("Line", sub_popup_line, 41)

	var sub_popup_folding := PopupMenu.new()
	sub_popup_folding.add_item("Fold/Unfold Line")
	sub_popup_folding.add_item("Fold All Lines")
	sub_popup_folding.add_item("Unfold All Lines")
	sub_popup_folding.add_item("Create Code Region")
	popup.add_submenu_node_item("Folding", sub_popup_folding, 42)

	popup.add_separator()
	popup.add_item("Completion Query", 51)
	popup.add_item("Trim Trailing Whitespace", 52)
	popup.add_item("Trim Final Newlines", 53)

	var sub_popup_indentation := PopupMenu.new()
	sub_popup_indentation.add_item("Convert Indent to Spaces")
	sub_popup_indentation.add_item("Convert Indent to Tabs")
	sub_popup_indentation.add_item("Auto Indent")
	popup.add_submenu_node_item("Indentation", sub_popup_indentation, 54)

	popup.add_separator()
	var sub_popup_convert_case := PopupMenu.new()
	sub_popup_convert_case.add_item("Uppercase")
	sub_popup_convert_case.add_item("Lowercase")
	sub_popup_convert_case.add_item("Capitalize")
	popup.add_submenu_node_item("Convert Case", sub_popup_convert_case, 61)

	var sub_popup_syntax_highlighter := PopupMenu.new()
	sub_popup_syntax_highlighter.add_radio_check_item("Plain Text")
	sub_popup_syntax_highlighter.add_radio_check_item("Standard")
	sub_popup_syntax_highlighter.add_radio_check_item("JSON")
	sub_popup_syntax_highlighter.add_radio_check_item("Markdown")
	sub_popup_syntax_highlighter.add_radio_check_item("ConfigFile")
	sub_popup_syntax_highlighter.add_radio_check_item("GDScript")
	popup.add_submenu_node_item("Syntax Highlighter", sub_popup_syntax_highlighter, 62)

func _setup_search_menu() -> void:
	var popup: PopupMenu = search

	popup.add_item("Find...", 11)
	popup.add_item("Find Next", 12)
	popup.add_item("Find Previous", 13)
	popup.add_item("Replace...", 14)

	popup.add_separator()
	popup.add_item("Find in Files...", 21)
	popup.add_item("Replace in Files...", 22)

	popup.add_separator()
	popup.add_item("Contextual Help", 31)

func _setup_go_to_menu() -> void:
	var popup: PopupMenu = go_to

	popup.add_item("Go to Function...", 11)
	popup.add_item("Go to Line...", 12)
	popup.add_item("Lookup Symbol", 13)

	popup.add_separator()
	var sub_popup_bookmarks := PopupMenu.new()
	sub_popup_bookmarks.add_item("Toggle Bookmark")
	sub_popup_bookmarks.add_item("Remove All Bookmarks")
	sub_popup_bookmarks.add_item("Go to Next Bookmark")
	sub_popup_bookmarks.add_item("Go to Previous Bookmark")
	popup.add_submenu_node_item("Bookmarks", sub_popup_bookmarks, 21)

	var sub_popup_breakpoints := PopupMenu.new()
	sub_popup_breakpoints.add_item("Toggle Breakpoint")
	sub_popup_breakpoints.add_item("Remove All Breakpoints")
	sub_popup_breakpoints.add_item("Go to Next Breakpoint")
	sub_popup_breakpoints.add_item("Go to Previous Breakpoint")
	popup.add_submenu_node_item("Breakpoints", sub_popup_breakpoints, 22)

func _setup_debug_menu() -> void:
	var popup: PopupMenu = debug

	popup.add_item("Step Into", 11)
	popup.add_item("Step Over", 12)

	popup.add_separator()
	popup.add_item("Break", 21)
	popup.add_item("Continue", 22)

	popup.add_separator()
	popup.add_check_item("Debug with External Editor", 31)



func disable_all_items() -> void:
	var popup_list: Array[PopupMenu] = [
		file,
		edit,
		search,
		go_to,
		debug,
	]
	for popup: PopupMenu in popup_list:
		for index: int in popup.item_count:
			if popup.is_item_separator(index): continue
			popup.set_item_disabled(index, true)

func close_all_popups() -> void:
	for child in get_children():
		if child is PopupMenu:
			child.hide()



func _on_file_id_pressed(id: int) -> void:
	match id:
		21: file_save.emit()
		23: file_save_all.emit()
		61: file_close.emit()
		62: file_close_all.emit()
		63: file_close_other.emit()
		64: file_close_below.emit()
		65: file_close_docs.emit()
		81: file_toggle_side_panel.emit()

func _on_edit_id_pressed(id: int) -> void:
	match id:
		11: pass
		12: pass

func _on_search_id_pressed(id: int) -> void:
	match id:
		11: pass
		12: pass

func _on_go_to_id_pressed(id: int) -> void:
	match id:
		11: pass
		12: pass

func _on_debug_id_pressed(id: int) -> void:
	match id:
		31:
			var item_index: int = debug.get_item_index(31)
			debug.set_item_checked(item_index, not debug.is_item_checked(item_index))
