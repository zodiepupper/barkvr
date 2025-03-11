extends Control
class_name SettingsMenu

@onready var restart_in_vr_button := $ScrollContainer/VBoxContainer/GeneralSettingsMargin/GeneralSettings/RestartInVR/RestartInVR/Button as Button
@onready var passthrough_button := $ScrollContainer/VBoxContainer/VRSettingsMargin/VRSettings/Passthrough/Passthrough/Toggle as Button
@onready var passthrough_rect := $ScrollContainer/VBoxContainer/VRSettingsMargin/VRSettings/Passthrough/Passthrough/Toggle/ColorRect as ColorRect
@onready var hand_tracking_button := $ScrollContainer/VBoxContainer/VRSettingsMargin/VRSettings/HandTracking/HandTracking/Toggle as Button
@onready var hand_tracking_rect := $ScrollContainer/VBoxContainer/VRSettingsMargin/VRSettings/HandTracking/HandTracking/Toggle/ColorRect as ColorRect
@onready var local_menu_lookat_x_button := $ScrollContainer/VBoxContainer/UISettingsMargin/UISettings/LocalMenuLookAtAxisToggles/Position/XVBox/XVal as Button
@onready var local_menu_lookat_x_rect := $ScrollContainer/VBoxContainer/UISettingsMargin/UISettings/LocalMenuLookAtAxisToggles/Position/XVBox/XVal/ColorRect as ColorRect
@onready var local_menu_lookat_y_button := $ScrollContainer/VBoxContainer/UISettingsMargin/UISettings/LocalMenuLookAtAxisToggles/Position/YVbox/YVal as Button
@onready var local_menu_lookat_y_rect := $ScrollContainer/VBoxContainer/UISettingsMargin/UISettings/LocalMenuLookAtAxisToggles/Position/YVbox/YVal/ColorRect as ColorRect
@onready var local_menu_lookat_z_button := $ScrollContainer/VBoxContainer/UISettingsMargin/UISettings/LocalMenuLookAtAxisToggles/Position/ZVbox/ZVal as Button
@onready var local_menu_lookat_z_rect := $ScrollContainer/VBoxContainer/UISettingsMargin/UISettings/LocalMenuLookAtAxisToggles/Position/ZVbox/ZVal/ColorRect as ColorRect
@onready var ctrl_enter_button := $ScrollContainer/VBoxContainer/ChatSettingsMargin/ChatSettings/CtrlEnter/Toggle as Button
@onready var inspector_update_interval_spinbox := $ScrollContainer/VBoxContainer/UISettingsMargin/UISettings/InspectorUpdateInterval/SpinBox as SpinBox
@onready var scaling_slider := $ScrollContainer/VBoxContainer/GraphicsMargin/Graphics/ViewportScaling/HSlider as HSlider
@onready var anti_aliasing_dropdown := ($ScrollContainer/VBoxContainer/GraphicsMargin/Graphics/AntiAliasing as Enum_Attribute).val

func set_button(button_ref: Button, rect_ref: ColorRect, toggled_on: bool, on_color: Color) -> void:
	button_ref.button_pressed = toggled_on
	button_ref.text = "is enabled" if toggled_on else "is disabled"
	rect_ref.color = on_color if toggled_on else Color.GRAY

