extends Node

func normalize_float32_array(array:PackedFloat32Array):
	# holder for normalized array
	var norm_array :PackedFloat32Array = PackedFloat32Array(array)
	# magnitude
	var mag = 0.0
	# create some vars for intermediate math
	var a = 0.0
	# use pythagorian theorem to calculate the ^2 length of vector
	for i in array:
		a += pow(i,2)
	# root the ^2 length of the array to get it's length
	mag = sqrt(a)
	for i in norm_array.size():
		norm_array[i] = norm_array[i]/mag
	return norm_array

func normalize_float64_array(array:PackedFloat64Array):
	# holder for normalized array
	var norm_array :PackedFloat64Array = PackedFloat64Array(array)
	# magnitude
	var mag = 0.0
	# create some vars for intermediate math
	var a = 0.0
	# use pythagorian theorem to calculate the ^2 length of vector
	for i in array:
		a += pow(i,2)
	# root the ^2 length of the array to get it's length
	mag = sqrt(a)
	for i in norm_array.size():
		norm_array[i] = norm_array[i]/mag
	return norm_array

func float64_array_size(array:PackedFloat64Array):
	# magnitude
	var mag = 0.0
	# create some vars for intermediate math
	var a = 0.0
	# use pythagorian theorem to calculate the ^2 length of vector
	for i in array:
		a += pow(i,2)
	# root the ^2 length of the array to get it's length
	mag = sqrt(a)
	return mag

func float32_array_size(array:PackedFloat32Array):
	# magnitude
	var mag = 0.0
	# create some vars for intermediate math
	var a = 0.0
	# use pythagorian theorem to calculate the ^2 length of vector
	for i in array:
		a += pow(i,2)
	# root the ^2 length of the array to get it's length
	mag = sqrt(a)
	return mag

## a helper to automatically join threads that are finished processing
## back with the main thread. 
func rejoin_thread_when_finished(thread: Thread) -> void:
	# if the thread has been started and is still alive...
	if thread and thread.is_started() and thread.is_alive():
		# create a timer that runs this function again once the time runs out
		get_tree().create_timer(1).timeout.connect(rejoin_thread_when_finished.bind(thread))
		# return to break out of this instance of the function
		return
	# otherwise, rejoin the thread with the main thread
	thread.wait_to_finish()
