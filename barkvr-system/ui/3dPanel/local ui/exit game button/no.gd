extends Button

@onready var exit_game_popup: Control = $"../../../../.."

func _pressed() -> void:
	exit_game_popup.queue_free()