func tween_button(button_ref: Button, rect_ref: ColorRect, toggled_on: bool, on_color: Color) -> void:
	create_tween().tween_property(button_ref, ^"text", "is enabled" if toggled_on else "is disabled", 0.5)
	create_tween().tween_property(rect_ref, ^"color", on_color if toggled_on else Color.GRAY, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

func _ready() -> void:
	var anti_aliasing_control := $ScrollContainer/VBoxContainer/GraphicsMargin/Graphics/AntiAliasing as Enum_Attribute
	anti_aliasing_control.label.text = "Anti Aliasing"
	anti_aliasing_control.property_name = "msaa_3d"
	anti_aliasing_control.val.add_item("MSAA_DISABLED")
	anti_aliasing_control.val.add_item("MSAA_2X")
	anti_aliasing_control.val.add_item("MSAA_4X")
	anti_aliasing_control.val.add_item("MSAA_8X")
	anti_aliasing_control.val.add_item("MSAA_MAX")
	anti_aliasing_control.target = get_window()
	
	if LocalGlobals.vr_supported:
		($ScrollContainer/VBoxContainer/GeneralSettingsMargin/GeneralSettings/RestartInVR as VBoxContainer).hide()
	var settings_singleton := Engine.get_singleton("settings_manager")
	if settings_singleton is SettingsSingleton:
		var setsing_casted := settings_singleton as SettingsSingleton
		set_button(passthrough_button, passthrough_rect, setsing_casted.vr_passthrough, Color.GREEN)
		set_button(hand_tracking_button, hand_tracking_rect, setsing_casted.hand_tracking_enabled, Color.GREEN)
		set_button(local_menu_lookat_x_button, local_menu_lookat_x_rect, setsing_casted.ui_local_menu_lookat_x, Color.RED)
		set_button(local_menu_lookat_y_button, local_menu_lookat_y_rect, setsing_casted.ui_local_menu_lookat_y, Color.GREEN)
		set_button(local_menu_lookat_z_button, local_menu_lookat_z_rect, setsing_casted.ui_local_menu_lookat_z, Color.BLUE)
		ctrl_enter_button.button_pressed = setsing_casted.send_messages_with_ctrl_enter
		ctrl_enter_button.text = "is enabled" if setsing_casted.send_messages_with_ctrl_enter else "is disabled"
		inspector_update_interval_spinbox.value = setsing_casted.inspector_update_interval
		scaling_slider.value = setsing_casted.viewport_scaling
		anti_aliasing_dropdown.selected = settings_singleton.anti_aliasing
	
	restart_in_vr_button.pressed.connect(restart_in_vr)
	passthrough_button.toggled.connect(toggle_vr_passthrough)
	hand_tracking_button.toggled.connect(toggle_hand_tracking)
	local_menu_lookat_x_button.toggled.connect(toggle_local_menu_lookat_x)
	local_menu_lookat_y_button.toggled.connect(toggle_local_menu_lookat_y)
	local_menu_lookat_z_button.toggled.connect(toggle_local_menu_lookat_z)
	inspector_update_interval_spinbox.value_changed.connect(inspector_update_interval_changed)
	ctrl_enter_button.toggled.connect(toggle_ctrl_enter)
	scaling_slider.value_changed.connect(viewport_scaling_slider_changed)
	anti_aliasing_dropdown.item_selected.connect(anti_aliasing_changed)

func restart_in_vr() -> void:
	var args := OS.get_cmdline_args()
	args.append("--xr-mode on")
	OS.set_restart_on_exit(true, PackedStringArray(args))
	if OS.is_restart_on_exit_set():
		get_tree().quit(0)

func toggle_vr_passthrough(toggled_on: bool) -> void:
	var settings_singleton = Engine.get_singleton("settings_manager")
	if settings_singleton is SettingsSingleton:
		# change to global var
		(settings_singleton as SettingsSingleton).vr_passthrough = toggled_on
		tween_button(passthrough_button, passthrough_rect, toggled_on, Color.GREEN)

func toggle_hand_tracking(toggled_on: bool) -> void:
	var settings_singleton = Engine.get_singleton("settings_manager")
	if settings_singleton is SettingsSingleton:
		# change to global var
		(settings_singleton as SettingsSingleton).hand_tracking_enabled = toggled_on
		tween_button(hand_tracking_button, hand_tracking_rect, toggled_on, Color.GREEN)

func toggle_local_menu_lookat_x(toggled_on: bool) -> void:
	var settings_singleton = Engine.get_singleton("settings_manager")
	if settings_singleton is SettingsSingleton:
		# change to global var
		(settings_singleton as SettingsSingleton).ui_local_menu_lookat_x = toggled_on
		tween_button(local_menu_lookat_x_button, local_menu_lookat_x_rect, toggled_on, Color.RED)

func toggle_local_menu_lookat_y(toggled_on: bool) -> void:
	var settings_singleton = Engine.get_singleton("settings_manager")
	if settings_singleton is SettingsSingleton:
		# change to global var
		(settings_singleton as SettingsSingleton).ui_local_menu_lookat_y = toggled_on
		tween_button(local_menu_lookat_y_button, local_menu_lookat_y_rect, toggled_on, Color.GREEN)

func toggle_local_menu_lookat_z(toggled_on: bool) -> void:
	var settings_singleton = Engine.get_singleton("settings_manager")
	if settings_singleton is SettingsSingleton:
		# change to global var
		(settings_singleton as SettingsSingleton).ui_local_menu_lookat_z = toggled_on
		tween_button(local_menu_lookat_z_button, local_menu_lookat_z_rect, toggled_on, Color.BLUE)

func toggle_ctrl_enter(toggled_on: bool) -> void:
	var settings_singleton = Engine.get_singleton("settings_manager")
	if settings_singleton is SettingsSingleton:
		# change to global var
		(settings_singleton as SettingsSingleton).send_messages_with_ctrl_enter = toggled_on
		create_tween().tween_property(ctrl_enter_button, ^"text", "is enabled" if toggled_on else "is disabled", 0.5)

func inspector_update_interval_changed(value: float) -> void:
	var settings_singleton = Engine.get_singleton("settings_manager")
	if settings_singleton is SettingsSingleton:
		# change to global var
		(settings_singleton as SettingsSingleton).inspector_update_interval = value

func anti_aliasing_changed(index: int) -> void:
	var settings_singleton = Engine.get_singleton("settings_manager")
	if settings_singleton is SettingsSingleton:
		# change to global var
		(settings_singleton as SettingsSingleton).anti_aliasing = index

func viewport_scaling_slider_changed(value: float) -> void:
	var settings_singleton = Engine.get_singleton("settings_manager")
	if settings_singleton is SettingsSingleton:
		# change to global var
		(settings_singleton as SettingsSingleton).viewport_scaling = value
