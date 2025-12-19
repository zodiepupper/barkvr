class_name ScriptMenuBar
extends MenuBar
## A custom class to handle popup management in the script editor.
## Due to the impractical ID system that popup items use,
## this file has been made to manage all of it in one place.



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

func _setup_file_menu() -> void:
	file.add_item("New Script...", 11)
	file.add_item("New Text File...", 12)
	file.add_item("Open...", 13)
	file.add_item("Reopen Closed Script", 14)
	# TODO: Auto-generate sub-popup list.
	var sub_popup_recent := PopupMenu.new()
	file.add_submenu_node_item("Open Recent", sub_popup_recent, 15)

	file.add_separator()
	file.add_item("Save", 21)
	file.add_item("Save As...", 22)
	file.add_item("Save All", 23)

	file.add_separator()
	file.add_item("Soft Reload Tool Script", 31)
	file.add_item("Copy Script Path", 32)
	file.add_item("Copy Script UID", 33)
	file.add_item("Show in FileSystem", 34)

	file.add_separator()
	file.add_item("History Previous", 41)
	file.add_item("History Next", 42)

	file.add_separator()
	var sub_popup_theme := PopupMenu.new()
	sub_popup_theme.add_item("Import Theme...")
	sub_popup_theme.add_item("Reload Theme")
	sub_popup_theme.add_separator()
	sub_popup_theme.add_item("Save Theme As...")
	file.add_submenu_node_item("Theme", sub_popup_theme, 51)

	file.add_separator()
	file.add_item("Close", 61)
	file.add_item("Close All", 62)
	file.add_item("Close Other Tabs", 63)
	file.add_item("Close Tabs Below", 64)
	file.add_item("Close Docs", 65)

	file.add_separator()
	file.add_item("Run", 71)

	file.add_separator()
	file.add_item("Toggle Files Panel", 81)

func _setup_edit_menu() -> void:
	edit.add_item("Undo", 11)
	edit.add_item("Redo", 12)

	edit.add_separator()
	edit.add_item("Cut", 21)
	edit.add_item("Copy", 22)
	edit.add_item("Paste", 23)

	edit.add_separator()
	edit.add_item("Select All", 31)
	edit.add_item("Duplicate Selection", 32)
	edit.add_item("Duplicate Lines", 33)
	edit.add_item("Evaluate Selection", 34)
	edit.add_item("Toggle Word Wrap", 35)

	edit.add_separator()
	var sub_popup_line := PopupMenu.new()
	sub_popup_line.add_item("Move Up")
	sub_popup_line.add_item("Move Down")
	sub_popup_line.add_item("Indent")
	sub_popup_line.add_item("Unindent")
	sub_popup_line.add_item("Delete Line")
	sub_popup_line.add_item("Toggle Comment")
	edit.add_submenu_node_item("Line", sub_popup_line, 41)

	var sub_popup_folding := PopupMenu.new()
	sub_popup_folding.add_item("Fold/Unfold Line")
	sub_popup_folding.add_item("Fold All Lines")
	sub_popup_folding.add_item("Unfold All Lines")
	sub_popup_folding.add_item("Create Code Region")
	edit.add_submenu_node_item("Folding", sub_popup_folding, 42)

	edit.add_separator()
	edit.add_item("Completion Query", 51)
	edit.add_item("Trim Trailing Whitespace", 52)
	edit.add_item("Trim Final Newlines", 53)

	var sub_popup_indentation := PopupMenu.new()
	sub_popup_indentation.add_item("Convert Indent to Spaces")
	sub_popup_indentation.add_item("Convert Indent to Tabs")
	sub_popup_indentation.add_item("Auto Indent")
	edit.add_submenu_node_item("Indentation", sub_popup_indentation, 54)

	edit.add_separator()
	var sub_popup_convert_case := PopupMenu.new()
	sub_popup_convert_case.add_item("Uppercase")
	sub_popup_convert_case.add_item("Lowercase")
	sub_popup_convert_case.add_item("Capitalize")
	edit.add_submenu_node_item("Convert Case", sub_popup_convert_case, 61)

	var sub_popup_syntax_highlighter := PopupMenu.new()
	sub_popup_syntax_highlighter.add_radio_check_item("Plain Text")
	sub_popup_syntax_highlighter.add_radio_check_item("Standard")
	sub_popup_syntax_highlighter.add_radio_check_item("JSON")
	sub_popup_syntax_highlighter.add_radio_check_item("Markdown")
	sub_popup_syntax_highlighter.add_radio_check_item("ConfigFile")
	sub_popup_syntax_highlighter.add_radio_check_item("GDScript")
	edit.add_submenu_node_item("Syntax Highlighter", sub_popup_syntax_highlighter, 62)

func _setup_search_menu() -> void:
	search.add_item("Find...", 11)
	search.add_item("Find Next", 12)
	search.add_item("Find Previous", 13)
	search.add_item("Replace...", 14)

	search.add_separator()
	search.add_item("Find in Files...", 21)
	search.add_item("Replace in Files...", 22)

	search.add_separator()
	search.add_item("Contextual Help", 31)

func _setup_go_to_menu() -> void:
	go_to.add_item("Go to Function...", 11)
	go_to.add_item("Go to Line...", 12)
	go_to.add_item("Lookup Symbol", 13)

	go_to.add_separator()
	var sub_popup_bookmarks := PopupMenu.new()
	sub_popup_bookmarks.add_item("Toggle Bookmark")
	sub_popup_bookmarks.add_item("Remove All Bookmarks")
	sub_popup_bookmarks.add_item("Go to Next Bookmark")
	sub_popup_bookmarks.add_item("Go to Previous Bookmark")
	go_to.add_submenu_node_item("Bookmarks", sub_popup_bookmarks, 21)

	var sub_popup_breakpoints := PopupMenu.new()
	sub_popup_breakpoints.add_item("Toggle Breakpoint")
	sub_popup_breakpoints.add_item("Remove All Breakpoints")
	sub_popup_breakpoints.add_item("Go to Next Breakpoint")
	sub_popup_breakpoints.add_item("Go to Previous Breakpoint")
	go_to.add_submenu_node_item("Breakpoints", sub_popup_breakpoints, 22)

func _setup_debug_menu() -> void:
	debug.add_item("Step Into", 11)
	debug.add_item("Step Over", 12)

	debug.add_separator()
	debug.add_item("Break", 21)
	debug.add_item("Continue", 22)

	debug.add_separator()
	debug.add_check_item("Debug with External Editor", 31)
