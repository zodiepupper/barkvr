extends Control

var prevmessages:Dictionary
var requesting_user:String = ''
var target_room:String = ''
var already_processed_requests := []
var already_processed_offers := []
var already_processed_answers := []
@onready var roomlist :matrix_hashed_tree= %roomlist
@onready var scroll_container := $".."
@onready var text_edit = %messagetext

func _ready():
	if is_instance_valid(Engine.get_singleton("network_manager")):
		Engine.get_singleton("network_manager").created_offer.connect(offer_created)
		Engine.get_singleton("network_manager").created_answer.connect(answer_created)
		Engine.get_singleton("network_manager").finished_candidates.connect(candidates_finished)
	if is_instance_valid(Engine.get_singleton("user_manager")):
		Engine.get_singleton("user_manager").got_new_message.connect(func(event:Dictionary):
			#WorkerThreadPool.add_task(_process_message.bind(event))
			_process_message(event)
		)
		Engine.get_singleton("user_manager").got_room_messages.connect(func(data):
#			for child in get_children():
#				child.queue_free()
			if data and 'body' in data and data.body and 'chunk' in data.body:
				data.body.chunk.reverse()
			for event in data['body']['chunk']:
				_process_message(event)
				prevmessages = data
		)

func _process_message(event:Dictionary):
	match event['type']:
		'm.room.message':
			_display_message(event)
		'bark.session.request':
			if is_instance_valid(Engine.get_singleton("network_manager")):
				#_display_message(event)
				if event.event_id not in already_processed_requests:
					already_processed_requests.append(event.event_id)
					if event.sender != Engine.get_singleton("user_manager").userData.login.user_id:
						if Time.get_unix_time_from_system()*1000.0-10000 < event.origin_server_ts:
							Engine.get_singleton("network_manager").create_new_peer_connection('',event.sender)
							requesting_user = event.sender
							Notifyvr.send_notification('got request')
		'bark.session.offer':
			if is_instance_valid(Engine.get_singleton("network_manager")):
				#_display_message(event)
				if event.event_id not in already_processed_offers:
					already_processed_offers.append(event.event_id)
					if Time.get_unix_time_from_system()*1000.0-10000 < event.origin_server_ts:
						if event.content.for_user == Engine.get_singleton("user_manager").userData.login.user_id:
							Engine.get_singleton("network_manager").create_new_peer_connection(event.content.sdp,event.sender)
							Notifyvr.send_notification('got offer')
		'bark.session.answer':
			if is_instance_valid(Engine.get_singleton("network_manager")):
				#_display_message(event)
				if event.event_id not in already_processed_answers:
					already_processed_answers.append(event.event_id)
					if Time.get_unix_time_from_system()*1000.0-10000 < event.origin_server_ts:
						if event.content.for_user == Engine.get_singleton("user_manager").userData.login.user_id:
							for peer in Engine.get_singleton("network_manager").peers:
								if peer.for_user == event.sender:
									peer.peer.set_remote_description('answer',event.content.sdp)
									peer.set_remote = true
									Notifyvr.send_notification('got answer')
		'bark.session.ice':
			if is_instance_valid(Engine.get_singleton("network_manager")):
				#_display_message(event)
				if Time.get_unix_time_from_system()*1000.0-10000 < event.origin_server_ts and event.event_id not in already_processed_answers:
					if event.content.for_user == Engine.get_singleton("user_manager").userData.login.user_id:
						for peer in Engine.get_singleton("network_manager").peers:
							if peer.for_user == event.sender:
								if peer.set_remote:
									already_processed_answers.append(event.event_id)
									for candidate in event.content.candidates:
										peer.peer.add_ice_candidate(
											candidate.media,
											candidate.index,
											candidate.name
										)
										Notifyvr.send_notification('set_ice')
		_:
			print('none')

