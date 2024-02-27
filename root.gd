# Released by Aziroshin in 2024 under the CC0, Switzerland
@tool
extends Node3D

## The `_ready` function causes the error and contains comments to help guide
## its observation.
## By default, it prints curve information. Lines prefixed with `!` are
## baked curve points with a default `Basis()`. Given the points from
## the `add_4_section_curve_points` function, these are almost certainly error
## points.
## 
## Since the script is in tool mode, the curve can be observed in the scene
## editor. If you run the program, you can move the camera in the scene editor
## for it to move in the program.


func _ready() -> void:
	# Standalone error triggers you can try.
	# Error will not trigger.
	#standalone_trigger_curve2d()
	# Will trigger the error twice.
	#standalone_trigger_curve3d()
	
	var curve = Curve3D.new()
	curve.bake_interval = 0.1
	add_4_section_curve_points(curve)
	set_curve_handles(curve)
	tilt(curve)
	
	# Will cause the error twice and the first section will have a wrongly
	# rotated middle point (idx 7 if no other changes are introduced).
	skew_all_except_first_section_curve_control_points(curve)
	
	# Uncomment one at a time to observe their effects on the third section.
	# Error will not trigger. 
	#make_third_section_sub_linear(curve)
	# Will cause the error twice and the middle point will be wrongly
	# rotated (idx 43 if no other changes are introduced).
	#make_third_section_linear(curve)
	# Error will not trigger.
	#make_third_section_super_linear(curve)
	
	# Will nullify all the error causes from above.
	#skew_all_curve_control_points(curve)
	
	# This will trigger each error cause form above two times over
	# (e.g. if something is uncommented that triggers it twice, it will be
	# triggered four times here). That's because this function uses
	# `sample_baked_with_rotation` twice.
	visualize_curve(self, curve, true, false, true)
	
	visualize_curve_points(self, curve)
	visualize_curve_handle_in_points(self, curve)
	visualize_curve_handle_out_points(self, curve)
	#visualize_handles(self, curve)
	
	#print_curve_info(curve)
	# WARNING: This will trigger the error as well.
	#print_forward_vectors(curve)
	
	# Will trigger the error.
	#try_triggering_error(curve)


func set_curve_handles(p_curve: Curve3D) -> void:
	var i_first := 0
	var global_position_first := p_curve.get_point_position(0)
	var global_position_second := p_curve.get_point_position(1)
	p_curve.set_point_in(
		i_first,
		global_position_first - global_position_second
	)
	
	for i_current in range(0, p_curve.point_count-1):
		var i_next := i_current + 1
		var global_position_current := p_curve.get_point_position(i_current)
		var global_position_next := p_curve.get_point_position(i_next)
		p_curve.set_point_out(
			i_current,
			global_position_next - global_position_current
		)
		p_curve.set_point_in(
			i_next,
			global_position_current - global_position_next
		)
		
	var i_last := p_curve.point_count - 1
	var i_second_last := i_last - 1
	var global_position_last := p_curve.get_point_position(i_last)
	var global_position_second_last := p_curve.get_point_position(i_second_last)
	p_curve.set_point_out(
		i_last, 
		global_position_last - global_position_second_last
	)


func print_curve_info(p_curve: Curve3D) -> void:
	var linearity: String
	
	for idx in p_curve.point_count:
		if idx == p_curve.point_count - 1:
			linearity = "n/a"
		else:
			linearity = str(section_starting_at_is_linear(p_curve, idx))
	
		print(
			"idx: ", idx,
			", position: ", p_curve.get_point_position(idx),
			", in:", p_curve.get_point_in(idx),
			", out:", p_curve.get_point_out(idx),
			", section to idx %s is linear: " % (idx + 1), linearity
		)


func print_forward_vectors(p_curve: Curve3D) -> void:
	var _transform: Transform3D
	var baked_points := p_curve.get_baked_points()
	for i_baked in len(baked_points):
		_transform = p_curve.sample_baked_with_rotation(
			p_curve.get_closest_offset(baked_points[i_baked])
		)
		print(
			"baked idx: ", i_baked,
			", forward: ", -_transform.basis.z,
			", xyz: ", _transform.origin
		)


