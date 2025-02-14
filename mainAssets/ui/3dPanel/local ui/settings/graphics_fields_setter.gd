extends VBoxContainer

@onready var anti_aliasing: Enum_Attribute = $"anti aliasing"

# MSAA_DISABLED = 0
# MSAA_2X = 1
# MSAA_4X = 2
# MSAA_8X = 3
# MSAA_MAX = 4

var MSAA_STRINGS: String = "MSAA_DISABLED, MSAA_2X, MSAA_4X, MSAA_8X, MSAA_MAX"

func _ready() -> void:
	anti_aliasing.set_data("anti aliasing",\
	 get_window(),\
	 "msaa_3d",\
	 {"hint_string": MSAA_STRINGS}\
	)
