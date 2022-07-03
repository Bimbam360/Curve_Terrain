tool
extends Path

export(float, 0.1, 100.0, 0.1) var depth = 1.0
export(float, 0.05, 10.0, 0.05) var bake_interval = 1.0

export var smooth_faces = true
export var use_collision = true
export(int, 1, 10, 1) var edge_noise_freq = 1
export(float, 0.0, 1.0, 0.02) var edge_noise_strength := 0.0

export(Material) var material = preload("res://addons/curve_terrain/terrain.material")

var childvarlist = ["depth","smooth_faces", "use_collision"]
var oldvarlist = [0.1, 0.0, 0.1, material]
var varlist = [bake_interval, edge_noise_strength, edge_noise_freq, "material"]

var old_vertices = PoolVector3Array()
var vertices = []
var vert_in = []
var vert_out = []
var generate = false
var change = 0


# Called when the node enters the scene tree for the first time.
func _ready():
	if Engine.editor_hint: # only run if in the editor. We don't want to have any updates occuring in game for any reason
		self.connect("curve_changed", self, "_on_Path_curve_changed")
		self.name = "Lake"


func _process(delta):
	if Engine.editor_hint:
		# If the Curve object has been updated
		varlist = [bake_interval, edge_noise_strength, edge_noise_freq]
		if generate:
			generate=false
			gen_mesh(self.curve.get_baked_points(), true)

		# If an inspector value has been updated
		for index in range(0, varlist.size()):
			if varlist[index] != oldvarlist[index]:
				oldvarlist[index] = varlist[index]
				regen_mesh()

		for index in range(0, childvarlist.size()):
			for idx in range(0,get_node("../Terrain Holder/Land").get_children().size()):
				if idx == 0: # should only ever be 0, but prevent invalid index lookups
					if get_node("../Terrain Holder/Land").get_child(idx)[childvarlist[index]] != self[childvarlist[index]]:
						get_node("../Terrain Holder/Land").get_child(idx)[childvarlist[index]] = self[childvarlist[index]]


func gen_mesh(vertices, regen):
	if vertices.size()>2:
		if vertices != old_vertices or regen:
			for child in get_node("../Terrain Holder/Land").get_children():
				child.free()

			old_vertices = vertices
			var csg_lakebed := CSGPolygon.new()
			var csg_lakewater := CSGPolygon.new()

			for csg in [csg_lakebed, csg_lakewater]:
				csg.set_path_node(NodePath(".."))
				var arrays = PoolVector2Array()
				var idx_mod = 0.2
				var idx_modmod = 0.001
				for idx in range(0, vertices.size()):
					if idx%10 == 0:
						idx_mod = idx_mod+idx_modmod
					arrays.push_back(Vector2(-vertices[idx].z + sin(idx*idx_mod)*edge_noise_strength, -vertices[idx].x+ cos(idx*idx_mod)*edge_noise_strength))

					if idx%edge_noise_freq == 0:
						idx_modmod = -idx_modmod

				csg.path_rotation = CSGPolygon.PATH_ROTATION_POLYGON
				csg.polygon = arrays
				csg.set_path_joined(true)
				csg.depth = depth
				get_node("../Terrain Holder/Land").add_child(csg)
				csg.set_owner(get_tree().edited_scene_root)

				for index in range(0, childvarlist.size()):
					csg[childvarlist[index]] = self[childvarlist[index]]

			# Lakebed Specific
			csg_lakebed.material = load("res://addons/curve_terrain/lakebed.material") # hardcoded, fix this later
			csg_lakebed.translation.z = 0.1 # moving up slightly to avoid coplanar issues with CSG
			csg_lakebed.name='lake'
			csg_lakebed.operation = CSGShape.OPERATION_SUBTRACTION

			# Lakewater Specific
			csg_lakewater.material = load("res://addons/curve_terrain/lakewater.material") # hardcoded, fix this later
			csg_lakewater.translation.z = -0.1 # moving down
			csg_lakewater.name = 'water'
			csg_lakewater.depth = 0.001
			csg_lakewater.operation = CSGShape.OPERATION_UNION
			csg_lakewater.scale = Vector3(1.01,1.01,1.01)

	else:
		for child in get_node("../Terrain Holder/Land").get_children():
			child.free() # 'dangerous', but breaks otherwise


func regen_curve(vertices, vert_in, vert_out):
	var tcurve = Curve3D.new()
	tcurve.bake_interval = bake_interval
	for index in range(0, vertices.size()):
		tcurve.add_point(vertices[index], vert_in[index], vert_out[index])

	return tcurve


func regen_mesh():
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

	self.set_curve(regen_curve(vertices, vert_in, vert_out))
	generate=true



func _on_Path_curve_changed():
	if change > 0: # prevent recursive loop due to continoues Curve changes
		change = 0
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

		self.set_curve(regen_curve(vertices, vert_in, vert_out))
		generate=true

	change+=1
