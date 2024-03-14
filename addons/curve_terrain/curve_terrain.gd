@tool
extends EditorPlugin

func _enter_tree():
	add_custom_type("Curve_terrain", "Path3D", preload("path_terrain.gd"), preload("land.png"))

func _exit_tree():
	# Clean-up of the plugin goes here.
	remove_custom_type("Curve_terrain")
