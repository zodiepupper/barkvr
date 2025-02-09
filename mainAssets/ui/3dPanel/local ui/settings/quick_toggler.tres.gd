extends Button

## The node that will have it's [code]visibility[/code] field toggled when this button is pressed
@export var node_to_toggle : Node

@export var slide := false
var slide_start_pos

func _toggled(toggled_on):
	if is_instance_valid(node_to_toggle):
		if !slide:
			node_to_toggle.visible = toggled_on
		if slide:
			if !slide_start_pos:
				slide_start_pos = node_to_toggle.position
			node_to_toggle.show()
			if toggled_on:
				create_tween().tween_property(node_to_toggle,"position:x",slide_start_pos.x,.5).\
				set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
			else:
				create_tween().tween_property(node_to_toggle,"position:x",-(node_to_toggle.size.x+slide_start_pos.x),.5).\
				set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
