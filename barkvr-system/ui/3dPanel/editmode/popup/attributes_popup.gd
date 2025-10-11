extends MarginContainer

@onready var attributes: Control = %attributes
@onready var close: Button = %close
@onready var color_rect: ColorRect = %ColorRect

var target:Object:
	set(val):
		target = val
		if attributes:
			attributes.call_deferred("set_target",target)
			rand_color.call_deferred()
			hide_titlebar = hide_titlebar
			full_height = full_height

var hide_titlebar := false:
	set(val):
		hide_titlebar = val
		if attributes:
			attributes.set_deferred("hide_titlebar", val)

var full_height := false:
	set(val):
		full_height = val
		if attributes:
			attributes.set_deferred("full_height", val)

func _ready() -> void:
	close.pressed.connect(queue_free)

func rand_color():
	color_rect.color = Color.from_hsv(hash(target.to_string()),1.0,.8,.8)
