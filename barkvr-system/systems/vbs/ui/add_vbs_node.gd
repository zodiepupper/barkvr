extends Control

@export var target :GraphEdit

@onready var item_list = $ItemList
@onready var line_edit = $LineEdit

var vbs_nodes : Dictionary = {
	"process": load("res://barkvr-system/systems/vbs/ui/process.tscn"),
	"float": load("res://barkvr-system/systems/vbs/ui/float_bvs.tscn")
}

var event_manager

func set_target(item:Node):
	target = item

func _ready():
	event_manager = Engine.get_singleton("event_manager")
	print("event supplier: "+str(event_manager))
	item_list.item_selected.connect(func(index):
		if is_instance_valid(target):
			var tmpclass :String = item_list.get_item_text(index)
			if vbs_nodes.has(tmpclass): 
				var tmp = vbs_nodes[tmpclass].instantiate()
				target.add_child(tmp)
				tmp.position_offset = (target.size/2.0)+target.scroll_offset
		item_list.deselect_all()
		hide()
		)
	line_edit.text_changed.connect(func(new_text:String):
		item_list.deselect_all()
		item_list.clear()
		new_text = new_text.to_lower()
		var filtered := Array()
		var class_list :PackedStringArray = vbs_nodes.keys()
		for node_class in class_list:
			if vbs_nodes:
				var contains_all_chars :bool = true
				var node_class_lower := node_class.to_lower()
				for character in new_text:
					if !node_class_lower.contains(character):
						contains_all_chars = false
						break
				if contains_all_chars or node_class_lower.contains(new_text) or node_class_lower.similarity(new_text) > .6:
					filtered.append(node_class)
		filtered.sort_custom(func(a:String, b:String):
			return true if new_text.similarity(a.to_lower()) > new_text.similarity(b.to_lower()) else false
		)
		for item in filtered:
			item_list.add_item(item)
	)
	for cls in vbs_nodes:
		item_list.add_item(cls)
