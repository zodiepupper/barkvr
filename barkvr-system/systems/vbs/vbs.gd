class_name bvscript
extends RefCounted

var script_callable: Callable

var script_instructions: Dictionary:
	set(val):
		script_instructions = val
