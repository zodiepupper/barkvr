extends Path3D

## hold the target position, upon being set it also applies the position
## to the appropriate point on the curve3d
var new_pos : Vector3 = Vector3(0,1,0):
	set(val):
		new_pos = val
		if curve and curve.point_count > 0:
			curve.set_point_in(curve.point_count-1, Vector3.FORWARD*(new_pos.distance_to(to_local(global_origin_offset) ) ) )
			curve.set_point_position(0, new_pos)

## global position to use as an offset for the line origin.
## this makes it so we can show the origin of the laser 
## being extruded from the hand instead of the head for desktop users
var global_origin_offset : Vector3 = Vector3():
	set(val):
		global_origin_offset = val
		if curve and curve.point_count > 1:
			if val.is_zero_approx():
				curve.set_point_position(curve.point_count-1,Vector3())
				return
			curve.set_point_position(curve.point_count-1, to_local(val))
