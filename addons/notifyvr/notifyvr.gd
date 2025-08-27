extends Node

var queuedmessages = []
var height_offset = 0
var notif_parent : Node3D :
	get:
		notif_parent = get_tree().get_first_node_in_group("notificationparent")
		return notif_parent

func send_notification(message):
	message = str(message)
	var lbl := Label3D.new()
	lbl.no_depth_test = true
	lbl.text = message
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	lbl.set_script(load("res://addons/notifyvr/textscript.gd"))
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	queuedmessages.append(lbl)

func _ready() -> void:
	setup_notif_parent.call_deferred()

func setup_notif_parent() -> void:
	if notif_parent:
		notif_parent.child_entered_tree.connect(update_height_offset)
		notif_parent.child_exiting_tree.connect(update_height_offset)
	else:
		get_tree().create_timer(.1).timeout.connect(setup_notif_parent)

func update_height_offset(_sink_for_entered_tree=null) -> void:
	height_offset = 0
	for child in notif_parent.get_children():
		if "get_aabb" in child and child is VisualInstance3D:
			height_offset += child.get_aabb().size.y

func _process(delta: float) -> void:
	if queuedmessages.size() > 0:
		for i: Label3D in queuedmessages:
			var notif_parent : Node3D = get_tree().get_first_node_in_group("notificationparent")
			if notif_parent:
				notif_parent.add_child(i)
				#update_height_offset()
				i.pixel_size = .005*Engine.get_singleton("settings_manager").vr_notification_size
				notif_parent.move_child(i,0)
				i.offset.y = height_offset*4.0
				queuedmessages.erase(i)
			