func try_triggering_error(p_curve: Curve3D) -> void:
	var baked_points := p_curve.get_baked_points()
	for idx in len(baked_points):
		var baked_point := baked_points[idx]
		p_curve.sample_baked_with_rotation(
			p_curve.get_closest_offset(baked_point)
		)


func create_box(p_size: Vector3, p_color: Color, p_transform: Transform3D) -> CSGBox3D:
	var box := CSGBox3D.new()
	var material := StandardMaterial3D.new()
	material.albedo_color = p_color
	box.material = material
	box.size = p_size
	box.transform = p_transform
	return box


func create_box_pointer(p_size: Vector3, p_color: Color, p_transform: Transform3D) -> Node3D:
	var box_pointer := Node3D.new()
	var base_box := create_box(p_size, p_color, p_transform)
	var pointer := create_box(
		Vector3((p_size.x+p_size.y) * 0.05, (p_size.x+p_size.y) * 0.05, p_size.z * 4.0),
		p_color,
		p_transform
	)
	pointer.translate(
		Vector3(0.0, base_box.size.y * 0.5, -(pointer.size.z * 0.5 + base_box.size.z * 0.5))
	)
	add_child(base_box)
	add_child(pointer)
	return box_pointer


func sample_closest_baked_with_rotation(p_curve: Curve3D, p_point: Vector3) -> Transform3D:
	var offset := p_curve.get_closest_offset(p_point)
	return p_curve.sample_baked_with_rotation(offset)


func visualize_curve(
	p_target: Node3D,
	p_curve: Curve3D,
	p_verbose := false,
	p_cubic := false,
	p_apply_tilt := false
) -> void:
	if p_verbose:
		print("=== BEGIN func visualize_curve ===")
	
	var i_baked := 0
	for baked in p_curve.get_baked_points():
		var offset := p_curve.get_closest_offset(baked)
		# This is the error trigger.
		var baked_transform := p_curve.sample_baked_with_rotation(offset, p_cubic, p_apply_tilt)
		var baked_untilted_basis = p_curve.sample_baked_with_rotation(offset, p_cubic).basis
		var box = create_box_pointer(
			Vector3(0.01, 0.01, 0.02),
			Color(0.4, 0.4, 0.9),
			baked_transform
		)
		p_target.add_child(box)
		
		if p_verbose:
			print(
				"%sidx: " % ["!" if baked_untilted_basis == Basis() else ""], i_baked,
				", baked: ", baked,
				", offset: ", offset,
				", baked_transform: ", baked_transform,
				", untilted basis: ", baked_untilted_basis
			)
		i_baked += 1
	
	if p_verbose:
		print("=== END func visualize_curve ===")


func visualize_curve_points(p_target: Node3D, p_curve: Curve3D) -> void:
	for idx in p_curve.point_count:
		var box := create_box_pointer(
			Vector3(0.05, 0.05, 0.05),
			Color(0.06, 0.06, 0.6),
			sample_closest_baked_with_rotation(p_curve, p_curve.get_point_position(idx))
		)
		p_target.add_child(box)


func visualize_curve_handle_in_points(p_target: Node3D, p_curve: Curve3D) -> void:
	for idx in p_curve.point_count:
		var point_transform := sample_closest_baked_with_rotation(
			p_curve,
			p_curve.get_point_position(idx)
		)
		var global_in_position := point_transform.origin + p_curve.get_point_in(idx)
		var in_transform := Transform3D(
			Basis.looking_at(p_curve.get_point_in(idx)),
			global_in_position
		)
		var box := create_box_pointer(
			Vector3(0.03, 0.12, 0.03),
			Color(1.0, 0.1, 0.1),
			in_transform
		)
		p_target.add_child(box)


func visualize_curve_handle_out_points(p_target: Node3D, p_curve: Curve3D) -> void:
	for idx in p_curve.point_count:
		var point_transform := sample_closest_baked_with_rotation(
			p_curve,
			p_curve.get_point_position(idx)
		)
		var global_out_position := point_transform.origin + p_curve.get_point_out(idx)
		var out_transform := Transform3D(
			Basis.looking_at(p_curve.get_point_out(idx)),
			global_out_position
		)
		var box := create_box_pointer(
			Vector3(0.01, 0.25, 0.01),
			Color(1.0, 1.0, 0.1),
			out_transform
		)
		p_target.add_child(box)


