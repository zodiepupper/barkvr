extends Node3D

@onready var equip_avatar: GridMenuButton = $"equip avatar"

# pre-allocate the ik nodes
# we will just move these around when a new skeleton is set
var root_ik := GodotIK.new()
var left_hand_ik_effector := GodotIKEffector.new()
var right_hand_ik_effector := GodotIKEffector.new()
var head_ik_effector := GodotIKEffector.new()
var head_remote_transform : RemoteTransform3D
var right_hand_remote_transform : RemoteTransform3D
var left_hand_remote_transform : RemoteTransform3D

var equipped : bool

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
		head_ik_effector.chain_length = 4
		right_hand_ik_effector.transform_mode = GodotIKEffector.FULL_TRANSFORM
		left_hand_ik_effector.transform_mode = GodotIKEffector.FULL_TRANSFORM
		head_ik_effector.transform_mode = GodotIKEffector.FULL_TRANSFORM
		_check_and_fix_remote_transform_nodes()
		

func _check_and_fix_remote_transform_nodes():
	if !is_instance_valid(head_remote_transform):
		head_remote_transform = RemoteTransform3D.new()
		head_remote_transform.remote_path = head_remote_transform.get_path_to(head_ik_effector)
	if !is_instance_valid(right_hand_remote_transform):
		right_hand_remote_transform = RemoteTransform3D.new()
		right_hand_remote_transform.remote_path = right_hand_remote_transform.get_path_to(right_hand_ik_effector)
	if !is_instance_valid(left_hand_remote_transform):
		left_hand_remote_transform = RemoteTransform3D.new()
		left_hand_remote_transform.remote_path = left_hand_remote_transform.get_path_to(left_hand_ik_effector)

func _ready() -> void:
	equip_avatar.clicked.connect(func():
		var player := get_tree().get_first_node_in_group("player")
		var parent := get_parent()
		parent.reparent(player, false)
		parent.position = Vector3()
		parent.rotation = Vector3(0,PI,0)
		equipped = true
		)

func _physics_process(delta: float) -> void:
	var player = get_tree().get_first_node_in_group('player')
	if is_instance_valid(armature_skeleton) and player and equipped:
		right_hand_ik_effector.global_transform = player.righthand.handiktarget.global_transform
		left_hand_ik_effector.global_transform = player.lefthand.handiktarget.global_transform
		head_ik_effector.global_transform = player.headiktarget.global_transform
