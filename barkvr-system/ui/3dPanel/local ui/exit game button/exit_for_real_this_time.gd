extends Button

@onready var label: Label = $"../../Label"

func _pressed() -> void:
	var tmp = create_tween()
	tmp.tween_property(label, "text", "thank you for playing 💜", 4.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	tmp.tween_callback(func():
		get_tree().quit()
		).set_delay(1.0)
