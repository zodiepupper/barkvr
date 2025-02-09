extends Node3D

@onready var ren_ik = $RenIK
@onready var ren_ik_foot_placement = $RenIKFootPlacement

@onready var head = $Targets/Head
@onready var hips = $Targets/Hips
@onready var left_hand = $Targets/LeftHand
@onready var right_hand = $Targets/RightHand
@onready var left_foot = $Targets/LeftFoot
@onready var right_foot = $Targets/RightFoot

var calculated_height_coefficient : float = 0.0

@export var armature_skeleton: Skeleton3D:
	set(value):
		armature_skeleton = value
		ren_ik.armature_skeleton_path = ren_ik.get_path_to(armature_skeleton)
		print("renik armature skeleton path: ", ren_ik.armature_skeleton_path)
		ren_ik_foot_placement.armature_skeleton_path = ren_ik_foot_placement.\
			get_path_to(armature_skeleton)
		print("renik foot placement skeleton path: ", ren_ik_foot_placement.armature_skeleton_path)
		_determine_avatar_height()
		_determine_avatar_spine_length()
		print("spine length: ", ren_ik_foot_placement.spine_length)

func _determine_avatar_height() -> void:
	var tmpright := armature_skeleton.find_bone("RightFoot")
	var tmpleft := armature_skeleton.find_bone("LeftFoot")
	var tmphead := armature_skeleton.find_bone("Head")
	var avgfootpos :Vector3 = (armature_skeleton.get_bone_global_pose(tmpright).origin\
		+armature_skeleton.get_bone_global_pose(tmpleft).origin)/2.0
	var headpos := armature_skeleton.get_bone_global_pose(tmphead).origin
	var approxheight := avgfootpos.distance_to(headpos)
	calculated_height_coefficient = approxheight
	armature_skeleton.scale *= 1/approxheight

func _determine_avatar_spine_length() -> void:
	var tmpspine := armature_skeleton.find_bone("Spine")
	var tmpchest := armature_skeleton.find_bone("Chest")
	var tmpneck := armature_skeleton.find_bone("Neck")
	var spinepos := armature_skeleton.get_bone_global_pose(tmpspine).origin
	var chestpos := armature_skeleton.get_bone_global_pose(tmpchest).origin
	var neckpos := armature_skeleton.get_bone_global_pose(tmpneck).origin
	ren_ik_foot_placement.spine_length = neckpos.distance_to(spinepos)*(armature_skeleton.scale.length())
