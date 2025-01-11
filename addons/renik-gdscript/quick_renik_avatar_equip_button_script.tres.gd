extends Node

var renik : RenIK3D
var renikfootplacement : RenIKPlacement3D

func onclick() -> void:
	if !renik:
		print("grab renik")
		renik = get_parent().get_parent().find_child("RenIK")
	if !renikfootplacement:
		print("grab renikfootplacement")
		renikfootplacement = get_parent().get_parent().find_child("RenIKFootPlacement")
	
	if renik and renikfootplacement:
		print(renik.armature_head_target)
		renik.head_target_spatial = get_tree().get_first_node_in_group("player").headiktarget
		renik.hand_left_target_spatial = get_tree().get_first_node_in_group("player").lefthand.handiktarget
		renik.hand_right_target_spatial = get_tree().get_first_node_in_group("player").righthand.handiktarget
		renikfootplacement.head_target_spatial = renik.head_target_spatial
		print(renik.armature_head_target)
