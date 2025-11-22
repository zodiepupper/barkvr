extends Button
const EXIT_GAME_POPUP = preload("uid://dr1bo74h23rnm")

func _pressed() -> void:
	get_viewport().add_child(EXIT_GAME_POPUP.instantiate())
