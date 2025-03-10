extends Button
@onready var text_edit = %messagetext
@onready var item_list = %roomlist
const SEND_SHORTCUT_CTRL_ENTER = preload("res://mainAssets/ui/3dPanel/local ui/login/send_shortcut_ctrl_enter.tres")
const SEND_SHORTCUT_ENTER = preload("res://mainAssets/ui/3dPanel/local ui/login/send_shortcut_enter.tres")
func _ready():
	pressed.connect(ispressed)
	var settings_singleton := Engine.get_singleton("settings_manager")
	if settings_singleton is SettingsSingleton:
		var setsing_casted := settings_singleton as SettingsSingleton
		setsing_casted.changed.connect(func(name: StringName):
			if name == &"send_messages_with_ctrl_enter":
				shortcut = SEND_SHORTCUT_CTRL_ENTER if setsing_casted.send_messages_with_ctrl_enter else SEND_SHORTCUT_ENTER
		)

func ispressed()->void:
	if is_instance_valid(Engine.get_singleton("user_manager")):
		print(text_edit.text.strip_edges())
		Engine.get_singleton("user_manager").send_room_event(item_list.get_selected().get_metadata(0)['room_id'], 'm.room.message', {
		  "body": text_edit.text.strip_edges(),
		  "msgtype": "m.text"
		})
		text_edit.clear()
		text_edit.release_focus()

func _shortcut_input(event: InputEvent) -> void:
	if shortcut.matches_event(event):
		ispressed()
