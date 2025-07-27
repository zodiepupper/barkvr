extends GraphEdit

func _ready() -> void:
	connection_request.connect(connect_nodes)
	disconnection_request.connect(disconnect_nodes)
	popup_request.connect(request_popup)
	connection_to_empty.connect(connect_to_empty)

func connect_nodes(from_node: StringName, from_port: int, to_node: StringName, to_port: int):
	connect_node(from_node, from_port, to_node, to_port)
	print(connections)

func disconnect_nodes(from_node: StringName, from_port: int, to_node: StringName, to_port: int):
	disconnect_node(from_node, from_port, to_node, to_port)
	print(from_node)
	print(connections)

func request_popup(at_position: Vector2):
	print('do popup shit at: ', at_position)

func connect_to_empty(from_node: StringName, from_port: int, release_position: Vector2):
	print('do connect to empty shit:\nfrom_node: ', from_node, '\nfrom_port: ', from_port, '\nrelease_position', release_position)
