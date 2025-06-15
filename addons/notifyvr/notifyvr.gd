extends Node

var queuedmessages = []

func send_notification(message):
	message = str(message)
	var lbl := Label3D.new()
	lbl.no_depth_test = true
	lbl.text = message
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	lbl.set_script(load("res://addons/notifyvr/textscript.gd"))
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	queuedmessages.append(lbl)

func _process(delta: float) -> void:
	if queuedmessages.size() > 0:
		for i: Label3D in queuedmessages:
			var tmp = get_tree().get_first_node_in_group("notificationparent")
			if tmp:
				tmp.add_child(i)
				i.pixel_size = .005*Engine.get_singleton("settings_manager").vr_notification_size
				tmp.move_child(i,0)
				queuedmessages.erase(i)
			
