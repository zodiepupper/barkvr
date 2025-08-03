extends GraphEdit

@onready var add_vbs_node: Control = %AddVBSNode

func _ready() -> void:
	connection_request.connect(connect_nodes)
	disconnection_request.connect(disconnect_nodes)
	popup_request.connect(request_popup)
	connection_to_empty.connect(connect_to_empty)
	var btn := Button.new()
	btn.text = "Add Node"
	btn.pressed.connect(request_popup.bind(Vector2(get_viewport().size)/2.0))
	get_menu_hbox().add_child(btn)
	var t := Thread.new()
	t.start(get_time)
	BarkHelpers.rejoin_thread_when_finished(t)

func connect_nodes(from_node: StringName, from_port: int, to_node: StringName, to_port: int):
	connect_node(from_node, from_port, to_node, to_port)
	print(connections)

func disconnect_nodes(from_node: StringName, from_port: int, to_node: StringName, to_port: int):
	disconnect_node(from_node, from_port, to_node, to_port)
	print(connections)

func request_popup(at_position: Vector2):
	print('do popup shit at: ', at_position)
	add_vbs_node.show()

func connect_to_empty(from_node: StringName, from_port: int, release_position: Vector2):
	print('do connect to empty shit:\nfrom_node: ', from_node, '\nfrom_port: ', from_port, '\nrelease_position', release_position)

func get_time() -> void:
	var t := 0
	while true:
		Time.get_ticks_msec()
		t += 1
