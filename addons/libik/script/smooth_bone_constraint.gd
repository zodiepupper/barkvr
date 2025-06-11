@tool
class_name SmoothBoneConstraint extends GodotIKConstraint

## Enables or disables the smooth constraint.
@export var active = true
## Maximum allowed stretch factor for the bone.
@export var max_stretch : float = 1.5
## Speed at which the bone position is interpolated.
@export var smooth_speed : float = 20.

var _cached_pos_bone : Vector3
var _prev_time = Time.get_ticks_msec() * 0.001

## Smooths the bone position and applies a stretch limit.
func apply(
		pos_parent_bone: Vector3,
		pos_bone: Vector3,
		pos_child_bone: Vector3,
		chain_dir : Dir
	) -> PackedVector3Array:
	var result : PackedVector3Array = [pos_parent_bone, pos_bone, pos_child_bone]

	if active:
		if not _cached_pos_bone:
			_cached_pos_bone = result[1]
		var cur_time = Time.get_ticks_msec() * 0.001
		var delta = cur_time - _prev_time
		_prev_time = cur_time
		result[1] = lerp(_cached_pos_bone, result[1], min(delta * smooth_speed, 1.))
		_cached_pos_bone = result[1]
		if chain_dir == FORWARD:
			var d_old = pos_parent_bone.distance_to(pos_bone)
			var d_new = pos_parent_bone.distance_to(result[1])
			if d_old != 0 and d_new / d_old >= max_stretch:
				result[1] = pos_parent_bone + max_stretch * d_old * pos_parent_bone.direction_to(pos_bone)
	return result
