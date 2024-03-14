@tool
extends Path3D

@export_range(0.1, 100.0, 0.1) var depth : float = 5.0
@export_range(0.1, 10.0, 0.1) var bake_interval : float = 1.0
@export var smooth_faces = true
@export var use_collision = true
@export_range(1, 10, 1) var edge_noise_freq : int = 1

@export_range(0.0, 1.0, 0.1) var edge_noise_strength :float = 0.0

@export var terrain_mat: Material = preload("res://addons/curve_terrain/terrain.material")

var childvarlist = ["depth","smooth_faces", "use_collision"]
var oldvarlist = [0.1, 0.0, 0.1, terrain_mat]
var varlist = [bake_interval, edge_noise_strength, edge_noise_freq, "terrain_mat"]


#var old_verts = []
var vertices = []
var vert_in = []
var vert_out = []

var old_vertices = []
var old_vert_in = []
var old_vert_out = []

var generate = false
var change = 0
var time_start = 0
var time_now = 0



# Called when the node enters the scene tree for the first time.
func _ready():
	if Engine.is_editor_hint: # only run if in the editor. We don't want to have any updates occuring in game for any reason
		connect("curve_changed", self._on_Path_curve_changed)
		self.name = "Curve Terrain"
		if get_child_count() ==0:
			var lake = Lake.new()
			self.add_child(lake)
			lake.set_owner(get_tree().edited_scene_root) # uncomment to show children to user need to make this a function

			var terrain_holder = Node3D.new()
			terrain_holder.name = "Terrain Holder"
			self.add_child(terrain_holder)
			terrain_holder.set_owner(get_tree().edited_scene_root) # uncomment to show children to user need to make this a function



func _process(delta):
	if Engine.is_editor_hint:
		# If the Curve object has been updated
		varlist = [bake_interval, edge_noise_strength, edge_noise_freq]
		if generate:
			generate=false

			var time_now = Time.get_ticks_msec()
			gen_mesh(self.curve.get_baked_points())
#			print(OS.get_ticks_msec() - time_now)
			get_node("Curve Lake").gen_mesh(get_node("Curve Lake").curve.get_baked_points())
#			print(OS.get_ticks_msec() - time_now)

		# If an inspector value has been updated
		for index in range(0, varlist.size()):
			if varlist[index] != oldvarlist[index]:
				oldvarlist[index] = varlist[index]
				regen_mesh(true)

		for index in range(0, childvarlist.size()):
			for idx in range(0,get_node("Terrain Holder").get_children().size()): # should only ever be 0-1
				if get_node("Terrain Holder").get_child(idx)[childvarlist[index]] != self[childvarlist[index]]:
					get_node("Terrain Holder").get_child(idx)[childvarlist[index]] = self[childvarlist[index]]




func gen_mesh(v):
	for child in get_node("Terrain Holder").get_children():
		child.free()

	if v.size()>2:
		# situationally add noise to the edge of the mesh.
		# FUTURE: Add multiple noise profiles
		var csg_poly := CSGPolygon3D.new()
		csg_poly.set_path_node(NodePath(".."))
		csg_poly.material = terrain_mat

		var arrays = PackedVector2Array()
		var idx_mod = 0.2
		var idx_modmod = 0.001

		for idx in range(0, v.size()):
			if idx%10 == 0:
				idx_mod = idx_mod+idx_modmod
			arrays.push_back(Vector2(-v[idx].z + sin(idx*idx_mod)*edge_noise_strength, -v[idx].x+ cos(idx*idx_mod)*edge_noise_strength))

			if idx%edge_noise_freq == 0:
				idx_modmod = -idx_modmod

		csg_poly.path_rotation = CSGPolygon3D.PATH_ROTATION_POLYGON
		csg_poly.polygon = arrays
		csg_poly.set_path_joined(true)
		csg_poly.depth = depth
		csg_poly.name = "Land"

		# Relies on "Terrain Holder" existing, if user renames this will breaK
		get_node("Terrain Holder").add_child(csg_poly)
		csg_poly.set_owner(get_tree().edited_scene_root)
		csg_poly.global_rotate(Vector3(1,0,0),deg_to_rad(-90))
		csg_poly.global_rotate(Vector3(0,1,0),deg_to_rad(90))

func regen_curve(v, v_in, v_out):
	var tcurve = Curve3D.new()
	tcurve.bake_interval = bake_interval
	for index in range(0, v.size()):
		tcurve.add_point(v[index], v_in[index], v_out[index])

	return tcurve

func regen_mesh(setgetbool):
	if setgetbool:
		vertices = []
		vert_in = []
		vert_out = []
		for index in range(0, self.curve.get_point_count()):
			var pos = self.curve.get_point_position(index)
			var p_in = self.curve.get_point_in(index)
			var p_out = self.curve.get_point_out(index)
			vertices.append(Vector3(pos.x, pos.y-pos.y, pos.z))
			vert_in.append(Vector3(p_in.x, pos.y-pos.y, p_in.z))
			vert_out.append(Vector3(p_out.x, pos.y-pos.y, p_out.z))
		old_vertices = vertices
		old_vert_in = vert_in
		old_vert_out = vert_out
		self.set_curve(regen_curve(vertices, vert_in, vert_out))
		gen_mesh(self.curve.get_baked_points())
		get_node("Curve Lake").gen_mesh(get_node("Curve Lake").curve.get_baked_points())

	else:
		vertices = []
		vert_in = []
		vert_out = []
		# bit janky, but want to flatten the curve to the Y axis to make it visually match the terrain
		for index in range(0, self.curve.get_point_count()):
			var pos = self.curve.get_point_position(index)
			var p_in = self.curve.get_point_in(index)
			var p_out = self.curve.get_point_out(index)
			vertices.append(Vector3(pos.x, pos.y-pos.y, pos.z))
			vert_in.append(Vector3(p_in.x, pos.y-pos.y, p_in.z))
			vert_out.append(Vector3(p_out.x, pos.y-pos.y, p_out.z))
		if vertices.size()>2:
			if vertices != old_vertices or vert_in != old_vert_in or vert_out != old_vert_out:
				old_vertices = vertices
				old_vert_in = vert_in
				old_vert_out = vert_out
				self.set_curve(regen_curve(vertices, vert_in, vert_out))
				generate=true
			else:
				generate=false



func _on_Path_curve_changed():
	if Engine.is_editor_hint:
		vertices = []
		vert_in = []
		vert_out = []
		# bit janky, but want to flatten the curve to the Y axis to make it visually match the terrain
		for index in range(0, self.curve.get_point_count()):
			var pos = self.curve.get_point_position(index)
			var p_in = self.curve.get_point_in(index)
			var p_out = self.curve.get_point_out(index)
			vertices.append(Vector3(pos.x, pos.y-pos.y, pos.z))
			vert_in.append(Vector3(p_in.x, pos.y-pos.y, p_in.z))
			vert_out.append(Vector3(p_out.x, pos.y-pos.y, p_out.z))

		if vertices != old_vertices or vert_in != old_vert_in or vert_out != old_vert_out:
			old_vertices = vertices
			old_vert_in = vert_in
			old_vert_out = vert_out


			self.set_curve(regen_curve(vertices, vert_in, vert_out))
			generate=true
		else:
			generate=false
