extends OptionButton

@onready var color_rect = $ColorRect

func _ready():
	for device in AudioServer.get_input_device_list():
		if !has_item_label(device):
			add_item(device, hash(device))
	for item in item_count:
		if get_item_text(item) not in AudioServer.get_input_device_list():
			remove_item(item)
	get_popup().hide_on_checkable_item_selection = false
	get_popup().hide_on_item_selection = false
	get_popup().hide_on_state_item_selection = false
	toggled.connect(func(toggled_on:bool):
		var _selected_id = get_item_id(selected)
		if toggled_on:
			for device in AudioServer.get_input_device_list():
				if !has_item_label(device):
					add_item(device, hash(device))
			for item in item_count:
				if get_item_text(item) not in AudioServer.get_input_device_list():
					remove_item(item)
		)
	item_selected.connect(func(index:int):
		AudioServer.input_device = get_item_text(index)
		)
	_show_audio_activity()

func _show_audio_activity() -> void:
	if LocalGlobals.voice_analyzer:
		color_rect.color.a = LocalGlobals.voice_analyzer.get_magnitude_for_frequency_range(0,40000,AudioEffectSpectrumAnalyzerInstance.MAGNITUDE_MAX).length()*100.0
		#get_tree().create_timer(.05).timeout.connect(_show_audio_activity)
		create_tween().tween_callback(_show_audio_activity).set_delay(.05)

func has_item_label(item_label:String) -> bool:
	for item in range(item_count):
		if get_item_text(item) == item_label:
			return true
	return false

func items() -> PackedStringArray:
	var output :PackedStringArray
	for item in range(item_count):
		output.append(get_item_text(item))
	return output
