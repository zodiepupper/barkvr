## Class to manage a barkvr webrtc remote peer connection.
##
## This class manages the remote webrtc peer and it's data channels
##[br]
## It's best to create an instance of this using the [code]create[/code] method
class_name BarkWebrtcPeer
extends WebRTCPeerConnection

## keep a reference to the remote player (that way we can send the voip/viseme/etc data to it)
var remote_peer_node : BarkRemotePeer
## if true, all threads should stop asap and we should try to clean up rq
var close_requested : bool = false

## (might be removed soon in favor of peer_id's) target peer aliases, this is so we can 
## correlate this peer to whatever the remote peer's name is on the
## social api they were obtained from. [br][br]
## stored as a dictionary so we can find the alias by asking for a given platform
var remote_peer_aliases : Dictionary[StringName, String]

## a signal to listen to that will emit data we need to send over the signaling medium to the other
## peer
signal signal_this(data:Dictionary)

## Creates, sets up, and returns a new BarkWebrtcPeer
static func create() -> BarkWebrtcPeer:
	var new_peer := BarkWebrtcPeer.new()
	new_peer.remote_peer = WebRTCPeerConnection.new()
	new_peer.voip_channel =\
		new_peer.create_data_channel("voip_channel", voip_default_channel_config)
	new_peer.journal_channel =\
		new_peer.create_data_channel("journal_channel", journal_default_channel_config)
	new_peer.extra_data_reliable_channel =\
		new_peer.create_data_channel("extra_data_reliable_channel", exta_data_reliable_default_channel_config)
	new_peer.extra_data_unreliable_channel =\
		new_peer.create_data_channel("extra_data_unreliable_channel", exta_data_unreliable_default_channel_config)
	return new_peer

# TODO: handle this later. we don't need this because we pre-negotiate the channels for now
func data_channel_received(channel: WebRTCDataChannel):
	pass

## holds the ice candidates for this peer
var ice_candidates : Array = []

## signal to let us automatically respond when the ice candidates are finished being gathered
signal ice_candidates_gathered()

## to be called when a new ICE candidate has been created (meant to be sent to the remote peer)
func ice_candidate_created(media: String, index: int, name: String):
	ice_candidates.append({"media": media, "index": index, "name": name})
	if get_gathering_state() == GATHERING_STATE_COMPLETE:
		signal_this.emit({"what": "ice_candidates_complete", "data": ice_candidates})
		ice_candidates_gathered.emit()

## handles session description created signal ( from [code]create_offer()[/code] or [code]set_remote_description()[/code] 
## and meant to be sent to [code]set_local_description()[/code] and to the remote peer's [code]set_remote_description()[/code] )
func session_description_created(type: String, sdp: String):
	set_local_description(type, sdp)
	signal_this.emit({"what": "session_description_created", "data": {"type":type, "sdp":sdp}})

#region voip

## the channel designated for send/recv voip data
var voip_channel : WebRTCDataChannel
## the configuration for the voip channel (needs to be unreliable)
static var voip_default_channel_config : Dictionary = {
	"id": "voip_channel".hash(),
	"negotiated": true,
	"maxRetransmits": 0,
}

# TODO: voip thread needs to include viseme data once we get that working

## holds the audio packets we want to send next
var audio_buffer_to_send : Array[PackedByteArray] = []

## thread for sending voip data
func voip_send_thread():
	while !close_requested:
		if get_connection_state() == WebRTCPeerConnection.STATE_CONNECTED &&\
		 voip_channel.get_ready_state() == WebRTCDataChannel.STATE_OPEN:
			if voip_channel:
				for packet : PackedByteArray in audio_buffer_to_send:
					voip_channel.put_packet(packet)
		# calculate the time in milliseconds each audio frame takes up for the current mix rate
		var audio_rate := (1000.0/AudioServer.get_input_mix_rate())
		# calculate how much time before we can send again (960 rn due to gdopus)
		if !Thread.is_main_thread():
			OS.delay_msec(\
				audio_rate * 960 - ( audio_rate * LocalGlobals.voice_capture.get_frames_available() )\
			 )

## reusable variable to buffer received voip data
var voip_recv_data : PackedByteArray

## thread to receive voip for this peer
func voip_recv_thread():
	while !close_requested:
		if get_connection_state() == WebRTCPeerConnection.STATE_CONNECTED &&\
		 voip_channel.get_ready_state() == WebRTCDataChannel.STATE_OPEN:
			while voip_channel.get_available_packet_count() > 0:
				voip_recv_data = voip_channel.get_packet()
				if remote_peer_node:
					remote_peer_node.push_audio_buffer_bytes(voip_recv_data)
		# calculate the time in milliseconds each audio frame takes up for the current mix rate
		var audio_rate := (1000.0/AudioServer.get_input_mix_rate())
		# calculate how much time we should probably wait before we can recv again (960 rn due to gdopus)
		if !Thread.is_main_thread():
			OS.delay_msec(\
				audio_rate * 960 - ( audio_rate * voip_recv_data.size() )\
			 )
		# empty the recv'd variable so it's empty for the next iteration 
		voip_recv_data.clear()

#endregion voip

#region journal

