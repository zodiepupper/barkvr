extends Node

## Each singleton entry should be a dictionary formatted like this:
## {"singleton_name":"singleton_script"}
## the script should extend Object, or a type that has the Object class as it's
## ancestor. If the script type is a node, then it will be added to the root of 
## the tree, otherwise it will be instantiated and then registered as a singleton
@export var singletons :Dictionary = {}
var registered_singletons : Dictionary

func _ready():
	add_singleton("bark_singleton_manager", self)
	for singleton in singletons:
		var tmp = singletons[singleton].new()
		Engine.register_singleton(singleton, tmp)
		registered_singletons[singleton] = tmp
		if tmp is Node:
			tmp.name = singleton
			get_tree().root.call_deferred("add_child",tmp)

func add_singleton(singleton_name:String, instance:Object):
	Engine.register_singleton(singleton_name, instance)
