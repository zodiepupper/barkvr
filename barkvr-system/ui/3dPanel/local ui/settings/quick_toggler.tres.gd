extends Button
 
## The node that will have it's [code]visibility[/code] field toggled when this button is pressed
@export var node_to_toggle : Node

@export var slide := false
var slide_start_pos

var prevtween : Tween

func _toggled(toggled_on):
	if is_instance_valid(node_to_toggle):
		var tmptween := create_tween()
		if prevtween:
			prevtween.kill()
		if !slide:
			node_to_toggle.visible = toggled_on
		if slide and is_instance_valid(tmptween):
			if !slide_start_pos:
				slide_start_pos = node_to_toggle.position
			if toggled_on:
				tmptween.tween_property(node_to_toggle,"position:x",slide_start_pos.x,.5).\
				set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
				tmptween.parallel()
				tmptween.tween_property(node_to_toggle,"visible", true,0.0)
			else:
				tmptween.tween_property(node_to_toggle,"position:x",-(node_to_toggle.size.x+slide_start_pos.x),.5).\
				set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
				tmptween.tween_property(node_to_toggle,"visible", false,0.0)
		prevtween = tmptween
