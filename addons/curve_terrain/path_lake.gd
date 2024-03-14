@icon("res://addons/curve_terrain/lake.png")
@tool
class_name Lake
extends Path3D


@export_range(0.1, 100.0, 0.1) var depth : float = 1.0
@export_range(0.05, 10.0, 0.05) var bake_interval : float = 1.0

@export var smooth_faces = true
@export var use_collision = true
@export_range(1, 10, 1) var edge_noise_freq : int = 1
@export_range(0.0, 1.0, 0.02) var edge_noise_strength : float = 0.0

@export var lakebed_mat : Material =  preload("res://addons/curve_terrain/lakebed.material")
@export var lakewater_mat : Material =  preload("res://addons/curve_terrain/lakewater.material")

var childvarlist = ["depth","smooth_faces", "use_collision"]
var oldvarlist = [0.1, 0.0, 0.1, lakebed_mat, lakewater_mat]
var varlist = [bake_interval, edge_noise_strength, edge_noise_freq, lakebed_mat, lakewater_mat]

var vertices = []
var vert_in = []
var vert_out = []

var old_vertices = []
var old_vert_in = []
var old_vert_out = []

var generate = false
var change = 0

var queue = []

# Called when the node enters the scene tree for the first time.
func _ready():
	if Engine.is_editor_hint: # only run if in the editor. We don't want to have any updates occuring in game for any reason
		connect("curve_changed", self._on_Path_curve_changed_lake)
		self.name = "Curve Lake"


var counter = 0.0
func _process(delta):
	if Engine.is_editor_hint:
		# If the Curve object has been updated
		varlist = [bake_interval, edge_noise_strength, edge_noise_freq]
#		if generate:
#			generate=false
#			gen_mesh(self.curve.get_baked_points())

		# If an inspector value has been updated
		for index in range(0, varlist.size()):
			if varlist[index] != oldvarlist[index]:
				oldvarlist[index] = varlist[index]
				regen_mesh(true)

		for index in range(0, childvarlist.size()):
			if get_node("../Terrain Holder").get_children().size() > 0:
				for idx in range(0,get_node("../Terrain Holder/Land").get_children().size()):
					if idx == 0: # should only ever be 0, but prevent invalid index lookups
						if get_node("../Terrain Holder/Land").get_child(idx)[childvarlist[index]] != self[childvarlist[index]]:
							get_node("../Terrain Holder/Land").get_child(idx)[childvarlist[index]] = self[childvarlist[index]]


func _physics_process(delta):
	if Engine.is_editor_hint:
		if self.lakewater_mat.get_class() == "ShaderMaterial":
			self.lakewater_mat.set_shader_param("usetime",1)
			self.lakewater_mat.set_shader_param("time",counter)

		counter+= delta
		if counter >3600:
			counter=0
	else:
		if self.lakewater_mat.get_class() == "ShaderMaterial":
			self.lakewater_mat.set_shader_param("usetime",0)

####################################################################################################
####################################################################################################
####################################################################################################
####################################################################################################
####################################################################################################

func gen_mesh(v):
	if get_node("../Terrain Holder").get_children().size() > 0:
		for child in get_node("../Terrain Holder/Land").get_children():
			child.free()

		if v.size()>2:
			var csg_lakebed := CSGPolygon3D.new()
			var csg_lakewater := CSGPolygon3D.new()

			for csg in [csg_lakebed, csg_lakewater]:
				csg.set_path_node(NodePath(".."))
				var arrays = PackedVector2Array()
				var idx_mod = 0.2
				var idx_modmod = 0.001
				for idx in range(0, v.size()):
					if idx%10 == 0:
						idx_mod = idx_mod+idx_modmod
					arrays.push_back(Vector2(-v[idx].z + sin(idx*idx_mod)*edge_noise_strength, -v[idx].x+ cos(idx*idx_mod)*edge_noise_strength))

					if idx%edge_noise_freq == 0:
						idx_modmod = -idx_modmod

				csg.path_rotation = CSGPolygon3D.PATH_ROTATION_POLYGON
				csg.polygon = arrays
				csg.set_path_joined(true)
				csg.depth = depth


			# Lakebed Specific
			csg_lakebed.material = lakebed_mat # hardcoded, fix this later
			csg_lakebed.translation.z = 0.1 # moving up slightly to avoid coplanar issues with CSG
			csg_lakebed.name='lake'
			csg_lakebed.operation = CSGShape3D.OPERATION_SUBTRACTION

			# Lakewater Specific
			csg_lakewater.material = lakewater_mat # hardcoded, fix this later
			csg_lakewater.translation.z = -0.1 # moving down
			csg_lakewater.name = 'water'
			csg_lakewater.depth = 0.001
			csg_lakewater.operation = CSGShape3D.OPERATION_UNION
			csg_lakewater.scale = Vector3(1.01,1.01,1.01)

			for csg in [csg_lakebed, csg_lakewater]:
				get_node("../Terrain Holder/Land").add_child(csg)
				csg.set_owner(get_tree().edited_scene_root)


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


		if vertices != old_vertices or vert_in != old_vert_in or vert_out != old_vert_out:
			old_vertices = vertices
			old_vert_in = vert_in
			old_vert_out = vert_out

			self.set_curve(regen_curve(vertices, vert_in, vert_out))
			gen_mesh(self.curve.get_baked_points())



func _on_Path_curve_changed_lake():
	if Engine.is_editor_hint:
		if change > 0: # prevent recursive loop due to continoues Curve changes
			change = 0
			regen_mesh(false)

		change+=1