func skew_in_control_point(p_curve: Curve3D, idx: int) -> void:
	var old_in := p_curve.get_point_in(idx)
	p_curve.set_point_in(
		idx,
		Vector3(
			old_in.x - old_in.x * 0.12,
			old_in.y,
			old_in.z + old_in.z * 0.9
		),
	)


func skew_out_control_point(p_curve: Curve3D, idx: int) -> void:
	var old_out := p_curve.get_point_out(idx)
	p_curve.set_point_out(
		idx,
		Vector3(
			old_out.x - old_out.x * 0.07,
			old_out.y,
			old_out.z + old_out.z * 0.05
		),
	)


func skew_curve_control_points(p_curve: Curve3D, idx: int) -> void:
	skew_in_control_point(p_curve, idx)
	skew_out_control_point(p_curve, idx)


func skew_all_curve_control_points(p_curve: Curve3D) -> void:
	for idx in p_curve.point_count:
		skew_curve_control_points(p_curve, idx)
		
		
func skew_all_except_first_section_curve_control_points(p_curve: Curve3D) -> void:
	for idx in p_curve.point_count:
		if not idx == 1:
			skew_in_control_point(p_curve, idx)
		if not idx == 0:
			skew_out_control_point(p_curve, idx)


func skew_all_except_first_and_third_section_curve_control_points(p_curve: Curve3D) -> void:
	for idx in p_curve.point_count:
		if not idx == 1 and not idx == 3:
			skew_in_control_point(p_curve, idx)
			skew_in_control_point(p_curve, idx)
		if not idx == 0 and not idx == 2:
			skew_out_control_point(p_curve, idx)
			skew_out_control_point(p_curve, idx)


func create_handle_shaft(point_a: Vector3, point_b: Vector3) -> MeshInstance3D:
	assert(not point_b == Vector3.ZERO)
	assert(not point_a == point_b)
	
	var st := SurfaceTool.new()
	var mesh_instance := MeshInstance3D.new()
	var material := StandardMaterial3D.new()
	#var shaft_basis := Basis.looking_at(point_b)
	
	material.albedo_color = Color(0.4, 0.9, 0.4)
	#shaft.material = material
	#shaft.radius = 0.1
	
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Tri 1
	st.add_vertex(Vector3(-0.1, -0.1, 0.0) + point_a)
	st.add_vertex(Vector3(-0.1, 0.1, 0.0) + point_a)
	st.add_vertex(Vector3(0.1, -0.1, 0.0) + point_a)
	st.add_vertex(Vector3(0.1, -0.1, 0.0) + point_a)
	st.add_vertex(Vector3(-0.1, 0.1, 0.0) + point_a)
	st.add_vertex(Vector3(0.1, 0.1, 0.0) + point_a)
	# Tri 2
	st.add_vertex(Vector3(0.1, -0.1, 0.0) + point_b)
	st.add_vertex(Vector3(0.1, 0.1, 0.0) + point_b)
	st.add_vertex(Vector3(-0.1, -0.1, 0.0) + point_b)
	st.add_vertex(Vector3(-0.1, -0.1, 0.0) + point_b)
	st.add_vertex(Vector3(0.1, 0.1, 0.0) + point_b)
	st.add_vertex(Vector3(-0.1, 0.1, 0.0) + point_b)
	mesh_instance.mesh = st.commit()
	mesh_instance.mesh.surface_set_material(0, material)
	return mesh_instance
	

func visualize_handles(p_target: Node3D, p_curve: Curve3D) -> void:
	var baked_points := p_curve.get_baked_points()
	for idx in len(baked_points):
		p_target.add_child(create_handle_shaft(baked_points[idx],p_curve.get_point_in(idx)))
		p_target.add_child(create_handle_shaft(baked_points[idx],p_curve.get_point_out(idx)))


func make_section_linear(p_curve: Curve3D, p_idx_1: int, p_idx_2: int) -> void:
	p_curve.set_point_out(p_idx_1, p_curve.get_point_position(p_idx_2) - p_curve.get_point_position(p_idx_1))
	p_curve.set_point_in(p_idx_2, p_curve.get_point_position(p_idx_1) - p_curve.get_point_position(p_idx_2))


