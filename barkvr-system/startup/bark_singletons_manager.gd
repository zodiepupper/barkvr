## THIS SCRIPT exists because the autoload singletons don't allow us to check if 
## the singleton exists. for some reason, it uses a completely different process
## to register the singletons than when you use Engine.register_singleton
## which does let us check if a singleton exists by Engine.has_singleton()
extends Node

## Each singleton entry should be a dictionary formatted like this:
## {"singleton_name":"singleton_script"}
## the script should extend Object, or a type that has the Object class as it's
## ancestor. If the script type is a node, then it will be added to the root of 
## the tree, otherwise it will be instantiated and then registered as a singleton
@export var singletons :Dictionary = {}

## tracks the already registered singletons
##
## this is here to hold the instances of each singleton that we create below
## so they don't exit the scope of the game and get freed by refcounting
var registered_singletons : Dictionary

func _ready():
	# we start by creating this object as a singleton, so it is globally accessible
	add_singleton("bark_singleton_manager", self)
	# for every singleton requested...
	for singleton in singletons:
		# create an instance of the class we wanna load
		var tmp = singletons[singleton].new()
		# register that instance as a singleton
		Engine.register_singleton(singleton, tmp)
		# updated tracking of registered singletons
		registered_singletons[singleton] = tmp
		# if the singleton instantiation results in a Node, then
		# we wanna put it in the tree so it can behave how
		# the code expects to behave. (nodes outside the tree can't 
		# access many node functions)
		if tmp is Node:
			tmp.name = singleton
			get_tree().root.call_deferred("add_child",tmp)

# idk why we needed this, but sure.
func add_singleton(singleton_name:String, instance:Object):
	Engine.register_singleton(singleton_name, instance)