## journal polling rate for recv and send, in mlliseconds (interval, not synchronized ticks)
var journal_polling_rate : int = 1000.0/240
## the channel designated for send/recv journal data
var journal_channel : WebRTCDataChannel
## the configuration for the journal channel
static var journal_default_channel_config : Dictionary = {
	"id":"journal_channel".hash(),
	"negotiated": true
}

## reusable variable to buffer events to send
var events_to_send : Array[PackedByteArray] = []

var journal_send_last_ticks_msec : int

## thread to prepare and send journal events
func journal_send_thread():
	while !close_requested:
		journal_send_last_ticks_msec = Time.get_ticks_msec()
		if get_connection_state() == WebRTCPeerConnection.STATE_CONNECTED &&\
		 journal_channel.get_ready_state() == WebRTCDataChannel.STATE_OPEN:
			while events_to_send.size() > 0:
				journal_channel.put_packet(events_to_send.pop_back())
		# calculate how much time we should wait before the next iteration
		if !Thread.is_main_thread():
			OS.delay_msec( journal_polling_rate - (Time.get_ticks_msec() - journal_send_last_ticks_msec) )

var journal_recv_last_ticks_msec : int

## thread to receive journal data for this peer
func journal_recv_thread():
	while !close_requested:
		journal_recv_last_ticks_msec = Time.get_ticks_msec()
		if get_connection_state() == WebRTCPeerConnection.STATE_CONNECTED &&\
		 journal_channel.get_ready_state() == WebRTCDataChannel.STATE_OPEN:
			while journal_channel.get_available_packet_count() > 0:
				var in_journal_data = journal_channel.get_packet()
				# TODO: send journal data to journal or maybe a singleton
		# calculate how much time we should wait before the next iteration
		if !Thread.is_main_thread():
			OS.delay_msec( journal_polling_rate - (Time.get_ticks_msec() - journal_recv_last_ticks_msec) )

#endregion journal

#region reliable extra channel

## the channel designated for send/recv reliable extra data
var extra_data_reliable_channel : WebRTCDataChannel
## the configuration for the unreliable extra data channel
static var exta_data_reliable_default_channel_config : Dictionary = {
	"id":"extra_data_reliable_channel".hash(),
	"negotiated": true
}

var extra_data_reliable_last_ticks_msec : int
var extra_data_reliable_packets_to_send : Array[PackedByteArray]
var in_extra_data_reliable_data : PackedByteArray

## thread to send and recv for teh reliable extra data channel
func extra_data_reliable_thread() -> void:
	while !close_requested:
		extra_data_reliable_last_ticks_msec = Time.get_ticks_msec()
		if get_connection_state() == WebRTCPeerConnection.STATE_CONNECTED &&\
		 extra_data_reliable_channel.get_ready_state() == WebRTCDataChannel.STATE_OPEN:
			while events_to_send.size() > 0:
				extra_data_reliable_channel.put_packet(events_to_send.pop_back())
		if get_connection_state() == WebRTCPeerConnection.STATE_CONNECTED &&\
		 extra_data_reliable_channel.get_ready_state() == WebRTCDataChannel.STATE_OPEN:
			while extra_data_reliable_channel.get_available_packet_count() > 0:
				in_extra_data_reliable_data = extra_data_reliable_channel.get_packet()
				# TODO: send journal data to journal or maybe a singleton
		
		# calculate how much time we should wait before the next iteration
		if !Thread.is_main_thread():
			OS.delay_msec( journal_polling_rate - (Time.get_ticks_msec() - extra_data_reliable_last_ticks_msec) )

#endregion

#region unreliable extra channel

## the channel designated for send/recv unreliable extra data
var extra_data_unreliable_channel : WebRTCDataChannel
## the configuration for the unreliable extra data channel
static var exta_data_unreliable_default_channel_config : Dictionary = {
	"id":"extra_data_unreliable_channel".hash(),
	"negotiated": true,
	"maxRetransmits": 4 
}

var extra_data_unreliable_last_ticks_msec : int
var extra_data_unreliable_packets_to_send : Array[PackedByteArray]
var in_extra_data_unreliable_data : PackedByteArray

## thread to send and recv for teh reliable extra data channel
func extra_data_unreliable_thread() -> void:
	while !close_requested:
		extra_data_unreliable_last_ticks_msec = Time.get_ticks_msec()
		if get_connection_state() == WebRTCPeerConnection.STATE_CONNECTED &&\
		 extra_data_unreliable_channel.get_ready_state() == WebRTCDataChannel.STATE_OPEN:
			while events_to_send.size() > 0:
				extra_data_unreliable_channel.put_packet(events_to_send.pop_back())
		if get_connection_state() == WebRTCPeerConnection.STATE_CONNECTED &&\
		 extra_data_unreliable_channel.get_ready_state() == WebRTCDataChannel.STATE_OPEN:
			while extra_data_unreliable_channel.get_available_packet_count() > 0:
				in_extra_data_unreliable_data = extra_data_unreliable_channel.get_packet()
				# TODO: send journal data to journal or maybe a singleton
		
		# calculate how much time we should wait before the next iteration
		if !Thread.is_main_thread():
			OS.delay_msec( journal_polling_rate - (Time.get_ticks_msec() - extra_data_unreliable_last_ticks_msec) )
#endregion
