class_name Snackbar
extends PanelContainer
## A UI snackbar used to display information inside inspectors.



func _ready() -> void:
	%CloseButton.pressed.connect(_on_close_button_pressed)



## Sets the data for this snackbar, a time of 0 makes it not clear itself automatically.
func set_data(text: String, texture: Texture2D, time: float = 3) -> void:
	%Label.text = text
	if texture: %Icon.texture = texture

	await ready

	if time != 0:
		await get_tree().create_timer(time).timeout
		queue_free()



func _on_close_button_pressed() -> void:
	queue_free()