func _display_message(event):
	if event.has('content'):
		if event.room_id == target_room:
			if "content" in event and "msgtype" in event.content:
				print(event.content.msgtype)
			var exists = false
			for i in get_children():
				if i.name == event.event_id:
					exists = true
			if !exists:
				var displayname :String = event.sender.split(':')[0].right(-1)
				if event.room_id in roomlist.tree and "users" in roomlist.tree[event.room_id] and event.sender in roomlist.tree[event.room_id].users and "displayname" in roomlist.tree[event.room_id].users[event.sender]:
					displayname = roomlist.tree[event.room_id].users[event.sender].displayname
				var tmp :Control = load("res://barkvr-system/ui/3dPanel/local ui/login/message.tscn").instantiate()
				tmp.name = event.event_id
				if event['content'].has('body'):
					tmp.text = (event.content.body)
				else:
					tmp.text = str(event)
				tmp.time = str(Time.get_datetime_string_from_unix_time((event.origin_server_ts/1000)+(Time.get_time_zone_from_system().bias*60),true))
				tmp.sender = displayname+":"
				# this part sets some data so files sent over matrix can be imported
				# using the journal import_asset flow (the copy text button becomes
				# an import asset button)
				if "url" in event.content:
					if event.content.url.begins_with("mxc://"):
						var download_url : String = event.content.url.trim_prefix("mxc://")
						var download_homeserver : String = download_url.split("/")[0]
						var download_content_id : String = download_url.split("/")[1]
						Thread.set_thread_safety_checks_enabled(false)
						tmp.set_meta("import", true)
						# automatically convert the mxc uri for the matrix media
						# repository to a useable uri
						tmp.set_meta("asset_url", "https://matrix.pupper.dev/_matrix/client/v1/media/download/"+download_homeserver+"/"+download_content_id+"?allow_redirect=true")
						if "body" in event.content:
							tmp.set_meta("import_asset_name", event.content.body)
							tmp.text = event.content.body
						else:
							tmp.text = "could not get asset name"
						if "info" in event.content:
							if "mimetype" in event.content.info:
								tmp.text += "\n[color=#8888][font_size=14]asset type: "+event.content.info.mimetype
							else:
								tmp.text += "\n[color=#8888][font_size=14]asset type: "+"binary file"
							if "size" in event.content.info:
								tmp.text += ", asset size: "+str(int(event.content.info.size))+" bytes"
						
						Thread.set_thread_safety_checks_enabled(true)
						
				if is_instance_valid(Engine.get_singleton("user_manager")) and event.sender == Engine.get_singleton("user_manager").userData.login.user_id:
					tmp.leftside = false
				if scroll_container.scroll_vertical == size.y:
					add_child(tmp)
					move_child(tmp,0)
					scroll_container.scroll_vertical = size.y
				else:
					add_child(tmp)
					move_child(tmp,0)

func offer_created(data:Dictionary):
	if data.for_user == requesting_user and target_room and is_instance_valid(Engine.get_singleton("user_manager")):
		Engine.get_singleton("user_manager").send_room_event(
			target_room,
			'bark.session.offer',
			{
				'sdp':data.offer,
				'for_user':data.for_user
			}
		)
		Notifyvr.send_notification('sent offer')

func answer_created(data:Dictionary):
	if target_room and is_instance_valid(Engine.get_singleton("user_manager")):
		Engine.get_singleton("user_manager").send_room_event(
			target_room,
			'bark.session.answer',
			{
				'sdp':data.answer,
				'for_user':data.for_user
			}
		)
		Notifyvr.send_notification('sent answer')

func candidates_finished(data:Dictionary):
	if target_room and is_instance_valid(Engine.get_singleton("user_manager")):
		Engine.get_singleton("user_manager").send_room_event(
			target_room,
			'bark.session.ice',
			{
				'candidates':data.candidates,
				'for_user': data.for_user
			}
		)

func set_room(new_room):
	target_room = new_room
	for child in get_children():
		child.queue_free()
