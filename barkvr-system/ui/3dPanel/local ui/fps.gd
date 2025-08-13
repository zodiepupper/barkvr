extends Label

func _process(delta: float) -> void:
	text = "fps: "+str(1.0/delta)                                                                 
