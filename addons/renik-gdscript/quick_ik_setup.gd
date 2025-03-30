extends Node3D

@onready var head_target: Marker3D = $Targets/Head
@onready var hips_target: Marker3D = $Targets/Hips
@onready var left_hand_target: Marker3D = $Targets/LeftHand
@onready var right_hand_target: Marker3D = $Targets/RightHand
@onready var left_foot_target: Marker3D = $Targets/LeftFoot
@onready var right_foot_target: Marker3D = $Targets/RightFoot

@onready var equip_avatar: GridMenuButton = $"equip avatar"

# pre-allocate the ik nodes
# we will just move these around when a new skeleton is set
var root_ik := GodotIK.new()
var left_hand_ik_effector := GodotIKEffector.new()
var right_hand_ik_effector := GodotIKEffector.new()
var head_ik_effector := GodotIKEffector.new()

@export var armature_skeleton: Skeleton3D:
	set(value):
		armature_skeleton = value
		armature_skeleton.add_child(root_ik)
		root_ik.add_child(left_hand_ik_effector)
		root_ik.add_child(right_hand_ik_effector)
		root_ik.add_child(head_ik_effector)
		right_hand_ik_effector.bone_idx = armature_skeleton.find_bone("RightHand")
		left_hand_ik_effector.bone_idx = armature_skeleton.find_bone("LeftHand")
		head_ik_effector.bone_idx = armature_skeleton.find_bone("Head")
		right_hand_ik_effector.chain_length = 3
		left_hand_ik_effector.chain_length = 3
		head_ik_effector.chain_length = 2
		right_hand_ik_effector.transform_mode = GodotIKEffector.FULL_TRANSFORM
		left_hand_ik_effector.transform_mode = GodotIKEffector.FULL_TRANSFORM
		head_ik_effector.transform_mode = GodotIKEffector.FULL_TRANSFORM

func _physics_process(delta: float) -> void:
	var player = get_tree().get_first_node_in_group('player')
	if is_instance_valid(armature_skeleton) and player:
		right_hand_ik_effector.global_transform = player.righthand.handiktarget.global_transform
		left_hand_ik_effector.global_transform = player.lefthand.handiktarget.global_transform
		head_ik_effector.global_transform = player.headiktarget.global_transform
