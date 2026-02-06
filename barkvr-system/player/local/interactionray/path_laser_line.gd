extends Path3D

## hold the target position, upon being set it also applies the position
## to the appropriate point on the curve3d
var new_pos : Vector3 = Vector3(0,0,-1):
	set(val):
		new_pos = val
		if curve and curve.point_count > 0:
			var length_mod : float = new_pos.length()
			curve.set_point_out(0, Vector3.FORWARD*(length_mod*.8 ) )
			curve.bake_interval = length_mod/10.0 if length_mod/10.0 > .1 else .1
			curve.set_point_position(curve.point_count-1, new_pos)

## global position to use as an offset for the line origin.
## this makes it so we can show the origin of the laser 
## being extruded from the hand instead of the head for desktop users
## (or from any other global position)
var global_origin_offset : Vector3 = Vector3():
	set(val):
		global_origin_offset = val
		if curve and curve.point_count > 1:
			if val.is_zero_approx():
				curve.set_point_position(0,Vector3())
				return
			curve.set_point_position(0, to_local(val))
