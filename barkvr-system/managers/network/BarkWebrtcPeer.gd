## Class to manage a barkvr webrtc remote peer connection.
##
## This class manages the remote webrtc peer and it's data channels
class_name BarkWebrtcPeer
extends RefCounted

## the remote WebRTC peer for this connection
var remote_peer : WebRTCPeerConnection
## the channel designated for send/recv voip data
var voip_channel : WebRTCDataChannel
## the default configuration for the voip channel (needs to be unreliable)
var voip_channel_config : Dictionary = {
	"id": "voip_channel".hash(),
	"negotiated": true,
	"maxRetransmits": 0,
}
## the channel designated for send/recv journal data
var journal_channel : WebRTCDataChannel
## the default configuration for the journal channel
var journal_channel_config : Dictionary = {
	"id":"journal_channel".hash(),
	"negotiated": true
}
## the channel designated for send/recv reliable extra data
var extra_data_reliable_channel : WebRTCDataChannel
## the default configuration for the unreliable extra data channel
var exta_data_reliable_channel_config : Dictionary = {
	"id":"extra_data_reliable_channel".hash(),
	"negotiated": true
}
## the channel designated for send/recv unreliable extra data
var extra_data_unreliable_channel : WebRTCDataChannel
## the default configuration for the unreliable extra data channel
var exta_data_channel_reliable_config : Dictionary = {
	"id":"extra_data_unreliable_channel".hash(),
	"negotiated": true,
	"maxRetransmits": 4 
}
## holds the ice candidates for this peer
var ice_candidates : Array
## (might be removed soon in favor of peer_id's) target peer aliases, this is so we can 
## correlate this peer to whatever the remote peer's name is on the
## social api they were obtained from. [br][br]
## stored as a dictionary so we can find the alias by asking for a given platform
var remote_peer_aliases : Dictionary[StringName, String]
