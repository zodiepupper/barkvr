extends Node3D

@onready var equip_avatar: GridMenuButton = $"equip avatar"

# pre-allocate the ik nodes
# we will just move these around when a new skeleton is set
var root_ik := GodotIK.new()
#var left_hand_ik_effector := GodotIKEffector.new()
#var right_hand_ik_effector := GodotIKEffector.new()
#var head_ik_effector := GodotIKEffector.new()
@onready var ren_ik_spine_modifier_3d: RenIKSpineModifier3D = %RenIKSpineModifier3D
@onready var left_hand_ren_ik_limb_modifier_3d: RenIKLimbModifier3D = %LeftHandRenIKLimbModifier3D
@onready var right_hand_ren_ik_limb_modifier_3d: RenIKLimbModifier3D = %RightHandRenIKLimbModifier3D
@onready var left_foot_ren_ik_limb_modifier_3d: RenIKLimbModifier3D = %LeftFootRenIKLimbModifier3D
@onready var right_foot_ren_ik_limb_modifier_3d: RenIKLimbModifier3D = %RightFootRenIKLimbModifier3D
@onready var logic_container: Node3D = $LogicContainer
@onready var ren_ik_foot_placement: RenIKPlacement3D = %RenIKFootPlacement

var head_remote_transform : RemoteTransform3D
var right_hand_remote_transform : RemoteTransform3D
var left_hand_remote_transform : RemoteTransform3D

var equipped : bool

var calculated_height_coefficient : float = 0.0

@export var armature_skeleton: Skeleton3D:
	set(value):
		armature_skeleton = value
		#_determine_avatar_height() 
		ren_ik_spine_modifier_3d.reparent(armature_skeleton)
		
		left_hand_ren_ik_limb_modifier_3d.reparent(armature_skeleton)
		
		right_hand_ren_ik_limb_modifier_3d.reparent(armature_skeleton)
		
		left_foot_ren_ik_limb_modifier_3d.reparent(armature_skeleton)
		
		right_foot_ren_ik_limb_modifier_3d.reparent(armature_skeleton)
		
		logic_container.reparent(armature_skeleton)
		ren_ik_foot_placement.armature_skeleton_path = armature_skeleton
		ren_ik_foot_placement.enable_hip_placement = true
		ren_ik_foot_placement.enable_left_foot_placement = true
		ren_ik_foot_placement.enable_right_foot_placement = true
		

func _ready() -> void:
	equip_avatar.clicked.connect(func():
		var player := get_tree().get_first_node_in_group("player")
		var parent := get_parent()
		parent.reparent(player, false)
		parent.position = Vector3()
		parent.rotation = Vector3(0,0,0)
		equipped = true
		ren_ik_spine_modifier_3d.head_target.reparent(get_viewport().get_camera_3d())
		ren_ik_spine_modifier_3d.head_target.position = Vector3()
		ren_ik_spine_modifier_3d.head_target.rotation = Vector3(0,PI,0)
		ren_ik_spine_modifier_3d.head_target.scale = Vector3(1,1,1)
		
		
		
		left_hand_ren_ik_limb_modifier_3d.target.reparent(player.lefthand.handiktarget)
		left_hand_ren_ik_limb_modifier_3d.target.position = Vector3()
		left_hand_ren_ik_limb_modifier_3d.target.rotation = Vector3()
		left_hand_ren_ik_limb_modifier_3d.target.scale = Vector3(1,1,1)
		
		right_hand_ren_ik_limb_modifier_3d.target.reparent(player.righthand.handiktarget)
		right_hand_ren_ik_limb_modifier_3d.target.position = Vector3()
		right_hand_ren_ik_limb_modifier_3d.target.rotation = Vector3()
		right_hand_ren_ik_limb_modifier_3d.target.scale = Vector3(1,1,1)
		)

func _determine_avatar_height() -> void:
	var tmpright := armature_skeleton.find_bone("RightFoot")
	var tmpleft := armature_skeleton.find_bone("LeftFoot")
	var lefteye := armature_skeleton.find_bone("LeftEye")
	var righteye := armature_skeleton.find_bone("RightEye")
	var topposition : Vector3
	if lefteye and righteye:
		topposition = (armature_skeleton.get_bone_global_pose(righteye).origin\
		+armature_skeleton.get_bone_global_pose(lefteye).origin)/2.0
	else:
		var tmphead := armature_skeleton.find_bone("Head")
		topposition = armature_skeleton.get_bone_global_pose(tmphead).origin
	var avgfootpos :Vector3 = (armature_skeleton.get_bone_global_pose(tmpright).origin\
		+armature_skeleton.get_bone_global_pose(tmpleft).origin)/2.0
	_place_model_origin_at_point(avgfootpos)
	var approxheight := avgfootpos.distance_to(topposition)
	calculated_height_coefficient = approxheight
	armature_skeleton.scale *= 1/approxheight

func _place_model_origin_at_point(offset:Vector3) -> void:
	armature_skeleton.position = -offset

func _determine_avatar_spine_length() -> void:
	var tmpspine := armature_skeleton.find_bone("Spine")
	var tmpchest := armature_skeleton.find_bone("Chest")
	var tmpneck := armature_skeleton.find_bone("Neck")
	var spinepos := armature_skeleton.get_bone_global_pose(tmpspine).origin
	var chestpos := armature_skeleton.get_bone_global_pose(tmpchest).origin
	var neckpos := armature_skeleton.get_bone_global_pose(tmpneck).origin
	#ren_ik_foot_placement.spine_length = neckpos.distance_to(spinepos)*(armature_skeleton.scale.length())
