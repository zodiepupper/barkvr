extends GraphEdit

func _ready() -> void:
	connection_request.connect(func(from_node: StringName, from_port: int, to_node: StringName, to_port: int):
		connect_node(from_node, from_port, to_node, to_port)
		print(connections)
	)
	disconnection_request.connect(func(from_node: StringName, from_port: int, to_node: StringName, to_port: int):
		disconnect_node(from_node, from_port, to_node, to_port)
		print(from_node)
		print(connections)
	)
	popup_request.connect(func(at_position: Vector2):
		print('do popup shit')
	)
