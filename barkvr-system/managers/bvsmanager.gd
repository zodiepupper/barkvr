class_name bvsmanager
extends Node

## schema (target will be replaced with the target uuid later for netwrk):
## { target_object: Object, script: Variant, thread: Thread }
static var script_threads: Array[Dictionary] = []

func _process(delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
	pass

static func register_script(target_object:Object, script:Variant, one_shot: bool) -> void :
	if !script_threads.any(does_dict_have_script):
		if one_shot:
			#WorkerThreadPool.add_task(script)
			return
		var thread := Thread.new()
		#thread.start(script)
		script_threads.append({"target_object":target_object, "script": script, "thread": thread})

static func does_dict_have_script(dict:Dictionary, script:Variant) -> bool:
	if "script" in dict and dict.script == script:
		return true
	return false