func scale_section_control_points(p_curve: Curve3D, p_idx_1: int, p_idx_2: int, factor: float) -> void:
	p_curve.set_point_out(p_idx_1, p_curve.get_point_out(p_idx_1) * factor)
	p_curve.set_point_in(p_idx_2, p_curve.get_point_in(p_idx_2) * factor)


func make_section_sub_linear(p_curve: Curve3D, p_idx_1: int, p_idx_2: int) -> void:
	make_section_linear(p_curve, p_idx_1, p_idx_2)
	scale_section_control_points(p_curve, p_idx_1, p_idx_2, 0.75)


func make_section_super_linear(p_curve: Curve3D, p_idx_1: int, p_idx_2: int) -> void:
	make_section_linear(p_curve, p_idx_1, p_idx_2)
	scale_section_control_points(p_curve, p_idx_1, p_idx_2, 1.3)


func make_third_section_linear(p_curve: Curve3D) -> void:
	make_section_linear(p_curve, 2, 3)


func make_third_section_sub_linear(p_curve: Curve3D) -> void:
	make_section_sub_linear(p_curve, 2, 3)


func make_third_section_super_linear(p_curve: Curve3D) -> void:
	make_section_super_linear(p_curve, 2, 3)


func add_4_section_curve_points(p_curve: Curve3D) -> void:
	p_curve.add_point(Vector3(0.0, 0.0, 0.0))
	p_curve.add_point(Vector3(0.8, 0.0, 0.3))
	p_curve.add_point(Vector3(1.6, 0.0, 1.0))
	p_curve.add_point(Vector3(2.3, 0.0, 2.2))
	p_curve.add_point(Vector3(1.0, 0.0, 3.5))


func is_parallel(p_a: Vector3, p_b: Vector3) -> bool:
	return p_a.dot(p_b) == 0.0


func section_starting_at_is_linear(p_curve: Curve3D, p_idx: int) -> bool:
	var a := p_curve.get_point_position(p_idx) + p_curve.get_point_out(p_idx)
	var b := p_curve.get_point_position(p_idx+1) + p_curve.get_point_in(p_idx+1)
	return is_parallel(a, b)


func standalone_trigger_curve2d(p_cubic := false) -> void:
	var curve := Curve2D.new()
	curve.add_point(Vector2(), Vector2(-1.0, 0.0), Vector2(1.0, 0.0))
	curve.add_point(Vector2(1.0, 0.0), Vector2(-1.0, 0.0), Vector2(1.0, 0.0))
	for baked in curve.get_baked_points():
		curve.sample_baked_with_rotation(
			curve.get_closest_offset(baked),
			p_cubic
		)


func standalone_triggering_curve3d(p_cubic := false, p_apply_tilt := false) -> void:
	var curve := Curve3D.new()
	curve.add_point(Vector3(), Vector3(-1.0, 0.0, 0.0), Vector3(1.0, 0.0, 0.0))
	curve.add_point(Vector3(1.0, 0.0, 0.0), Vector3(-1.0, 0.0, 0.0), Vector3(1.0, 0.0, 0.0))

	for idx in range(4, 6):
		var baked := curve.get_baked_points()[idx]
		print(
			"idx: ", idx,
			", baked: ", baked,
			", transform: ", curve.sample_baked_with_rotation(curve.get_closest_offset(baked),
				p_cubic,
				p_apply_tilt
			)
		)


# The vectors with two-digit coordinates aren't relevant, they're just set to
# something else than `Vector3()` to make it less likely for other corner cases
# to be triggered by accident.
func issue_text_reproduction_steps() -> void:
	var curve := Curve3D.new()
	curve.add_point(Vector3(), Vector3(23, 87, -15), Vector3(1, 0, 0))
	curve.add_point(Vector3(1, 0, 0), Vector3(-1, 0, 0), Vector3(19, -22, 56))

	var baked_points := curve.get_baked_points()
	var middle_point_idx := int(len(baked_points) / 2.0)

	for idx in range(middle_point_idx, middle_point_idx + 2):
		var offset := curve.get_closest_offset(baked_points[idx])
		# Error will trigger here.
		curve.sample_baked_with_rotation(offset)


func tilt(p_curve: Curve3D) -> void:
	assert(p_curve.point_count > 0)
	var tilt_frac := 4.0 / p_curve.point_count
	for idx in p_curve.point_count:
		p_curve.set_point_tilt(idx, tilt_frac * idx)
